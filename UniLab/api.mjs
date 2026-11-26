const S = 'lab_tracker';
const fields = (object = {}, allowed = []) => {
  if (!object || typeof object !== 'object' || Array.isArray(object)) fail(400, 'INVALID_BODY', 'Nội dung yêu cầu không hợp lệ.');
  if (Object.keys(object).some(key => !allowed.includes(key))) fail(400, 'INVALID_FIELD', 'Yêu cầu có trường không được phép.');
};
function fail(status, code, message) {
  throw Object.assign(new Error(message), {status, code});
}
const invalid = (key) => fail(400, 'INVALID_FIELD', `Giá trị ${key} không hợp lệ.`);
const missing = (message) => fail(404, 'NOT_FOUND', message);
function id(value, key = 'mã định danh') {
  const v = typeof value === 'number' && Number.isSafeInteger(value) ? String(value) : value;
  if (typeof v !== 'string' || !/^[1-9]\d{0,18}$/.test(v) || BigInt(v) > 9223372036854775807n) invalid(key);
  return v;
}
function day(value, key = 'ngày') {
  if (typeof value !== 'string' || !/^\d{4}-\d{2}-\d{2}$/.test(value) || value.startsWith('0000')) invalid(key);
  const date = new Date(value + 'T00:00:00Z');
  if (!Number.isFinite(date.valueOf()) || date.toISOString().slice(0, 10) !== value) invalid(key);
  return value;
}
function str(value, key, max) {
  if (typeof value !== 'string') invalid(key);
  const out = value.trim();
  if (!out || [...out].length > max || out.includes('\0')) invalid(key);
  return out;
}
function decimal(value, key, {scale, digits, positive = false}) {
  const s = typeof value === 'number' && Number.isFinite(value) ? String(value) : value;
  if (typeof s !== 'string' || !new RegExp(`^(?:0|[1-9]\\d{0,${digits-1}})(?:\\.\\d{1,${scale}})?$`).test(s) || (positive && !/[1-9]/.test(s))) invalid(key);
  return s;
}
const qty = (value) => decimal(value, 'số lượng', {scale:3,digits:11,positive:true});
const cost = (value) => decimal(value, 'chi phí', {scale:2,digits:16});
const staff = (u) => ['faculty','technician'].includes(u?.role);
const permissions = (u) => u?.permissions ?? u?.roles;
const hasPermission = (u,p) => Array.isArray(permissions(u)) && permissions(u).includes(p);
const technician = (u) => u?.role === 'technician' && (permissions(u) == null || hasPermission(u,'lab_operator'));
const auditorOnly = (u) => u?.role === 'auditor' || (hasPermission(u,'auditor') && !permissions(u).some(p => ['member','lab_operator','research_admin'].includes(p)));
const admin = (u) => hasPermission(u,'research_admin');
const person = (u) => u?.person_id == null ? null : id(u.person_id);
const member = (u) => !!person(u) && hasPermission(u,'member') && !auditorOnly(u);
const labLevels = ['Normal','Restricted','Hazardous'];
const readOnly = 'Tài khoản này chỉ có quyền xem.';
function requireStaff(u) {
  if (!staff(u) || auditorOnly(u)) fail(403, 'FORBIDDEN', 'Chỉ giảng viên hoặc kỹ thuật viên được phê duyệt lượt vào.');
}
function requireOperator(u) {
  if (!technician(u) || auditorOnly(u)) fail(403, 'FORBIDDEN', 'Chỉ kỹ thuật viên có quyền vận hành được thực hiện thao tác này.');
}
const qs = (db, sql, args = []) => db.query(sql, args).then(r => r.rows);
const first = (db, sql, args) => qs(db, sql, args).then(rows => rows[0]);
const ts = (expression) => `to_char(${expression}, 'YYYY-MM-DD"T"HH24:MI:SS') || '+07:00'`;
const borrowStatus = 'b.status';
const certStatus = `CASE WHEN h.issue_date > CURRENT_DATE THEN 'Pending' ELSE h.status END`;
const ownOrAdmin = `(g.principal_investigator_id=$1::bigint OR $2::boolean)`;
const numericPage = (value, fallback, max) => {
  if (value == null || value === '') return fallback;
  if (!/^\d{1,8}$/.test(value) || Number(value)<1) invalid('trang');
  return Math.min(Number(value),max);
};
async function page(db, p, sql, values, order, allowedSort = []) {
  const index = numericPage(p.get('page'),1,100000);
  const size = numericPage(p.get('page_size'),20,100);
  const requested = p.get('sort');
  if (requested) {
    const descending=requested.startsWith('-'), key=descending ? requested.slice(1) : requested;
    if (!allowedSort.includes(key)) invalid('sắp xếp');
    order=`${key} ${descending ? 'DESC' : 'ASC'} NULLS LAST, ${order}`;
  }
  // The SQL and order strings are composed solely from fixed route definitions.
  const [meta] = await qs(db, `SELECT count(*)::integer AS total FROM (${sql}) AS scoped`, values);
  const rows = await qs(db,`SELECT * FROM (${sql}) AS scoped ORDER BY ${order} LIMIT $${values.length+1} OFFSET $${values.length+2}`,[...values,size,(index-1)*size]);
  return {rows,total:meta.total,page:index,page_size:size};
}
function where(initial = [], args = []) {
  const parts = [...initial], values = [...args];
  return {
    values,
    add(clause,value) {
      if (value == null || value === '') return;
      if (typeof clause === 'function') {
        values.push(value);
        parts.push(clause('$'+values.length));
      } else parts.push(clause);
    },
    search(cols,value) {
      if (value == null || value.trim() === '') return;
      const s = str(value,'tìm kiếm',150);
      this.add(slot => '('+cols.map(col => `strpos(lower(${col}),lower(${slot}::text))>0`).join(' OR ')+')',s);
    },
    get sql() { return parts.length ? ' WHERE '+parts.join(' AND ') : ''; }
  };
}
function optId(params,key) { const v = params.get(key); return v ? id(v,key) : null; }
function pick(value, allowed, key) {
  if (value == null || value === '' || value === 'all') return null;
  if (!allowed.includes(value)) invalid(key);
  return value;
}
function dateRange(params) {
  const from = params.get('from') ? day(params.get('from'),'ngày bắt đầu') : null;
  const to = params.get('to') ? day(params.get('to'),'ngày kết thúc') : null;
  if (from && to && to <= from) invalid('khoảng ngày');
  return {from,to};
}
function dateWhere(w,column,params) {
  const {from,to}=dateRange(params);
  w.add(s=>`${column}>=${s}::date`,from);
  w.add(s=>`${column}<${s}::date`,to);
}
function flagWhere(w,value, clauses, key = 'trạng thái') {
  if (value == null || value === '' || value === 'all') return;
  if (!Object.hasOwn(clauses,value.toLowerCase())) invalid(key);
  w.add(clauses[value.toLowerCase()],true);
}

const labSelect = `SELECT l.lab_id::text, l.lab_name,l.building,l.room_number,l.capacity,l.safety_level,
  count(e.equipment_id)::integer AS equipment_count,
  (count(e.equipment_id) FILTER(WHERE e.current_status='Available'))::integer AS available_count
  FROM ${S}.laboratory l LEFT JOIN ${S}.equipment e USING(lab_id)
  GROUP BY l.lab_id ORDER BY l.lab_id`;
const labCertificates = ['An toàn phòng thí nghiệm cơ bản','Xử lý dung môi dễ cháy','Xử lý axit oxy hóa mạnh'];
const sqlLiteral = value => "'"+value.replaceAll("'","''")+"'";
const labCertified = (actor,level) => `NOT EXISTS (
 SELECT 1 FROM unnest(ARRAY[${labCertificates.map(sqlLiteral).join(',')}]) WITH ORDINALITY AS required(cert_name,n)
 WHERE ((${level})='Restricted' AND required.n=1 OR (${level})='Hazardous')
 AND NOT EXISTS (SELECT 1 FROM ${S}.v_certification_current h JOIN ${S}.certification c USING(cert_id)
 WHERE h.person_id=${actor} AND c.cert_name=required.cert_name
 AND CURRENT_DATE BETWEEN h.issue_date AND h.expiry_date))`;
