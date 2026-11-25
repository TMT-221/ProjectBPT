import test from 'node:test';
import assert from 'node:assert/strict';
import {once} from 'node:events';
import {createHash} from 'node:crypto';
import {createApp} from '../server.mjs';
import {demoPassword,openDatabase} from '../db.mjs';

test('Security S21-S29: HTTP isolation, SQL injection and authentication',async t=>{
 const db=await openDatabase('memory://');
 const server=createApp(db,{logger:{error(){}}});
 server.listen(0,'127.0.0.1');
 await once(server,'listening');
 const base=`http://127.0.0.1:${server.address().port}`;
 t.after(async()=>{await new Promise(resolve=>server.close(resolve));await db.close();});
 const scalar=async(sql,args=[])=>Object.values((await db.query(sql,args)).rows[0])[0];
 const request=async(path,{actor,body,csrf=true,headers={}}={})=>{
  const post=body!==undefined;
  const response=await fetch(base+'/api/v1'+path,{
   method:post?'POST':'GET',headers:{
    ...(actor?{cookie:actor.cookie}:{}),...(post?{'content-type':'application/json'}:{}),
    ...(actor&&post&&csrf?{'x-csrf-token':actor.user.csrf}:{}),...headers,
   },body:post?JSON.stringify(body):undefined,
  });
  return {status:response.status,payload:response.status===204?{}:await response.json(),cookie:response.headers.get('set-cookie')};
 };
 const expect=async(promise,status)=>{
  const result=await promise;assert.equal(result.status,status,JSON.stringify(result));return result;
 };
 const login=async(email)=>{
  const result=await expect(request('/auth/login',{body:{email,password:demoPassword}}),200);
  return {cookie:result.cookie.split(';')[0],setCookie:result.cookie,user:result.payload.data};
 };
 const catalogSql=`SELECT c.table_name,c.column_name,c.data_type,c.is_nullable
  FROM information_schema.columns c JOIN information_schema.tables t USING(table_catalog,table_schema,table_name)
  WHERE c.table_schema='lab_tracker' AND t.table_type='BASE TABLE' ORDER BY c.table_name,c.ordinal_position`;
 const schemaBefore=(await db.query(catalogSql)).rows;
 const equipmentBefore=await scalar('SELECT count(*)::int FROM lab_tracker.equipment');
 let student,faculty,admin;

 await t.test('S21: login SQL injection cannot create an authenticated session',async()=>{
  const sessionsBefore=await scalar('SELECT count(*)::int FROM app_auth.session');
  for(const body of [
   {email:"admin@lab.local' OR '1'='1' --",password:'incorrect'},
   {email:'admin@lab.local',password:"' OR '1'='1' --"},
  ]){
   const result=await expect(request('/auth/login',{body}),401);
   assert.equal(result.cookie,null);
   assert.equal(result.payload.error.code,'UNAUTHENTICATED');
  }
  assert.equal(await scalar('SELECT count(*)::int FROM app_auth.session'),sessionsBefore);
  await expect(request('/auth/me'),401);
  student=await login('student@lab.local');
  faculty=await login('faculty@lab.local');
  admin=await login('admin@lab.local');
  assert.equal(admin.user.person_id,'2');
 });
 await t.test('S22: search treats SQL predicates and DROP payloads as literal text',async()=>{
  const baseline=await expect(request('/equipment',{actor:student}),200);
  assert.equal(baseline.payload.data.total,equipmentBefore);
  for(const attack of ["' OR 1=1 --","'; DROP TABLE lab_tracker.equipment; --"]){
   const result=await expect(request('/equipment?q='+encodeURIComponent(attack),{actor:student}),200);
   assert.equal(result.payload.data.total,0);
   assert.deepEqual(result.payload.data.rows,[]);
   assert.equal(await scalar('SELECT count(*)::int FROM lab_tracker.equipment'),equipmentBefore);
  }
  const valid=await expect(request('/equipment?q='+encodeURIComponent('Máy trạm'),{actor:student}),200);
  assert.equal(valid.payload.data.total,2);
 });
 await t.test('S23: sort allowlist accepts valid columns and rejects injected SQL',async()=>{
  const valid=await expect(request('/equipment?sort=-purchase_date&page_size=100',{actor:student}),200);
  const expected=(await db.query('SELECT equipment_id::text FROM lab_tracker.equipment ORDER BY purchase_date DESC NULLS LAST,equipment_name,equipment_id')).rows;
  assert.deepEqual(valid.payload.data.rows.map(row=>row.equipment_id),expected.map(row=>row.equipment_id));
  for(const attack of ['equipment_name; DROP TABLE lab_tracker.equipment; --',"(SELECT password_hash FROM app_auth.user_account LIMIT 1)"]){
   const result=await expect(request('/equipment?sort='+encodeURIComponent(attack),{actor:student}),400);
   assert.equal(result.payload.error.code,'INVALID_FIELD');
   assert.equal(await scalar('SELECT count(*)::int FROM lab_tracker.equipment'),equipmentBefore);
  }
 });
 await t.test('S24: self-service history remains scoped to the session owner',async()=>{
  // Add only an authentication fixture for an existing person with nonempty history.
  await db.query(`INSERT INTO app_auth.user_account(person_id,email,password_hash)
   SELECT 4,'privacy-target@lab.local',password_hash FROM app_auth.user_account WHERE person_id=7`);
  await db.query("INSERT INTO app_auth.account_role(person_id,role) VALUES(4,'member')");
  const owner=await login('privacy-target@lab.local');
  for(const [endpoint,table,key] of [['/me/borrows','borrow_transaction','borrow_id'],['/me/access','access_log','log_id']]){
   const expected=(await db.query(`SELECT ${key}::text AS id FROM lab_tracker.${table} WHERE person_id=4`)).rows.map(row=>row.id).sort();
   assert.ok(expected.length>0);
   const foreign=(await db.query(`SELECT ${key}::text AS id FROM lab_tracker.${table} WHERE person_id=5`)).rows.map(row=>row.id);
   const result=await expect(request(endpoint+'?person_id=5&page_size=100',{actor:owner}),200);
   const actual=result.payload.data.rows.map(row=>row[key]).sort();
   assert.equal(result.payload.data.total,expected.length);
   assert.deepEqual(actual,expected);
   assert.ok(actual.every(id=>!foreign.includes(id)));
  }
 });
 await t.test('S25: budget and personal attributes follow API permissions',async()=>{
  const all=await expect(request('/grants',{actor:student}),200);
  assert.ok(all.payload.data.rows.length>0);
  assert.ok(all.payload.data.rows.every(row=>row.total_budget===null&&row.remaining_budget===null));
  const own=await expect(request('/grants/2',{actor:faculty}),200);
  assert.ok(Number(own.payload.data.total_budget)>0);
  const other=await expect(request('/grants/1',{actor:faculty}),200);
  assert.equal(other.payload.data.total_budget,null);
  assert.equal(other.payload.data.remaining_budget,null);
  const administrative=await expect(request('/grants/1',{actor:admin}),200);
  assert.ok(Number(administrative.payload.data.total_budget)>0);
  const students=await expect(request('/students',{actor:faculty}),200);
  assert.ok(students.payload.data.length>0);
  for(const row of students.payload.data)for(const key of ['email','phone','date_of_birth','password_hash'])assert.equal(Object.hasOwn(row,key),false);
  await expect(request('/students',{actor:student}),403);
 });
 await t.test('S26: session cookie and stored password/token use their intended protections',async()=>{
  assert.match(admin.setCookie,/; HttpOnly(?:;|$)/);
  assert.match(admin.setCookie,/; SameSite=Strict(?:;|$)/);
  assert.match(admin.setCookie,/; Max-Age=28800(?:;|$)/);
  const rawToken=admin.cookie.slice(admin.cookie.indexOf('=')+1);
  assert.match(rawToken,/^[A-Za-z0-9_-]{43}$/);
  const digest=createHash('sha256').update(rawToken).digest('hex');
  const stored=(await db.query('SELECT token_hash,csrf_token FROM app_auth.session WHERE token_hash=$1',[digest])).rows[0];
  assert.ok(stored);
  assert.equal(stored.token_hash,digest);
  assert.notEqual(stored.token_hash,rawToken);
  assert.equal(stored.csrf_token,admin.user.csrf);
  const account=(await db.query('SELECT password_hash FROM app_auth.user_account WHERE person_id=2')).rows[0];
  assert.match(account.password_hash,/^[a-f0-9]{32}:[a-f0-9]{128}$/);
  assert.ok(!account.password_hash.includes(demoPassword));
  const identity=await expect(request('/auth/me',{actor:admin}),200);
  assert.equal(Object.hasOwn(identity.payload.data,'password_hash'),false);
  assert.equal(Object.hasOwn(identity.payload.data,'token_hash'),false);
 });
 await t.test('S27: invalid CSRF tokens and foreign Origins cannot create a loan',async()=>{
  const before=await scalar('SELECT count(*)::int FROM lab_tracker.borrow_transaction');
  const due=await scalar('SELECT (CURRENT_DATE+7)::text');
  const body={equipment_id:'3',expected_return_date:due};
  const missing=await expect(request('/borrows',{actor:student,body,csrf:false}),403);
  assert.equal(missing.payload.error.code,'CSRF_REQUIRED');
  const wrong=await expect(request('/borrows',{actor:student,body,headers:{'x-csrf-token':'incorrect'}}),403);
  assert.equal(wrong.payload.error.code,'CSRF_REQUIRED');
  await expect(request('/borrows',{actor:student,body,headers:{origin:'https://attacker.invalid'}}),403);
  assert.equal(await scalar('SELECT count(*)::int FROM lab_tracker.borrow_transaction'),before);
  assert.equal(await scalar('SELECT current_status FROM lab_tracker.equipment WHERE equipment_id=3'),'Available');
 });
 await t.test('S28: logout revokes the stored session and clears the cookie',async()=>{
  const actor=await login('student@lab.local');
  const rawToken=actor.cookie.slice(actor.cookie.indexOf('=')+1);
  const digest=createHash('sha256').update(rawToken).digest('hex');
  assert.equal(await scalar('SELECT count(*)::int FROM app_auth.session WHERE token_hash=$1',[digest]),1);
  const result=await expect(request('/auth/logout',{actor,body:{}}),204);
  assert.match(result.cookie,/Max-Age=0(?:;|$)/);
  assert.equal(await scalar('SELECT count(*)::int FROM app_auth.session WHERE token_hash=$1',[digest]),0);
  await expect(request('/auth/me',{actor}),401);
 });
 await t.test('S29: attack requests preserve the 19-table schema and 1,200 business rows',async()=>{
  assert.deepEqual((await db.query(catalogSql)).rows,schemaBefore);
  assert.equal(schemaBefore.length,98);
  const tables=(await db.query("SELECT table_name FROM information_schema.tables WHERE table_schema='lab_tracker' AND table_type='BASE TABLE'")).rows;
  assert.equal(tables.length,19);
  let total=0;
  for(const {table_name} of tables)total+=await scalar('SELECT count(*)::int FROM lab_tracker.'+table_name);
  assert.equal(total,1200);
  assert.equal(await scalar('SELECT bool_and(reconciled) FROM lab_tracker.v_chemical_stock_audit'),true);
 });
});
