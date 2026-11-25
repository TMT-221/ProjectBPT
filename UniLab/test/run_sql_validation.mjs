import {PGlite} from '@electric-sql/pglite';
import {readFile,writeFile,mkdir} from 'node:fs/promises';
import {fileURLToPath} from 'node:url';
import path from 'node:path';
import {createHash} from 'node:crypto';

const here=path.dirname(fileURLToPath(import.meta.url));
const root=path.resolve(here,'..');
const out=path.join(here,'results');
const read=name=>readFile(path.join(root,name),'utf8');
const sources=['sql/01_schema.sql','test/fixtures/02_seed.sql','sql/02_dataset_1200.sql','sql/03_queries.sql','sql/04_rbac.sql','test/sql/05_tests.sql','sql/07_upgrade_normalized.sql'];
const hashes={};for(const name of sources)hashes[name]=createHash('sha256').update(await readFile(path.join(root,name))).digest('hex');
const report={run_at:new Date().toISOString(),engine:'PGlite 0.5.10 (PostgreSQL WASM)',source_sha256:hashes,queries:[],tests:[],security:[],concurrency:{executed:false,reason:'Independent PostgreSQL connections are required; this run uses one embedded PGlite connection.'}};
const catalogSql=`SELECT
 (SELECT count(*)::int FROM information_schema.tables WHERE table_schema='lab_tracker' AND table_type='BASE TABLE') AS tables,
 (SELECT count(*)::int FROM information_schema.columns c JOIN information_schema.tables t USING(table_schema,table_name) WHERE c.table_schema='lab_tracker' AND t.table_type='BASE TABLE') AS columns,
 (SELECT count(*)::int FROM information_schema.table_constraints WHERE constraint_schema='lab_tracker' AND constraint_type='FOREIGN KEY') AS foreign_keys,
 (SELECT count(*)::int FROM information_schema.views WHERE table_schema='lab_tracker') AS views,
 (SELECT count(*)::int FROM pg_trigger t JOIN pg_class c ON c.oid=t.tgrelid JOIN pg_namespace n ON n.oid=c.relnamespace WHERE n.nspname='lab_tracker' AND NOT t.tgisinternal) AS triggers,
 (SELECT count(*)::int FROM pg_proc p JOIN pg_namespace n ON n.oid=p.pronamespace WHERE n.nspname='lab_tracker') AS functions`;
