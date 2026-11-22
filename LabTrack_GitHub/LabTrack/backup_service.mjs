import {PGlite} from '@electric-sql/pglite';
import {readFile,mkdir,open,link,unlink,readdir,lstat} from 'node:fs/promises';
import path from 'node:path';
import {fileURLToPath} from 'node:url';
import {createHash,randomBytes,scrypt,createCipheriv,createDecipheriv} from 'node:crypto';
import {promisify} from 'node:util';
import {performance} from 'node:perf_hooks';

const derive=promisify(scrypt);
const MAGIC=Buffer.from('LABTRACK-BACKUP-V1\n');
const AUTO_NAME=/^labtrack-\d{8}T\d{9}Z-[a-f0-9]{8}\.labbackup$/;
const HOUR=60*60*1000;
const digest=data=>createHash('sha256').update(data).digest('hex');
const canonical=value=>JSON.stringify(value);
const quote=value=>'"'+value.replaceAll('"','""')+'"';

function validatePassphrase(value){
 if(value!==undefined&&(typeof value!=='string'||value.length<12))throw new Error('Mật khẩu sao lưu phải có ít nhất 12 ký tự.');
}

// Hashes cover every stored column, including password hashes and sessions, without returning those values.
export async function captureDatabaseState(db){
 await db.exec("SET TIME ZONE 'Asia/Ho_Chi_Minh'");
 const catalog=(await db.query(`SELECT table_schema,table_name FROM information_schema.tables
   WHERE table_schema IN ('lab_tracker','app_auth') AND table_type='BASE TABLE'
   ORDER BY table_schema,table_name`)).rows;
 const tables=[];
 for(const {table_schema:schema,table_name:name} of catalog){
  const primary=(await db.query(`SELECT k.column_name FROM information_schema.table_constraints t
    JOIN information_schema.key_column_usage k USING(constraint_catalog,constraint_schema,constraint_name)
    WHERE t.table_schema=$1 AND t.table_name=$2 AND t.constraint_type='PRIMARY KEY'
    ORDER BY k.ordinal_position`,[schema,name])).rows.map(row=>quote(row.column_name));
  if(!primary.length)throw new Error(`Bảng ${schema}.${name} thiếu khóa chính để kiểm chứng sao lưu.`);
  const {rows}=await db.query(`SELECT row_to_json(r)::text AS value FROM
    (SELECT * FROM ${quote(schema)}.${quote(name)} ORDER BY ${primary.join(',')}) r`);
  tables.push({schema,name,count:rows.length,sha256:digest(rows.map(row=>row.value).join('\n'))});
 }
 const business=tables.filter(t=>t.schema==='lab_tracker'),identity=tables.filter(t=>t.schema==='app_auth');
 const stock=(await db.query('SELECT chemical_id,quantity_in_stock::text,ledger_balance::text,reconciled FROM lab_tracker.v_chemical_stock_audit ORDER BY chemical_id')).rows;
 if(!business.length||!stock.length||!stock.every(row=>row.reconciled))throw new Error('Tồn kho không khớp sổ hoặc lược đồ nghiệp vụ chưa đầy đủ.');
 return {business_table_count:business.length,business_record_count:business.reduce((n,t)=>n+t.count,0),
  business_sha256:digest(canonical(business)),identity_sha256:digest(canonical(identity)),
  account_count:identity.find(t=>t.name==='user_account')?.count??0,
  session_count:identity.find(t=>t.name==='session')?.count??0,
  table_counts:Object.fromEntries(tables.map(t=>[`${t.schema}.${t.name}`,t.count])),
  stock_reconciled:true,stock_audit:stock};
}

function compareState(actual,expected){
 if(!expected)return;
 for(const key of ['business_sha256','identity_sha256','business_table_count','business_record_count','account_count','session_count']){
  if(actual[key]!==expected[key])throw new Error(`Kiểm chứng phục hồi không khớp: ${key}.`);
 }
}

async function stateFromDump(dump){
 const restored=new PGlite({loadDataDir:new Blob([dump])});
 try{return await captureDatabaseState(restored)}finally{await restored.close()}
}

async function encodeSnapshot(dump,metadata,passphrase){
 const header={format:'LabTrackSnapshot',version:1,...metadata,dump_sha256:digest(dump),compression:'gzip',encrypted:passphrase!==undefined};
 let payload;
 if(passphrase!==undefined){
  const salt=randomBytes(16),iv=randomBytes(12);
  Object.assign(header,{cipher:'aes-256-gcm',kdf:'scrypt',kdf_N:32768,kdf_r:8,kdf_p:1,salt:salt.toString('base64'),iv:iv.toString('base64')});
  const aad=Buffer.from(JSON.stringify(header));
  const key=await derive(passphrase,salt,32,{N:32768,r:8,p:1,maxmem:64*1024*1024});
  try{
   const cipher=createCipheriv('aes-256-gcm',key,iv);cipher.setAAD(aad);
   payload=Buffer.concat([cipher.update(dump),cipher.final(),cipher.getAuthTag()]);
  }finally{key.fill(0)}
 }else payload=dump;
 const json=Buffer.from(JSON.stringify(header)),length=Buffer.alloc(4);length.writeUInt32BE(json.length);
 return Buffer.concat([MAGIC,length,json,payload]);
}

