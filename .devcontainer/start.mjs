import {spawn} from 'node:child_process';
import {mkdir,open,readFile,writeFile} from 'node:fs/promises';
import {fileURLToPath} from 'node:url';
import {setTimeout as delay} from 'node:timers/promises';
import {portFromEnvironment,publicOriginFromEnvironment} from '../UniLab/deployment.mjs';

const root=fileURLToPath(new URL('../',import.meta.url));
const runtime=new URL('./runtime/',import.meta.url);
const logFile=new URL('./runtime/server.log',import.meta.url);
const port=portFromEnvironment();
const local=`http://127.0.0.1:${port}`;
const external=publicOriginFromEnvironment(process.env,port)||local;

async function ready(){
  try{
    const response=await fetch(`${local}/api/v1/preview`,{signal:AbortSignal.timeout(1500)});
    if(!response.ok)return false;
    const result=await response.json();
    return Boolean(result.data&&result.request_id);
  }catch{return false;}
}

if(await ready()){
  console.log(`UniLab đang chạy: ${local}\nMở trong trình duyệt: ${external}`);
}else{
  await mkdir(runtime,{recursive:true});
  const log=await open(logFile,'a');
  let child;
  try{
    child=spawn(process.execPath,[fileURLToPath(new URL('../UniLab/server.mjs',import.meta.url))],{
      cwd:root,env:process.env,detached:true,windowsHide:true,stdio:['ignore',log.fd,log.fd]
    });
    await new Promise((resolve,reject)=>{child.once('spawn',resolve);child.once('error',reject);});
    await writeFile(new URL('./runtime/server.pid',import.meta.url),String(child.pid)+'\n');
  }finally{await log.close();}
  let stopped;
  child.once('exit',(code,signal)=>{stopped={code,signal};});
  child.unref();
  let available=false;
  const deadline=Date.now()+120_000;
  while(Date.now()<deadline){
    if(await ready()){available=true;break;}
    if(stopped)break;
    await delay(500);
  }
  if(!available){
    const tail=(await readFile(logFile,'utf8')).slice(-3000);
    console.error(`Chưa khởi động được UniLab. Xem .devcontainer/runtime/server.log.\n${tail}`);
    process.exitCode=1;
  }else{
    console.log(`UniLab đã sẵn sàng: ${local}\nMở trong trình duyệt: ${external}\nDữ liệu được lưu trong UniLab/.data. Mở lại Codespace này để tiếp tục sử dụng.`);
  }
}
