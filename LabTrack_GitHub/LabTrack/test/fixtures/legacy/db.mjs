import { readFile } from 'node:fs/promises';
import { fileURLToPath } from 'node:url';
import { createHash, randomBytes, scrypt, timingSafeEqual } from 'node:crypto';
import { promisify } from 'node:util';

const derive=promisify(scrypt);
const COOKIE='labtrack_session';
export const demoPassword='DemoLab2026!';
export const token=()=>randomBytes(32).toString('base64url');
const digest=value=>createHash('sha256').update(value).digest('hex');
export const same=(a,b)=>typeof a==='string' && typeof b==='string'
 && Buffer.byteLength(a)===Buffer.byteLength(b) && timingSafeEqual(Buffer.from(a),Buffer.from(b));
async function hashPassword(password,salt=randomBytes(16).toString('hex')){
 return salt+':'+(await derive(password,salt,64)).toString('hex');
}
export async function openDatabase(location,options={}){
 const {PGlite}=await import('@electric-sql/pglite').catch(error=>{
   if(error.code!=='ERR_MODULE_NOT_FOUND') throw error;
   return import('../work/node_modules/@electric-sql/pglite/dist/index.js');
 });
 const db=new PGlite({dataDir:location || fileURLToPath(new URL('.data',import.meta.url)),...options});
 try{
  if(!(await db.query("SELECT to_regclass('app_auth.user_account') AS ready")).rows[0].ready){
   const [schema,seed,auth,migration]=await Promise.all(['sql/01_schema.sql','sql/02_dataset_1200.sql','auth.sql','api_migration.sql'].map(name=>readFile(new URL(name,import.meta.url),'utf8')));
   const accounts=[
    ['7','student@lab.local',['member']],
    ['1','faculty@lab.local',['member']],
    ['2','admin@lab.local',['member','research_admin']],
    ['10','technician@lab.local',['member','lab_operator']],
    ['3','auditor@lab.local',['auditor']],
    ['8','inactive@lab.local',['member']],
   ];
   const passwords=await Promise.all(accounts.map(()=>hashPassword(demoPassword)));
   await db.transaction(async tx=>{
    await tx.exec(schema);
    await tx.exec(seed.replace(/^(?:BEGIN|COMMIT);[ \t]*\r?$/gm,''));
    await tx.exec(auth);
    await tx.exec(migration);
    for(const [index,[id,email,roles]] of accounts.entries()){
     await tx.query('INSERT INTO app_auth.user_account(person_id,email,password_hash) VALUES($1,$2,$3)',[id,email,passwords[index]]);
     for(const role of roles) await tx.query('INSERT INTO app_auth.account_role(person_id,role) VALUES($1,$2)',[id,role]);
    }
   });
  }
  await db.exec("SET TIME ZONE 'Asia/Ho_Chi_Minh'; SET search_path TO pg_catalog, lab_tracker");
  const demoUpgrade=await readFile(new URL('demo_upgrade.sql',import.meta.url),'utf8');
  await db.transaction(tx=>tx.exec(demoUpgrade));
  return db;
 }catch(error){await db.close();throw error;}
}
export function withRole(db, role, run){
 const grant={auth:'SET LOCAL ROLE lab_web_auth',business:'SET LOCAL ROLE lab_web_demo'}[role];
 if(!grant) throw new Error('Unknown runtime scope');
 return db.transaction(async tx=>{
  await tx.exec(grant);
  return run(tx);
 });
}
const userFields=`i.person_id::text,i.full_name AS name,i.role,a.email,i.status,a.enabled,
 ARRAY(SELECT role FROM app_auth.account_role r WHERE r.person_id=i.person_id ORDER BY role) AS permissions`;
const publicUser=({person_id,name,role,email,permissions,csrf})=>({person_id,name,role,email,permissions,csrf});
export function cookieValue(headers){
 const value=headers.cookie?.split(';').map(x=>x.trim()).find(x=>x.startsWith(COOKIE+'='))?.slice(COOKIE.length+1);
 return /^[A-Za-z0-9_-]{43}$/.test(value||'') ? value : '';
}
export const cookie=(value='',secure=false)=>`${COOKIE}=${value}; Path=/; HttpOnly; SameSite=Strict; Max-Age=${value?28800:0}${secure?'; Secure':''}`;

export async function signIn(db,email,password,oldToken){
 const account=await withRole(db,'auth',async tx=>(await tx.query(`SELECT ${userFields},a.password_hash
   FROM app_auth.user_account a JOIN app_auth.v_person_identity i USING(person_id) WHERE a.email=$1`,[email])).rows[0]);
 const stored=account?.password_hash;
 const hash=await hashPassword(password,stored?.split(':')[0]||'8eaee314dfb96efb1a84bb0728d3de80');
 if(!stored||!same(stored,hash)||!account.enabled||account.status!=='Active'||!account.role) return null;
 const session=token(), csrf=token();
 await withRole(db,'auth',async tx=>{
  await tx.query("DELETE FROM app_auth.session WHERE expires_at<=now() OR last_seen<=now()-interval '30 minutes' OR token_hash=$1",[digest(oldToken)]);
  await tx.query('INSERT INTO app_auth.session(token_hash,person_id,csrf_token) VALUES($1,$2,$3)',[digest(session),account.person_id,csrf]);
 });
 return {session,user:publicUser({...account,csrf})};
}
export async function sessionUser(db,session){
 if(!session) return null;
 return withRole(db,'auth',async tx=>{
  const {rows:[user]}=await tx.query(`SELECT ${userFields},s.csrf_token AS csrf
    FROM app_auth.session s JOIN app_auth.user_account a USING(person_id)
    JOIN app_auth.v_person_identity i USING(person_id)
    WHERE s.token_hash=$1 AND a.enabled AND i.status='Active' AND s.expires_at>now()
    AND s.last_seen>now()-interval '30 minutes'`,[digest(session)]);
  if(!user) return null;
  await tx.query("UPDATE app_auth.session SET last_seen=now() WHERE token_hash=$1 AND last_seen<now()-interval '1 minute'",[digest(session)]);
  return publicUser(user);
 });
}
export const signOut=(db,session)=>withRole(db,'auth',tx=>tx.query('DELETE FROM app_auth.session WHERE token_hash=$1',[digest(session)]));