async function labsForUser(db,user) {
 const writable=member(user);
 const rows=await qs(db,`SELECT l.*,${labCertified('$1::bigint','l.safety_level')} AS has_cert,
  (t.local_time<time '07:00' OR t.local_time>=time '17:00') AS student_outside_hours,
  (t.local_time<time '06:00' OR t.local_time>=time '22:00') AS faculty_outside_hours,
  EXISTS (SELECT 1 FROM ${S}.chemical c WHERE c.lab_id=l.lab_id::bigint AND c.hazard_level='Extreme') AS contains_extreme,
  o.log_id::text AS open_log_id,${ts('o.entry_time')} AS open_entry_time
  FROM (${labSelect}) l CROSS JOIN (SELECT (clock_timestamp() AT TIME ZONE 'Asia/Ho_Chi_Minh')::time AS local_time) t
  LEFT JOIN LATERAL (
    SELECT a.log_id,a.entry_time FROM ${S}.access_log a
    WHERE a.person_id=$1::bigint AND a.lab_id=l.lab_id::bigint AND a.exit_time IS NULL
    ORDER BY a.entry_time DESC,a.log_id DESC LIMIT 1
  ) o ON true
  ORDER BY l.lab_id::bigint`,[person(user)]);
 return rows.map(({has_cert,student_outside_hours,faculty_outside_hours,contains_extreme,...room})=>{
  const needsApproval=user.role==='student'&&student_outside_hours;
  const reason=!writable ? readOnly : !has_cert ? (room.safety_level==='Hazardous'
   ? 'Phòng nguy hiểm cần đủ chứng nhận cơ bản, xử lý dung môi dễ cháy và xử lý axit oxy hóa mạnh còn hiệu lực.'
   : 'Phòng hạn chế cần chứng nhận An toàn phòng thí nghiệm cơ bản còn hiệu lực.') :
   needsApproval ? 'Sinh viên cần giảng viên hoặc kỹ thuật viên phê duyệt ngoài khung 07:00–17:00.' : null;
  const levels=writable&&admin(user) ? labLevels.filter(level=>level!==room.safety_level&&(!contains_extreme||level==='Hazardous')) : [];
  return {...room,has_cert,can_enter:!reason,entry_block_reason:reason,
   requires_out_of_hours_reason:user.role==='faculty'&&faculty_outside_hours,
   can_change_safety:levels.length>0,allowed_safety_levels:levels,
   safety_block_reason:writable&&admin(user)&&contains_extreme?'Phòng đang chứa hóa chất mức Cực cao nên phải giữ mức an toàn Nguy hiểm.':null};
 });
}
const equipColumns = `e.equipment_id::text,e.lab_id::text,e.equipment_name,e.serial_number,e.purchase_date::text,e.current_status,l.lab_name,l.safety_level`;
const grantColumns = `g.grant_id::text,g.grant_title,g.principal_investigator_id::text,p.full_name AS principal_investigator,
  g.start_date::text,g.end_date::text,g.status,
  CASE WHEN ${ownOrAdmin} THEN g.total_budget::text END AS total_budget,
  CASE WHEN ${ownOrAdmin} THEN g.remaining_budget::text END AS remaining_budget,
  coalesce(${ownOrAdmin} AND g.status='Active',false) AS can_edit,
  (SELECT count(*)::integer FROM ${S}.research_point rp WHERE rp.grant_id=g.grant_id) AS point_count`;
const pointColumns = `r.rearch_point_id::text,r.grant_id::text,r.point_name,r.description,r.start_date::text,r.end_date::text,r.status`;
const borrowsColumns = `b.borrow_id::text,b.equipment_id::text,e.equipment_name,e.lab_id::text,l.lab_name,
  b.borrow_date::text,b.expected_return_date::text,b.actual_return_date::text,${borrowStatus} AS status,
  CASE WHEN b.actual_return_date IS NULL THEN greatest(CURRENT_DATE-b.expected_return_date,0) ELSE greatest(b.actual_return_date-b.expected_return_date,0) END AS days_overdue`;
const borrowsJoin = `FROM ${S}.v_borrow_current b JOIN ${S}.equipment e USING(equipment_id) JOIN ${S}.laboratory l ON l.lab_id=e.lab_id`;
const accessColumns = `a.log_id::text,a.lab_id::text,l.lab_name,${ts('a.entry_time')} AS entry_time,
  ${ts('a.exit_time')} AS exit_time,a.purpose,a.approved_by::text,p.full_name AS approver_name,
  CASE WHEN a.exit_time IS NULL THEN 'Open' ELSE 'Closed' END AS status`;
const accessJoin = `FROM ${S}.access_log a JOIN ${S}.laboratory l USING(lab_id) LEFT JOIN ${S}.person p ON p.person_id=a.approved_by`;
const maintenanceJoin = `FROM ${S}.maintenance_log m JOIN ${S}.equipment e USING(equipment_id) JOIN ${S}.laboratory l ON l.lab_id=e.lab_id`;

async function dashboard(db, user) {
  const actor = person(user);
  const stats = await first(db,`SELECT
    (SELECT count(*)::integer FROM ${S}.equipment) AS equipment_total,
    (SELECT count(*)::integer FROM ${S}.equipment WHERE current_status='Available') AS equipment_available,
    (SELECT count(*)::integer FROM ${S}.v_borrow_current WHERE actual_return_date IS NULL
      AND ($1::bigint IS NULL OR person_id=$1::bigint)) AS open_borrows,
    (SELECT count(*)::integer FROM ${S}.research_grant WHERE status='Active') AS active_grants,
    (SELECT count(*)::integer FROM ${S}.chemical WHERE expiry_date BETWEEN CURRENT_DATE AND CURRENT_DATE+30 AND quantity_in_stock>0) AS chemicals_expiring,
    (SELECT count(*)::integer FROM ${S}.v_certification_current WHERE person_id=$1::bigint AND status='Valid'
      AND issue_date<=CURRENT_DATE AND expiry_date BETWEEN CURRENT_DATE AND CURRENT_DATE+30) AS certifications_expiring,
    (SELECT count(*)::integer FROM ${S}.laboratory) AS labs_total`,[actor]);
  const labs = actor ? await labsForUser(db, user) : await qs(db, labSelect);
  const activities = await qs(db,`SELECT type,title,subtitle,${ts('event_time')} AS date,status FROM (
    SELECT 'borrow' AS type,e.equipment_name AS title,'Mượn thiết bị' AS subtitle,b.borrow_date::timestamp AS event_time,${borrowStatus} AS status
    FROM ${S}.v_borrow_current b JOIN ${S}.equipment e USING(equipment_id)
    WHERE ($1::bigint IS NULL OR b.person_id=$1::bigint)
    UNION ALL
    SELECT 'access',l.lab_name,'Ra vào phòng',a.entry_time,CASE WHEN a.exit_time IS NULL THEN 'Open' ELSE 'Closed' END
    FROM ${S}.access_log a JOIN ${S}.laboratory l USING(lab_id)
    WHERE ($1::bigint IS NULL OR a.person_id=$1::bigint)
    UNION ALL
    SELECT 'maintenance',e.equipment_name,'Bảo trì thiết bị',m.start_date::timestamp,CASE WHEN m.end_date IS NULL THEN 'Open' ELSE 'Closed' END
    FROM ${S}.maintenance_log m JOIN ${S}.equipment e USING(equipment_id)
    WHERE ($1::bigint IS NULL OR m.technician_id=$1::bigint)
    UNION ALL
    SELECT 'chemical',c.chemical_name,CASE WHEN m.movement_type='Receipt' THEN 'Nhập kho' ELSE 'Xuất kho' END,
      m.occurred_at AT TIME ZONE 'Asia/Ho_Chi_Minh',m.movement_type
    FROM ${S}.v_chemical_movement m JOIN ${S}.chemical c USING(chemical_id)
    WHERE m.person_id=$1::bigint
  ) AS recent ORDER BY event_time DESC,type,title LIMIT 6`,[actor]);
  const borrow_chart = await qs(db,`WITH periods AS (
    SELECT generate_series(date_trunc('quarter',CURRENT_DATE::timestamp)-interval '21 months',
      date_trunc('quarter',CURRENT_DATE::timestamp), interval '3 months') AS start_at
  )
  SELECT 'Q'||extract(quarter FROM p.start_at)::integer||'/'||to_char(p.start_at,'YY') AS label,
    count(b.borrow_id)::integer AS total,
    (count(b.borrow_id) FILTER(WHERE b.actual_return_date IS NOT NULL))::integer AS returned
  FROM periods p LEFT JOIN ${S}.v_borrow_current b
    ON b.borrow_date>=p.start_at AND b.borrow_date<p.start_at+interval '3 months'
  GROUP BY p.start_at ORDER BY p.start_at`);
  return {stats,labs,activities,borrow_chart};
}

