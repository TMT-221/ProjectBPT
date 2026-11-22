import {openDatabase} from '../db.mjs';
import {captureDatabaseState,saveSnapshot,verifySnapshot} from '../backup_service.mjs';
import {mkdtemp,mkdir,writeFile,rm,readFile} from 'node:fs/promises';
import path from 'node:path';
import {tmpdir,platform,arch,cpus} from 'node:os';
import {fileURLToPath} from 'node:url';
import {randomBytes,createHash} from 'node:crypto';

const root=path.resolve(path.dirname(fileURLToPath(import.meta.url)),'..');
const directory=await mkdtemp(path.join(tmpdir(),'labtrack-recovery-drill-'));
const passphrase=randomBytes(32).toString('base64url');
const sourceFiles=['sql/01_schema.sql','sql/02_dataset_1200.sql','backup_service.mjs','backup.mjs','benchmark/run_recovery.mjs'];
const source_sha256={};for(const name of sourceFiles)source_sha256[name]=createHash('sha256').update(await readFile(path.join(root,name))).digest('hex');
const result={run_at:new Date().toISOString(),environment:{platform:platform(),architecture:arch(),cpu:cpus()[0]?.model,node:process.version,pglite:'0.5.10'},
 source_sha256,scope:'Local 1200-record PGlite recovery drill into memory; includes database creation, restoration, full stored-row hash verification, accounts, sessions and ledger. Excludes replacement of live .data, application restart, operating-system recovery and production-scale RTO/RPO acceptance.',
 method:{encryption:'AES-256-GCM; ephemeral random passphrase not persisted',backup_clock:'performance.now: database dump, validation in independent memory database, encryption, atomic filesystem publication',restore_clock:'performance.now: file read, authentication/decryption, independent memory database restoration and hash checks',
  data_as_of:'UTC instant when the PGlite transaction mutex is acquired for the snapshot; conservative committed-data watermark',
  observed_rpo:'failure_at minus snapshot data_as_of; one deliberately committed change after the snapshot is excluded from the restored copy',
  rpo_target_hours:24,rto_target_hours:2,rpo_target_seconds:86400,rto_target_seconds:7200,
  automatic_policy:{backup_every_hours:23,check_interval_minutes:15,retained_snapshots:7,requires_running_process:true}},measurements:[],passed:false};
let db;
try{
 db=await openDatabase('memory://');
 await db.query('INSERT INTO app_auth.session(token_hash,person_id,csrf_token) VALUES($1,7,$2)',[randomBytes(32).toString('hex'),randomBytes(32).toString('hex')]);
 const expected=await captureDatabaseState(db);
 if(expected.business_record_count!==1200||expected.business_table_count!==19)throw Error('Recovery drill requires the1200-record19-table dataset');
 result.dataset={business_record_count:expected.business_record_count,business_table_count:expected.business_table_count,account_count:expected.account_count,session_count:expected.session_count,table_counts:expected.table_counts};
 const snapshot=await saveSnapshot(db,path.join(directory,'drill.labbackup'),{passphrase});
 await db.query("UPDATE lab_tracker.laboratory SET lab_name=lab_name||' [post-snapshot drill]' WHERE lab_id=1");
 const postSnapshot=await captureDatabaseState(db);
 if(postSnapshot.business_sha256===expected.business_sha256)throw Error('The post-snapshot change was not committed');
 const failureAt=new Date(),observedRpoMs=failureAt.getTime()-Date.parse(snapshot.data_as_of);
 const restoreStarted=new Date();
 const restored=await verifySnapshot(snapshot.file,{passphrase,expectedState:expected});
 const verifiedReady=new Date();
 const m={id:'RECOVERY-1200',backup_ms:snapshot.backup_ms,restore_ms:restored.restore_ms,backup_bytes:snapshot.bytes,
  snapshot_data_as_of:snapshot.data_as_of,failure_at:failureAt.toISOString(),observed_rpo_ms:observedRpoMs,
  observed_rpo_seconds:observedRpoMs/1000,restore_seconds:restored.restore_ms/1000,
  restore_started_at:restoreStarted.toISOString(),verified_ready_at:verifiedReady.toISOString(),
  rpo_threshold_seconds:86400,rto_threshold_seconds:7200,
  observed_rpo_below_threshold:observedRpoMs<=86400000,observed_restore_below_threshold:restored.restore_ms<=7200000,
  encrypted:true,restored_business_records:restored.state.business_record_count,restored_accounts:restored.state.account_count,restored_sessions:restored.state.session_count,
  business_rows_match:restored.state.business_sha256===expected.business_sha256,
  account_password_role_session_rows_match:restored.state.identity_sha256===expected.identity_sha256,
  post_snapshot_change_excluded:restored.state.business_sha256!==postSnapshot.business_sha256,
  stock_reconciled:restored.state.stock_reconciled,
  snapshot_business_sha256:expected.business_sha256,snapshot_identity_sha256:expected.identity_sha256};
 result.measurements.push(m);
 if(!m.business_rows_match||!m.account_password_role_session_rows_match||!m.post_snapshot_change_excluded||!m.stock_reconciled)throw Error('Recovery verification failed');
 result.passed=true;result.completed_at=new Date().toISOString();
}catch(error){result.error=error.message;process.exitCode=1}
finally{
 if(db)await db.close();
 const resolved=path.resolve(directory),allowed=path.resolve(tmpdir())+path.sep;
 if(!resolved.startsWith(allowed)||!path.basename(resolved).startsWith('labtrack-recovery-drill-'))throw Error('Unexpected temporary recovery directory');
 await rm(resolved,{recursive:true,force:true});
 await mkdir(path.join(root,'evidence'),{recursive:true});
 await writeFile(path.join(root,'evidence/recovery_results.json'),JSON.stringify(result,null,2));
 console.log(JSON.stringify({passed:result.passed,dataset:result.dataset,measurements:result.measurements,error:result.error},null,2));
}
