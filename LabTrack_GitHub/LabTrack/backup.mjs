import {openDatabase} from './db.mjs';
import {resolve} from 'node:path';
import {saveSnapshot,verifySnapshot,restoreSnapshot} from './backup_service.mjs';

const [command,file,directory]=process.argv.slice(2);
if(!file||!['save','verify','drill','restore'].includes(command)||(command==='restore'&&!directory)){
 console.error('Cách dùng: node backup.mjs save <backup.labbackup> | verify <backup> | drill <backup> | restore <backup> <thư-mục-mới>');
 process.exit(1);
}
let db;
try{
 const passphrase=process.env.LABTRACK_BACKUP_PASSPHRASE;
 if(command==='save'){
  db=await openDatabase(process.env.LABTRACK_DATA_DIR||undefined);
  const legacyGzip=/\.tar\.gz$/i.test(file)&&passphrase===undefined;
  console.log(JSON.stringify(await saveSnapshot(db,resolve(file),{passphrase,legacyGzip}),null,2));
 }else if(command==='restore'){
  console.log(JSON.stringify(await restoreSnapshot(file,directory,{passphrase}),null,2));
 }else{
  // Both commands restore into memory, leaving the live data directory unchanged.
  console.log(JSON.stringify(await verifySnapshot(file,{passphrase}),null,2));
 }
}catch(error){console.error(error.message);process.exitCode=1}
finally{if(db)await db.close();}