async function equipment(db, p, user) {
  const w=where([], [person(user)]);
  w.search(['e.equipment_name','e.serial_number','l.lab_name'],p.get('q'));
  w.add(s=>`e.lab_id=${s}::bigint`,optId(p,'lab_id'));
  w.add(s=>`e.current_status=${s}`,pick(p.get('status') || p.get('current_status'),['Available','In Use','Under Maintenance','Retired'],'trạng thái'));
  return page(db,p,`SELECT ${equipColumns},${labCertified('$1::bigint','l.safety_level')} AS has_lab_cert FROM ${S}.equipment e JOIN ${S}.laboratory l USING(lab_id)${w.sql}`,w.values,'equipment_name,equipment_id::bigint',['equipment_name','serial_number','purchase_date','current_status','lab_name']);
}
async function equipmentDetail(db, asset, user) {
  const record=await first(db,`SELECT ${equipColumns}, CASE WHEN $2::boolean THEN e.purchase_cost::text END AS purchase_cost,
    ${labCertified('$3::bigint','l.safety_level')} AS has_lab_cert
    FROM ${S}.equipment e JOIN ${S}.laboratory l USING(lab_id) WHERE e.equipment_id=$1::bigint`,[asset,technician(user),person(user)]);
  if (!record) missing('Không tìm thấy thiết bị.');
  const borrows=await qs(db,`SELECT ${borrowsColumns} ${borrowsJoin} WHERE b.equipment_id=$1::bigint AND b.person_id=$2::bigint
    ORDER BY b.borrow_date DESC,b.borrow_id DESC LIMIT 25`,[asset,person(user)]);
  const maintenance=await qs(db,`SELECT m.maintenance_id::text,m.start_date::text,m.end_date::text,m.description,
    CASE WHEN $2::boolean THEN m.cost::text END AS cost
    FROM ${S}.maintenance_log m WHERE m.equipment_id=$1::bigint ORDER BY m.start_date DESC,m.maintenance_id DESC LIMIT 25`,
  [asset,technician(user)]);
  const {open_count,has_open_loan}=await first(db,`SELECT
    (SELECT count(*)::int FROM ${S}.v_borrow_current b WHERE b.person_id=$1::bigint AND b.actual_return_date IS NULL) AS open_count,
    EXISTS (SELECT 1 FROM ${S}.v_borrow_current b WHERE b.equipment_id=$2::bigint AND b.actual_return_date IS NULL) AS has_open_loan`,[person(user),asset]);
  const certReason=!record.has_lab_cert ? (record.safety_level==='Hazardous'
    ? 'Thiết bị thuộc phòng nguy hiểm — cần đủ chứng nhận cơ bản, xử lý dung môi dễ cháy và xử lý axit oxy hóa mạnh còn hiệu lực để mượn.'
    : 'Thiết bị thuộc phòng hạn chế — cần chứng nhận An toàn phòng thí nghiệm cơ bản còn hiệu lực để mượn.') : null;
  const reason=!member(user) ? readOnly : record.current_status!=='Available'||has_open_loan ? 'Thiết bị này hiện không khả dụng để mượn.' :
    certReason ? certReason :
    open_count>=3 ? 'Bạn đang giữ đủ 3 thiết bị chưa trả. Hãy trả một thiết bị trước khi mượn thêm.' : null;
  return {...record,borrows,maintenance,can_borrow:!reason,borrow_block_reason:reason,
    can_start_maintenance:member(user)&&technician(user)&&record.current_status==='Available'&&!has_open_loan};
}
async function grants(db,p,user) {
  const w=where([], [person(user),admin(user)]);
  w.search(['g.grant_title','p.full_name'],p.get('q'));
  w.add(s=>`g.status=${s}`,pick(p.get('status'),['Active','Completed','Suspended'],'trạng thái'));
  w.add(s=>`g.principal_investigator_id=${s}::bigint`,optId(p,'principal_investigator_id'));
  const {from,to}=dateRange(p);
  w.add(s=>`g.end_date>=${s}::date`,from);
  w.add(s=>`g.start_date<${s}::date`,to);
  const result=await page(db,p,`SELECT ${grantColumns} FROM ${S}.research_grant g JOIN ${S}.person p ON p.person_id=g.principal_investigator_id${w.sql}`,
    w.values,'start_date DESC,grant_id::bigint',['grant_title','principal_investigator','start_date','end_date','status']);
  return {...result,rows:result.rows.map(row=>({...row,can_edit:member(user)&&row.can_edit,can_update_budget:member(user)&&admin(user)}))};
}
async function grantDetail(db,grant,user) {
  const args=[person(user),admin(user),grant];
  const record=await first(db,`SELECT ${grantColumns} FROM ${S}.research_grant g JOIN ${S}.person p ON p.person_id=g.principal_investigator_id
    WHERE g.grant_id=$3::bigint`,args);
  if (!record) missing('Không tìm thấy đề tài.');
  const labs=await qs(db,`SELECT l.lab_id::text,l.lab_name,l.building,l.room_number,l.safety_level
    FROM ${S}.grant_laboratory gl JOIN ${S}.laboratory l USING(lab_id) WHERE gl.grant_id=$1::bigint ORDER BY l.lab_id`,[grant]);
  const points=await qs(db,`SELECT ${pointColumns},
    coalesce((SELECT json_agg(q ORDER BY q.equipment_name) FROM (
      SELECT e.equipment_id::text,e.equipment_name,e.serial_number,e.current_status,e.lab_id::text
      FROM ${S}.allocated_equip a JOIN ${S}.equipment e USING(equipment_id) WHERE a.rearch_point_id=r.rearch_point_id) q),'[]'::json) AS equipment,
    coalesce((SELECT json_agg(q ORDER BY q.chemical_name) FROM (
      SELECT c.chemical_id::text,c.chemical_name,c.hazard_level,c.lab_id::text,c.unit
      FROM ${S}.allocated_chem a JOIN ${S}.chemical c USING(chemical_id) WHERE a.rearch_point_id=r.rearch_point_id) q),'[]'::json) AS chemicals
    FROM ${S}.research_point r WHERE r.grant_id=$1::bigint ORDER BY r.start_date,r.rearch_point_id`,[grant]);
  return {...record,labs,points,can_edit:member(user)&&record.can_edit,can_update_budget:member(user)&&admin(user)};
}
async function chemicals(db,p,user) {
  const w=where([], [person(user),member(user),member(user)&&admin(user)]);
  w.search(['c.chemical_name','c.cas_number','l.lab_name'],p.get('q'));
  w.add(s=>`c.lab_id=${s}::bigint`,optId(p,'lab_id'));
  w.add(s=>`c.hazard_level=${s}`,pick(p.get('hazard_level'),['None','Low','Medium','High','Extreme'],'mức nguy hiểm'));
  flagWhere(w,p.get('expiry') || p.get('status'),{expired:'c.expiry_date<CURRENT_DATE',expiring:'c.expiry_date BETWEEN CURRENT_DATE AND CURRENT_DATE+30 AND c.quantity_in_stock>0',valid:'c.expiry_date>=CURRENT_DATE'});
  const result=await page(db,p,`SELECT c.chemical_id::text,c.lab_id::text,c.chemical_name,c.cas_number,c.quantity_in_stock::text,
    c.unit,c.expiry_date::text,c.hazard_level,c.storage_condition,l.lab_name,
    (c.expiry_date-CURRENT_DATE) AS days_to_expiry,
    CASE WHEN c.expiry_date<CURRENT_DATE THEN 'Expired' WHEN c.expiry_date<=CURRENT_DATE+30 THEN 'Expiring' ELSE 'Valid' END AS status,
    CASE
      WHEN NOT $2::boolean THEN 'read_only'
      WHEN c.expiry_date<CURRENT_DATE THEN 'expired'
      WHEN c.hazard_level IN ('High','Extreme') AND (
        NOT EXISTS (SELECT 1 FROM ${S}.chemical_certification req WHERE req.chemical_id=c.chemical_id)
        OR EXISTS (SELECT 1 FROM ${S}.chemical_certification req WHERE req.chemical_id=c.chemical_id AND NOT EXISTS (
          SELECT 1 FROM ${S}.v_certification_current h WHERE h.person_id=$1::bigint AND h.cert_id=req.cert_id
            AND h.status='Valid' AND h.issue_date<=CURRENT_DATE AND h.expiry_date>=CURRENT_DATE))) THEN 'certification'
      WHEN c.quantity_in_stock<=0 THEN 'stock'
      WHEN NOT EXISTS (SELECT 1 ${issuePointJoins} WHERE a.chemical_id=c.chemical_id AND c.lab_id=gl.lab_id AND g.status='Active') THEN 'allocation'
    END AS issue_block,
    CASE WHEN $3::boolean AND EXISTS (SELECT 1 FROM ${S}.allocated_chem a WHERE a.chemical_id=c.chemical_id) THEN 'allocated' END AS relocation_block,
    CASE WHEN $3::boolean AND NOT EXISTS (SELECT 1 FROM ${S}.allocated_chem a WHERE a.chemical_id=c.chemical_id) THEN ARRAY(
      SELECT dest.lab_id::text FROM ${S}.laboratory dest WHERE dest.lab_id<>c.lab_id
        AND (c.hazard_level<>'Extreme' OR dest.safety_level='Hazardous') ORDER BY dest.lab_id) ELSE ARRAY[]::text[] END AS allowed_relocation_lab_ids
    FROM ${S}.chemical c JOIN ${S}.laboratory l USING(lab_id)${w.sql}`,w.values,'chemical_name,chemical_id::bigint',['chemical_name','lab_name','expiry_date','days_to_expiry','status']);
  return {...result,rows:result.rows.map(({issue_block,relocation_block,...row})=>({...row,
    can_issue:!issue_block,issue_block_reason:issueReasons[issue_block]??null,
    can_receive:member(user)&&technician(user),can_relocate:row.allowed_relocation_lab_ids.length>0,
    relocation_block_reason:relocation_block ? 'Hóa chất đã gắn với hạng mục nên không thể đổi phòng.' :
      member(user)&&admin(user)&&!row.allowed_relocation_lab_ids.length ? 'Không có phòng khác đáp ứng điều kiện lưu trữ của hóa chất này.' : null,
  }))};
}
const issuePointJoins=`FROM ${S}.allocated_chem a JOIN ${S}.research_point r USING(rearch_point_id)
  JOIN ${S}.research_grant g USING(grant_id) JOIN ${S}.grant_laboratory gl USING(grant_id)`;
