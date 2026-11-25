import { createServer } from 'node:http';
import { createServer as createHttpsServer } from 'node:https';
import { readFile } from 'node:fs/promises';
import { pathToFileURL,fileURLToPath } from 'node:url';
import { randomUUID } from 'node:crypto';
import { cookie, cookieValue, openDatabase, same, sessionUser, signIn, signOut, withRole } from './db.mjs';
import { routeApi } from './api.mjs';
import { startBackupService } from './backup_service.mjs';
import {auditResource,createSecurityAudit} from './security_audit.mjs';
import {portFromEnvironment,publicOriginFromEnvironment,validatePublicOrigin} from './deployment.mjs';

const staticFiles=new Map([
 ['/', ['index.html','text/html; charset=utf-8']],
 ['/index.html',['index.html','text/html; charset=utf-8']],
 ['/style.css',['style.css','text/css; charset=utf-8']],
 ['/app.js',['app.js','text/javascript; charset=utf-8']],
 ['/icons.js',['icons.js','text/javascript; charset=utf-8']],
 ['/favicon.svg',['favicon.svg','image/svg+xml']],
]);
const json=value=>JSON.stringify(value,(_,v)=>typeof v==='bigint'?v.toString():v);
const fail=(status,message,code)=>Object.assign(new Error(message),{status,code});
const limit=16384;
async function readBody(req){
 if (!/^application\/json(?:\s*;|$)/i.test(req.headers['content-type']||'')) throw fail(415,'Yêu cầu phải ở định dạng JSON.');
 let length=0;
 const parts=[];
 for await(const part of req){
  length+=part.length;
  if(length<=limit) parts.push(part);
 }
 if(length>limit) throw fail(413,'Dữ liệu gửi quá lớn.');
 try{
  const result=JSON.parse(Buffer.concat(parts).toString('utf8'));
  if(!result || Array.isArray(result) || typeof result!=='object') throw new Error();
  return result;
 }catch{throw fail(400,'Dữ liệu JSON không hợp lệ.');}
}
function write(res,status,value){
 res.statusCode=status;
 if(value!==undefined){
  res.setHeader('Content-Type','application/json; charset=utf-8');
  res.end(json(value));
 }else res.end();
}
const responses={400:'BAD_REQUEST',401:'UNAUTHENTICATED',403:'FORBIDDEN',404:'NOT_FOUND',405:'METHOD_NOT_ALLOWED',409:'CONFLICT',413:'TOO_LARGE',415:'UNSUPPORTED_MEDIA_TYPE',429:'TOO_MANY_ATTEMPTS'};
const nonPublicFields=new Set(['person_id','approved_by','technician_id','actor','p_actor','role','permissions','status','actual_return_date','entry_time','exit_time','quantity_in_stock']);
const sqlError=(error)=>{
 if(error.code==='23505') return fail(409,'Dữ liệu đã tồn tại hoặc tài sản đang được sử dụng.','CONFLICT');
 if(error.code==='23514') return fail(409,'Giá trị không đáp ứng ràng buộc dữ liệu.','CHECK_CONSTRAINT');
 if(error.code==='23503') return fail(409,'Không thể thay đổi vì có dữ liệu đang tham chiếu.','FOREIGN_KEY');
 if(['22003','22007','22008','22P02','22001'].includes(error.code)) return fail(400,'Giá trị vượt giới hạn hoặc sai định dạng.','INVALID_VALUE');
 if(['40P01','40001'].includes(error.code)) return fail(409,'Dữ liệu vừa thay đổi. Hãy tải lại và thử lại.','RETRY');
 return error;
};
export async function tlsFromEnvironment(env=process.env){
 const cert=env.LABTRACK_TLS_CERT,key=env.LABTRACK_TLS_KEY;
 if(!!cert!==!!key)throw new Error('Cần cấu hình đồng thời LABTRACK_TLS_CERT và LABTRACK_TLS_KEY.');
 if(!cert)return undefined;
 const [certificate,privateKey]=await Promise.all([readFile(cert),readFile(key)]);
 return {cert:certificate,key:privateKey,minVersion:'TLSv1.2'};
}
export function createApp(db,{logger=console,audit,tls,publicOrigin}={}){
 if(tls&&(!tls.cert||!tls.key))throw new Error('HTTPS cần cả chứng chỉ và khóa riêng.');
 if(publicOrigin!==undefined)publicOrigin=validatePublicOrigin(publicOrigin);
 const attempts=new Map();
 let busyLogins=0;
 const handler=async (req,res)=>{
  const id=randomUUID();
  const method=req.method;
  let route,actor;
  const record=async event=>{
   if(!audit)return;
   try{await audit.record({request_id:id,actor_id:actor?.person_id??null,resource:auditResource(route),method,...event});}
   catch(error){logger.error?.('UniLab security audit write failed (%s).',/^[A-Z0-9_]+$/.test(error?.code||'')?error.code:'AUDIT_WRITE_FAILED');}
  };
  res.setHeader('X-Content-Type-Options','nosniff');
  res.setHeader('Referrer-Policy','no-referrer');
  res.setHeader('X-Frame-Options','DENY');
  res.setHeader('Permissions-Policy','camera=(), microphone=(), geolocation=()');
  res.setHeader('Content-Security-Policy',"default-src 'self'; base-uri 'none'; object-src 'none'; frame-ancestors 'none'; script-src 'self'; style-src 'self' 'unsafe-inline'; img-src 'self' data:; connect-src 'self'; form-action 'self'");
  res.setHeader('Cache-Control','no-store');
  try{
   const url=new URL(req.url,'http://localhost');
   const path=url.pathname;
   if(!path.startsWith('/api/v1/')){
    if(!['GET','HEAD'].includes(method)) throw fail(405,'Phương thức không được hỗ trợ.');
    const item=staticFiles.get(path);
    if(!item) throw fail(404,'Không tìm thấy trang.');
    const bytes=await readFile(new URL('public/'+item[0],import.meta.url));
    res.setHeader('Content-Type',item[1]);
    res.setHeader('Content-Length',bytes.length);
    return res.end(method==='HEAD'?undefined:bytes);
   }
   route=path.slice('/api/v1'.length);
   if(!['GET','POST'].includes(method)) throw fail(405,'Phương thức không được hỗ trợ.');
   if(method==='POST'&&req.headers.origin){
    const allowed=publicOrigin||new URL(`${req.socket.encrypted?'https':'http'}://${req.headers.host}`).origin;
    if(req.headers.origin!==allowed) throw fail(403,'Nguồn yêu cầu không hợp lệ.');
   }
   const session=cookieValue(req.headers);
   if(method==='GET'&&route==='/preview'){
    const data=await withRole(db,'business',tx=>routeApi({method,path:'/dashboard',params:new URLSearchParams(),user:null,db:tx}));
    return write(res,200,{data,request_id:id});
   }
   if(method==='POST'&&route==='/auth/login'){
    const now=Date.now(), ip=req.socket.remoteAddress||'local';
    for(const [key,a] of attempts) if(a.reset<=now) attempts.delete(key);
    const entry=attempts.get(ip)||{count:0,reset:now+5*60_000};
    if(entry.count>=10||busyLogins>=3) throw fail(429,'Quá nhiều lần thử. Vui lòng thử lại sau.');
    const body=await readBody(req);
    if(Object.keys(body).some(key=>key!=='email'&&key!=='password') || typeof body.email!=='string' || typeof body.password!=='string' || body.email.length>254 || body.password.length>128 || !body.password)
     throw fail(400,'Vui lòng nhập email và mật khẩu hợp lệ.');
    busyLogins++;
    let result;
    try{result=await signIn(db,body.email.trim().toLowerCase(),body.password,session);}
    finally{busyLogins--;}
    if(!result){entry.count++;attempts.set(ip,entry);throw fail(401,'Email hoặc mật khẩu không hợp lệ.');}
    attempts.delete(ip);
    actor=result.user;
    await record({action:'auth.login',outcome:'success',status:200});
    res.setHeader('Set-Cookie',cookie(result.session,!!publicOrigin||req.socket.encrypted));
    return write(res,200,{data:result.user,request_id:id});
   }
   const user=await sessionUser(db,session);
   if(!user) throw fail(401,'Vui lòng đăng nhập để tiếp tục.');
   actor=user;
   if(method==='GET'&&route==='/auth/me') return write(res,200,{data:user,request_id:id});
   let body={};
   if(method==='POST'){
    if(!same(req.headers['x-csrf-token'],user.csrf)) throw fail(403,'Phiên thao tác không hợp lệ. Hãy tải lại trang.','CSRF_REQUIRED');
    if(route==='/auth/logout'){
     await signOut(db,session);
     await record({action:'auth.logout',outcome:'success',status:204});
     res.setHeader('Set-Cookie',cookie('',!!publicOrigin||req.socket.encrypted));
     return write(res,204);
    }
    if(!user.permissions.includes('member')) throw fail(403,'Tài khoản này chỉ có quyền đọc.');
    body=await readBody(req);
    if(Object.keys(body).some(key=>nonPublicFields.has(key)&&!(key==='status'&&/^\/grants\/[1-9]\d*\/points$/.test(route)))) throw fail(400,'Danh tính và trạng thái được xác lập bởi hệ thống.','SERVER_CONTROLLED_FIELD');
   }
   const data=await withRole(db,'business',tx=>routeApi({method,path:route,params:url.searchParams,body,user,db:tx}));
   if(data===undefined) throw fail(404,'Không tìm thấy chức năng.');
   const status=method==='POST'&&!/(\/return|\/exit|\/complete|\/budget|\/location|\/safety)$/.test(route)?201:200;
   if(method==='POST')await record({action:'api.mutation',outcome:'success',status});
   return write(res,status,{data,request_id:id});
  }catch(raw){
   const error=sqlError(raw);
   const status=Number.isInteger(error.status)&&error.status>=400&&error.status<500?error.status:500;
   const code=status===500?'SERVER_ERROR':(error.code||responses[status]||'BAD_REQUEST');
   if(route!==undefined&&(method==='POST'||[401,403,429].includes(status))){
    const action=route==='/auth/login'?'auth.login':route==='/auth/logout'?'auth.logout':method==='POST'?'api.mutation':'access.denied';
    await record({action,outcome:[401,403,429].includes(status)?'denied':'failure',status,error_code:code});
   }
   if(status===500) logger.error?.('UniLab request %s failed (%s).',id,code);
   return write(res,status,{error:{code:status===500?'SERVER_ERROR':(error.code||responses[status]),message:status===500?'Không thể xử lý yêu cầu. Vui lòng thử lại.':error.message},request_id:id});
  }
 };
 const server=tls?createHttpsServer({...tls,minVersion:tls.minVersion||'TLSv1.2'},handler):createServer(handler);
 server.flushSecurityAudit=async()=>{if(audit)await audit.flush();};
 return server;
}

