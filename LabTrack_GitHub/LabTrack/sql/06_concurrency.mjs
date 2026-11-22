import {writeFile} from 'node:fs/promises';
import {fileURLToPath} from 'node:url';
const result={engine:'Native PostgreSQL with independent connections',run_at:new Date().toISOString(),executed:false,tests:[]};
if(!process.env.DATABASE_URL){
 result.reason='DATABASE_URL is required and must point to a disposable PostgreSQL database loaded with 01_schema.sql and 02_seed.sql.';
 console.log(result.reason);process.exitCode=2;
}else{
 let clients=[];
 try{
  const {Client}=await import('pg');
  const admin=new Client({connectionString:process.env.DATABASE_URL});
  const a=new Client({connectionString:process.env.DATABASE_URL});
  const b=new Client({connectionString:process.env.DATABASE_URL});
  clients=[admin,a,b];await Promise.all(clients.map(c=>c.connect()));
  result.executed=true;
  for(const c of clients)await c.query("SET search_path=lab_tracker,pg_catalog; SET TIME ZONE 'Asia/Ho_Chi_Minh'; SET statement_timeout='15s'");
  result.version=(await admin.query('SELECT version()')).rows[0].version;
  const pid=(await b.query('SELECT pg_backend_pid() AS pid')).rows[0].pid;
  async function confirmBlocked(){
   const until=Date.now()+5000;
   while(Date.now()<until){
    const r=await admin.query("SELECT wait_event_type FROM pg_stat_activity WHERE pid=$1",[pid]);
    if(r.rows[0]?.wait_event_type==='Lock')return true;
    await new Promise(resolve=>setTimeout(resolve,50));
   }
   return false;
  }
  const initial=(await admin.query('SELECT count(*)::int AS n FROM borrow_transaction WHERE person_id=4 AND actual_return_date IS NULL')).rows[0].n;
  if(initial!==2)throw Error('T14 requires fresh seed where person 4 has exactly two open loans');
  await a.query('BEGIN');await b.query('BEGIN');
  const loan=(await a.query('SELECT checkout_equipment(4,3,CURRENT_DATE+3) AS id')).rows[0].id;
  let error=null;
  const waiting=b.query('SELECT checkout_equipment(4,11,CURRENT_DATE+3)').catch(e=>{error={code:e.code,message:e.message};return null});
  const blocked=await confirmBlocked();await a.query('COMMIT');await waiting;await b.query('ROLLBACK');
  const open=(await admin.query('SELECT count(*)::int AS n FROM borrow_transaction WHERE person_id=4 AND actual_return_date IS NULL')).rows[0].n;
  const passed=blocked&&open===3&&error?.message.includes('BR14');
  result.tests.push({id:'T14',passed,blocked_on_lock:blocked,committed_open_loans:open,second_transaction:error});
  if(!passed)throw Error('T14 concurrent loan assertion failed');
  await admin.query('SELECT return_equipment(4,$1)',[loan]);
  await a.query('BEGIN');await b.query('BEGIN');
  const before=(await a.query('SELECT quantity_in_stock FROM chemical WHERE chemical_id=6')).rows[0].quantity_in_stock;
  if(Number(before)!==8)throw Error('H13 requires fresh seed chemical 6 stock=8');
  await a.query("SELECT issue_chemical(6,5,1,5,'Concurrency session A')");
  error=null;
  const issueWaiting=b.query("SELECT issue_chemical(6,5,1,5,'Concurrency session B')").catch(e=>{error={code:e.code,message:e.message};return null});
  const issueBlocked=await confirmBlocked();await a.query('COMMIT');await issueWaiting;await b.query('ROLLBACK');
  const stock=(await admin.query('SELECT quantity_in_stock FROM chemical WHERE chemical_id=6')).rows[0].quantity_in_stock;
  const issuePassed=issueBlocked&&Number(stock)===3&&error?.message.includes('BR17');
  result.tests.push({id:'H13',passed:issuePassed,blocked_on_lock:issueBlocked,final_stock:stock,second_transaction:error});
  if(!issuePassed)throw Error('H13 concurrent issuance assertion failed');
  await admin.query("SELECT receive_chemical(6,10,5,'Restore concurrency test quantity')");
  result.executed=true;result.passed=true;
 }catch(e){result.passed=false;result.error={code:e.code,message:e.message};process.exitCode=1;}
 finally{await Promise.allSettled(clients.map(async c=>{try{await c.query('ROLLBACK')}finally{await c.end()}}));}
}
await writeFile(fileURLToPath(new URL('concurrency_results.json',import.meta.url)),JSON.stringify(result,null,2));
console.log(JSON.stringify(result,null,2));