const issueReasons={read_only:readOnly,expired:'Hóa chất đã hết hạn sử dụng.',
  certification:'Bạn không có quyền xuất kho hóa chất này vì chưa đủ chứng nhận phù hợp còn hiệu lực.',
  stock:'Hóa chất này hiện đã hết tồn kho.',allocation:'Hóa chất chưa được phân bổ vào hạng mục của đề tài đang hoạt động.'};
async function chemicalPoints(db,chemical) {
  return qs(db,`SELECT ${pointColumns},g.grant_title ${issuePointJoins}
    JOIN ${S}.chemical c ON c.chemical_id=a.chemical_id AND c.lab_id=gl.lab_id
    WHERE a.chemical_id=$1::bigint AND g.status='Active' ORDER BY g.grant_title,r.point_name`,[chemical]);
}
async function myBorrows(db,p,actor) {
  const w=where(['b.person_id=$1::bigint'],[actor]);
  w.search(['e.equipment_name','e.serial_number','l.lab_name'],p.get('q'));
  flagWhere(w,p.get('status'),{open:'b.actual_return_date IS NULL',closed:'b.actual_return_date IS NOT NULL',
    overdue:"b.actual_return_date IS NULL AND b.expected_return_date<CURRENT_DATE",borrowed:'b.actual_return_date IS NULL',
    returned:'b.actual_return_date IS NOT NULL'});
  w.add(s=>`e.lab_id=${s}::bigint`,optId(p,'lab_id'));
  dateWhere(w,'b.borrow_date',p);
  const returned=p.get('actual_return_date');
  if (returned==='null' || returned==='not_null') w.add(`b.actual_return_date IS ${returned==='not_null'?'NOT ':''}NULL`,true);
  else if (returned) w.add(s=>`b.actual_return_date=${s}::date`,day(returned,'ngày trả thực tế'));
  return page(db,p,`SELECT ${borrowsColumns} ${borrowsJoin}${w.sql}`,w.values,'borrow_date DESC,borrow_id::bigint DESC',['equipment_name','lab_name','borrow_date','expected_return_date','actual_return_date','status','days_overdue']);
}
async function myAccess(db,p,actor) {
  const w=where(['a.person_id=$1::bigint'],[actor]);
  w.search(['l.lab_name','a.purpose'],p.get('q'));
  w.add(s=>`a.lab_id=${s}::bigint`,optId(p,'lab_id'));
  flagWhere(w,p.get('status'),{open:'a.exit_time IS NULL',closed:'a.exit_time IS NOT NULL'});
  dateWhere(w,'a.entry_time',p);
  return page(db,p,`SELECT ${accessColumns} ${accessJoin}${w.sql}`,w.values,'entry_time DESC,log_id::bigint DESC',['lab_name','entry_time','exit_time','status']);
}
async function myCerts(db,p,actor) {
  const w=where(['h.person_id=$1::bigint'],[actor]);
  w.search(['c.cert_name','c.issuing_authority'],p.get('q'));
  flagWhere(w,p.get('status'),{valid:`(${certStatus})='Valid'`,
    expired:`(${certStatus})='Expired'`,expiring:`(${certStatus})='Valid' AND h.expiry_date<=CURRENT_DATE+30`});
  dateWhere(w,'h.expiry_date',p);
  return page(db,p,`SELECT h.cert_id::text,c.cert_name,c.issuing_authority,c.validity_period_months,
    h.issue_date::text,h.expiry_date::text,h.expiry_date-CURRENT_DATE AS days_to_expiry,${certStatus} AS status,${certStatus} AS effective_status
    FROM ${S}.v_certification_current h JOIN ${S}.certification c USING(cert_id)${w.sql}`,w.values,'expiry_date,cert_id::bigint',['cert_name','issue_date','expiry_date','days_to_expiry','status']);
}
async function maintenance(db,p,user) {
  const w=where([], [person(user),technician(user)]);
  w.search(['e.equipment_name','e.serial_number','m.description'],p.get('q'));
  w.add(s=>`e.lab_id=${s}::bigint`,optId(p,'lab_id'));
  w.add(s=>`m.equipment_id=${s}::bigint`,optId(p,'equipment_id'));
  flagWhere(w,p.get('status'),{open:'m.end_date IS NULL',closed:'m.end_date IS NOT NULL'});
  dateWhere(w,'m.start_date',p);
  return page(db,p,`SELECT m.maintenance_id::text,m.equipment_id::text,e.equipment_name,e.lab_id::text,l.lab_name,
    m.start_date::text,m.end_date::text,m.description,
    CASE WHEN $2::boolean THEN m.cost::text END AS cost,
    (m.technician_id=$1::bigint AND $2::boolean AND m.end_date IS NULL) AS can_complete,
    CASE WHEN m.end_date IS NULL THEN 'Open' ELSE 'Closed' END AS status
    ${maintenanceJoin}${w.sql}`,w.values,'start_date DESC,maintenance_id::bigint DESC',['equipment_name','lab_name','start_date','end_date','status']);
}
async function students(db,p,user) {
  requireStaff(user);
  const w=where(["p.status='Active'"]);
  w.search(['p.full_name','s.student_code'],p.get('q'));
  return qs(db,`SELECT p.person_id::text,p.full_name,s.student_code,${labCertified('p.person_id',sqlLiteral('Restricted'))} AS has_valid_lab_certification,
    ${labCertified('p.person_id',sqlLiteral('Hazardous'))} AS has_hazardous_lab_certification
    FROM ${S}.student s JOIN ${S}.person p ON p.person_id=s.student_id${w.sql} ORDER BY p.full_name,p.person_id LIMIT 20`,w.values);
}

