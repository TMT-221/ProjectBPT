import test from 'node:test';
import assert from 'node:assert/strict';
import {openDatabase,signIn,sessionUser,withRole,demoPassword} from '../db.mjs';
import {routeApi} from '../api.mjs';
import {openDatabase as legacyOpen,signIn as legacySignIn} from './fixtures/legacy/db.mjs';

const catalog=async db=>(await db.query(`SELECT table_name FROM information_schema.tables
 WHERE table_schema='lab_tracker' AND table_type='BASE TABLE' ORDER BY table_name`)).rows;
const counts=async db=>{
 const rows={};
 for(const {table_name} of await catalog(db)) rows[table_name]=(await db.query('SELECT count(*)::int AS n FROM lab_tracker.'+table_name)).rows[0].n;
 return rows;
};
for(const [dataset,expected] of [['seed',127],['1200',1200]]){
 test('Khởi tạo '+dataset+' bản ghi theo cùng lược đồ chuẩn hóa và mở đủ 12 báo cáo',async()=>{
  const db=await openDatabase('memory://',{dataset});
  try{
   const n=await counts(db);
   assert.equal(Object.keys(n).length,19);
   assert.equal(Object.values(n).reduce((a,b)=>a+b,0),expected);
   const user=(await signIn(db,'admin@lab.local',demoPassword,'')).user;
   const reports=await withRole(db,'business',tx=>routeApi({method:'GET',path:'/reports',params:new URLSearchParams(),user,db:tx}));
   assert.equal(reports.length,12);
   for(const {code} of reports){
    const result=await withRole(db,'business',tx=>routeApi({method:'GET',path:'/reports/'+code,params:new URLSearchParams(),user,db:tx}));
    assert.ok(Array.isArray(result.rows),code);
   }
   assert.equal((await db.query("SELECT count(*)::int AS n FROM information_schema.columns WHERE table_schema='lab_tracker' AND table_name IN (SELECT table_name FROM information_schema.tables WHERE table_schema='lab_tracker' AND table_type='BASE TABLE')")).rows[0].n,98);
  }finally{await db.close();}
 });
}

test('API Faculty ngoài giờ yêu cầu lý do riêng và lưu cùng mục đích (đồng hồ kiểm thử)',async()=>{
 const db=await openDatabase('memory://',{dataset:'seed'});
 try{
  const user=(await signIn(db,'faculty@lab.local',demoPassword,'')).user;
  const send=body=>withRole(db,'business',tx=>routeApi({method:'POST',path:'/access-logs',body,user,db:{
   query(sql,args){
    if(sql.includes('AS outside')&&sql.includes('AS local_clock')) return Promise.resolve({rows:[{outside:true}]});
    return tx.query(sql,args);
   }
  }}));
  for(const reason of [undefined,'','   ']){
   await assert.rejects(send({lab_id:'1',purpose:'Giám sát thiết bị',out_of_hours_reason:reason}),e=>e.status===400&&/lý do ngoài giờ/.test(e.message));
  }
  const log=await send({lab_id:'1',purpose:'Giám sát thiết bị',out_of_hours_reason:'Kiểm tra cảnh báo an toàn'});
  assert.match(log.purpose,/Giám sát thiết bị; Lý do ngoài giờ: Kiểm tra cảnh báo an toàn/);
 }finally{await db.close();}
});

test('Nâng cấp bản Windows cũ giữ nguyên dữ liệu nghiệp vụ, tài khoản và phiên đăng nhập',async()=>{
 const old=await legacyOpen('memory://');
 let snapshot,before,identity,session,stock,customLog;
 try{
  await old.query("UPDATE lab_tracker.person SET phone='0900002026' WHERE person_id=7");
  customLog=(await old.query("SELECT lab_tracker.record_access(10,1,'Giao dịch người dùng trước nâng cấp',NULL)::text AS id")).rows[0].id;
  session=await legacySignIn(old,'student@lab.local',demoPassword,'');
  before=await counts(old);
  identity=(await old.query('SELECT person_id::text,email,password_hash,enabled FROM app_auth.user_account ORDER BY person_id')).rows;
  stock=(await old.query('SELECT chemical_id::text,quantity_in_stock::text FROM lab_tracker.chemical ORDER BY chemical_id')).rows;
  snapshot=await old.dumpDataDir('gzip');
 }finally{await old.close();}
 const upgraded=await openDatabase('memory://',{loadDataDir:snapshot});
 let nextSnapshot;
 try{
  assert.deepEqual(await counts(upgraded),before);
  assert.deepEqual((await upgraded.query('SELECT person_id::text,email,password_hash,enabled FROM app_auth.user_account ORDER BY person_id')).rows,identity);
  assert.deepEqual((await upgraded.query('SELECT chemical_id::text,quantity_in_stock::text FROM lab_tracker.chemical ORDER BY chemical_id')).rows,stock);
  assert.equal((await upgraded.query('SELECT phone FROM lab_tracker.person WHERE person_id=7')).rows[0].phone,'0900002026');
  assert.equal((await upgraded.query('SELECT purpose FROM lab_tracker.access_log WHERE log_id=$1',[customLog])).rows[0].purpose,'Giao dịch người dùng trước nâng cấp');
  assert.equal((await sessionUser(upgraded,session.session)).person_id,'7');
  assert.equal((await signIn(upgraded,'student@lab.local',demoPassword,'')).user.person_id,'7');
  assert.equal((await upgraded.query(`SELECT count(*)::int AS n FROM information_schema.columns WHERE table_schema='lab_tracker'
   AND (table_name IN ('has_certification','borrow_transaction') AND column_name='status'
   OR table_name='chemical_movement' AND column_name='movement_type')`)).rows[0].n,0);
  assert.equal((await upgraded.query('SELECT bool_and(reconciled) AS ok FROM lab_tracker.v_chemical_stock_audit')).rows[0].ok,true);
  nextSnapshot=await upgraded.dumpDataDir('gzip');
 }finally{await upgraded.close();}
 const again=await openDatabase('memory://',{loadDataDir:nextSnapshot});
 try{
  assert.deepEqual(await counts(again),before);
  assert.equal((await again.query('SELECT count(*)::int AS n FROM app_auth.release_migration WHERE version=$1',['1.1.0'])).rows[0].n,1);
 }finally{await again.close();}
});
