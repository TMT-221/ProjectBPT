import { PGlite } from '@electric-sql/pglite';
import { readFile, writeFile, mkdir } from 'node:fs/promises';
import { createHash } from 'node:crypto';
import { fileURLToPath } from 'node:url';
import path from 'node:path';
import os from 'node:os';
import { performance } from 'node:perf_hooks';

const root=path.resolve(path.dirname(fileURLToPath(import.meta.url)),'..');
const output=path.join(root,'evidence');
await mkdir(output,{recursive:true});
const datasetFile='02_dataset_1200.sql';
const queryFiles=Array.from({length:12},(_,i)=>`queries/Q${String(i+1).padStart(2,'0')}.sql`);
const names=['01_schema.sql',datasetFile,'04_rbac.sql','03_queries.sql',...queryFiles];
const source=Object.fromEntries(await Promise.all(names.map(async name=>[name,await readFile(path.join(root,'sql',name),'utf8')])));
const sha=text=>createHash('sha256').update(text).digest('hex');
const before=Object.fromEntries(names.map(n=>[n,sha(source[n])]));
const statements=source['03_queries.sql'].split(';').map(s=>s.trim()).filter(s=>s&&!/^SET\s/i.test(s));
if(statements.length!==12)throw Error(`Expected 12 query statements; found ${statements.length}`);
const normalize=sql=>sql.replace(/--[^\r\n]*/g,'').replace(/\s+/g,' ').trim();
for(const [i,name] of queryFiles.entries()){
  const individual=source[name].split(';').map(s=>s.trim()).filter(s=>s&&!/^SET\s/i.test(s));
  if(individual.length!==1||normalize(individual[0])!==normalize(statements[i]))throw Error(`Query source mismatch: ${name}`);
}
const median=values=>{const a=[...values].sort((a,b)=>a-b);return a[Math.floor(a.length/2)];};
const p95=values=>[...values].sort((a,b)=>a-b)[Math.ceil(values.length*.95)-1];
const round=n=>Math.round(n*1e6)/1e6;
const result={run_at:new Date().toISOString(),scope:'PostgreSQL SQL execution in one embedded PGlite connection; no HTTP, network, native PostgreSQL server, or concurrent-session benchmark.',environment:{platform:os.platform(),architecture:os.arch(),cpu:os.cpus()[0]?.model,cpu_logical_threads:os.cpus().length,node:process.version,pglite:'0.5.10',total_memory_bytes:os.totalmem()},method:{warmup_per_query:3,direct_samples_per_query:15,explain_samples_per_query:15,interleaved:true,p95:'Nearest rank: sorted sample at ceil(0.95*n); n=15 means the maximum observed sample.',direct_clock:'performance.now() around db.query; includes JavaScript/WASM bridge and result materialization.',explain_clock:'Execution Time returned by EXPLAIN (ANALYZE, BUFFERS, FORMAT JSON); includes instrumentation overhead; not directly comparable with client duration.'},source_sha256_before:before,queries:[]};
const db=new PGlite();
try{
  for(const name of ['01_schema.sql',datasetFile,'04_rbac.sql'])await db.exec(source[name]);
  result.environment.database=(await db.query("SELECT version(),CURRENT_DATE::text AS database_date,current_setting('TimeZone') AS timezone")).rows[0];
  result.catalog=(await db.query(`SELECT
    (SELECT count(*)::int FROM information_schema.tables WHERE table_schema='lab_tracker' AND table_type='BASE TABLE') AS tables,
    (SELECT count(*)::int FROM information_schema.columns c JOIN information_schema.tables t USING(table_catalog,table_schema,table_name) WHERE c.table_schema='lab_tracker' AND t.table_type='BASE TABLE') AS columns,
    (SELECT count(*)::int FROM information_schema.table_constraints WHERE table_schema='lab_tracker' AND constraint_type='FOREIGN KEY') AS foreign_keys,
    (SELECT count(*)::int FROM information_schema.views WHERE table_schema='lab_tracker') AS views,
    (SELECT count(*)::int FROM pg_trigger t JOIN pg_class c ON c.oid=t.tgrelid JOIN pg_namespace n ON n.oid=c.relnamespace WHERE n.nspname='lab_tracker' AND NOT t.tgisinternal) AS triggers,
    (SELECT count(*)::int FROM pg_proc p JOIN pg_namespace n ON n.oid=p.pronamespace WHERE n.nspname='lab_tracker') AS functions`)).rows[0];
  const tables=(await db.query("SELECT table_name FROM information_schema.tables WHERE table_schema='lab_tracker' AND table_type='BASE TABLE' ORDER BY table_name")).rows;
  result.row_counts={};
  for(const {table_name:n} of tables)result.row_counts[n]=(await db.query(`SELECT count(*)::int AS n FROM lab_tracker."${n}"`)).rows[0].n;
  const recordCount=Object.values(result.row_counts).reduce((sum,n)=>sum+n,0);
  const stockAudit=(await db.query('SELECT * FROM lab_tracker.v_chemical_stock_audit ORDER BY chemical_id')).rows;
  if(result.catalog.tables!==19||result.catalog.columns!==98||recordCount!==1200)throw Error('Expected 19 business tables, 98 columns, and 1200 records');
  if(stockAudit.length!==6||!stockAudit.every(row=>row.reconciled))throw Error('Chemical stock does not reconcile');
  result.dataset={name:'Synthetic 1200-record business dataset',file:`sql/${datasetFile}`,sha256:before[datasetFile],record_count:recordCount,business_table_count:result.catalog.tables,base_column_count:result.catalog.columns,database_date:result.environment.database.database_date,timezone:result.environment.database.timezone,stock_reconciled:true,stock_audit:stockAudit};
  result.query_sources_match=true;
  await db.exec("ANALYZE; SET ROLE lab_manager; SET search_path=lab_tracker,pg_catalog; SET TIME ZONE 'Asia/Ho_Chi_Minh'");
  for(const [index,sql] of statements.entries()){
    for(let j=0;j<3;j++)await db.query(sql);
    const direct=[],explain=[],clientExplain=[];let expected,rows,fields,firstPlan;
    for(let j=0;j<15;j++){
      let start=performance.now();const r=await db.query(sql);direct.push(round(performance.now()-start));
      const encoded=JSON.stringify(r.rows);if(expected!==undefined&&encoded!==expected)throw Error(`Q${index+1}: unstable result`);
      expected=encoded;rows=r.rows;fields=r.fields;
      start=performance.now();const e=await db.query(`EXPLAIN (ANALYZE, BUFFERS, FORMAT JSON) ${sql}`);clientExplain.push(round(performance.now()-start));
      const plan=e.rows[0]['QUERY PLAN'][0];explain.push(plan['Execution Time']);if(j===0)firstPlan=plan;
    }
    const summary={median_client_ms:round(median(direct)),p95_client_ms:round(p95(direct)),median_explain_execution_ms:round(median(explain))};
    result.queries.push({id:`Q${String(index+1).padStart(2,'0')}`,sql,row_count:rows.length,fields,rows,...summary,median_explain_ms:summary.median_explain_execution_ms,samples:{direct_client_ms:direct,explain_client_ms:clientExplain,explain_execution_ms:explain},summary,first_plan:firstPlan,stable_result:true});
  }
}finally{await db.close();}
result.source_sha256_after=Object.fromEntries(await Promise.all(names.map(async n=>[n,sha(await readFile(path.join(root,'sql',n),'utf8'))])));
result.sources_unchanged=JSON.stringify(result.source_sha256_before)===JSON.stringify(result.source_sha256_after);
result.completed_at=new Date().toISOString();
await writeFile(path.join(output,'query_performance_results.json'),JSON.stringify(result,null,2));
await writeFile(path.join(output,'query_results.json'),JSON.stringify({run_at:result.run_at,engine:result.environment.database.version,timezone:result.environment.database.timezone,environment:result.environment,catalog:result.catalog,dataset:result.dataset,row_counts:result.row_counts,query_sources_match:result.query_sources_match,queries:result.queries.map(({id,sql,row_count,fields,rows})=>({id,sql,row_count,fields,rows})),source_sha256:before},null,2));
console.log(JSON.stringify({catalog:result.catalog,dataset_rows:result.dataset.record_count,row_counts:result.queries.map(q=>q.row_count),performance:result.queries.map(q=>({id:q.id,...q.summary})),sources_unchanged:result.sources_unchanged,query_sources_match:result.query_sources_match}));