const reportSpecs = [
  ['Q01','Nguồn lực theo đề tài','Tổng hợp hạng mục, thiết bị, hóa chất và ngân sách trong phạm vi quyền.',['grant_id']],
  ['Q02','Thiết bị tôi đang giữ','Tổng hợp các lượt chưa trả, bao gồm lượt quá hạn.',['lab_id']],
  ['Q03','Hóa chất gần hết hạn','Hóa chất còn tồn và sẽ hết hạn trong 30 ngày.',['lab_id']],
  ['Q04','Tình trạng chứng nhận của tôi','Đối chiếu từng loại chứng nhận với hồ sơ của phiên. ',[]],
  ['Q05','Lượt sử dụng phòng','Tổng hợp lượt vào và thời lượng ở phòng; mặc định 7 ngày gần nhất.',['lab_id','from','to']],
  ['Q06','Thiết bị theo trạng thái','Thống kê số lượng khả dụng, đang mượn, bảo trì và ngừng sử dụng theo phòng.',['lab_id']],
  ['Q07','Chi phí bảo trì thiết bị','Xếp hạng thiết bị theo chi phí bảo trì trong từng phòng.',['lab_id','from','to'],'ops'],
  ['Q08','Điều kiện sử dụng hóa chất nguy hiểm','Các hóa chất chưa hết hạn mà phiên có đủ chứng nhận bắt buộc.',['lab_id']],
  ['Q09','Đối chiếu sổ kho','So sánh tổng nhập trừ xuất với tồn hiện tại theo hóa chất.',['lab_id'],'ops'],
  ['Q10','Độ phủ phân bổ thiết bị','Đề tài Active có đủ phân bổ thiết bị cho mọi hạng mục Active.',['grant_id']],
  ['Q11','Phê duyệt ra vào ngoài giờ','Lượt của phiên hoặc do phiên phê duyệt; không hiển thị danh tính khách.',['lab_id','from','to']],
  ['Q12','Xếp hạng sử dụng thiết bị','Thống kê lượt mượn, lượt trễ hạn và tỷ lệ trễ theo thiết bị.',['lab_id','from','to']],
].map(([code,title,description,filters,scope])=>({code,title,description,filters,scope}));
const reportVisible = (spec,user) => !spec.scope || technician(user) || admin(user) || hasPermission(user,'auditor') || user?.role==='auditor';
const reportMeta = ({scope,...rest}) => rest;
const labels = {
  grant_title:'Đề tài',principal_investigator:'Chủ nhiệm',point_count:'Hạng mục',equipment_count:'Thiết bị',
  chemical_count:'Hóa chất',total_budget:'Tổng ngân sách',remaining_budget:'Còn lại',lab_name:'Phòng',
  open_loans:'Đang mượn',overdue_loans:'Quá hạn',chemical_name:'Hóa chất',quantity_in_stock:'Tồn kho',
  unit:'Đơn vị',days_to_expiry:'Số ngày còn lại',expiry_date:'Hạn dùng',cert_name:'Chứng nhận',status:'Trạng thái',
  issuing_authority:'Đơn vị cấp',visits:'Lượt vào',completed_person_hours:'Giờ sử dụng',total_equipment:'Tổng thiết bị',
  available:'Khả dụng',in_use:'Đang sử dụng',under_maintenance:'Bảo trì',retired:'Ngừng sử dụng',
  equipment_name:'Thiết bị',maintenance_cost:'Chi phí bảo trì',cost_rank:'Xếp hạng',hazard_level:'Mức nguy hiểm',
  total_received:'Tổng nhập',total_issued:'Tổng xuất',ledger_balance:'Số dư sổ kho',reconciled:'Khớp tồn',
  entry_time:'Giờ vào',exit_time:'Giờ ra',loan_count:'Lượt mượn',late_count:'Lượt trễ',late_pct:'Tỷ lệ trễ (%)',
  usage_rank:'Xếp hạng',days_overdue:'Số ngày trễ'
};
async function report(db,p,user,code) {
  const spec=reportSpecs.find(s=>s.code===code);
  if (!spec) missing('Không tìm thấy báo cáo.');
  if (!reportVisible(spec,user)) fail(403,'FORBIDDEN','Tài khoản không có quyền xem báo cáo này.');
  const actor=person(user), lab=optId(p,'lab_id'), grant=optId(p,'grant_id');
  let w=where(), sql, order, keys;
  const labFilter=(col)=>w.add(s=>`${col}=${s}::bigint`,lab);
  const grantFilter=(col)=>w.add(s=>`${col}=${s}::bigint`,grant);
  switch (code) {
    case 'Q01':
      w=where(["g.status='Active'"],[actor,admin(user)]);
      grantFilter('g.grant_id');
      sql=`SELECT g.grant_title,p.full_name AS principal_investigator,
        (SELECT count(*)::integer FROM ${S}.research_point r WHERE r.grant_id=g.grant_id) AS point_count,
        (SELECT count(DISTINCT a.equipment_id)::integer FROM ${S}.research_point r JOIN ${S}.allocated_equip a USING(rearch_point_id) WHERE r.grant_id=g.grant_id) AS equipment_count,
        (SELECT count(DISTINCT a.chemical_id)::integer FROM ${S}.research_point r JOIN ${S}.allocated_chem a USING(rearch_point_id) WHERE r.grant_id=g.grant_id) AS chemical_count,
        CASE WHEN ${ownOrAdmin} THEN g.total_budget::text END AS total_budget,
        CASE WHEN ${ownOrAdmin} THEN g.remaining_budget::text END AS remaining_budget
        FROM ${S}.research_grant g JOIN ${S}.person p ON p.person_id=g.principal_investigator_id${w.sql}`;
      order='grant_title'; keys=['grant_title','principal_investigator','point_count','equipment_count','chemical_count','total_budget','remaining_budget']; break;
    case 'Q02':
      w=where(['b.person_id=$1::bigint','b.actual_return_date IS NULL'],[actor]);
      labFilter('e.lab_id');
      sql=`SELECT l.lab_name,count(b.borrow_id)::integer AS open_loans,
        (count(b.borrow_id) FILTER(WHERE b.expected_return_date<CURRENT_DATE))::integer AS overdue_loans
        ${borrowsJoin}${w.sql} GROUP BY l.lab_id,l.lab_name`;
      order='lab_name'; keys=['lab_name','open_loans','overdue_loans']; break;
    case 'Q03':
      w=where(['c.expiry_date BETWEEN CURRENT_DATE AND CURRENT_DATE+30','c.quantity_in_stock>0']);
      labFilter('c.lab_id');
      sql=`SELECT c.chemical_name,l.lab_name,c.quantity_in_stock::text,c.unit,c.expiry_date::text,
        c.expiry_date-CURRENT_DATE AS days_to_expiry FROM ${S}.chemical c JOIN ${S}.laboratory l USING(lab_id)${w.sql}`;
      order='expiry_date,chemical_name'; keys=['chemical_name','lab_name','quantity_in_stock','unit','expiry_date','days_to_expiry']; break;
    case 'Q04':
      w=where([],[actor]);
      sql=`SELECT c.cert_name,c.issuing_authority,h.expiry_date::text,CASE WHEN h.cert_id IS NULL THEN 'Missing' ELSE ${certStatus} END AS status
        FROM ${S}.certification c LEFT JOIN ${S}.v_certification_current h ON h.cert_id=c.cert_id AND h.person_id=$1::bigint`;
      order='cert_name'; keys=['cert_name','issuing_authority','expiry_date','status']; break;
    case 'Q05': {
      const {from,to}=dateRange(p);
      w=where([],[from,to]);
      labFilter('l.lab_id');
      sql=`SELECT l.lab_name,count(a.log_id)::integer AS visits,
        round(coalesce(sum(extract(epoch FROM(a.exit_time-a.entry_time))/3600),0)::numeric,2)::text AS completed_person_hours
        FROM ${S}.laboratory l LEFT JOIN ${S}.access_log a ON a.lab_id=l.lab_id
        AND a.entry_time>=coalesce($1::date,CURRENT_DATE-7) AND a.entry_time<coalesce($2::date,CURRENT_DATE+1)${w.sql}
        GROUP BY l.lab_id,l.lab_name`;
      order='lab_name'; keys=['lab_name','visits','completed_person_hours']; break;
    }
    case 'Q06':
      labFilter('l.lab_id');
      sql=`SELECT l.lab_name,count(e.equipment_id)::integer AS total_equipment,
        (count(e.equipment_id) FILTER(WHERE e.current_status='Available'))::integer AS available,
        (count(e.equipment_id) FILTER(WHERE e.current_status='In Use'))::integer AS in_use,
        (count(e.equipment_id) FILTER(WHERE e.current_status='Under Maintenance'))::integer AS under_maintenance,
        (count(e.equipment_id) FILTER(WHERE e.current_status='Retired'))::integer AS retired
        FROM ${S}.laboratory l LEFT JOIN ${S}.equipment e USING(lab_id)${w.sql} GROUP BY l.lab_id,l.lab_name`;
      order='lab_name'; keys=['lab_name','total_equipment','available','in_use','under_maintenance','retired']; break;
    case 'Q07':
      labFilter('l.lab_id'); dateWhere(w,'m.start_date',p);
      sql=`WITH costs AS (SELECT l.lab_name,e.equipment_name,e.lab_id,sum(m.cost) AS cost_num
        ${maintenanceJoin}${w.sql} GROUP BY e.equipment_id,e.lab_id,l.lab_name)
        SELECT lab_name,equipment_name,cost_num::text AS maintenance_cost,
        dense_rank() OVER(PARTITION BY lab_id ORDER BY cost_num DESC)::integer AS cost_rank
        FROM costs WHERE cost_num>0`;
      order='lab_name,cost_rank,equipment_name'; keys=['lab_name','equipment_name','maintenance_cost','cost_rank']; break;
    case 'Q08':
      w=where(["c.hazard_level IN('High','Extreme')",'c.expiry_date>=CURRENT_DATE'],[actor]); labFilter('c.lab_id');
      sql=`SELECT c.chemical_name,l.lab_name,c.hazard_level,c.expiry_date::text
        FROM ${S}.chemical c JOIN ${S}.laboratory l USING(lab_id)${w.sql}
        AND EXISTS(SELECT 1 FROM ${S}.chemical_certification r WHERE r.chemical_id=c.chemical_id)
        AND NOT EXISTS(SELECT 1 FROM ${S}.chemical_certification r WHERE r.chemical_id=c.chemical_id AND NOT EXISTS(
          SELECT 1 FROM ${S}.v_certification_current h WHERE h.person_id=$1::bigint AND h.cert_id=r.cert_id
          AND h.status='Valid' AND CURRENT_DATE BETWEEN h.issue_date AND h.expiry_date))`;
      order='chemical_name,lab_name'; keys=['chemical_name','lab_name','hazard_level','expiry_date']; break;
    case 'Q09':
      labFilter('c.lab_id');
      sql=`WITH totals AS (SELECT c.chemical_name,l.lab_name,c.unit,c.quantity_in_stock,
        coalesce(sum(m.quantity) FILTER(WHERE m.movement_type='Receipt'),0) AS received,
        coalesce(sum(m.quantity) FILTER(WHERE m.movement_type='Issue'),0) AS issued
        FROM ${S}.chemical c JOIN ${S}.laboratory l USING(lab_id) LEFT JOIN ${S}.v_chemical_movement m USING(chemical_id)${w.sql}
        GROUP BY c.chemical_id,l.lab_name)
        SELECT chemical_name,lab_name,unit,quantity_in_stock::text,received::text AS total_received,
          issued::text AS total_issued,(received-issued)::text AS ledger_balance,
          received-issued=quantity_in_stock AS reconciled FROM totals`;
      order='chemical_name,lab_name'; keys=['chemical_name','lab_name','unit','quantity_in_stock','total_received','total_issued','ledger_balance','reconciled']; break;
    case 'Q10':
      w=where(["g.status='Active'"]); grantFilter('g.grant_id');
      sql=`SELECT g.grant_title,(SELECT count(*)::integer FROM ${S}.research_point r WHERE r.grant_id=g.grant_id AND r.status='Active') AS point_count
        FROM ${S}.research_grant g${w.sql}
        AND NOT EXISTS(SELECT 1 FROM ${S}.research_point r WHERE r.grant_id=g.grant_id AND r.status='Active' AND NOT EXISTS(
          SELECT 1 FROM ${S}.allocated_equip a WHERE a.rearch_point_id=r.rearch_point_id))`;
      order='grant_title'; keys=['grant_title','point_count']; break;
    case 'Q11':
      w=where(["(a.person_id=$1::bigint OR a.approved_by=$1::bigint)",
        `EXISTS(SELECT 1 FROM ${S}.student s WHERE s.student_id=a.person_id)`,
        "a.approved_by IS NOT NULL","(a.entry_time::time<time '07:00' OR a.entry_time::time>=time '17:00')"],[actor]);
      labFilter('a.lab_id'); dateWhere(w,'a.entry_time',p);
      sql=`SELECT l.lab_name,${ts('a.entry_time')} AS entry_time,${ts('a.exit_time')} AS exit_time
        FROM ${S}.access_log a JOIN ${S}.laboratory l USING(lab_id)${w.sql}`;
      order='entry_time DESC,lab_name'; keys=['lab_name','entry_time','exit_time']; break;
    case 'Q12':
      labFilter('e.lab_id'); dateWhere(w,'b.borrow_date',p);
      sql=`WITH usage AS (
        SELECT e.equipment_name,l.lab_name,count(b.borrow_id)::integer AS loan_count,
        (count(b.borrow_id) FILTER(WHERE (${borrowStatus})='Overdue'))::integer AS late_count
        ${borrowsJoin}${w.sql} GROUP BY e.equipment_id,l.lab_name
      ) SELECT equipment_name,lab_name,loan_count,late_count,
        round(100.0*late_count/nullif(loan_count,0),2)::text AS late_pct,
        rank() OVER(ORDER BY loan_count DESC)::integer AS usage_rank FROM usage`;
      order='usage_rank,equipment_name'; keys=['equipment_name','lab_name','loan_count','late_count','late_pct','usage_rank']; break;
  }
  return {...reportMeta(spec),columns:keys.map(key=>({key,label:labels[key]})),...await page(db,p,sql,w.values,order)};
}

