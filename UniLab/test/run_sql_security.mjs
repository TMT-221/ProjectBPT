import {PGlite} from '@electric-sql/pglite';
import assert from 'node:assert/strict';
import {readFile,writeFile,mkdir} from 'node:fs/promises';
import {createHash} from 'node:crypto';

const files=['sql/01_schema.sql','sql/02_dataset_1200.sql','sql/04_rbac.sql','auth.sql'];
const sources=Object.fromEntries(await Promise.all(files.map(async name=>[name,await readFile(new URL('../'+name,import.meta.url),'utf8')])));
const hash=value=>createHash('sha256').update(value).digest('hex');
const result={
 started_at:new Date().toISOString(),engine:'PGlite 0.5.10 (PostgreSQL WASM)',
 dataset:{file:'sql/02_dataset_1200.sql',expected_business_rows:1200},
 scope:'SQL access-control checks in an isolated in-memory database. Temporary column grants and role memberships are rolled back. HTTP security tests S21-S29 are recorded by test/run_validation.mjs, not counted as SQL tests here.',
 source_sha256:Object.fromEntries(files.map(name=>[name,hash(sources[name])])),checks:[],
};
const db=new PGlite();
const scalar=async(sql,args=[])=>Object.values((await db.query(sql,args)).rows[0])[0];

async function asRole(role,sql){
 assert.match(role,/^lab_[a-z_]+$/);
 await db.exec(`BEGIN; SET LOCAL ROLE ${role}; SET LOCAL search_path=lab_tracker,pg_catalog;`);
 try{
  const {rows}=await db.query(sql);
  return {role,sql,accepted:true,row_count:rows.length};
 }catch(error){
  return {role,sql,accepted:false,sqlstate:error.code,message:error.message};
 }finally{await db.exec('ROLLBACK');}
}
async function denied(role,sql){
 const actual=await asRole(role,sql);
 assert.equal(actual.accepted,false,`${role} unexpectedly executed ${sql}`);
 assert.equal(actual.sqlstate,'42501');
 return actual;
}
async function accepted(role,sql){
 const actual=await asRole(role,sql);
 assert.equal(actual.accepted,true,JSON.stringify(actual));
 assert.ok(actual.row_count>0);
 return actual;
}
async function check(id,name,run){
 const item={id,name};
 try{item.evidence=await run();item.passed=true;}
 catch(error){item.passed=false;item.error={message:error.message,code:error.code};throw error;}
 finally{result.checks.push(item);}
}
async function reversibleGrant({grant,revoke,role,sql,after}){
 const evidence={grant,revoke,role,sql};
 await db.exec('BEGIN');
 try{
  await db.exec(grant);
  await db.exec(`SET LOCAL ROLE ${role}`);
  evidence.after_grant={accepted:true,row_count:(await db.query(sql)).rows.length};
  assert.ok(evidence.after_grant.row_count>0);
  await db.exec('RESET ROLE');
  await db.exec(revoke);
  await db.exec(`SET LOCAL ROLE ${role}; SAVEPOINT expected_security_denial`);
  try{await db.query(sql);evidence.after_revoke={accepted:true};}
  catch(error){evidence.after_revoke={accepted:false,sqlstate:error.code,message:error.message};}
  await db.exec('ROLLBACK TO SAVEPOINT expected_security_denial; RESET ROLE');
  assert.equal(evidence.after_revoke.accepted,false);
  assert.equal(evidence.after_revoke.sqlstate,'42501');
 }finally{await db.exec('ROLLBACK');}
 evidence.rolled_back=await after();
 assert.equal(evidence.rolled_back,true);
 return evidence;
}

