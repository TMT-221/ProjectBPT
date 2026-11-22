import test from 'node:test';
import assert from 'node:assert/strict';
import {mkdtemp,readFile,rm} from 'node:fs/promises';
import {tmpdir} from 'node:os';
import {join} from 'node:path';
import {request as httpRequest} from 'node:http';
import {request as httpsRequest} from 'node:https';
import {once} from 'node:events';
import {createSecurityAudit,auditResource} from '../security_audit.mjs';
import {createApp,tlsFromEnvironment} from '../server.mjs';
import {openDatabase,demoPassword} from '../db.mjs';

async function start(server){server.listen(0,'127.0.0.1');await once(server,'listening');return server;}
async function stop(server){await new Promise((resolve,reject)=>server.close(error=>error?reject(error):resolve()));}
async function call(server,path,{body,cookie,csrf,origin,ca}={}){
 const bytes=body===undefined?undefined:JSON.stringify(body);
 return new Promise((resolve,reject)=>{
  const req=(ca?httpsRequest:httpRequest)({hostname:'127.0.0.1',port:server.address().port,path:'/api/v1'+path,
   method:bytes===undefined?'GET':'POST',...(ca?{ca}:{}),headers:{...(bytes===undefined?{}:{'content-type':'application/json','content-length':Buffer.byteLength(bytes)}),
    ...(cookie?{cookie}:{}),...(csrf?{'x-csrf-token':csrf}:{}),...(origin?{origin}:{})}},res=>{
   let data='';res.setEncoding('utf8');res.on('data',part=>{data+=part;});
   res.on('end',()=>{try{resolve({status:res.statusCode,headers:res.headers,...(data?JSON.parse(data):{})});}catch(error){reject(error);}});
  });req.on('error',reject);req.end(bytes);
 });
}
const login=async(server,name,extra={})=>{
 const result=await call(server,'/auth/login',{body:{email:name+'@lab.local',password:demoPassword},...extra});
 assert.equal(result.status,200,JSON.stringify(result));
 return {cookie:result.headers['set-cookie'][0].split(';')[0],csrf:result.data.csrf,user:result.data,result};
};

test('Nhật ký bảo mật nối tiếp, ghi bền vững và chỉ giữ trường an toàn',async t=>{
 const directory=await mkdtemp(join(tmpdir(),'labtrack-audit-'));
 t.after(()=>rm(directory,{recursive:true,force:true}));
 const file=join(directory,'nested','events.jsonl');
 const audit=await createSecurityAudit(file);
 const secret='never-log-this-password-cookie-token-email@example.test';
 await Promise.all(Array.from({length:20},(_,i)=>audit.record({action:'api.mutation',outcome:'success',actor_id:'10',resource:'/api/v1/chemical-receipts',method:'POST',status:201,
  request_id:'12345678-1234-1234-1234-123456789abc',password:secret,cookie:secret,token:secret,csrf_token:secret,body:{reason:secret},sql:secret,
  metadata:{record_count:i,encrypted:true,password:secret,filename:secret}})));
 await audit.flush();
 const first=await readFile(file,'utf8');
 await audit.close();
 const records=first.trim().split('\n').map(JSON.parse);
 assert.equal(records.length,20);
 assert.deepEqual(records.map(row=>row.metadata.record_count),Array.from({length:20},(_,i)=>i));
 assert.ok(records.every(row=>row.timestamp.endsWith('Z')&&row.actor_id==='10'));
 assert.ok(!first.includes(secret));
 assert.ok(!first.includes('password')&&!first.includes('cookie')&&!first.includes('csrf_token'));
 const reopened=await createSecurityAudit(file);
 await reopened.record({action:'backup.save',outcome:'success',actor_id:null,resource:'backup',method:'CLI',metadata:{encrypted:true}});
 await reopened.close();
 const final=await readFile(file,'utf8');
 assert.ok(final.startsWith(first));assert.equal(final.trim().split('\n').length,21);
 await assert.rejects(reopened.record({action:'api.mutation',outcome:'success'}),/closed/);
 assert.equal(auditResource('/auth/login?password='+secret),'unknown');
 assert.equal(auditResource('/reports/'+secret),'unknown');
 assert.equal(auditResource('/points/1/chemical-allocations'),'/api/v1/points/1/chemical-allocations');
});

