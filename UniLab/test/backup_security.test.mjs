import test from 'node:test';
import assert from 'node:assert/strict';
import {mkdtemp,readFile,writeFile,readdir,rm,mkdir} from 'node:fs/promises';
import {tmpdir} from 'node:os';
import path from 'node:path';
import {randomBytes,createHash} from 'node:crypto';
import {openDatabase} from '../db.mjs';
import {captureDatabaseState,saveSnapshot,verifySnapshot,restoreSnapshot,startBackupService} from '../backup_service.mjs';

test('Sao lưu, mã hóa, lịch tự động và phục hồi dữ liệu',async t=>{
 const directory=await mkdtemp(path.join(tmpdir(),'labtrack-backup-test-'));
 const db=await openDatabase('memory://');
 t.after(async()=>{
  await db.close();
  const resolved=path.resolve(directory),allowed=path.resolve(tmpdir())+path.sep;
  assert.ok(resolved.startsWith(allowed)&&path.basename(resolved).startsWith('labtrack-backup-test-'));
  await rm(resolved,{recursive:true,force:true});
 });
 await db.query('INSERT INTO app_auth.session(token_hash,person_id,csrf_token) VALUES($1,7,$2)',[randomBytes(32).toString('hex'),randomBytes(32).toString('hex')]);
 const expected=await captureDatabaseState(db);
 assert.equal(expected.business_record_count,1200);assert.equal(expected.business_table_count,19);
 assert.ok(expected.account_count>0);assert.equal(expected.session_count,1);
 const passphrase=randomBytes(32).toString('base64url');
 const encrypted=path.join(directory,'encrypted.labbackup');

 await t.test('Gzip cũ vẫn phục hồi được, giữ đủ dữ liệu nghiệp vụ và danh tính',async()=>{
  const file=path.join(directory,'legacy.tar.gz');
  await saveSnapshot(db,file,{legacyGzip:true});
  const bytes=await readFile(file);assert.equal(bytes[0],0x1f);assert.equal(bytes[1],0x8b);
  const restored=await verifySnapshot(file,{expectedState:expected});
  assert.equal(restored.state.business_sha256,expected.business_sha256);
  assert.equal(restored.state.identity_sha256,expected.identity_sha256);
  assert.equal(restored.state.stock_reconciled,true);
 });
 await t.test('AES-256-GCM phục hồi đúng toàn bộ bảng, mật khẩu băm và phiên',async()=>{
  const saved=await saveSnapshot(db,encrypted,{passphrase});
  assert.equal(saved.encrypted,true);
  const restored=await verifySnapshot(encrypted,{passphrase,expectedState:expected});
  assert.equal(restored.state.business_sha256,expected.business_sha256);
  assert.equal(restored.state.identity_sha256,expected.identity_sha256);
  assert.equal(restored.state.session_count,1);
 });
 await t.test('Thiếu mật khẩu, mật khẩu sai và tệp mã hóa bị sửa đều bị từ chối',async()=>{
  await assert.rejects(verifySnapshot(encrypted),/cần LABTRACK_BACKUP_PASSPHRASE/);
  await assert.rejects(verifySnapshot(encrypted,{passphrase:randomBytes(32).toString('hex')}),/Không thể xác thực/);
  const bytes=await readFile(encrypted);bytes[bytes.length-1]^=1;
  const file=path.join(directory,'tampered.labbackup');await writeFile(file,bytes);
  await assert.rejects(verifySnapshot(file,{passphrase}),/Không thể xác thực/);
 });
 await t.test('Bản không mã hóa phát hiện sửa dữ liệu bằng SHA-256',async()=>{
  const file=path.join(directory,'plain.labbackup');await saveSnapshot(db,file);
  const bytes=await readFile(file);bytes[bytes.length-1]^=1;await writeFile(file,bytes);
  await assert.rejects(verifySnapshot(file),/SHA-256/);
 });
 await t.test('Không ghi đè bản sao đã có và không để lại tệp tạm',async()=>{
  const before=createHash('sha256').update(await readFile(encrypted)).digest('hex');
  await assert.rejects(saveSnapshot(db,encrypted,{passphrase}),{code:'EEXIST'});
  assert.equal(createHash('sha256').update(await readFile(encrypted)).digest('hex'),before);
  assert.equal((await readdir(directory)).filter(name=>name.endsWith('.tmp')).length,0);
 });
 await t.test('Phục hồi vào thư mục mới, giữ bản cũ và từ chối thư mục đã có',async()=>{
  await db.query("UPDATE lab_tracker.laboratory SET lab_name=lab_name||' / thay đổi sau sao lưu' WHERE lab_id=1");
  assert.notEqual((await captureDatabaseState(db)).business_sha256,expected.business_sha256);
  const target=path.join(directory,'restored-data');
  const restored=await restoreSnapshot(encrypted,target,{passphrase});
  assert.equal(restored.state.business_sha256,expected.business_sha256);
  assert.equal(restored.state.identity_sha256,expected.identity_sha256);
  assert.notEqual((await captureDatabaseState(db)).business_sha256,expected.business_sha256);
  await assert.rejects(restoreSnapshot(encrypted,target,{passphrase}),{code:'EEXIST'});
 });
 await t.test('Bản sao chờ giao dịch kết thúc, không lưu trạng thái giữa giao dịch',async()=>{
  let entered;const started=new Promise(resolve=>{entered=resolve});
  const transaction=db.transaction(async tx=>{
   await tx.query("UPDATE lab_tracker.laboratory SET lab_name='Recovery concurrency marker' WHERE lab_id=1");
   entered();await new Promise(resolve=>setTimeout(resolve,30));
  });
  await started;
  const file=path.join(directory,'transaction.labbackup');
  const snapshot=saveSnapshot(db,file,{passphrase});
  await transaction;await snapshot;
  const state=await captureDatabaseState(db);
  assert.equal((await verifySnapshot(file,{passphrase,expectedState:state})).state.business_sha256,state.business_sha256);
 });
 await t.test('Tạo ban đầu, đến hạn23 giờ trước RPO24 giờ; giữ đúng phiên bản tự động',async()=>{
  const folder=path.join(directory,'automatic');await mkdir(folder);
  const unrelated=path.join(folder,'khong-xoa.tar.gz');await writeFile(unrelated,'keep');
  let instant=Date.now();const clock=()=>new Date(instant);
  const events=[];
  const service=startBackupService(db,{directory:folder,passphrase,retention:2,now:clock,onSnapshot:event=>{events.push(event);throw Error('audit callback failure')}});
  try{
   const first=await service.ready;assert.equal(first.created,true);assert.equal(first.encrypted,true);
   instant+=23*60*60*1000-1;assert.equal((await service.tick()).created,false);
   instant+=1;const second=await service.tick();assert.equal(second.created,true);
   assert.equal(Date.parse(second.data_as_of)-Date.parse(first.data_as_of),23*60*60*1000);
   instant+=23*60*60*1000;assert.equal((await service.tick()).created,true);
   const files=await readdir(folder);assert.equal(files.filter(name=>name.endsWith('.labbackup')).length,2);
   assert.equal(await readFile(unrelated,'utf8'),'keep');
   assert.equal(events.length,3);assert.equal(events[0].record_count,1200);assert.equal(events[0].encrypted,true);
   assert.ok(events.every(event=>Object.keys(event).sort().join(',')==='bytes,duration_ms,encrypted,record_count'));
   assert.equal(service.status().check_interval_ms,15*60*1000);assert.equal(service.status().last_error,null);
  }finally{await service.stop()}
  assert.equal((await service.tick()).stopped,true);
 });
});
