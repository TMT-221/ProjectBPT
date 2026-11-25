import {spawn} from 'node:child_process';
import {readFile,writeFile,readdir,mkdir} from 'node:fs/promises';
import {createHash} from 'node:crypto';
import {fileURLToPath} from 'node:url';
const root=fileURLToPath(new URL('../',import.meta.url));
const files=['api.mjs','db.mjs','server.mjs','security_audit.mjs','backup_service.mjs','backup.mjs','auth.sql','api_migration.sql','public/app.js','sql/01_schema.sql','sql/02_dataset_1200.sql','sql/07_upgrade_normalized.sql','test/run_sql_security.mjs','test/run_sql_validation.mjs','test/fixtures/02_seed.sql','test/sql/05_tests.sql','test/sql/06_concurrency.mjs'];
const digests=async()=>Object.fromEntries(await Promise.all(files.map(async p=>[p,createHash('sha256').update(await readFile(new URL('../'+p,import.meta.url))).digest('hex')])));
const before=await digests(),started=new Date().toISOString();
const tests=(await readdir(new URL('./',import.meta.url))).filter(x=>x.endsWith('.test.mjs')).map(x=>'test/'+x);
let output='';
const child=spawn(process.execPath,['--test','--test-concurrency=1','--test-reporter=tap',...tests],{cwd:root,windowsHide:true});
child.stdout.on('data',x=>{output+=x;process.stdout.write(x)});
child.stderr.on('data',x=>{output+=x;process.stderr.write(x)});
const exit=await new Promise((resolve,reject)=>{child.on('error',reject);child.on('close',resolve)});
const after=await digests();
const count=name=>Number([...output.matchAll(new RegExp('^# '+name+' (\\d+)','gm'))].at(-1)?.[1]??-1);
const result={started_at:started,finished_at:new Date().toISOString(),engine:'Node '+process.version+' / PGlite 0.5.10',exit_code:exit,
 tests:count('tests'),passed:count('pass'),failed:count('fail'),skipped:count('skipped'),
 source_files_unchanged:JSON.stringify(before)===JSON.stringify(after),source_sha256:after,
 scope:'HTTP local acceptance, SQL injection, sensitive-data isolation, session/CSRF/Origin, durable redacted security audit, real HTTPS Secure-cookie, encrypted snapshots and scheduled backup, restore verification, both datasets and old Windows migration. The Faculty API clock test explicitly controls the clock query; SQL boundary tests are in test/sql/05_tests.sql. HTTP requests share one embedded PGlite connection; not native PostgreSQL concurrency.'};
await mkdir(new URL('./results/',import.meta.url),{recursive:true});
await writeFile(new URL('./results/api_acceptance.tap',import.meta.url),output);
await writeFile(new URL('./results/api_acceptance.json',import.meta.url),JSON.stringify(result,null,2));
if(exit!==0||!result.source_files_unchanged||result.failed!==0) process.exitCode=1;