async function borrowById(db,actor,borrow) {
  return first(db,`SELECT ${borrowsColumns},e.current_status
    ${borrowsJoin} WHERE b.person_id=$1::bigint AND b.borrow_id=$2::bigint`,[actor,borrow]);
}
async function accessById(db,log) {
  return first(db,`SELECT ${accessColumns},a.person_id::text ${accessJoin} WHERE a.log_id=$1::bigint`,[log]);
}
async function movementById(db,movement) {
  return first(db,`SELECT m.movement_id::text,m.chemical_id::text,m.rearch_point_id::text,c.chemical_name,c.unit,
    m.quantity::text,m.balance_after::text,m.balance_after::text AS quantity_in_stock,m.movement_type,m.reason,
    ${ts("m.occurred_at AT TIME ZONE 'Asia/Ho_Chi_Minh'")} AS occurred_at
    FROM ${S}.v_chemical_movement m JOIN ${S}.chemical c USING(chemical_id) WHERE m.movement_id=$1::bigint`,[movement]);
}
async function maintenanceById(db,maintenanceId,user) {
  return first(db,`SELECT m.maintenance_id::text,m.equipment_id::text,e.equipment_name,e.lab_id::text,l.lab_name,
    m.start_date::text,m.end_date::text,m.description,m.cost::text,
    (m.technician_id=$2::bigint AND m.end_date IS NULL) AS can_complete,
    CASE WHEN m.end_date IS NULL THEN 'Open' ELSE 'Closed' END AS status,e.current_status
    ${maintenanceJoin} WHERE m.maintenance_id=$1::bigint AND m.technician_id=$2::bigint`,[maintenanceId,person(user)]);
}
const makeAdmin = (u) => {
  if (!admin(u) || auditorOnly(u)) fail(403,'FORBIDDEN','Chỉ quản trị nghiên cứu được cập nhật mục này.');
};

