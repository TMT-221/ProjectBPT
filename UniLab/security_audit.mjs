import {mkdir,open} from 'node:fs/promises';
import {dirname,resolve} from 'node:path';

const methods=new Set(['GET','POST','CLI']);
const outcomes=new Set(['success','failure','denied']);
const resources=new Set(['authentication','database','backup','security-audit','unknown']);
const apiResource=/^\/api\/v1\/(?:auth\/(?:login|logout|me)|preview|dashboard|equipment(?:\/[1-9]\d{0,18})?|labs(?:\/[1-9]\d{0,18}(?:\/safety)?)?|chemicals(?:\/[1-9]\d{0,18}(?:\/(?:points|location))?)?|chemical-(?:issues|receipts)|grants(?:\/[1-9]\d{0,18}(?:\/(?:points|budget))?)?|points\/[1-9]\d{0,18}\/(?:equipment|chemical)-allocations|borrows(?:\/[1-9]\d{0,18}\/return)?|access-logs(?:\/approved|\/[1-9]\d{0,18}\/exit)?|maintenance(?:\/[1-9]\d{0,18}\/complete)?|me\/(?:borrows|access|certifications)|reports(?:\/Q(?:0[1-9]|1[0-2]))?|students)$/;

export function auditResource(route){
 const value='/api/v1'+(typeof route==='string'?route:'');
 return apiResource.test(value)?value:'unknown';
}

function safeEvent(event){
 if(!event||!/^\w[\w.-]{0,63}$/.test(event.action||'')||!outcomes.has(event.outcome))
  throw new TypeError('Invalid security audit event.');
 const actor=event.actor_id==null?null:String(event.actor_id);
 if(actor!==null&&!/^[1-9]\d{0,18}$/.test(actor)) throw new TypeError('Invalid audit actor identifier.');
 const resource=resources.has(event.resource)||apiResource.test(event.resource||'')?event.resource:'unknown';
 const value={timestamp:new Date().toISOString(),request_id:/^[0-9a-f-]{36}$/i.test(event.request_id||'')?event.request_id:null,
  action:event.action,outcome:event.outcome,actor_id:actor,resource};
 if(methods.has(event.method)) value.method=event.method;
 if(Number.isInteger(event.status)&&event.status>=100&&event.status<=599)value.status=event.status;
 if(/^[A-Z][A-Z0-9_]{0,63}$/.test(event.error_code||''))value.error_code=event.error_code;
 if(event.metadata&&typeof event.metadata==='object'){
  const metadata={};
  for(const name of ['encrypted','scheduled'])if(typeof event.metadata[name]==='boolean')metadata[name]=event.metadata[name];
  for(const name of ['removed_count','record_count','duration_ms'])if(Number.isFinite(event.metadata[name])&&event.metadata[name]>=0)metadata[name]=event.metadata[name];
  if(Object.keys(metadata).length)value.metadata=metadata;
 }
 return value;
}

// Application writes only append operations. A host administrator can still alter the file.
export async function createSecurityAudit(file){
 const path=resolve(file);
 await mkdir(dirname(path),{recursive:true});
 const handle=await open(path,'a',0o600);
 let tail=Promise.resolve(),closed=false,lastError;
 const enqueue=operation=>{
  const task=tail.then(operation);
  tail=task.catch(error=>{lastError=error;});
  return task;
 };
 return {
  path,
  record(event){
   if(closed)return Promise.reject(new Error('Security audit is closed.'));
   const line=JSON.stringify(safeEvent(event))+'\n';
   return enqueue(async()=>{await handle.appendFile(line,'utf8');await handle.sync();});
  },
  async flush(){await tail;await handle.sync();if(lastError)throw lastError;},
  async close(){
   if(closed)return;
   closed=true;
   try{await tail;await handle.sync();}finally{await handle.close();}
   if(lastError)throw lastError;
  },
 };
}