async function counts(db){
 const names=(await db.query("SELECT table_name FROM information_schema.tables WHERE table_schema='lab_tracker' AND table_type='BASE TABLE' ORDER BY table_name")).rows;
 const result={};for(const {table_name} of names)result[table_name]=(await db.query(`SELECT count(*)::int AS n FROM lab_tracker.${table_name}`)).rows[0].n;
 return result;
}
const db=new PGlite();let large;
try{
 for(const name of ['sql/01_schema.sql','test/fixtures/02_seed.sql','sql/04_rbac.sql'])await db.exec(await read(name));
 report.version=(await db.query("SELECT version(),CURRENT_DATE AS database_date,current_setting('TimeZone') AS timezone")).rows[0];
 report.catalog=(await db.query(catalogSql)).rows[0];
 if(JSON.stringify(report.catalog)!==JSON.stringify({tables:19,columns:98,foreign_keys:27,views:7,triggers:22,functions:18}))throw Error('Unexpected business catalog');
 report.seed_counts=await counts(db);report.seed_total=Object.values(report.seed_counts).reduce((a,b)=>a+b,0);
 const results=await db.exec(await read('test/sql/05_tests.sql'));
 report.tests=results.findLast(r=>r.fields?.some(f=>f.name==='test_id'))?.rows??[];
 if(report.tests.length<60||!report.tests.every(r=>r.passed))throw Error('Business regression results are incomplete');
 const security=[
  ['S01','lab_app',`UPDATE lab_tracker.chemical SET quantity_in_stock=999 WHERE chemical_id=1`,false],
  ['S02','lab_manager',`UPDATE lab_tracker.chemical SET quantity_in_stock=999 WHERE chemical_id=1`,false],
  ['S03','lab_app',`INSERT INTO lab_tracker.chemical_movement(chemical_id,person_id,quantity,reason,balance_after) VALUES(1,5,1,'Forged',100)`,false],
  ['S04','lab_app',`SELECT lab_tracker.issue_chemical(1,5,1,0.1,'RBAC valid issue')`,true],
  ['S05','lab_app',`SELECT lab_tracker.receive_chemical(1,10,1,'Unauthorized receipt')`,false],
  ['S06','lab_technician',`SELECT lab_tracker.receive_chemical(1,10,1,'RBAC receipt')`,true],
  ['S07','lab_reader',`SELECT lab_tracker.issue_chemical(1,5,1,0.1,'Reader issue')`,false],
  ['S08','lab_app',`INSERT INTO lab_tracker.maintenance_log(technician_id,equipment_id,start_date,description,cost) VALUES(9,12,CURRENT_DATE,'Direct write',1)`,false],
  ['S09','lab_technician',`SELECT lab_tracker.start_maintenance(4,12,'Invalid actor',1)`,false],
  ['S10','lab_app',`SELECT lab_tracker.checkout_equipment(7,12,CURRENT_DATE+1)`,true],
  ['S11','lab_reader',`SELECT status FROM lab_tracker.v_borrow_current LIMIT 1`,true],
  ['S12','lab_reader',`SELECT movement_type FROM lab_tracker.v_chemical_movement LIMIT 1`,true],
 ];
 for(const [id,role,sql,accept] of security){
  await db.exec(`BEGIN; SET LOCAL ROLE ${role}; SET LOCAL search_path=lab_tracker,pg_catalog;`);
  let error;try{await db.exec(sql)}catch(e){error={message:e.message,code:e.code}}
  await db.exec('ROLLBACK');
  const passed=accept?!error:!!error;
  report.security.push({id,role,passed,expected:accept?'Accepted':'Rejected',actual:error?.message??'Accepted',sqlstate:error?.code??null});
  if(!passed)throw Error(`Security test ${id} failed`);
 }
 report.seed_rows_after_tests=await counts(db);
 if(JSON.stringify(report.seed_counts)!==JSON.stringify(report.seed_rows_after_tests))throw Error('Regression tests altered seed rows');
 large=new PGlite();
 await large.exec(await read('sql/01_schema.sql'));await large.exec(await read('sql/02_dataset_1200.sql'));
 report.dataset_counts=await counts(large);report.dataset_total=Object.values(report.dataset_counts).reduce((a,b)=>a+b,0);
 report.dataset_reconciled=(await large.query('SELECT bool_and(reconciled) AS ok FROM lab_tracker.v_chemical_stock_audit')).rows[0].ok;
 if(report.dataset_total!==1200||!report.dataset_reconciled)throw Error('The 1200-row dataset does not load or reconcile');
 await large.exec(await read('sql/04_rbac.sql'));
 await large.exec("ANALYZE; SET ROLE lab_manager; SET search_path=lab_tracker,pg_catalog; SET TIME ZONE 'Asia/Ho_Chi_Minh'");
 report.query_dataset={file:'sql/02_dataset_1200.sql',business_record_count:report.dataset_total,role:'lab_manager'};
 for(let i=1;i<=12;i++){
  const results=await large.exec(await read(`sql/queries/Q${String(i).padStart(2,'0')}.sql`));
  const result=results.at(-1);report.queries.push({id:`Q${String(i).padStart(2,'0')}`,rows:result.rows,row_count:result.rows.length});
 }
 report.passed=true;
}catch(e){report.passed=false;report.error={message:e.message,code:e.code,detail:e.detail,where:e.where};process.exitCode=1;}
finally{
 await db.close();if(large)await large.close();await mkdir(out,{recursive:true});
 await writeFile(path.join(out,'sql_validation_results.json'),JSON.stringify(report,null,2));
 console.log(JSON.stringify({passed:report.passed,catalog:report.catalog,queries:report.queries.length,business_tests:report.tests.length,security_tests:report.security.length,seed_total:report.seed_total,dataset_total:report.dataset_total,error:report.error},null,2));
}
