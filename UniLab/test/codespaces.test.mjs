import test from 'node:test';
import assert from 'node:assert/strict';
import {once} from 'node:events';
import {createApp} from '../server.mjs';
import {openDatabase,demoPassword} from '../db.mjs';
import {portFromEnvironment,publicOriginFromEnvironment,validatePublicOrigin} from '../deployment.mjs';

const origin='https://friendly-space-4173.app.github.dev';
const credentials={email:'student@lab.local',password:demoPassword};

test('Deployment configuration validates canonical HTTPS origin and Codespaces environment',()=>{
 assert.equal(portFromEnvironment({}),4173);
 assert.equal(portFromEnvironment({LABTRACK_PORT:'5000'}),5000);
 for(const value of ['', '0','1023','65536','4173.0',' 4173','4173junk'])
  assert.throws(()=>portFromEnvironment({LABTRACK_PORT:value}),/LABTRACK_PORT/);
 assert.equal(publicOriginFromEnvironment({}),undefined);
 assert.equal(publicOriginFromEnvironment({CODESPACES:'false',CODESPACE_NAME:'ignored'}),undefined);
 assert.equal(publicOriginFromEnvironment({CODESPACES:'true',CODESPACE_NAME:'friendly-space',GITHUB_CODESPACES_PORT_FORWARDING_DOMAIN:'app.github.dev'}),origin);
 assert.equal(publicOriginFromEnvironment({CODESPACES:'true',CODESPACE_NAME:'friendly-space',GITHUB_CODESPACES_PORT_FORWARDING_DOMAIN:'app.github.dev',LABTRACK_PORT:'5000'}),
  'https://friendly-space-5000.app.github.dev');
 assert.equal(publicOriginFromEnvironment({LABTRACK_PUBLIC_ORIGIN:'https://demo.example.test',CODESPACES:'true'}),'https://demo.example.test');
 for(const value of ['http://demo.example.test','https://demo.example.test/','https://demo.example.test/path','https://demo.example.test?x=1',
  'https://demo.example.test#x','https://user:password@demo.example.test',' https://demo.example.test','https://DEMO.example.test','https://demo.example.test:443',''])
  assert.throws(()=>validatePublicOrigin(value),/LABTRACK_PUBLIC_ORIGIN/);
 for(const env of [
  {CODESPACES:'true'},
  {CODESPACES:'true',CODESPACE_NAME:'space/path',GITHUB_CODESPACES_PORT_FORWARDING_DOMAIN:'app.github.dev'},
  {CODESPACES:'true',CODESPACE_NAME:'space',GITHUB_CODESPACES_PORT_FORWARDING_DOMAIN:'app.github.dev/path'},
  {CODESPACES:'true',CODESPACE_NAME:'space',GITHUB_CODESPACES_PORT_FORWARDING_DOMAIN:'app.github.dev:443'},
  {CODESPACES:'true',CODESPACE_NAME:'space',GITHUB_CODESPACES_PORT_FORWARDING_DOMAIN:'app..github.dev'},
  {CODESPACES:'true',CODESPACE_NAME:'a'.repeat(63),GITHUB_CODESPACES_PORT_FORWARDING_DOMAIN:'app.github.dev'},
 ])assert.throws(()=>publicOriginFromEnvironment(env),/Codespace/);
 assert.throws(()=>createApp({}, {publicOrigin:'http://unsafe.example.test'}),/LABTRACK_PUBLIC_ORIGIN/);
});

test('Codespaces HTTPS origin works over internal HTTP while preserving Origin and CSRF checks',async t=>{
 const db=await openDatabase('memory://');
 const server=createApp(db,{publicOrigin:origin,logger:{error(){}}});
 server.listen(0,'127.0.0.1');
 await once(server,'listening');
 t.after(async()=>{await new Promise(resolve=>server.close(resolve));await db.close();});
 const base=`http://127.0.0.1:${server.address().port}`;
 const call=async(path,{body,headers={}}={})=>{
  const response=await fetch(base+'/api/v1'+path,{method:body===undefined?'GET':'POST',
   headers:{...(body===undefined?{}:{'content-type':'application/json'}),...headers},body:body===undefined?undefined:JSON.stringify(body)});
  return {status:response.status,cookie:response.headers.get('set-cookie'),payload:response.status===204?undefined:await response.json()};
 };
 const login=await call('/auth/login',{body:credentials,headers:{origin}});
 assert.equal(login.status,200,JSON.stringify(login.payload));
 assert.match(login.cookie,/; HttpOnly; SameSite=Strict;/);
 assert.match(login.cookie,/; Secure$/);
 const cookie=login.cookie.split(';')[0],csrf=login.payload.data.csrf;
 for(const spoofedOrigin of ['https://evil.example.test',base]){
  const denied=await call('/auth/login',{body:credentials,headers:{origin:spoofedOrigin,
   'x-forwarded-host':new URL(spoofedOrigin).host,'x-forwarded-proto':'https',forwarded:`proto=https;host=${new URL(spoofedOrigin).host}`}});
  assert.equal(denied.status,403);
  assert.equal(denied.cookie,null);
 }
 const missing=await call('/auth/logout',{body:{},headers:{origin,cookie}});
 assert.equal(missing.status,403);
 assert.equal(missing.payload.error.code,'CSRF_REQUIRED');
 const incorrect=await call('/auth/logout',{body:{},headers:{origin,cookie,'x-csrf-token':'incorrect'}});
 assert.equal(incorrect.status,403);
 assert.equal(incorrect.payload.error.code,'CSRF_REQUIRED');
 const foreign=await call('/auth/logout',{body:{},headers:{origin:'https://evil.example.test',cookie,'x-csrf-token':csrf,
  'x-forwarded-host':new URL(origin).host,'x-forwarded-proto':'https'}});
 assert.equal(foreign.status,403);
 assert.equal((await call('/auth/me',{headers:{cookie}})).status,200);
 const logout=await call('/auth/logout',{body:{},headers:{origin,cookie,'x-csrf-token':csrf}});
 assert.equal(logout.status,204);
 assert.match(logout.cookie,/Max-Age=0; Secure$/);
 assert.equal((await call('/auth/me',{headers:{cookie}})).status,401);
});

test('Local HTTP keeps its own origin and does not trust forwarded protocol',async t=>{
 const db=await openDatabase('memory://');
 const server=createApp(db,{logger:{error(){}}});
 server.listen(0,'127.0.0.1');
 await once(server,'listening');
 t.after(async()=>{await new Promise(resolve=>server.close(resolve));await db.close();});
 const base=`http://127.0.0.1:${server.address().port}`;
 const login=await fetch(base+'/api/v1/auth/login',{method:'POST',headers:{'content-type':'application/json',origin:base,
  'x-forwarded-proto':'https','x-forwarded-host':'evil.example.test'},body:JSON.stringify(credentials)});
 assert.equal(login.status,200);
 assert.ok(!login.headers.get('set-cookie').includes('; Secure'));
 const foreign=await fetch(base+'/api/v1/auth/login',{method:'POST',headers:{'content-type':'application/json',origin,
  'x-forwarded-proto':'https','x-forwarded-host':new URL(origin).host},body:JSON.stringify(credentials)});
 assert.equal(foreign.status,403);
});