async function writeApi(db,path,body,user) {
  const actor=person(user);
  if (!actor) fail(401,'UNAUTHENTICATED','Vui lòng đăng nhập.');
  if (auditorOnly(user)) fail(403,'FORBIDDEN','Tài khoản này chỉ có quyền đọc.');
  let match;
  if (path==='/borrows') {
    fields(body,['equipment_id','expected_return_date']);
    const equipmentId=id(body.equipment_id,'thiết bị'), due=day(body.expected_return_date,'ngày trả dự kiến');
    const current=await first(db,'SELECT CURRENT_DATE::text AS today');
    if (due<current.today) fail(400,'INVALID_DUE_DATE','Ngày trả dự kiến không được trước ngày hôm nay.');
    const row=await first(db,`SELECT ${S}.checkout_equipment($1::bigint,$2::bigint,$3::date)::text AS id`,[actor,equipmentId,due]);
    return borrowById(db,actor,row.id);
  }
  if ((match=/^\/borrows\/([^/]+)\/return$/.exec(path))) {
    fields(body,[]);
    const borrow=id(match[1],'lượt mượn');
    await qs(db,`SELECT ${S}.return_equipment($1::bigint,$2::bigint)`,[actor,borrow]);
    return borrowById(db,actor,borrow);
  }
  if (path==='/access-logs' || path==='/access-logs/approved') {
    const approved=path.endsWith('/approved');
    if (approved) requireStaff(user);
    fields(body,approved ? ['visitor_id','lab_id','purpose'] : ['lab_id','purpose','out_of_hours_reason']);
    const visitor=approved ? id(body.visitor_id,'sinh viên') : actor;
    const lab=id(body.lab_id,'phòng');
    let purpose=str(body.purpose,'mục đích',500);
    if(!approved && user.role==='faculty'){
      const {outside}=await first(db,`SELECT (t<time '06:00' OR t>=time '22:00') AS outside
        FROM (SELECT (clock_timestamp() AT TIME ZONE 'Asia/Ho_Chi_Minh')::time AS t) AS local_clock`);
      if(outside){
        const reason=str(body.out_of_hours_reason,'lý do ngoài giờ',400);
        purpose=str(purpose+'; Lý do ngoài giờ: '+reason,'mục đích và lý do ngoài giờ',500);
      }else if(body.out_of_hours_reason!=null && body.out_of_hours_reason!==''){
        purpose=str(purpose+'; Lý do ngoài giờ: '+str(body.out_of_hours_reason,'lý do ngoài giờ',400),'mục đích và lý do ngoài giờ',500);
      }
    }else if(body.out_of_hours_reason!=null){
      invalid('lý do ngoài giờ');
    }
    if (approved) {
      const target=await first(db,`SELECT s.student_id FROM ${S}.student s JOIN ${S}.person p ON p.person_id=s.student_id
        WHERE s.student_id=$1::bigint AND p.status='Active'`,[visitor]);
      if (!target) missing('Không tìm thấy sinh viên đang hoạt động.');
    }
    const previousOpen=await qs(db,`SELECT a.log_id::text,l.lab_name
      FROM ${S}.access_log a JOIN ${S}.laboratory l USING(lab_id)
      WHERE a.person_id=$1::bigint AND a.exit_time IS NULL
        AND a.entry_time<(clock_timestamp() AT TIME ZONE 'Asia/Ho_Chi_Minh')
      ORDER BY a.entry_time,a.log_id`,[visitor]);
    for (const prev of previousOpen) {
      await qs(db,`SELECT ${S}.close_access($1::bigint,$2::bigint)`,[visitor,prev.log_id]);
    }
    const row=await first(db,`SELECT ${S}.record_access($1::bigint,$2::bigint,$3::text,$4::bigint)::text AS id`,
      [visitor,lab,purpose,approved ? actor : null]);
    const record=await accessById(db,row.id);
    if (previousOpen.length) record.auto_closed_labs=previousOpen.map(x=>x.lab_name);
    return record;
  }
  if ((match=/^\/access-logs\/([^/]+)\/exit$/.exec(path))) {
    fields(body,[]);
    const log=id(match[1],'lượt vào');
    await qs(db,`SELECT ${S}.close_access($1::bigint,$2::bigint)`,[actor,log]);
    return accessById(db,log);
  }
  if (path==='/chemical-issues' || path==='/chemical-receipts') {
    const isReceipt=path==='/chemical-receipts';
    if (isReceipt) requireOperator(user);
    fields(body,isReceipt ? ['chemical_id','quantity','reason'] : ['chemical_id','rearch_point_id','quantity','reason']);
    const chemical=id(body.chemical_id,'hóa chất'), quantity=qty(body.quantity), reason=str(body.reason,'lý do',500);
    const row=isReceipt
      ? await first(db,`SELECT ${S}.receive_chemical($1::bigint,$2::bigint,$3::numeric,$4::text)::text AS id`,[chemical,actor,quantity,reason])
      : await first(db,`SELECT ${S}.issue_chemical($1::bigint,$2::bigint,$3::bigint,$4::numeric,$5::text)::text AS id`,
        [chemical,actor,id(body.rearch_point_id,'hạng mục'),quantity,reason]);
    return movementById(db,row.id);
  }
  if (path==='/maintenance') {
    requireOperator(user);
    fields(body,['equipment_id','description','cost']);
    const asset=id(body.equipment_id,'thiết bị'), description=str(body.description,'nội dung bảo trì',1000);
    const row=await first(db,`SELECT ${S}.start_maintenance($1::bigint,$2::bigint,$3::text,$4::numeric)::text AS id`,
      [actor,asset,description,cost(body.cost ?? '0')]);
    return maintenanceById(db,row.id,user);
  }
  if ((match=/^\/maintenance\/([^/]+)\/complete$/.exec(path))) {
    requireOperator(user);
    fields(body,['description','cost']);
    const maintenanceId=id(match[1],'nhật ký bảo trì'), old=await maintenanceById(db,maintenanceId,user);
    if (!old?.can_complete) fail(409,'MAINTENANCE_NOT_OPEN','Không còn nhật ký bảo trì đang mở của bạn.');
    const description=body.description==null ? old.description : str(body.description,'nội dung bảo trì',1000);
    const amount=body.cost==null ? old.cost : cost(body.cost);
    await qs(db,`SELECT ${S}.finish_maintenance($1::bigint,$2::bigint,$3::text,$4::numeric)`,[actor,maintenanceId,description,amount]);
    return maintenanceById(db,maintenanceId,user);
  }
  if ((match=/^\/grants\/([^/]+)\/points$/.exec(path))) {
    fields(body,['point_name','description','start_date','end_date','status']);
    const grant=id(match[1],'đề tài'), name=str(body.point_name,'tên hạng mục',200);
    if (body.description!=null && typeof body.description!=='string') invalid('mô tả');
    const description=body.description?.trim() ? str(body.description,'mô tả',1000) : null;
    const start=day(body.start_date,'ngày bắt đầu'),end=day(body.end_date,'ngày kết thúc');
    const status=body.status==null ? 'Planned' : pick(body.status,['Planned','Active','Completed','Suspended'],'trạng thái');
    if (!status || end<=start) invalid('khoảng ngày hoặc trạng thái hạng mục');
    const row=await first(db,`SELECT ${S}.web_add_point($1::bigint,$2::bigint,$3::text,$4::text,$5::date,$6::date,$7::text)::text AS id`,
      [actor,grant,name,description,start,end,status]);
    return first(db,`SELECT ${pointColumns} FROM ${S}.research_point r WHERE r.rearch_point_id=$1::bigint`,[row.id]);
  }
  if ((match=/^\/points\/([^/]+)\/(equipment|chemical)-allocations$/.exec(path))) {
    const kind=match[2], key=kind+'_id';
    fields(body,[key]);
    const point=id(match[1],'hạng mục'), asset=id(body[key],kind==='equipment'?'thiết bị':'hóa chất');
    await qs(db,`SELECT ${S}.web_allocate($1::bigint,$2::bigint,$3::bigint,$4::text)`,[actor,point,asset,kind]);
    return {rearch_point_id:point,[key]:asset};
  }
  if ((match=/^\/grants\/([^/]+)\/budget$/.exec(path))) {
    makeAdmin(user);
    fields(body,['remaining_budget']);
    const grant=id(match[1],'đề tài'), amount=decimal(body.remaining_budget,'ngân sách còn lại',{scale:2,digits:16});
    await qs(db,`SELECT ${S}.web_set_budget($1::bigint,$2::bigint,$3::numeric)`,[actor,grant,amount]);
    return first(db,`SELECT grant_id::text,remaining_budget::text,total_budget::text FROM ${S}.research_grant WHERE grant_id=$1::bigint`,[grant]);
  }
  if ((match=/^\/chemicals\/([^/]+)\/location$/.exec(path))) {
    makeAdmin(user);
    fields(body,['lab_id']);
    const chemical=id(match[1],'hóa chất'), lab=id(body.lab_id,'phòng');
    await qs(db,`SELECT ${S}.web_set_chemical_location($1::bigint,$2::bigint,$3::bigint)`,[actor,chemical,lab]);
    return {chemical_id:chemical,lab_id:lab};
  }
  if ((match=/^\/labs\/([^/]+)\/safety$/.exec(path))) {
    makeAdmin(user);
    fields(body,['safety_level']);
    const lab=id(match[1],'phòng'), safety=pick(body.safety_level,['Normal','Restricted','Hazardous'],'mức an toàn');
    if (!safety) invalid('mức an toàn');
    await qs(db,`SELECT ${S}.web_set_lab_safety($1::bigint,$2::bigint,$3::text)`,[actor,lab,safety]);
    return {lab_id:lab,safety_level:safety};
  }
  return undefined;
}

