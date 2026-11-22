import {PGlite} from '@electric-sql/pglite';
import {readFile,writeFile,mkdir} from 'node:fs/promises';
import {createHash} from 'node:crypto';
import {fileURLToPath} from 'node:url';
import path from 'node:path';
import os from 'node:os';
import {performance} from 'node:perf_hooks';
const root=path.resolve(path.dirname(fileURLToPath(import.meta.url)),'..');
const output=path.join(root,'evidence');await mkdir(output,{recursive:true});
const schema=await readFile(path.join(root,'sql/01_schema.sql'),'utf8');
const db=new PGlite();
const result={run_at:new Date().toISOString(),scope:'NFR02-scale SQL microbenchmark in one embedded PGlite connection. Not a native PostgreSQL server, API latency, cold-cache test, or concurrent-user acceptance.',environment:{platform:os.platform(),architecture:os.arch(),cpu:os.cpus()[0]?.model,node:process.version,pglite:'0.5.10'},source_sha256:createHash('sha256').update(schema).digest('hex'),method:{warmup_per_query:10,samples_per_query:100,p95:'Nearest rank: sorted sample number 95 of 100.',sql_clock:'Execution Time from EXPLAIN (ANALYZE, BUFFERS, FORMAT JSON); instrumentation enabled.',client_clock:'performance.now around EXPLAIN call; measured separately and not compared with NFR02 threshold.',cache:'Warm in-memory engine; no network.'},measurements:[]};
const median=a=>[...a].sort((x,y)=>x-y)[Math.floor(a.length/2)];
const p95=a=>[...a].sort((x,y)=>x-y)[94];
const collectNodes=plan=>[plan,...(plan.Plans||[]).flatMap(collectNodes)];
try{
  await db.exec(schema);
  result.environment.database=(await db.query("SELECT version(),CURRENT_DATE::text AS database_date,current_setting('TimeZone') AS timezone")).rows[0];
  await db.exec(`BEGIN;
    INSERT INTO lab_tracker.person(person_id,full_name,email,status) VALUES(1,'Người đo hiệu năng','benchmark@lab.example','Active');
    INSERT INTO lab_tracker.faculty(faculty_id,department,academic_rank) VALUES(1,'Kiểm thử','Giảng viên');
    COMMIT;
    INSERT INTO lab_tracker.laboratory(lab_id,lab_name,building,room_number,capacity,safety_level)
      SELECT g,'Phòng đo '||g,'BENCH',g::text,100,'Normal' FROM generate_series(1,10) g;
    INSERT INTO lab_tracker.equipment(equipment_id,lab_id,equipment_name,serial_number,purchase_date,purchase_cost,current_status)
      SELECT g,((g/10)%10)+1,'Thiết bị đo '||g,'BENCH-'||g,CURRENT_DATE,1000000,
        CASE WHEN g%10<3 THEN 'Available' ELSE 'Retired' END FROM generate_series(1,100000) g;`);
  const start=performance.now();
  // All rows satisfy the same FK, date, role, and Normal-room access policy. Batch construction avoids storing unrelated business histories.
  for(let offset=0;offset<1000000;offset+=100000){
    await db.exec(`INSERT INTO lab_tracker.access_log(log_id,person_id,lab_id,entry_time,exit_time,purpose)
      SELECT g,1,(g%10)+1,CURRENT_DATE-(g%180)::int+time '08:00'+(g%540)*interval '1 minute',
        CURRENT_DATE-(g%180)::int+time '08:30'+(g%540)*interval '1 minute','Đo hiệu năng truy vấn'
      FROM generate_series(${offset+1},${offset+100000}) g`);
    console.log(`Loaded ${offset+100000} access logs`);
  }
  result.load_ms=performance.now()-start;
  result.dataset=(await db.query(`SELECT
    (SELECT count(*)::int FROM lab_tracker.equipment) AS equipment,
    (SELECT count(*)::int FROM lab_tracker.equipment WHERE current_status='Available') AS available_equipment,
    (SELECT count(*)::int FROM lab_tracker.access_log) AS access_log,
    (SELECT count(*)::int FROM lab_tracker.laboratory) AS laboratory`)).rows[0];
  await db.exec('ANALYZE');
  const queries=[
    {id:'NFR02-E',name:'Tra cứu thiết bị',limit:20,parameters:{lab_id:1,current_status:'Available'},sql:"SELECT equipment_id,equipment_name,lab_id,current_status FROM lab_tracker.equipment WHERE lab_id=1 AND current_status='Available' ORDER BY equipment_id LIMIT 20"},
    {id:'NFR02-A',name:'Lịch sử truy cập',limit:50,parameters:{lab_id:1,days:30},sql:"SELECT log_id,person_id,entry_time,exit_time,purpose FROM lab_tracker.access_log WHERE lab_id=1 AND entry_time>=CURRENT_DATE-30 ORDER BY entry_time DESC LIMIT 50"}
  ];
  for(const q of queries){
    for(let j=0;j<10;j++)await db.query(q.sql);
    const sqlMs=[],clientMs=[],planning=[];let firstPlan;
    for(let j=0;j<100;j++){
      const start=performance.now();const r=await db.query('EXPLAIN (ANALYZE, BUFFERS, FORMAT JSON) '+q.sql);
      clientMs.push(performance.now()-start);const p=r.rows[0]['QUERY PLAN'][0];sqlMs.push(p['Execution Time']);planning.push(p['Planning Time']);
      if(j===0)firstPlan=p;
    }
    const rows=(await db.query(q.sql)).rows;
    result.measurements.push({...q,row_count:rows.length,rows,samples:{execution_ms:sqlMs,planning_ms:planning,explain_client_ms:clientMs},median_sql_ms:median(sqlMs),p95_sql_ms:p95(sqlMs),p95_client_ms:p95(clientMs),threshold_ms:200,passes_embedded_measurement:p95(sqlMs)<200,first_plan:firstPlan,plan_nodes:collectNodes(firstPlan.Plan).map(n=>({node_type:n['Node Type'],index_name:n['Index Name'],relation_name:n['Relation Name'],actual_rows:n['Actual Rows'],actual_loops:n['Actual Loops'],shared_hit_blocks:n['Shared Hit Blocks'],shared_read_blocks:n['Shared Read Blocks'],rows_removed_by_filter:n['Rows Removed by Filter']}))});
  }
}finally{await db.close();}
result.completed_at=new Date().toISOString();
await writeFile(path.join(output,'nfr02_embedded_results.json'),JSON.stringify(result,null,2));
console.log(JSON.stringify({dataset:result.dataset,measurements:result.measurements.map(({id,row_count,median_sql_ms,p95_sql_ms,p95_client_ms,passes_embedded_measurement})=>({id,row_count,median_sql_ms,p95_sql_ms,p95_client_ms,passes_embedded_measurement}))}));
