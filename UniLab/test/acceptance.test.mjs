import test from 'node:test';
import assert from 'node:assert/strict';
import {once} from 'node:events';
import {readFile} from 'node:fs/promises';
import {createApp} from '../server.mjs';
import {demoPassword,openDatabase,withRole} from '../db.mjs';

test('Nghiệm thu UniLab trên API HTTP và PGlite',async t=>{
 const db=await openDatabase('memory://');
 const server=createApp(db);
 server.listen(0,'127.0.0.1');
 await once(server,'listening');
 const base=`http://127.0.0.1:${server.address().port}`;
 t.after(async()=>{await new Promise(resolve=>server.close(resolve));await db.close();});
 const scalar=async(sql,args=[])=>Object.values((await db.query(sql,args)).rows[0])[0];
 const call=async(path,{actor,body,csrf=true,headers={}}={})=>{
  const isPost=body!==undefined;
  const res=await fetch(base+'/api/v1'+path,{method:isPost?'POST':'GET',
   headers:{...(actor?{cookie:actor.cookie}:{}),...(isPost?{'content-type':'application/json'}:{}),
    ...(actor&&isPost&&csrf?{'x-csrf-token':actor.user.csrf}:{}),...headers},body:isPost?JSON.stringify(body):undefined});
  const payload=res.status===204?{}:await res.json();
  return {status:res.status,...payload,cookie:res.headers.get('set-cookie')};
 };
 const expect=async(p,status)=>{
  const r=await p;assert.equal(r.status,status,JSON.stringify(r));return r;
 };
 const login=async name=>{
  const res=await expect(call('/auth/login',{body:{email:name+'@lab.local',password:demoPassword}}),200);
  assert.match(res.cookie,/HttpOnly/);assert.match(res.cookie,/SameSite=Strict/);
  return {cookie:res.cookie.split(';')[0],user:res.data};
 };
 const state=(id)=>scalar('SELECT current_status FROM lab_tracker.equipment WHERE equipment_id=$1',[id]);
 const stock=(id)=>scalar('SELECT quantity_in_stock::text FROM lab_tracker.chemical WHERE chemical_id=$1',[id]);
 const movements=()=>scalar('SELECT count(*)::int FROM lab_tracker.chemical_movement');
 const open=(person)=>scalar('SELECT count(*)::int FROM lab_tracker.borrow_transaction WHERE person_id=$1 AND actual_return_date IS NULL',[person]);
 const today=await scalar('SELECT current_date::text');
 const due=await scalar('SELECT (current_date+7)::text');
 const student=await login('student'),faculty=await login('faculty'),tech=await login('technician'),admin=await login('admin'),auditor=await login('auditor');
 const post=(path,actor,body={})=>call(path,{actor,body});
 const checkout=(actor,equipment_id)=>post('/borrows',actor,{equipment_id,expected_return_date:due});

 await t.test('Dữ liệu / tất cả các API đọc và 12 báo cáo',async()=>{
  assert.equal((await fetch(base+'/')).status,200);
  assert.equal((await fetch(base+'/app.js')).status,200);
  const tables=(await db.query("SELECT table_name FROM information_schema.tables WHERE table_schema='lab_tracker' AND table_type='BASE TABLE'")).rows;
  assert.equal(tables.length,19);
  let total=0;for(const {table_name} of tables) total+=await scalar('SELECT count(*)::int FROM lab_tracker.'+table_name);
  assert.equal(total,1200);
  const derived=await scalar(`SELECT count(*)::int FROM information_schema.columns WHERE table_schema='lab_tracker'
   AND (table_name IN ('has_certification','borrow_transaction') AND column_name='status'
     OR table_name='chemical_movement' AND column_name='movement_type')`);
  assert.equal(derived,0);
  const preview=await expect(call('/preview'),200);assert.equal(preview.data.stats.equipment_total,12);
  assert.equal(preview.data.stats.open_borrows,3);
  assert.equal((await expect(call('/dashboard',{actor:student}),200)).data.stats.open_borrows,0);
  await expect(call('/equipment'),401);
  await expect(call('/auth/login',{body:{email:'inactive@lab.local',password:demoPassword}}),401);
  for(const p of ['/dashboard','/labs','/equipment','/equipment/3','/grants','/grants/1','/chemicals','/chemicals/1/points','/me/borrows','/me/access','/me/certifications','/maintenance']) await expect(call(p,{actor:student}),200);
  const reports=new Set();
  for(const actor of [student,faculty,tech,admin,auditor]){
   const {data}=await expect(call('/reports',{actor}),200);
   for(const {code} of data){reports.add(code);await expect(call('/reports/'+code,{actor}),200);}
  }
  assert.equal(reports.size,12);
  const q09=await db.exec(await readFile(new URL('../sql/queries/Q09.sql',import.meta.url),'utf8'));
  const canonical=q09.at(-1).rows;
  const {data:stockReport}=await expect(call('/reports/Q09',{actor:admin}),200);
  const stockValues=rows=>rows.map(row=>({
   chemical_name:row.chemical_name,unit:row.unit,
   total_received:Number(row.total_received),total_issued:Number(row.total_issued),
   quantity_in_stock:Number(row.quantity_in_stock),ledger_balance:Number(row.ledger_balance),
   reconciled:row.reconciled,
  })).sort((a,b)=>a.chemical_name<b.chemical_name?-1:a.chemical_name>b.chemical_name?1:0);
  assert.equal(stockReport.total,canonical.length);
  assert.deepEqual(stockValues(stockReport.rows),stockValues(canonical));
  assert.ok(canonical.every(row=>row.reconciled));
  assert.ok(canonical.some(row=>Number(row.total_received)>1000),'Q09 includes the expanded 1,200-row dataset movements');
 });
 await t.test('Luồng vận hành dùng dữ liệu chuẩn hóa, không cần thêm bản ghi demo tự động',async()=>{
  const body={visitor_id:student.user.person_id,lab_id:'1',purpose:'Thực hành được giảng viên phê duyệt'};
  const {data:visit}=await expect(post('/access-logs/approved',faculty,body),201);
  await expect(post('/access-logs/'+visit.log_id+'/exit',student),200);
  const blocked=await expect(post('/chemicals/3/location',admin,{lab_id:'1'}),409);
  assert.equal(blocked.error.code,'CHEMICAL_ALREADY_ALLOCATED');
  const {rows:[sample]}=await db.query(`INSERT INTO lab_tracker.chemical(lab_id,chemical_name,cas_number,unit,expiry_date,hazard_level,storage_condition)
   VALUES(1,'Mẫu kiểm thử chuyển phòng','144-55-8','g',CURRENT_DATE+365,'Low','Lọ kín') RETURNING chemical_id::text`);
  const {data:moved}=await expect(post('/chemicals/'+sample.chemical_id+'/location',admin,{lab_id:'2'}),200);
  assert.equal(moved.lab_id,'2');
  await db.query('DELETE FROM lab_tracker.chemical WHERE chemical_id=$1',[sample.chemical_id]);
  const {data:maintenance}=await expect(post('/maintenance',tech,{equipment_id:'12',description:'Kiểm tra trước bàn giao',cost:'0'}),201);
  await expect(post('/maintenance/'+maintenance.maintenance_id+'/complete',tech,{}),200);
  assert.equal(await state('12'),'Available');
 });
 await t.test('Quyền hiển thị khớp chức vụ, chứng nhận và trạng thái nghiệp vụ',async()=>{
  const get=(path,actor)=>expect(call(path,{actor}),200).then(x=>x.data);
  const catalog=async actor=>Object.fromEntries((await get('/chemicals',actor)).rows.map(c=>[c.chemical_id,c]));
  const [s,f,t,a,r]=await Promise.all([student,faculty,tech,admin,auditor].map(catalog));
  for(const memberCatalog of [s,f]){
   assert.equal(memberCatalog['6'].can_issue,false);
   assert.match(memberCatalog['6'].issue_block_reason,/chứng nhận/);
   assert.equal(memberCatalog['3'].can_issue,true);
   assert.equal(memberCatalog['3'].can_receive,false);
  }
  assert.equal(t['6'].can_issue,true);assert.equal(t['6'].can_receive,true);
  assert.equal(t['5'].can_issue,false);assert.match(t['5'].issue_block_reason,/hết hạn/);
  assert.equal(t['5'].can_receive,true);
  assert.equal(a['6'].can_issue,true);assert.equal(a['6'].can_receive,false);
  assert.equal(a['6'].can_relocate,false);assert.match(a['6'].relocation_block_reason,/hạng mục/);
  assert.ok(!a['7']);
  assert.ok(Object.values(r).every(c=>!c.can_issue&&!c.can_receive&&!c.can_relocate));
  const labs=await get('/labs',admin);
  assert.deepEqual(labs.find(l=>l.lab_id==='1').allowed_safety_levels,['Restricted','Hazardous']);
  assert.equal(labs.find(l=>l.lab_id==='3').can_change_safety,false);
  assert.ok((await get('/labs',auditor)).every(l=>!l.can_enter&&!l.can_change_safety));
  const outside=await scalar("SELECT (localtime<time '07:00' OR localtime>=time '17:00')");
  assert.equal((await get('/labs',student)).find(l=>l.lab_id==='2').can_enter,false);
  const visitors=await get('/students?q=N24DCCN104',faculty);
  assert.equal(visitors[0].has_valid_lab_certification,false);
  assert.equal(visitors[0].has_hazardous_lab_certification,false);
  const expiredVisitors=await get('/students?q=N23DCCN103',faculty);
  assert.equal(expiredVisitors[0].has_valid_lab_certification,false);
  await expect(call('/students',{actor:auditor}),403);
  assert.equal((await get('/equipment/3',student)).can_borrow,true);
  assert.equal((await get('/equipment/4',student)).can_borrow,false);
  assert.match((await get('/equipment/4',student)).borrow_block_reason,/chứng nhận/);
  assert.equal((await get('/equipment/8',student)).can_borrow,false);
  assert.match((await get('/equipment/8',student)).borrow_block_reason,/chứng nhận/);
  assert.equal((await get('/equipment/4',faculty)).can_borrow,true);
  assert.equal((await get('/equipment/8',faculty)).can_borrow,false);
  assert.match((await get('/equipment/8',faculty)).borrow_block_reason,/chứng nhận/);
  assert.equal((await get('/equipment/8',tech)).can_borrow,true);
  assert.equal((await get('/equipment/6',student)).can_borrow,false);
  assert.equal((await get('/equipment/3',auditor)).can_borrow,false);
  assert.equal((await get('/equipment/3',tech)).can_start_maintenance,true);
  assert.equal((await get('/grants/2',faculty)).can_edit,true);
  assert.equal((await get('/grants/1',faculty)).can_edit,false);
  assert.equal((await get('/grants/3',admin)).can_edit,false);
  assert.equal((await get('/grants/3',admin)).can_update_budget,true);
  assert.equal((await get('/grants/3',auditor)).can_update_budget,false);
 });
 await t.test('AT01: Mượn và trả thiết bị; CSDL khớp lịch sử',async()=>{
  assert.equal(await open(student.user.person_id),0);
  const dueWithoutNewLimit=await scalar('SELECT (CURRENT_DATE+30)::text');
  const {data}=await expect(post('/borrows',student,{equipment_id:'3',expected_return_date:dueWithoutNewLimit}),201);
  assert.equal(data.expected_return_date,dueWithoutNewLimit);
  assert.equal(await state('3'),'In Use');
  const hist=(await expect(call('/me/borrows?status=open',{actor:student}),200)).data;
  assert.ok(hist.rows.some(row=>row.borrow_id===data.borrow_id&&row.actual_return_date===null));
  assert.equal((await expect(call('/dashboard',{actor:student}),200)).data.stats.open_borrows,1);
  await expect(post('/borrows/'+data.borrow_id+'/return',student),200);
  assert.equal(await state('3'),'Available');
 });
 await t.test('AT02: Tối đa ba lượt mở, tính cả lượt quá hạn; chặn mượn thiết bị phòng thiếu chứng nhận',async()=>{
  const uncertRestricted=await expect(checkout(student,'4'),403);
  assert.equal(uncertRestricted.error.code,'CERTIFICATION_REQUIRED');
  assert.equal(await state('4'),'Available');
  const uncertHazardous=await expect(checkout(student,'8'),403);
  assert.equal(uncertHazardous.error.code,'CERTIFICATION_REQUIRED');
  assert.equal(await state('8'),'Available');
  const partialHazardous=await expect(checkout(faculty,'8'),403);
  assert.equal(partialHazardous.error.code,'CERTIFICATION_REQUIRED');
  assert.equal(await state('8'),'Available');
  await db.query('INSERT INTO lab_tracker.borrow_transaction(person_id,equipment_id,borrow_date,expected_return_date) VALUES($1,3,CURRENT_DATE-3,CURRENT_DATE-1)',[tech.user.person_id]);
  const other=[];
  for(const id of ['4','7']) other.push((await expect(checkout(tech,id),201)).data.borrow_id);
  const bad=await expect(checkout(tech,'8'),409);
  assert.equal(bad.error.code,'BORROW_LIMIT_REACHED');
  assert.equal(await open(tech.user.person_id),3);
  assert.equal(await state('8'),'Available');
  const detail=(await expect(call('/equipment/8',{actor:tech}),200)).data;
  assert.equal(detail.can_borrow,false);
  assert.match(detail.borrow_block_reason,/3 thiết bị/);
  other.push(await scalar('SELECT borrow_id::text FROM lab_tracker.borrow_transaction WHERE equipment_id=3 AND actual_return_date IS NULL'));
  for(const id of other) await expect(post('/borrows/'+id+'/return',tech),200);
  assert.equal(await scalar('SELECT status FROM lab_tracker.v_borrow_current WHERE borrow_id=$1',[other.at(-1)]),'Overdue');
 });
 await t.test('AT03: Hai yêu cầu HTTP đồng thời chỉ tạo một lượt mở (PGlite)',async()=>{
  const results=await Promise.all([checkout(student,'3'),checkout(faculty,'3')]);
  assert.deepEqual(results.map(r=>r.status).sort(),[201,409]);
  assert.equal(await scalar('SELECT count(*)::int FROM lab_tracker.borrow_transaction WHERE equipment_id=3 AND actual_return_date IS NULL'),1);
  const index=results.findIndex(r=>r.status===201);
  await expect(post('/borrows/'+results[index].data.borrow_id+'/return',[student,faculty][index]),200);
 });
 await t.test('AT04: Giờ sinh viên, cán bộ phê duyệt; BR27/28 không áp giờ sinh viên',async()=>{
  await assert.rejects(db.query("INSERT INTO lab_tracker.access_log(person_id,lab_id,entry_time,purpose) VALUES($1,1,CURRENT_DATE+time '17:00','Kiểm thử')",[student.user.person_id]),/BR04/);
  await db.query("INSERT INTO lab_tracker.access_log(person_id,lab_id,entry_time,purpose,approved_by) VALUES($1,1,CURRENT_DATE+time '17:00','Kiểm thử',$2)",[student.user.person_id,faculty.user.person_id]);
  for(const actor of [faculty,tech]){
   await db.query("INSERT INTO lab_tracker.access_log(person_id,lab_id,entry_time,purpose) VALUES($1,1,CURRENT_DATE+time '02:00','Xử lý sự cố; Lý do ngoài giờ: kiểm tra an toàn')",[actor.user.person_id]);
  }
  const outside=await scalar("SELECT (localtime<time '07:00' OR localtime>=time '17:00')");
  await expect(post('/access-logs',student,{lab_id:'1',purpose:'Nghiên cứu'}),outside?403:201);
  const r=await expect(post('/access-logs/approved',faculty,{visitor_id:student.user.person_id,lab_id:'1',purpose:'Được giảng viên xác nhận'}),201);
  assert.equal(await scalar('SELECT approved_by::text FROM lab_tracker.access_log WHERE log_id=$1',[r.data.log_id]),faculty.user.person_id);
  await expect(post('/access-logs/'+r.data.log_id+'/exit',student),200);
 });
 await t.test('AT05: Phân bổ ngoài phòng hoặc đề tài tạm dừng bị chặn; đường hợp lệ hoạt động',async()=>{
  const n=await scalar('SELECT count(*)::int FROM lab_tracker.allocated_equip');
  await expect(post('/points/6/equipment-allocations',admin,{equipment_id:'4'}),409);
  await expect(post('/points/3/equipment-allocations',faculty,{equipment_id:'7'}),409);
  assert.equal(await scalar('SELECT count(*)::int FROM lab_tracker.allocated_equip'),n);
  await expect(post('/points/3/equipment-allocations',student,{equipment_id:'10'}),403);
  const {data:point}=await expect(post('/grants/2/points',faculty,{point_name:'Kiểm tra độ bền',start_date:today,end_date:due,status:'Planned'}),201);
  await expect(post('/points/'+point.rearch_point_id+'/equipment-allocations',faculty,{equipment_id:'10'}),201);
  const before=await stock('3');
  await expect(post('/points/'+point.rearch_point_id+'/chemical-allocations',faculty,{chemical_id:'3'}),201);
  assert.equal(await stock('3'),before);
 });
 await t.test('AT06: BR05 đủ loại theo phòng; trạng thái chứng nhận được tính khi đọc',async()=>{
  const catalog=(await db.query('SELECT cert_id::text,cert_name FROM lab_tracker.certification')).rows;
  const basic=catalog.find(c=>c.cert_name==='An toàn phòng thí nghiệm cơ bản').cert_id;
  await db.query(`INSERT INTO lab_tracker.has_certification(person_id,cert_id,issue_date,expiry_date)
   VALUES(7,$1,CURRENT_DATE-30,CURRENT_DATE+1) ON CONFLICT(person_id,cert_id) DO UPDATE SET issue_date=excluded.issue_date,expiry_date=excluded.expiry_date`,[basic]);
  const visitors=(await expect(call('/students?q=N24DCCN104',{actor:faculty}),200)).data;
  assert.equal(visitors[0].has_valid_lab_certification,true);
  assert.equal(visitors[0].has_hazardous_lab_certification,false);
  const {data:visit}=await expect(post('/access-logs/approved',faculty,{visitor_id:student.user.person_id,lab_id:'2',purpose:'Thực hành có chứng nhận cơ bản'}),201);
  await expect(post('/access-logs/'+visit.log_id+'/exit',student),200);
  await expect(post('/access-logs/approved',faculty,{visitor_id:student.user.person_id,lab_id:'3',purpose:'Kiểm tra thiếu loại chứng nhận'}),403);
  await db.query('UPDATE lab_tracker.has_certification SET expiry_date=CURRENT_DATE-1 WHERE person_id=7 AND cert_id=$1',[basic]);
  await expect(post('/access-logs/approved',faculty,{visitor_id:student.user.person_id,lab_id:'2',purpose:'Kiểm tra chứng nhận hết hạn'}),403);
  assert.equal(await scalar('SELECT status FROM lab_tracker.v_certification_current WHERE person_id=7 AND cert_id=$1',[basic]),'Expired');
  const rooms=(await expect(call('/labs',{actor:student}),200)).data;
  assert.match(rooms.find(l=>l.lab_id==='2').entry_block_reason,/chứng nhận/);
 });
 await t.test('AT07: Chứng nhận High thiếu bị chặn; đủ thì xuất và ghi sổ',async()=>{
  const body={chemical_id:'1',rearch_point_id:'1',quantity:'1.125',reason:'Mẫu nghiên cứu'};
  const before=await stock('1'),n=await movements();
  await expect(post('/chemical-issues',student,body),403);
  assert.equal(await stock('1'),before);assert.equal(await movements(),n);
  const {data}=await expect(post('/chemical-issues',tech,body),201);
  assert.equal(await scalar('SELECT person_id::text FROM lab_tracker.chemical_movement WHERE movement_id=$1',[data.movement_id]),tech.user.person_id);
  assert.equal(await scalar('SELECT quantity::text FROM lab_tracker.chemical_movement WHERE movement_id=$1',[data.movement_id]),'1.125');
  assert.equal(await movements(),n+1);
  await expect(post('/chemical-receipts',tech,{chemical_id:'1',quantity:'1.125',reason:'Bổ sung kho'}),201);
  assert.equal(await stock('1'),before);
 });
 await t.test('AT08: Không xuất vượt tồn hoặc đã quá hạn; giữ nguyên ledger',async()=>{
  const before=await stock('1'), n=await movements();
  const a=await call('/chemical-issues',{actor:tech,body:{chemical_id:'1',rearch_point_id:'1',quantity:'999999',reason:'Kiểm thử'}});
  const b=await call('/chemical-issues',{actor:tech,body:{chemical_id:'5',rearch_point_id:'1',quantity:'1',reason:'Kiểm thử'}});
  assert.ok([400,409].includes(a.status)&&[400,409].includes(b.status),JSON.stringify([a,b]));
  assert.notEqual(a.error.message,b.error.message);
  assert.equal(await stock('1'),before);assert.equal(await movements(),n);
 });
 await t.test('AT09 một phần: Chặn số dư sai và phân bổ sau khi đóng; chưa thử race native',async()=>{
  const budget=await scalar('SELECT remaining_budget::text FROM lab_tracker.research_grant WHERE grant_id=2');
  for(const value of ['-1','9999999999']){
   const bad=await post('/grants/2/budget',admin,{remaining_budget:value});
   assert.ok([400,409].includes(bad.status),JSON.stringify(bad));
  }
  assert.equal(await scalar('SELECT remaining_budget::text FROM lab_tracker.research_grant WHERE grant_id=2'),budget);
  await db.exec("UPDATE lab_tracker.research_grant SET status='Completed' WHERE grant_id=2");
  await expect(post('/points/3/equipment-allocations',faculty,{equipment_id:'10'}),409);
 });
 await t.test('AT10: Không mượn thiết bị bảo trì; chỉ kỹ thuật viên được bảo trì',async()=>{
  await expect(checkout(student,'6'),409);
  const body={equipment_id:'3',description:'Kiểm tra đầu dò',cost:'0'};
  await expect(post('/maintenance',student,body),403);
  const {data}=await expect(post('/maintenance',tech,body),201);
  assert.equal(await state('3'),'Under Maintenance');
  await expect(post('/maintenance/'+data.maintenance_id+'/complete',tech,{description:'Đã kiểm tra',cost:'0'}),200);
  assert.equal(await state('3'),'Available');
 });
 await t.test('AT11: Không chuyển Extreme tới phòng thường và không hạ mức phòng đang chứa Extreme',async()=>{
  await expect(post('/chemicals/2/location',admin,{lab_id:'1'}),409);
  await expect(post('/labs/3/safety',admin,{safety_level:'Normal'}),409);
  assert.equal(await scalar('SELECT lab_id::text FROM lab_tracker.chemical WHERE chemical_id=2'),'3');
  assert.equal(await scalar('SELECT safety_level FROM lab_tracker.laboratory WHERE lab_id=3'),'Hazardous');
 });
 await t.test('AT12: Ràng buộc danh tính, dữ liệu tìm kiếm và phạm vi quyền',async()=>{
  await expect(post('/borrows',student,{person_id:'2',equipment_id:'3',expected_return_date:due}),400);
  await expect(post('/access-logs',student,{approved_by:'2',lab_id:'1',purpose:'Kiểm thử'}),400);
  const other=await scalar('SELECT borrow_id::text FROM lab_tracker.borrow_transaction WHERE person_id=4 AND actual_return_date IS NULL LIMIT 1');
  const foreign=await post('/borrows/'+other+'/return',student);
  assert.ok([403,404,409].includes(foreign.status),JSON.stringify(foreign));
  assert.equal(await scalar('SELECT actual_return_date::text FROM lab_tracker.borrow_transaction WHERE borrow_id=$1',[other]),null);
  const filter=(await expect(call('/equipment?q='+encodeURIComponent("Cảm biến '"),{actor:student}),200)).data;
  assert.equal(filter.total,0);
  const grants=(await expect(call('/grants',{actor:student}),200)).data;
  assert.ok(grants.rows.every(g=>g.remaining_budget==null));
 });
 await t.test('AT13: CSRF, session hết hạn, auditor chỉ đọc, cấm sửa tồn trực tiếp',async()=>{
  await expect(call('/borrows',{actor:student,csrf:false,body:{equipment_id:'3',expected_return_date:due}}),403);
  await expect(checkout(auditor,'3'),403);
  await assert.rejects(withRole(db,'business',tx=>tx.query('UPDATE lab_tracker.chemical SET quantity_in_stock=0 WHERE chemical_id=1')),e=>e.code==='42501');
  await db.query("UPDATE app_auth.session SET expires_at=now()-interval '1 second' WHERE person_id=$1",[student.user.person_id]);
  await expect(call('/auth/me',{actor:student}),401);
  await expect(post('/auth/logout',tech),204);
  await expect(call('/auth/me',{actor:tech}),401);
 });
 await t.test('AT14: Rollback thực tế và thử phục hồi bản sao vào CSDL mới (PGlite)',async()=>{
  const before=await stock('1'),n=await movements();
  await assert.rejects(withRole(db,'business',async tx=>{
   await tx.query("SELECT lab_tracker.receive_chemical(1,$1,2,'Thử rollback')",[tech.user.person_id]);
   throw new Error('test rollback');
  }),/test rollback/);
  assert.equal(await stock('1'),before);assert.equal(await movements(),n);
  const snapshot=await db.dumpDataDir('gzip');
  const restored=await openDatabase('memory://',{loadDataDir:snapshot});
  try{
   for(const name of ['person','borrow_transaction','access_log','chemical_movement','has_certification']){
    const sql='SELECT count(*)::int AS count FROM lab_tracker.'+name;
    assert.equal((await restored.query(sql)).rows[0].count,await scalar(sql));
   }
   assert.equal((await restored.query('SELECT bool_and(reconciled) AS ok FROM lab_tracker.v_chemical_stock_audit')).rows[0].ok,true);
   await assert.rejects(restored.query("UPDATE lab_tracker.research_grant SET remaining_budget=-1 WHERE grant_id=1"),e=>e.code==='23514');
   await assert.rejects(restored.query("UPDATE lab_tracker.equipment SET lab_id=9999 WHERE equipment_id=9"),e=>e.code==='23503');
  }finally{await restored.close();}
 });
});