try{
 for(const name of files)await db.exec(sources[name]);
 const tables=(await db.query("SELECT table_name FROM information_schema.tables WHERE table_schema='lab_tracker' AND table_type='BASE TABLE' ORDER BY table_name")).rows;
 result.dataset.actual_business_rows=0;
 for(const {table_name} of tables)result.dataset.actual_business_rows+=await scalar('SELECT count(*)::int FROM lab_tracker.'+table_name);
 assert.equal(result.dataset.actual_business_rows,1200);
 result.database=(await db.query("SELECT version(),CURRENT_DATE::text AS database_date,current_setting('TimeZone') AS timezone")).rows[0];

 await check('S13','lab_reader cannot select personal email, phone or date of birth',async()=>{
  const attempts=[];
  for(const column of ['email','phone','date_of_birth'])attempts.push(await denied('lab_reader',`SELECT ${column} FROM lab_tracker.person LIMIT 1`));
  return {attempts};
 });
 await check('S14','lab_app cannot select personal email, phone or date of birth',async()=>{
  const attempts=[];
  for(const column of ['email','phone','date_of_birth'])attempts.push(await denied('lab_app',`SELECT ${column} FROM lab_tracker.person LIMIT 1`));
  return {attempts};
 });
 await check('S15','runtime business role can read its permitted identity projection',()=>
  accepted('lab_web_demo','SELECT person_id,full_name,status FROM lab_tracker.person LIMIT 1'));
 await check('S16','runtime business role cannot read sensitive personal columns',async()=>{
  const attempts=[];
  for(const column of ['email','phone','date_of_birth'])attempts.push(await denied('lab_web_demo',`SELECT ${column} FROM lab_tracker.person LIMIT 1`));
  return {attempts};
 });
 await check('S17','authentication role cannot read business grant budgets',()=>
  denied('lab_web_auth','SELECT total_budget,remaining_budget FROM lab_tracker.research_grant LIMIT 1'));
 await check('S18','column GRANT permits access and REVOKE removes that access',async()=>{
  assert.equal(await scalar("SELECT has_column_privilege('lab_reader','lab_tracker.person','phone','SELECT')"),false);
  return reversibleGrant({
   grant:'GRANT SELECT(phone) ON lab_tracker.person TO lab_reader',
   revoke:'REVOKE SELECT(phone) ON lab_tracker.person FROM lab_reader',
   role:'lab_reader',sql:'SELECT phone FROM lab_tracker.person LIMIT 1',
   after:async()=>!await scalar("SELECT has_column_privilege('lab_reader','lab_tracker.person','phone','SELECT')"),
  });
 });
 await check('S19','role membership GRANT permits inherited access and REVOKE removes it',async()=>{
  const probe='lab_security_probe';
  assert.equal(await scalar('SELECT count(*)::int FROM pg_roles WHERE rolname=$1',[probe]),0);
  // Creation and all membership changes belong to the same rolled-back transaction.
  return reversibleGrant({
   grant:`CREATE ROLE ${probe} NOLOGIN; GRANT lab_reader TO ${probe}`,
   revoke:`REVOKE lab_reader FROM ${probe}`,
   role:probe,sql:'SELECT equipment_id FROM lab_tracker.equipment LIMIT 1',
   after:async()=>(await scalar('SELECT count(*)::int FROM pg_roles WHERE rolname=$1',[probe]))===0,
  });
 });
 await check('S20','reader can read an explicitly granted operational view',()=>
  accepted('lab_reader','SELECT borrow_id,equipment_id FROM lab_tracker.v_open_loans LIMIT 1'));
 result.passed=true;
}catch(error){
 result.passed=false;result.error={message:error.message,code:error.code};process.exitCode=1;
}finally{
 await db.close();
 result.completed_at=new Date().toISOString();
 result.passed_checks=result.checks.filter(x=>x.passed).length;
 result.failed_checks=result.checks.filter(x=>!x.passed).length;
 const current=await Promise.all(files.map(async name=>hash(await readFile(new URL('../'+name,import.meta.url),'utf8'))));
 result.source_files_unchanged=files.every((name,i)=>current[i]===result.source_sha256[name]);
 if(!result.source_files_unchanged){result.passed=false;process.exitCode=1;}
 await mkdir(new URL('./results/',import.meta.url),{recursive:true});
 await writeFile(new URL('./results/security_results.json',import.meta.url),JSON.stringify(result,null,2));
 console.log(JSON.stringify({passed:result.passed,passed_checks:result.passed_checks,failed_checks:result.failed_checks,ids:result.checks.map(x=>x.id),dataset:result.dataset,error:result.error},null,2));
}