if(process.argv[1]&&import.meta.url===pathToFileURL(process.argv[1]).href){
 const port=portFromEnvironment();
 const publicOrigin=publicOriginFromEnvironment(process.env,port);
 const tls=await tlsFromEnvironment();
 const audit=await createSecurityAudit(process.env.LABTRACK_AUDIT_FILE||fileURLToPath(new URL('.logs/security-events.jsonl',import.meta.url)));
 let db,server,backups;
 try{
  db=await openDatabase(process.env.LABTRACK_DATA_DIR||undefined,{dataset:process.env.LABTRACK_DATASET||'1200'});
  backups=startBackupService(db,{
   directory:process.env.LABTRACK_BACKUP_DIR,
   passphrase:process.env.LABTRACK_BACKUP_PASSPHRASE,
   onSnapshot:async snapshot=>{
    try{await audit.record({action:'backup.created',outcome:'success',resource:'backup',method:'CLI',
     metadata:{encrypted:snapshot.encrypted,scheduled:true,record_count:snapshot.record_count,duration_ms:snapshot.duration_ms}});}
    catch{console.error('Không thể ghi sự kiện sao lưu vào nhật ký bảo mật.');}
   },
   onError:async()=>{
    console.error('Không thể tạo bản sao lưu tự động. Kiểm tra thư mục sao lưu và cấu hình.');
    try{await audit.record({action:'backup.failed',outcome:'failure',resource:'backup',method:'CLI',error_code:'BACKUP_FAILED'});}
    catch{console.error('Không thể ghi sự kiện sao lưu vào nhật ký bảo mật.');}
   },
  });
  await backups.ready;
  server=createApp(db,{audit,tls,publicOrigin});
 }catch(error){
  try{await backups?.stop();await db?.close();}finally{await audit.close();}
  throw error;
 }
 let closing=false;
 const cleanup=async()=>{
  if(closing)return;closing=true;
  try{await backups.stop();await db.close();}finally{await audit.close();}
 };
 server.on('error',async error=>{console.error(error.message);try{await cleanup();}catch(error){console.error('Không thể hoàn tất nhật ký bảo mật.');}process.exitCode=1;});
 server.listen(port,'127.0.0.1',()=>console.log(`UniLab • ${publicOrigin||`${tls?'https':'http'}://127.0.0.1:${port}`}`));
 for(const signal of ['SIGINT','SIGTERM']) process.once(signal,()=>server.close(async()=>{
  try{await cleanup();}catch(error){console.error('Không thể hoàn tất nhật ký bảo mật.');process.exitCode=1;}
 }));
}