export async function decodeSnapshot(bytes,{passphrase,legacyDate}={}){
 const buffer=Buffer.from(bytes);
 if(buffer[0]===0x1f&&buffer[1]===0x8b)return {dump:buffer,metadata:{format:'LegacyPGliteGzip',version:0,encrypted:false,data_as_of:legacyDate??null,timestamp_source:'filesystem_mtime'}};
 if(!buffer.subarray(0,MAGIC.length).equals(MAGIC)||buffer.length<MAGIC.length+4)throw new Error('Định dạng bản sao lưu không hợp lệ.');
 const length=buffer.readUInt32BE(MAGIC.length),offset=MAGIC.length+4;
 if(length<=0||length>65536||buffer.length<=offset+length)throw new Error('Phần mô tả bản sao lưu không hợp lệ.');
 const aad=buffer.subarray(offset,offset+length);
 let metadata;try{metadata=JSON.parse(aad.toString('utf8'))}catch{throw new Error('Phần mô tả bản sao lưu không hợp lệ.')}
 if(metadata.format!=='LabTrackSnapshot'||metadata.version!==1||metadata.compression!=='gzip'||typeof metadata.encrypted!=='boolean')throw new Error('Phiên bản bản sao lưu không được hỗ trợ.');
 if(!Number.isFinite(Date.parse(metadata.data_as_of)))throw new Error('Mốc dữ liệu trong bản sao lưu không hợp lệ.');
 let dump=buffer.subarray(offset+length);
 if(metadata.encrypted){
  validatePassphrase(passphrase);
  if(passphrase===undefined)throw new Error('Bản sao lưu đã mã hóa; cần LABTRACK_BACKUP_PASSPHRASE.');
  if(metadata.cipher!=='aes-256-gcm'||metadata.kdf!=='scrypt'||metadata.kdf_N!==32768||metadata.kdf_r!==8||metadata.kdf_p!==1)throw new Error('Tham số mã hóa bản sao lưu không hợp lệ.');
  const salt=Buffer.from(metadata.salt??'','base64'),iv=Buffer.from(metadata.iv??'','base64');
  if(salt.length!==16||iv.length!==12||dump.length<17)throw new Error('Dữ liệu mã hóa không hợp lệ.');
  const key=await derive(passphrase,salt,32,{N:32768,r:8,p:1,maxmem:64*1024*1024});
  try{
   const decipher=createDecipheriv('aes-256-gcm',key,iv);decipher.setAAD(aad);decipher.setAuthTag(dump.subarray(-16));
   dump=Buffer.concat([decipher.update(dump.subarray(0,-16)),decipher.final()]);
  }catch{throw new Error('Không thể xác thực bản sao lưu: mật khẩu sai hoặc tệp đã bị thay đổi.')}
  finally{key.fill(0)}
 }
 if(digest(dump)!==metadata.dump_sha256)throw new Error('SHA-256 bản sao lưu không khớp; tệp có thể đã bị thay đổi.');
 return {dump,metadata};
}

async function writeAtomicExclusive(file,bytes){
 const target=path.resolve(file),directory=path.dirname(target);
 await mkdir(directory,{recursive:true,mode:0o700});
 const temporary=path.join(directory,`.labtrack-backup-${randomBytes(12).toString('hex')}.tmp`);
 let handle;
 try{
  handle=await open(temporary,'wx',0o600);await handle.writeFile(bytes);await handle.sync();await handle.close();handle=undefined;
  // Atomic publication without overwriting a previous backup, including on Windows.
  await link(temporary,target);
 }finally{
  if(handle)await handle.close();
  await unlink(temporary).catch(error=>{if(error.code!=='ENOENT')throw error});
 }
 return target;
}

export async function saveSnapshot(db,file,{passphrase,legacyGzip=false,now=()=>new Date()}={}){
 validatePassphrase(passphrase);
 if(legacyGzip&&passphrase!==undefined)throw new Error('Định dạng gzip cũ không hỗ trợ mã hóa.');
 const start=performance.now();let dataAsOf;
 // PGlite 0.5.10 exposes this mutex; regular queries and transactions use the same lock.
 const dump=await db._runExclusiveTransaction(async()=>{
  dataAsOf=now().toISOString();
  return Buffer.from(await (await db.dumpDataDir('gzip')).arrayBuffer());
 });
 const state=await stateFromDump(dump);
 const metadata={created_at:now().toISOString(),data_as_of:dataAsOf,state};
 const bytes=legacyGzip?dump:await encodeSnapshot(dump,metadata,passphrase);
 const saved=await writeAtomicExclusive(file,bytes);
 return {file:saved,bytes:bytes.length,encrypted:passphrase!==undefined,data_as_of:dataAsOf,
  backup_ms:performance.now()-start,state};
}

