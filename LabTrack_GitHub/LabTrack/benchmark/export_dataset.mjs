import { PGlite } from '@electric-sql/pglite';
import { readFile,writeFile,mkdir } from 'node:fs/promises';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import {createHash} from 'node:crypto';
const root=path.resolve(path.dirname(fileURLToPath(import.meta.url)),'..');
const hash=s=>createHash('sha256').update(s).digest('hex');
await mkdir(path.join(root,'evidence'),{recursive:true});
const schema=await readFile(path.join(root,'sql/01_schema.sql'),'utf8');
const seed=await readFile(path.join(root,'sql/02_dataset_1200.sql'),'utf8');
const db=new PGlite();
const result={run_at:new Date().toISOString(),source:{schema_sha256:hash(schema),dataset_sha256:hash(seed)},tables:[]};
try{
  await db.exec(schema);await db.exec(seed);
  result.environment=(await db.query("SELECT version(),CURRENT_DATE::text AS date,current_setting('TimeZone') AS timezone")).rows[0];
  const tables=(await db.query("SELECT table_name FROM information_schema.tables WHERE table_schema='lab_tracker' AND table_type='BASE TABLE' ORDER BY table_name")).rows;
  for(const {table_name:name} of tables){
    const columns=(await db.query("SELECT column_name,data_type,udt_name,ordinal_position,is_nullable,numeric_scale FROM information_schema.columns WHERE table_schema='lab_tracker' AND table_name=$1 ORDER BY ordinal_position",[name])).rows;
    const pk=(await db.query("SELECT k.column_name FROM information_schema.table_constraints t JOIN information_schema.key_column_usage k USING(constraint_catalog,constraint_schema,constraint_name) WHERE t.table_schema='lab_tracker' AND t.table_name=$1 AND t.constraint_type='PRIMARY KEY' ORDER BY k.ordinal_position",[name])).rows.map(r=>r.column_name);
    const select=columns.map(c=>['date','timestamp without time zone','timestamp with time zone'].includes(c.data_type)?`"${c.column_name}"::text AS "${c.column_name}"`:`"${c.column_name}"`).join(',');
    const rows=(await db.query(`SELECT ${select} FROM lab_tracker."${name}" ORDER BY ${pk.map(n=>'"'+n+'"').join(',')}`)).rows;
    result.tables.push({name,columns,primary_key:pk,rows});
  }
  result.business_table_count=result.tables.length;result.base_column_count=result.tables.reduce((s,t)=>s+t.columns.length,0);result.business_record_count=result.tables.reduce((s,t)=>s+t.rows.length,0);
  result.derived_base_columns=result.tables.flatMap(t=>t.columns.filter(c=>(['has_certification','borrow_transaction'].includes(t.name)&&c.column_name==='status')||(t.name==='chemical_movement'&&c.column_name==='movement_type')).map(c=>t.name+'.'+c.column_name));
  result.stock_audit=(await db.query('SELECT * FROM lab_tracker.v_chemical_stock_audit ORDER BY chemical_id')).rows;
  if(result.business_table_count!==19||result.base_column_count!==98||result.business_record_count!==1200||result.derived_base_columns.length)throw Error('Dataset shape mismatch');
}finally{await db.close();}
await writeFile(path.join(root,'evidence/dataset_1200.json'),JSON.stringify(result,null,2));
console.log(JSON.stringify({tables:result.business_table_count,columns:result.base_column_count,records:result.business_record_count,rows:Object.fromEntries(result.tables.map(t=>[t.name,t.rows.length])),stock:result.stock_audit}));