test('HTTP ghi đăng nhập, từ chối quyền, CSRF, giao dịch và giới hạn thử sai',async t=>{
 const directory=await mkdtemp(join(tmpdir(),'labtrack-security-http-'));
 const file=join(directory,'events.jsonl'),audit=await createSecurityAudit(file),db=await openDatabase('memory://');
 const server=await start(createApp(db,{audit}));
 t.after(async()=>{await stop(server);await audit.close();await db.close();await rm(directory,{recursive:true,force:true});});
 assert.equal((await call(server,'/equipment')).status,401);
 const secret='private-secret-password-and-reason';
 const invalid=await call(server,'/auth/login',{body:{email:'private-email@example.test',password:secret}});
 assert.equal(invalid.status,401);
 const tech=await login(server,'technician');
 const receipt={chemical_id:'3',quantity:'1',reason:secret};
 const csrf=await call(server,'/chemical-receipts',{body:receipt,cookie:tech.cookie});
 assert.equal(csrf.status,403);
 const forbidden=await call(server,'/grants/1/budget',{body:{remaining_budget:'1'},cookie:tech.cookie,csrf:tech.csrf});
 assert.equal(forbidden.status,403);
 const success=await call(server,'/chemical-receipts',{body:receipt,cookie:tech.cookie,csrf:tech.csrf});
 assert.equal(success.status,201);
 const failure=await call(server,'/chemical-receipts',{body:{...receipt,quantity:'-1'},cookie:tech.cookie,csrf:tech.csrf});
 assert.equal(failure.status,400);
 const forged=await call(server,'/chemical-receipts',{body:{...receipt,person_id:'999'},cookie:tech.cookie,csrf:tech.csrf});
 assert.equal(forged.status,400);
 const logout=await call(server,'/auth/logout',{body:{},cookie:tech.cookie,csrf:tech.csrf});
 assert.equal(logout.status,204);
 assert.equal((await call(server,'/equipment',{cookie:tech.cookie})).status,401);
 for(let i=0;i<11;i++){
  const attempt=await call(server,'/auth/login',{body:{email:'private-email@example.test',password:secret}});
  assert.equal(attempt.status,i===10?429:401);
 }
 assert.equal((await call(server,'/auth/login',{body:{email:'private-email@example.test',password:secret},origin:'https://other.invalid'})).status,403);
 await audit.flush();
 const text=await readFile(file,'utf8'),rows=text.trim().split('\n').map(JSON.parse);
 for(const value of [secret,'private-email@example.test',demoPassword,tech.cookie,tech.csrf])assert.ok(!text.includes(value));
 assert.ok(rows.some(row=>row.action==='auth.login'&&row.outcome==='success'&&row.actor_id==='10'));
 assert.ok(rows.some(row=>row.action==='auth.login'&&row.status===401&&row.actor_id===null));
 assert.ok(rows.some(row=>row.action==='auth.login'&&row.status===429));
 assert.ok(rows.some(row=>row.action==='access.denied'&&row.status===401));
 assert.ok(rows.some(row=>row.action==='auth.logout'&&row.outcome==='success'&&row.actor_id==='10'));
 const forRequest=response=>rows.find(row=>row.request_id===response.request_id);
 assert.equal(forRequest(csrf).error_code,'CSRF_REQUIRED');
 assert.equal(forRequest(forbidden).outcome,'denied');
 assert.equal(forRequest(success).outcome,'success');
 assert.equal(forRequest(success).resource,'/api/v1/chemical-receipts');
 assert.equal(forRequest(failure).outcome,'failure');
 assert.equal(forRequest(forged).actor_id,'10');
 assert.ok(rows.every(row=>/^[0-9a-f-]{36}$/i.test(row.request_id)&&row.timestamp.endsWith('Z')));
});

test('Lỗi ghi nhật ký được báo rõ và không đổi giao dịch đã thành công thành lỗi HTTP',async t=>{
 const db=await openDatabase('memory://');
 const errors=[],audit={record:async()=>{throw Object.assign(new Error('private raw detail'),{code:'EACCES'});},flush:async()=>{}};
 const server=await start(createApp(db,{audit,logger:{error:(...args)=>errors.push(args)}}));
 t.after(async()=>{await stop(server);await db.close();});
 const tech=await login(server,'technician');
 const before=Number((await db.query('SELECT quantity_in_stock FROM lab_tracker.chemical WHERE chemical_id=3')).rows[0].quantity_in_stock);
 const result=await call(server,'/chemical-receipts',{body:{chemical_id:'3',quantity:'1',reason:'Test audit failure'},cookie:tech.cookie,csrf:tech.csrf});
 assert.equal(result.status,201);
 assert.equal(Number((await db.query('SELECT quantity_in_stock FROM lab_tracker.chemical WHERE chemical_id=3')).rows[0].quantity_in_stock),before+1);
 assert.ok(errors.length>=2);assert.ok(JSON.stringify(errors).includes('EACCES'));assert.ok(!JSON.stringify(errors).includes('private raw detail'));
});

test('HTTPS yêu cầu đủ cấu hình, dùng chứng chỉ kiểm thử và đặt cookie Secure',async t=>{
 assert.equal(await tlsFromEnvironment({}),undefined);
 await assert.rejects(tlsFromEnvironment({LABTRACK_TLS_CERT:'missing.pem'}),/đồng thời/);
 await assert.rejects(tlsFromEnvironment({LABTRACK_TLS_KEY:'missing.pem'}),/đồng thời/);
 assert.throws(()=>createApp({}, {tls:{cert:Buffer.from('incomplete')}}),/cả chứng chỉ/);
 const cert=await readFile(new URL('./fixtures/tls/localhost-cert.pem',import.meta.url));
 const key=await readFile(new URL('./fixtures/tls/localhost-key.pem',import.meta.url));
 const db=await openDatabase('memory://');
 const server=await start(createApp(db,{tls:{cert,key}}));
 t.after(async()=>{await stop(server);await db.close();});
 assert.equal((await call(server,'/equipment',{ca:cert})).status,401);
 const tech=await login(server,'technician',{ca:cert});
 assert.match(tech.result.headers['set-cookie'][0],/; Secure(?:;|$)/);
 assert.equal((await call(server,'/auth/me',{cookie:tech.cookie,ca:cert})).status,200);
 const logout=await call(server,'/auth/logout',{body:{},cookie:tech.cookie,csrf:tech.csrf,ca:cert});
 assert.equal(logout.status,204);assert.match(logout.headers['set-cookie'][0],/; Secure(?:;|$)/);
});