export async function verifySnapshot(file,{passphrase,expectedState}={}){
 const start=performance.now(),resolved=path.resolve(file),stat=await lstat(resolved);
 if(!stat.isFile()||stat.isSymbolicLink())throw new Error('Bản sao lưu phải là tệp thường.');
 const {dump,metadata}=await decodeSnapshot(await readFile(resolved),{passphrase,legacyDate:stat.mtime.toISOString()});
 const state=await stateFromDump(dump);
 compareState(state,metadata.state);compareState(state,expectedState);
 return {file:resolved,encrypted:metadata.encrypted,data_as_of:metadata.data_as_of,
  timestamp_source:metadata.timestamp_source??'snapshot_lock_acquired',
  restore_ms:performance.now()-start,state};
}

export async function restoreSnapshot(file,directory,{passphrase}={}){
 const checked=await verifySnapshot(file,{passphrase});
 const {dump}=await decodeSnapshot(await readFile(path.resolve(file)),{passphrase});
 const target=path.resolve(directory);
 // Refuse existing directories; no deletion or replacement of the live .data is performed.
 await mkdir(target,{mode:0o700});
 const restored=new PGlite({dataDir:target,loadDataDir:new Blob([dump])});
 try{compareState(await captureDatabaseState(restored),checked.state)}finally{await restored.close()}
 return {...checked,restored_directory:target};
}

async function automaticFiles(directory){
 return (await readdir(directory,{withFileTypes:true})).filter(entry=>entry.isFile()&&AUTO_NAME.test(entry.name))
  .map(entry=>entry.name).sort();
}

export function startBackupService(db,{directory=new URL('.backups',import.meta.url),passphrase,
 backupEveryMs=23*HOUR,checkIntervalMs=15*60*1000,retention=7,now=()=>new Date(),onError=()=>{},onSnapshot=()=>{}}={}){
 validatePassphrase(passphrase);
 if(!Number.isFinite(backupEveryMs)||backupEveryMs<=0||backupEveryMs>23*HOUR||!Number.isFinite(checkIntervalMs)||checkIntervalMs<=0||checkIntervalMs>15*60*1000)throw new Error('Lịch sao lưu phải có chu kỳ tối đa 23 giờ và kiểm tra tối đa 15 phút.');
 if(!Number.isInteger(retention)||retention<1)throw new Error('Số bản sao giữ lại phải là số nguyên dương.');
 const folder=path.resolve(directory instanceof URL?fileURLToPath(directory):directory);
 let stopped=false,inFlight,lastSnapshot=null,lastError=null;
 async function check(){
  await mkdir(folder,{recursive:true,mode:0o700});
  const names=await automaticFiles(folder);
  if(!lastSnapshot){
   for(const name of [...names].reverse()){
    try{
     const {metadata}=await decodeSnapshot(await readFile(path.join(folder,name)),{passphrase});
     lastSnapshot={file:path.join(folder,name),data_as_of:metadata.data_as_of};break;
    }catch{/* An unreadable older snapshot does not suppress a new backup. */}
   }
  }
  const age=lastSnapshot?now().getTime()-Date.parse(lastSnapshot.data_as_of):Infinity;
  if(age>=0&&age<backupEveryMs)return {created:false,last_snapshot:lastSnapshot};
  const timestamp=now().toISOString().replace(/[-:.]/g,''),name=`labtrack-${timestamp}-${randomBytes(4).toString('hex')}.labbackup`;
  const saved=await saveSnapshot(db,path.join(folder,name),{passphrase,now});
  lastSnapshot={file:saved.file,data_as_of:saved.data_as_of,bytes:saved.bytes,encrypted:saved.encrypted};lastError=null;
  const managed=await automaticFiles(folder);
  for(const old of managed.slice(0,Math.max(0,managed.length-retention)))await unlink(path.join(folder,old));
  try{await onSnapshot({encrypted:saved.encrypted,record_count:saved.state.business_record_count,duration_ms:saved.backup_ms,bytes:saved.bytes})}catch{/* Logging failure does not invalidate an already published backup. */}
  return {created:true,...saved};
 }
 function tick(){
  if(stopped)return Promise.resolve({created:false,stopped:true});
  if(inFlight)return inFlight;
  inFlight=check().catch(error=>{lastError=error.message;try{onError(error)}catch{}throw error}).finally(()=>{inFlight=undefined});
  return inFlight;
 }
 const ready=tick();
 const timer=setInterval(()=>{tick().catch(()=>{})},checkIntervalMs);timer.unref?.();
 return {ready,tick,status:()=>({directory:String(folder),last_snapshot:lastSnapshot,last_error:lastError,
  encrypted:passphrase!==undefined,backup_every_ms:backupEveryMs,check_interval_ms:checkIntervalMs,retention}),
  stop:async()=>{stopped=true;clearInterval(timer);await inFlight?.catch(()=>{})}};
}