const businessErrors=[
  [/maximum three open loans/i,409,'BORROW_LIMIT_REACHED','Bạn đang giữ đủ 3 thiết bị chưa trả.'],
  [/equipment unavailable|cannot enter maintenance/i,409,'EQUIPMENT_UNAVAILABLE','Thiết bị không khả dụng cho thao tác này.'],
  [/BR04:/,403,'APPROVAL_REQUIRED','Cần giảng viên hoặc kỹ thuật viên phê duyệt hợp lệ.'],
  [/BR27:/,400,'OUT_OF_HOURS_REASON_REQUIRED','Giảng viên cần ghi lý do vào phòng trước 06:00 hoặc từ 22:00 trở đi.'],
  [/BR05:|BR06:/,403,'CERTIFICATION_REQUIRED','Thiếu chứng nhận phù hợp còn hiệu lực.'],
  [/BR17:/,409,'INSUFFICIENT_STOCK','Số lượng xuất vượt tồn kho khả dụng.'],
  [/BR18:/,409,'CHEMICAL_EXPIRED','Không thể xuất hóa chất đã hết hạn.'],
  [/remove chemical allocations before lab relocation/i,409,'CHEMICAL_ALREADY_ALLOCATED','Hóa chất đã gắn với hạng mục nên không thể đổi phòng. Hãy chọn hóa chất chưa phân bổ.'],
  [/BR11:/,409,'ASSET_LAB_NOT_ASSIGNED','Tài sản chưa được phân bổ hoặc phòng không phù hợp với đề tài.'],
  [/BR12:|WEB_GRANT_NOT_ACTIVE/,409,'GRANT_NOT_ACTIVE','Chỉ thao tác được khi đề tài đang hoạt động.'],
  [/BR20:/,409,'HAZARDOUS_STORAGE_REQUIRED','Hóa chất Extreme phải được lưu trong phòng Hazardous.'],
  [/BR25:|WEB_(?:GRANT|POINT|ASSET|LAB)_MISSING/,404,'NOT_FOUND','Không tìm thấy dữ liệu cần thao tác.'],
  [/BR03: active technician|BR19: active technician|BR23:|BR14: active borrower|WEB_GRANT_FORBIDDEN|WEB_ADMIN_ONLY/,403,'FORBIDDEN','Tài khoản không được phép thực hiện thao tác này.'],
  [/Loan not found or already returned/,409,'LOAN_NOT_OPEN','Không có lượt mượn chưa trả của bạn.'],
  [/Open access log not found/,409,'ACCESS_NOT_OPEN','Không có lượt vào đang mở của bạn.'],
  [/Open maintenance not found for technician/,409,'MAINTENANCE_NOT_OPEN','Không có lượt bảo trì đang mở của bạn.'],
  [/WEB_POINT_DATE_RANGE/,400,'INVALID_POINT_RANGE','Ngày hạng mục phải nằm trong thời gian của đề tài.'],
  [/WEB_BUDGET_AMOUNT/,400,'INVALID_BUDGET','Ngân sách phải không âm và tối đa hai chữ số thập phân.'],
];

export async function routeApi({method,path,params=new URLSearchParams(),body={},user,db}) {
  try {
    if (method==='POST') return await writeApi(db,path,body,user);
    if (method!=='GET') return undefined;
    if (path==='/dashboard') return await dashboard(db,user);
    if (!person(user)) fail(401,'UNAUTHENTICATED','Vui lòng đăng nhập.');
    switch (path) {
      case '/labs': return await labsForUser(db,user);
      case '/equipment': return await equipment(db,params,user);
      case '/grants': return await grants(db,params,user);
      case '/chemicals': return await chemicals(db,params,user);
      case '/me/borrows': return await myBorrows(db,params,person(user));
      case '/me/access': return await myAccess(db,params,person(user));
      case '/me/certifications': return await myCerts(db,params,person(user));
      case '/maintenance': return await maintenance(db,params,user);
      case '/students': return await students(db,params,user);
      case '/reports': return reportSpecs.filter(r=>reportVisible(r,user)).map(reportMeta);
    }
    let match;
    if ((match=/^\/equipment\/([^/]+)$/.exec(path))) return await equipmentDetail(db,id(match[1],'thiết bị'),user);
    if ((match=/^\/grants\/([^/]+)$/.exec(path))) return await grantDetail(db,id(match[1],'đề tài'),user);
    if ((match=/^\/chemicals\/([^/]+)\/points$/.exec(path))) return await chemicalPoints(db,id(match[1],'hóa chất'));
    if ((match=/^\/reports\/([^/]+)$/.exec(path))) return await report(db,params,user,match[1].toUpperCase());
    return undefined;
  } catch (error) {
    if (error?.code==='P0001') {
      const match=businessErrors.find(([pattern])=>pattern.test(error.message));
      if (match) fail(match[1],match[2],match[3]);
      fail(409,'BUSINESS_RULE','Thao tác chưa đáp ứng quy tắc nghiệp vụ.');
    }
    if (error?.code==='23505' && error?.constraint==='uq_open_equipment_loan')
      fail(409,'EQUIPMENT_UNAVAILABLE','Thiết bị đã có lượt mượn chưa trả.');
    if (error?.code==='23505' && error?.constraint==='uq_open_maintenance')
      fail(409,'MAINTENANCE_ALREADY_OPEN','Thiết bị đã có nhật ký bảo trì đang mở.');
    if (error?.code==='23514' && path.endsWith('/budget'))
      fail(409,'INVALID_BUDGET','Ngân sách còn lại không được vượt tổng ngân sách của đề tài.');
    throw error;
  }
}
