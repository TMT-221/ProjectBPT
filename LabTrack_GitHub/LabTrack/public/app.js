import { icon } from './icons.js';

const labels = {
  dashboard: ['Tổng quan', ''],
  equipment: ['Thiết bị', 'Tra cứu và mượn thiết bị nghiên cứu tại các phòng thí nghiệm.'],
  grants: ['Đề tài nghiên cứu', 'Theo dõi đề tài, hạng mục và các tài sản được phân bổ.'],
  chemicals: ['Kho hóa chất', 'Kiểm tra tồn kho, hạn dùng và ghi nhận nhập xuất hóa chất.'],
  borrows: ['Mượn trả của tôi', 'Quản lý thiết bị đang mượn và xem lại lịch sử giao dịch.'],
  access: ['Ra vào phòng', 'Ghi nhận lượt vào, ra và phê duyệt truy cập phòng thí nghiệm.'],
  certifications: ['Chứng nhận', 'Theo dõi thời hạn các chứng nhận an toàn của bạn.'],
  maintenance: ['Bảo trì', 'Xem lịch sử bảo trì và cập nhật tình trạng thiết bị.'],
  reports: ['Báo cáo', 'Chạy các báo cáo quản lý và tải kết quả theo quyền truy cập.'],
};
const roleNames = { student: 'Sinh viên', faculty: 'Giảng viên', technician: 'Kỹ thuật viên', auditor: 'Kiểm toán viên', admin: 'Quản trị viên' };
const status = {
  Available: ['Khả dụng','success'], 'In Use': ['Đang sử dụng','info'],
  'Under Maintenance': ['Đang bảo trì','warning'], Retired: ['Ngừng sử dụng','neutral'],
  Borrowed: ['Đang mượn','info'], Returned: ['Đã trả','success'], Overdue: ['Quá hạn','danger'],
  Active: ['Đang hoạt động','success'], Completed: ['Hoàn thành','success'], Planned: ['Dự kiến','info'],
  Suspended: ['Tạm dừng','warning'], Valid: ['Còn hiệu lực','success'], Expired: ['Hết hạn','danger'],
  Normal: ['Thông thường','success'], Restricted: ['Hạn chế','warning'], Hazardous: ['Nguy hiểm','danger'],
  None: ['Không nguy hiểm','neutral'], Low: ['Thấp','success'], Medium: ['Trung bình','warning'],
  High: ['Cao','danger'], Extreme: ['Rất cao','danger'], Open: ['Đang mở','info'], Closed: ['Đã đóng','success'],
  Receipt: ['Nhập kho','success'], Issue: ['Xuất kho','info'],
};
const account = document.querySelector('#auth-button');
const sidebarUser = document.querySelector('#sidebar-user');
const view = document.querySelector('#app-view');
const dialog = document.querySelector('#app-dialog');
const toastRegion = document.querySelector('#toast-region');
let user = null;
let current = { page: 'dashboard', params: new URLSearchParams() };
let latest = 0;
let reportData;
let labsCache;
let modalSerial = 0;
let modalLock = false;
let lastFocus;
const initialPage = getRoute();

function esc(value) {
  return String(value ?? '').replace(/[&<>"']/g, char => ({
    '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;',
  })[char]);
}
const shown = value => esc(value ?? '—');
const nf = new Intl.NumberFormat('vi-VN', { maximumFractionDigits: 3 });
const moneyf = new Intl.NumberFormat('vi-VN', { style: 'currency', currency: 'VND' });
const fmt = value => value == null ? '—' : nf.format(value);
const money = value => value == null ? '—' : moneyf.format(value);
const role = () => String(user?.role || '').toLowerCase();
const canWrite = () => !!user && (Array.isArray(user.permissions) ? user.permissions.includes('member') : role() !== 'auditor');
const readOnly = () => !!user && !canWrite();
const readOnlyText = 'Tài khoản của bạn chỉ có quyền xem.';
const displayRole = () => user?.permissions?.includes?.('research_admin') ? roleNames.admin
  : !canWrite() && user?.permissions?.includes?.('auditor') ? roleNames.auditor
  : roleNames[role()] || 'Thành viên';
const staff = () => canWrite() && ['faculty', 'technician'].includes(role());
function date(value, time = false) {
  if (!value) return '—';
  const match = String(value).match(/^(\d{4})-(\d{2})-(\d{2})(?:[T ](\d{2}:\d{2}))?/);
  if (!match) return esc(value);
  const stamp = match[3] + '/' + match[2] + '/' + match[1];
  return time && match[4] ? match[4] + ' · ' + stamp : stamp;
}
function isoToday() {
  return new Intl.DateTimeFormat('en-CA', { timeZone: 'Asia/Ho_Chi_Minh', year: 'numeric', month: '2-digit', day: '2-digit' }).format(new Date());
}
function badge(value) {
  if (value == null || value === '') return '—';
  const [label, kind] = Object.hasOwn(status, value) ? status[value] : [value, 'neutral'];
  return '<span class="status-badge badge ' + kind + '">' + esc(label) + '</span>';
}
function href(page, params) {
  return '#' + page + (params && params.toString() ? '?' + params.toString() : '');
}
function link(page, title, kind = 'secondary', glyph = '', params) {
  return '<a class="btn btn-' + kind + ' ' + kind + '" href="' + esc(href(page, params)) + '" data-page="' + page + '" data-query="' + esc(params?.toString() || '') + '">' + (glyph ? icon(glyph, 17) : '') + esc(title) + '</a>';
}
function button(action, title, { kind = 'secondary', glyph, id, label, small = false } = {}) {
  return '<button type="button" class="btn btn-' + kind + ' ' + kind + (small ? ' small' : '') + '" data-action="' + action + '"' + (id != null ? ' data-id="' + esc(id) + '"' : '') + (label != null ? ' data-label="' + esc(label) + '"' : '') + '>' + (glyph ? icon(glyph, 17) : '') + esc(title) + '</button>';
}
function rowButton(action, title, id, label, glyph = 'right') {
  return button(action, title, { id, label, small: true, kind: 'ghost', glyph });
}
function getRoute() {
  const [page, query] = location.hash.slice(1).split('?');
  return { page: Object.hasOwn(labels, page) ? page : 'dashboard', params: new URLSearchParams(query) };
}
function go(page, params = new URLSearchParams()) {
  if (!Object.hasOwn(labels, page)) return;
  const target = href(page, params);
  closeMenu();
  if (location.hash === target) {
    current = getRoute();
    loadPage();
  } else {
    location.hash = target;
  }
}
function closeMenu() {
  document.body.classList.remove('menu-open');
  document.querySelector('#menu-toggle')?.setAttribute('aria-expanded', 'false');
}
function syncHeader() {
  const label = document.querySelector('#page-title');
  if (label) label.textContent = labels[current.page][0];
  document.title = labels[current.page][0] + ' · LabTrack';
  for (const link of document.querySelectorAll('#sidebar [data-page]')) {
    const active = link.dataset.page === current.page;
    link.classList.toggle('active', active);
    if (active) link.setAttribute('aria-current', 'page'); else link.removeAttribute('aria-current');
  }
  const name = account?.querySelector('.account-label');
  if (name) name.textContent = user ? user.name : 'Đăng nhập';
  if (account) account.title = user ? user.name + ' · ' + displayRole() : 'Đăng nhập';
  const acctRole = account?.querySelector('.account-role');
  if (acctRole) acctRole.textContent = user ? displayRole() : 'Tài khoản';
  const sidebarLabel = sidebarUser?.querySelector('.sidebar-session-title');
  const sidebarDetail = sidebarUser?.querySelector('.sidebar-session-detail');
  if (sidebarLabel) sidebarLabel.textContent = user ? displayRole() : 'Môi trường demo';
  if (sidebarDetail) sidebarDetail.textContent = readOnly() ? 'Chỉ xem dữ liệu' : 'Dữ liệu mô phỏng';
}
async function request(path, { method = 'GET', body } = {}) {
  const headers = { Accept: 'application/json' };
  if (body !== undefined) headers['Content-Type'] = 'application/json';
  if (method !== 'GET' && user?.csrf) headers['X-CSRF-Token'] = user.csrf;
  const res = await fetch('/api/v1' + path, { method, headers, credentials: 'same-origin', cache: 'no-store', body: body === undefined ? undefined : JSON.stringify(body) });
  const data = res.status === 204 ? null : await res.json().catch(() => null);
  if (!res.ok) {
    const error = new Error(data?.error?.message || (res.status === 401 ? 'Vui lòng đăng nhập lại.' : 'Không thể thực hiện yêu cầu. Vui lòng thử lại.'));
    error.status = res.status;
    throw error;
  }
  return data?.data ?? null;
}
const post = (path, body = {}) => request(path, { method: 'POST', body });
const asRows = data => Array.isArray(data) ? data : data?.rows || [];
const currentParams = () => new URLSearchParams(current.params);
const queryOf = params => params.toString() ? '?' + params : '';
const list = (path, params = current.params) => request(path + queryOf(params));
async function labs() {
  const session = user;
  if (labsCache?.session === session) return labsCache.rows;
  const rows = asRows(await request('/labs'));
  if (user === session) labsCache = { session, rows };
  return rows;
}
function heading(page, actions = '') {
  return '<div class="page-head"><div class="page-intro"><h1>' + labels[page][0] + '</h1><p>' + labels[page][1] + '</p></div>' + (actions ? '<div class="page-actions">' + actions + '</div>' : '') + '</div>';
}
function section(title, detail, actions = '') {
  return '<div class="section-header panel-header"><div><h2>' + esc(title) + '</h2>' + (detail ? '<p class="section-subtitle">' + esc(detail) + '</p>' : '') + '</div>' + actions + '</div>';
}
function empty(title, text, glyph = 'search', action = '') {
  return '<div class="empty-state"><div class="row-icon">' + icon(glyph, 25) + '</div><h3>' + esc(title) + '</h3>' + (text ? '<p>' + esc(text) + '</p>' : '') + action + '</div>';
}
function table(cols, rows, noData = 'Không có bản ghi phù hợp.') {
  if (!rows.length) return empty(noData, 'Thử thay đổi bộ lọc hoặc quay lại sau.');
  return '<div class="table-wrap"><table class="data-table"><thead><tr>' +
    cols.map(([name]) => '<th scope="col">' + esc(name) + '</th>').join('') + '</tr></thead><tbody>' +
    rows.map(row => '<tr>' + cols.map(([, fn]) => '<td>' + fn(row) + '</td>').join('') + '</tr>').join('') +
    '</tbody></table></div>';
}
function nameCell(glyph, title, subtitle) {
  return '<div class="table-name"><span class="row-icon">' + icon(glyph, 18) + '</span><span><strong>' + shown(title) + '</strong>' + (subtitle ? '<small>' + esc(subtitle) + '</small>' : '') + '</span></div>';
}
function option(value, name, selected = '', disabled = false) {
  return '<option value="' + esc(value) + '"' + (String(value) === String(selected) && !disabled ? ' selected' : '') + (disabled ? ' disabled' : '') + '>' + esc(name) + '</option>';
}
function select(name, label, options, selected, required = false) {
  return '<select name="' + esc(name) + '" aria-label="' + esc(label) + '"' + (required ? ' required' : '') + '>' + options.map(([value, text, disabled]) => option(value, text, selected, disabled)).join('') + '</select>';
}
const labOptions = (rows, any = true) => [[ '', any ? 'Tất cả phòng' : 'Chọn phòng thí nghiệm' ], ...rows.map(row => [row.lab_id, row.lab_name])];
const enumOptions = (values, all = 'Tất cả trạng thái') => [['', all], ...values.map(v => [v, status[v]?.[0] || v])];
function filters({ search = '', fields = '' } = {}) {
  return '<form class="filters toolbar" data-form="filters">' +
    (search ? '<label class="search-field">' + icon('search', 18) + '<input type="search" name="q" placeholder="' + esc(search) + '" aria-label="Tìm kiếm" value="' + esc(current.params.get('q') || '') + '"></label>' : '') +
    fields + '<button type="submit" class="btn btn-secondary secondary">' + icon('search', 16) + 'Áp dụng</button>' +
    ([...current.params.keys()].some(key => key !== 'code') ? button('clear-filters', 'Xóa lọc', { kind: 'ghost' }) : '') + '</form>';
}
function pagination(data) {
  const total = Number(data?.total || 0), page = Number(data?.page || 1), size = Number(data?.page_size || 20);
  if (!total) return '';
  const pages = Math.ceil(total / size);
  return '<div class="pagination"><span>' + fmt(Math.min((page - 1) * size + 1, total)) + '–' + fmt(Math.min(page * size, total)) + ' / ' + fmt(total) + ' bản ghi</span><div>' +
    (page > 1 ? button('paginate', 'Trước', { glyph: 'left', id: page - 1, small: true }) : '') +
    (page < pages ? button('paginate', 'Sau', { glyph: 'right', id: page + 1, small: true }) : '') + '</div></div>';
}
function panel(title, subtitle, content, actions = '') {
  return '<section class="panel">' + section(title, subtitle, actions) + content + '</section>';
}
function actionNote(message) {
  return message ? '<p class="action-note">' + icon('lock', 16) + '<span>' + esc(message) + '</span></p>' : '';
}
function metric(label, value, glyph, color, hint, page, params) {
  return '<a class="stat-card metric-card" href="' + esc(href(page, params)) + '" data-page="' + page + '" data-query="' + esc(params?.toString() || '') + '">' +
    '<span class="metric-top"><span class="metric-icon ' + color + '">' + icon(glyph, 20) + '</span><span class="metric-arrow">' + icon('right', 16) + '</span></span>' +
    '<span class="metric-label">' + esc(label) + '</span><strong class="metric-value">' + fmt(value) + '</strong><span class="metric-hint">' + esc(hint) + '</span></a>';
}
function chart(rows) {
  if (!rows.length) return empty('Chưa có lượt mượn', 'Dữ liệu sẽ xuất hiện khi có giao dịch.', 'borrows');
  const peak = Math.max(1, ...rows.map(row => Number(row.total || 0)));
  const step = Math.max(1, Math.ceil(peak / 4));
  const max = step * 4;
  const bars = rows.map(row => {
    const total = Math.max(0, Number(row.total || 0));
    const returned = Math.min(total, Math.max(0, Number(row.returned || 0)));
    return '<div class="bar-col"><div class="bar-track" role="img" aria-label="' + esc(row.label + ': ' + total + ' lượt, ' + returned + ' đã trả') +
      '" title="' + esc(row.label + ': ' + total + ' lượt, ' + returned + ' đã trả') + '"><div class="bar-fill" style="height:' + (100 * total / max) + '%"></div><div class="bar-returned" style="height:' + (100 * returned / max) + '%"></div></div>' +
      '<span class="bar-label">' + esc(row.label) + '</span></div>';
  }).join('');
  return '<div class="chart-frame"><div class="chart-y">' + [max, step * 3, step * 2, step, 0].map(x => '<span>' + x + '</span>').join('') + '</div><div class="bars">' + bars + '</div></div>' +
    '<div class="chart-legend"><span><i></i>Lượt mượn</span><span><i></i>Đã trả</span></div>';
}
function dashboard(data) {
  const s = data?.stats || {};
  const activityTypes = { borrow: 'borrows', checkout: 'borrows', maintenance: 'maintenance', access: 'access', chemical: 'chemicals', receipt: 'chemicals', issue: 'chemicals', return: 'borrows' };
  const entries = data?.activities || [];
  const activities = entries.length ? '<ul class="activity-list">' + entries.slice(0, 5).map(item =>
    '<li class="activity-row"><span class="row-icon">' + icon(activityTypes[String(item.type || '').toLowerCase()] || 'clock', 18) + '</span><span class="activity-copy"><strong>' + esc(item.title) +
    '</strong><small>' + esc(item.subtitle || '') + '</small></span><span class="activity-date">' + date(item.date, true) + '</span></li>'
  ).join('') + '</ul>' : empty('Chưa có hoạt động', 'Các hoạt động mới sẽ xuất hiện tại đây.', 'clock');
  const available = new URLSearchParams({ status: 'Available' });
  const active = new URLSearchParams({ status: 'Active' });
  const open = new URLSearchParams({ status: 'open' });
  const near = new URLSearchParams({ expiry: 'expiring' });
  const today = new Intl.DateTimeFormat('vi-VN', { timeZone: 'Asia/Ho_Chi_Minh', dateStyle: 'full' }).format(new Date());
  const [primaryPage, primaryLabel, primaryIcon] = readOnly() ? ['reports', 'Xem báo cáo', 'reports'] :
    isAdmin() || role() === 'faculty' ? ['grants', 'Xem đề tài', 'grants'] :
    canOperate() ? ['maintenance', 'Xem bảo trì', 'maintenance'] : ['equipment', 'Khám phá thiết bị', 'arrow'];
  const hero = '<div class="page-head hero"><div class="hero-copy"><span class="eyebrow">' + icon('lab', 15) + ' KHÔNG GIAN NGHIÊN CỨU</span><h1>Quản lý phòng thí nghiệm</h1>' +
    '<p>Theo dõi tài sản, đề tài nghiên cứu và hoạt động phòng thí nghiệm tại một nơi.</p><div class="hero-actions">' +
    link(primaryPage, primaryLabel, 'primary', primaryIcon) +
    (user ? '' : button('account', 'Đăng nhập thử', { kind: 'secondary', glyph: 'user' })) + '</div></div>' +
    '<span class="hero-date">' + icon('calendar', 16) + esc(today) + '</span></div>';
  const metrics = '<div class="stat-grid metric-grid">' +
    metric('Thiết bị khả dụng', s.equipment_available, 'equipment', 'teal', 'Trong ' + fmt(s.equipment_total) + ' thiết bị', 'equipment', available) +
    metric('Thiết bị đang mượn', s.open_borrows, 'borrows', 'blue', user ? 'Lượt mượn của bạn' : 'Lượt mượn toàn hệ thống', 'borrows', open) +
    (user ? metric('Chứng nhận sắp hết hạn', s.certifications_expiring, 'certifications', 'purple', 'Chứng nhận của bạn · 30 ngày', 'certifications', new URLSearchParams({ status: 'expiring' })) :
      metric('Đề tài hoạt động', s.active_grants, 'grants', 'purple', 'Đề tài đang triển khai', 'grants', active)) +
    metric('Hóa chất sắp hết hạn', s.chemicals_expiring, 'chemicals', 'amber', 'Trong 30 ngày tới', 'chemicals', near) +
    '</div>';
  const labsRows = data?.labs || [];
  const labTable = table([
    ['Phòng thí nghiệm', row => nameCell('lab', row.lab_name, [row.building ? 'Tòa ' + row.building : '', row.room_number ? 'Phòng ' + row.room_number : ''].filter(Boolean).join(' · '))],
    ['Mức an toàn', row => badge(row.safety_level)],
    ['Thiết bị khả dụng', row => '<strong>' + fmt(row.available_count) + '</strong> / ' + fmt(row.equipment_count)],
    ['Sức chứa', row => fmt(row.capacity) + ' người'],
    ['Thiết bị', row => link('equipment', 'Xem', 'ghost', 'right', new URLSearchParams({ lab_id: row.lab_id }))],
  ], labsRows, 'Chưa có phòng thí nghiệm');
  return hero + metrics + '<div class="dashboard-grid">' +
    panel('Hoạt động mượn trả', 'Số lượt mượn theo quý và phần đã trả', chart(data?.borrow_chart || []), link('borrows', 'Xem lịch sử', 'ghost', 'right')) +
    panel('Hoạt động gần đây', 'Cập nhật từ các nhật ký nghiệp vụ', activities) + '</div>' +
    panel('Phòng thí nghiệm', labsRows.length ? fmt(labsRows.length) + ' phòng đang được theo dõi' : '', labTable,
      isAdmin() ? button('lab-safety', 'Mức an toàn', { glyph: 'warning' }) : link('access', 'Ra vào phòng', 'ghost', 'arrow'));
}

async function showEquipment() {
  const [data, rooms] = await Promise.all([list('/equipment'), labs()]);
  const html = table([
    ['Thiết bị', row => nameCell('equipment', row.equipment_name, row.serial_number)],
    ['Phòng thí nghiệm', row => shown(row.lab_name)],
    ['Ngày mua', row => date(row.purchase_date)],
    ['Trạng thái', row => badge(row.current_status)],
    ['Chi tiết', row => rowButton('equipment-detail', 'Xem', row.equipment_id)],
  ], asRows(data));
  return heading('equipment') + panel('Danh mục thiết bị', '', filters({
    search: 'Tìm tên hoặc số sê-ri',
    fields: select('lab_id', 'Phòng thí nghiệm', labOptions(rooms), current.params.get('lab_id')) +
      select('status', 'Trạng thái', enumOptions(['Available','In Use','Under Maintenance','Retired']), current.params.get('status')),
  }) + html + pagination(data));
}
async function showGrants() {
  const data = await list('/grants');
  const html = table([
    ['Đề tài', row => nameCell('grants', row.grant_title, 'ĐT-' + row.grant_id)],
    ['Chủ nhiệm', row => shown(row.principal_investigator || row.investigator_name || row.pi_name)],
    ['Thời gian', row => date(row.start_date) + ' – ' + date(row.end_date)],
    ['Trạng thái', row => badge(row.status)],
    ['Chi tiết', row => rowButton('grant-detail', 'Xem', row.grant_id)],
  ], asRows(data));
  return heading('grants') + panel('Danh mục đề tài', '', filters({
    search: 'Tìm tên đề tài',
    fields: select('status', 'Trạng thái', enumOptions(['Active','Completed','Suspended']), current.params.get('status')),
  }) + html + pagination(data));
}
async function showChemicals() {
  const session = user;
  const [data, rooms] = await Promise.all([list('/chemicals'), labs()]);
  if (session === user) for (const row of asRows(data)) catalog.set(String(row.chemical_id), row);
  const html = table([
    ['Hóa chất', row => nameCell('chemicals', row.chemical_name, row.cas_number ? 'CAS ' + row.cas_number : '')],
    ['Phòng thí nghiệm', row => shown(row.lab_name)],
    ['Tồn kho', row => '<strong>' + fmt(row.quantity_in_stock) + '</strong> ' + shown(row.unit)],
    ['Hạn dùng', row => date(row.expiry_date)],
    ['Mức nguy hiểm', row => badge(row.hazard_level)],
    ['Thao tác', row => rowButton('chemical-detail', 'Xem', row.chemical_id, row.chemical_name)],
  ], asRows(data));
  const opts = enumOptions(['None','Low','Medium','High','Extreme'], 'Tất cả mức nguy hiểm');
  const expiry = [['', 'Mọi hạn dùng'], ['expiring', 'Sắp hết hạn (30 ngày)'], ['expired', 'Đã hết hạn'], ['valid', 'Còn hạn']];
  return heading('chemicals') + panel('Danh mục hóa chất', '', filters({
    search: 'Tìm theo tên hoặc CAS',
    fields: select('lab_id', 'Phòng thí nghiệm', labOptions(rooms), current.params.get('lab_id')) +
      select('hazard_level', 'Mức nguy hiểm', opts, current.params.get('hazard_level')) +
      select('expiry', 'Hạn sử dụng', expiry, current.params.get('expiry')),
  }) + html + pagination(data));
}
async function showBorrows() {
  const data = await list('/me/borrows');
  const html = table([
    ['Thiết bị', row => nameCell('equipment', row.equipment_name, 'Phiếu #' + row.borrow_id)],
    ['Ngày mượn', row => date(row.borrow_date)],
    ['Hạn trả', row => date(row.expected_return_date)],
    ['Ngày trả', row => date(row.actual_return_date)],
    ['Trạng thái', row => badge(row.effective_status || row.status)],
    ...(canWrite() ? [['Thao tác', row => !row.actual_return_date && row.can_return !== false ? rowButton('return', 'Trả thiết bị', row.borrow_id, row.equipment_name, 'check') : '—']] : []),
  ], asRows(data), 'Chưa có lượt mượn');
  return heading('borrows', canWrite() ? link('equipment', 'Tìm thiết bị', 'primary', 'plus') : '') + panel('Giao dịch của bạn', readOnly() ? readOnlyText : '', filters({
      fields: select('status', 'Trạng thái', [['', 'Tất cả lượt'], ['open', 'Chưa trả'], ['closed', 'Đã trả'], ['overdue', 'Quá hạn']], current.params.get('status')),
  }) + html + pagination(data));
}
async function showAccess() {
  const [data, rooms] = await Promise.all([list('/me/access'), canWrite() ? request('/labs') : []]);
  const roomRows = asRows(rooms);
  const canEnter = roomRows.some(room => room.can_enter === true);
  const html = table([
    ['Phòng thí nghiệm', row => nameCell('lab', row.lab_name, 'Lượt #' + row.log_id)],
    ['Mục đích', row => shown(row.purpose)],
    ['Giờ vào', row => date(row.entry_time, true)],
    ['Giờ ra', row => date(row.exit_time, true)],
    ['Trạng thái', row => badge(row.exit_time ? 'Closed' : 'Open')],
    ...(canWrite() ? [['Thao tác', row => !row.exit_time && row.can_exit !== false ? rowButton('exit-lab', 'Ghi giờ ra', row.log_id, row.lab_name, 'access') : '—']] : []),
  ], asRows(data), 'Chưa có lượt ra vào');
  return heading('access', (staff() ? button('approve-access', 'Phê duyệt lượt vào', { glyph: 'check' }) : '') +
      (canEnter ? button('enter-lab', 'Ghi lượt vào', { kind: 'primary', glyph: 'plus' }) : '')) +
    panel('Nhật ký ra vào của bạn', readOnly() ? readOnlyText : !canEnter ? (roomRows.find(room => room.entry_block_reason)?.entry_block_reason || 'Bạn hiện không thể tự ghi lượt vào phòng.') : '', filters({
      fields: select('status', 'Trạng thái', [['', 'Tất cả lượt'], ['open', 'Đang mở'], ['closed', 'Đã đóng']], current.params.get('status')),
    }) + html + pagination(data));
}
async function showCertifications() {
  const data = await list('/me/certifications');
  const html = table([
    ['Chứng nhận', row => nameCell('certifications', row.cert_name, row.issuing_authority)],
    ['Ngày cấp', row => date(row.issue_date)],
    ['Ngày hết hạn', row => date(row.expiry_date)],
    ['Trạng thái', row => badge(row.effective_status || row.status)],
  ], asRows(data), 'Chưa có chứng nhận');
  return heading('certifications') + panel('Chứng nhận của bạn', '', filters({
    fields: select('status', 'Trạng thái', [['', 'Mọi hạn dùng'], ['valid', 'Còn hiệu lực'], ['expired', 'Hết hạn'], ['expiring', 'Sắp hết hạn (30 ngày)']], current.params.get('status')),
  }) + html + pagination(data));
}
async function showMaintenance() {
  const data = await list('/maintenance');
  const html = table([
    ['Thiết bị', row => nameCell('equipment', row.equipment_name, row.lab_name)],
    ['Nội dung', row => shown(row.description)],
    ['Bắt đầu', row => date(row.start_date)],
    ['Kết thúc', row => date(row.end_date)],
    ['Trạng thái', row => badge(row.end_date ? 'Closed' : 'Open')],
    ...(canOperate() ? [['Thao tác', row => row.can_complete ? rowButton('complete-maintenance', 'Kết thúc', row.maintenance_id, row.equipment_name, 'check') : '—']] : []),
  ], asRows(data), 'Chưa có bản ghi bảo trì');
  return heading('maintenance', canOperate() ? button('new-maintenance', 'Tạo phiếu bảo trì', { glyph: 'plus', kind: 'primary' }) : '') +
    panel('Nhật ký bảo trì', canOperate() ? '' : 'Chỉ kỹ thuật viên có quyền vận hành mới được lập và kết thúc phiếu bảo trì.', filters({ search: 'Tìm tên thiết bị',
      fields: select('status', 'Trạng thái', [['', 'Tất cả'], ['open', 'Đang bảo trì'], ['closed', 'Đã kết thúc']], current.params.get('status')),
    }) + html + pagination(data));
}
async function showReports() {
  const entries = asRows(await request('/reports'));
  const code = current.params.get('code');
  if (!code || !entries.some(row => row.code === code)) {
    reportData = null;
    return heading('reports') + panel('Danh sách báo cáo', code ? 'Báo cáo được chọn không có trong danh sách bạn được xem.' : 'Chọn báo cáo để xem dữ liệu tổng hợp', table([
      ['Báo cáo', row => nameCell('reports', row.title, row.code)],
      ['Mô tả', row => shown(row.description)],
      ['Kết quả', row => link('reports', 'Chạy báo cáo', 'ghost', 'arrow', new URLSearchParams({ code: row.code }))],
    ], entries, 'Không có báo cáo cho tài khoản này'));
  }
  const [data, rooms] = await Promise.all([
    request('/reports/' + encodeURIComponent(code) + queryOf(new URLSearchParams([...current.params].filter(([key]) => key !== 'code')))), labs(),
  ]);
  reportData = data;
  const value = (col, row) => {
    const x = row[col.key];
    if (x == null) return '—';
    if (typeof x === 'boolean') return x ? 'Có' : 'Không';
    if (typeof x === 'string' && Object.hasOwn(status, x)) return badge(x);
    if (/(?:_date|_time|_at)$/.test(col.key)) return date(x, /(?:_time|_at)$/.test(col.key));
    return esc(x);
  };
  const filterKeys = data.filters || [];
  const form = filterKeys.length ? filters({ fields: '<input type="hidden" name="code" value="' + esc(code) + '">' +
    (filterKeys.includes('lab_id') ? select('lab_id', 'Phòng thí nghiệm', labOptions(rooms), current.params.get('lab_id')) : '') +
    (filterKeys.includes('from') ? '<label class="inline-field">Từ ngày<input type="date" name="from" value="' + esc(current.params.get('from') || '') + '"></label>' : '') +
    (filterKeys.includes('to') ? '<label class="inline-field">Đến ngày (không gồm)<input type="date" name="to" value="' + esc(current.params.get('to') || '') + '"></label>' : '') +
    (filterKeys.includes('grant_id') ? '<label class="inline-field">Mã đề tài<input type="number" min="1" step="1" name="grant_id" value="' + esc(current.params.get('grant_id') || '') + '"></label>' : ''),
  }) : '';
  return heading('reports', link('reports', 'Danh sách báo cáo', 'secondary', 'left')) +
    panel(data.code + ' · ' + data.title, data.description, form + table(data.columns.map(col => [col.label, row => value(col, row)]), asRows(data)) +
      pagination(data), button('export-report', 'Tải CSV trang này', { glyph: 'download', small: true }));
}
const pages = { equipment: showEquipment, grants: showGrants, chemicals: showChemicals, borrows: showBorrows, access: showAccess, certifications: showCertifications, maintenance: showMaintenance, reports: showReports };
async function loadPage({ preserve = false } = {}) {
  const serial = ++latest;
  const page = current.page;
  const scroll = window.scrollY;
  syncHeader();
  if (!preserve) {
    if (page !== 'dashboard') view.innerHTML = heading(page) + '<section class="panel">' + empty('Đang tải dữ liệu', '', 'clock') + '</section>';
    view.setAttribute('aria-busy', 'true');
  }
  try {
    let content;
    if (page === 'dashboard') content = dashboard(await request(user ? '/dashboard' : '/preview'));
    else if (!user) {
      content = heading(page) + '<section class="panel">' + empty('Đăng nhập để tiếp tục', 'Chọn một tài khoản trình diễn để xem dữ liệu và thực hiện nghiệp vụ.', 'lock',
        button('account', 'Đăng nhập', { kind: 'primary', glyph: 'user' })) + '</section>';
    } else content = await pages[page]();
    if (serial !== latest) return;
    view.innerHTML = content;
    if (!preserve) window.scrollTo(0, 0); else window.scrollTo(0, scroll);
  } catch (error) {
    if (serial !== latest) return;
    if (error.status === 401 && user) {
      user = null;
      labsCache = undefined;
      await loadPage();
      return;
    }
    view.innerHTML = (page === 'dashboard' ? '<div class="page-head"><h1>Tổng quan</h1></div>' : heading(page)) +
      '<section class="panel">' + empty('Không tải được dữ liệu', error.message, 'warning', button('reload', 'Thử lại', { kind: 'primary' })) + '</section>';
  } finally {
    if (serial === latest) view.removeAttribute('aria-busy');
  }
}

function closeDialog() {
  if (modalLock) return;
  if (dialog.open) dialog.close();
}
function modal(title, body, actions = '', { wide = false } = {}) {
  if (!dialog.open) lastFocus = document.activeElement;
  dialog.classList.toggle('dialog-wide', wide);
  dialog.setAttribute('aria-labelledby', 'dialog-title');
  dialog.innerHTML = '<header class="dialog-header"><h2 id="dialog-title">' + esc(title) +
    '</h2><button class="icon-btn" type="button" data-action="close-dialog" aria-label="Đóng">' + icon('close', 21) + '</button></header>' +
    '<div class="dialog-body">' + body + '</div>' + (actions ? '<footer class="dialog-actions">' + actions + '</footer>' : '');
  if (!dialog.open) dialog.showModal();
}
async function modalLoad(title, operation) {
  const serial = ++modalSerial;
  modal(title, '<div class="loading-state" role="status"><span class="spinner"></span> Đang tải…</div>');
  try {
    const result = await operation();
    if (serial === modalSerial && dialog.open) result();
  } catch (error) {
    if (serial === modalSerial && dialog.open) modal(title, empty('Không thể tải thông tin', error.message, 'warning'));
  }
}
function details(items) {
  return '<dl class="detail-grid">' + items.map(([name, value]) => '<div><dt>' + esc(name) + '</dt><dd>' + (value ?? '—') + '</dd></div>').join('') + '</dl>';
}
function part(title, content, actions = '') {
  return '<section class="detail-section"><div class="section-header"><h3>' + esc(title) + '</h3>' + actions + '</div>' + content + '</section>';
}
function field(label, content, full = false, help = '') {
  return '<label class="field' + (full ? ' full' : '') + '"><span>' + esc(label) + '</span>' + content + (help ? '<small>' + esc(help) + '</small>' : '') + '</label>';
}
function input(name, type, options = {}) {
  return '<input name="' + esc(name) + '" type="' + esc(type) + '"' +
    Object.entries(options).filter(([, value]) => value !== false && value !== undefined && value !== null).map(([key, value]) =>
      value === true ? ' ' + key : ' ' + key + '="' + esc(value) + '"').join('') + '>';
}
function textArea(name, { limit = 500, required = true, placeholder = '', value = '' } = {}) {
  return '<textarea name="' + esc(name) + '" rows="3" maxlength="' + limit + '"' + (required ? ' required' : '') + ' placeholder="' + esc(placeholder) + '">' + esc(value) + '</textarea>';
}
function formError() {
  return '<p class="form-error" data-form-error role="alert" hidden></p>';
}
function mutationForm(path, fields, success, title = 'Xác nhận', preface = '', hidden = {}) {
  return '<form data-form="mutation" data-endpoint="' + esc(path) + '" data-success="' + esc(success) + '">' +
    (preface ? '<p class="dialog-description">' + esc(preface) + '</p>' : '') +
    Object.entries(hidden).map(([name, value]) => input(name, 'hidden', { value })).join('') +
    (fields ? '<div class="form-grid">' + fields + '</div>' : '') + formError() +
    '<div class="dialog-actions">' + button('close-dialog', 'Hủy', { kind: 'ghost' }) +
    '<button class="btn btn-primary primary" type="submit">' + icon('check', 17) + esc(title) + '</button></div></form>';
}
function confirm(title, message, path, success) {
  modal(title, mutationForm(path, '', success, 'Xác nhận', message));
}
function toast(message, isError = false) {
  if (!toastRegion) return;
  const item = document.createElement('div');
  item.className = 'toast' + (isError ? ' error' : ' success');
  item.innerHTML = icon(isError ? 'warning' : 'check', 19) + '<span>' + esc(message) + '</span>';
  toastRegion.append(item);
  setTimeout(() => item.remove(), 4800);
}
function showAccount() {
  if (user) {
    modal('Tài khoản của bạn', details([
      ['Họ tên', shown(user.name)], ['Vai trò', shown(displayRole())], ['Email', shown(user.email)],
    ]) + (readOnly() ? actionNote(readOnlyText) : '') + formError(), button('logout', 'Đăng xuất', { glyph: 'access', kind: 'secondary' }));
    return;
  }
  const demos = [
    ['student', 'Sinh viên'], ['faculty', 'Giảng viên'], ['technician', 'Kỹ thuật viên'], ['admin', 'Quản trị'], ['auditor', 'Kiểm toán'],
  ];
  modal('Đăng nhập LabTrack', '<form data-form="login"><div class="form-grid">' +
    field('Email', input('email', 'email', { required: true, autofocus: true, autocomplete: 'username', maxlength: 254, placeholder: 'Email của bạn' }), true) +
    field('Mật khẩu', input('password', 'password', { required: true, autocomplete: 'current-password', maxlength: 128, placeholder: 'Nhập mật khẩu' }), true) +
    '</div>' + formError() + '<div class="dialog-actions"><button type="submit" class="btn btn-primary primary">' + icon('user', 17) + 'Đăng nhập</button></div></form>' +
    '<div class="demo-accounts"><h3>Dùng tài khoản trình diễn</h3><p>Dữ liệu của các tài khoản này là dữ liệu mẫu.</p><div class="quick-links">' +
    demos.map(([key, label]) => button('demo-login', label, { id: key, kind: 'secondary', small: true })).join('') + '</div></div>');
}
async function doLogin(form, data) {
  if (modalLock) return;
  await runForm(form, async () => {
    user = await post('/auth/login', data);
    labsCache = undefined;
    catalog.clear();
    pointAllocations.clear();
    editableGrants.clear();
    return 'Đã đăng nhập.';
  });
}
async function showEquipmentDetail(id) {
  await modalLoad('Chi tiết thiết bị', async () => {
    const row = await request('/equipment/' + encodeURIComponent(id));
    const borrowed = table([
      ['Ngày mượn', x => date(x.borrow_date)], ['Hạn trả', x => date(x.expected_return_date)], ['Ngày trả', x => date(x.actual_return_date)],
      ['Trạng thái', x => badge(x.effective_status || x.status)],
    ], row.borrows || [], 'Bạn chưa mượn thiết bị này');
    const maintenance = table([
      ['Bắt đầu', x => date(x.start_date)], ['Kết thúc', x => date(x.end_date)], ['Nội dung', x => shown(x.description)],
    ], row.maintenance || [], 'Chưa có lịch bảo trì');
    const canBorrow = canWrite() && row.can_borrow === true;
    return () => modal(row.equipment_name, details([
      ['Số sê-ri', shown(row.serial_number)], ['Trạng thái', badge(row.current_status)], ['Phòng thí nghiệm', shown(row.lab_name)], ['Ngày mua', date(row.purchase_date)],
    ]) + (!canBorrow ? actionNote(row.borrow_block_reason || (readOnly() ? readOnlyText : 'Hiện chưa thể mượn thiết bị này.')) : '') + part('Lịch sử mượn của bạn', borrowed) + part('Lịch sử bảo trì', maintenance),
    (canOperate() && row.can_start_maintenance === true ? button('new-maintenance', 'Tạo phiếu bảo trì', { id, label: row.equipment_name, glyph: 'maintenance' }) : '') +
    (canBorrow ? button('borrow', 'Mượn thiết bị', { id, label: row.equipment_name, glyph: 'borrows', kind: 'primary' }) : ''),
    { wide: true });
  });
}
const catalog = new Map();
const pointAllocations = new Map();
const editableGrants = new Map();
const isAdmin = () => canWrite() && (user?.permissions?.includes?.('research_admin') || user?.research_admin || role() === 'admin');
const canOperate = () => canWrite() && role() === 'technician' && (!Array.isArray(user?.permissions) || user.permissions.includes('lab_operator'));
function showChemicalDetail(id, label) {
  const row = catalog.get(String(id));
  if (!row) return;
  const canIssue = canWrite() && row.can_issue === true;
  const canReceive = canOperate() && row.can_receive === true;
  const canRelocate = isAdmin() && row.can_relocate === true;
  const notices = readOnly() ? actionNote(readOnlyText) :
    (!canIssue ? actionNote(row.issue_block_reason || 'Bạn không có quyền xuất kho hóa chất này.') : '') +
    (isAdmin() && !canRelocate ? actionNote(row.relocation_block_reason || 'Không có phòng phù hợp để chuyển hóa chất này.') : '');
  modal(label, details([
    ['Mã CAS', shown(row.cas_number)], ['Phòng thí nghiệm', shown(row.lab_name)], ['Số lượng tồn', fmt(row.quantity_in_stock) + ' ' + shown(row.unit)],
    ['Hạn dùng', date(row.expiry_date)], ['Mức nguy hiểm', badge(row.hazard_level)], ['Điều kiện bảo quản', shown(row.storage_condition)],
  ]) + notices, (canReceive ? button('chemical-receipt', 'Nhập kho', { id, label, glyph: 'plus' }) : '') +
    (canRelocate ? button('chemical-location', 'Đổi phòng', { id, label, glyph: 'lab' }) : '') +
    (canIssue ? button('chemical-issue', 'Xuất kho', { id, label, glyph: 'arrow', kind: 'primary' }) : ''), { wide: true });
}
async function showGrantDetail(id) {
  await modalLoad('Chi tiết đề tài', async () => {
    const row = await request('/grants/' + encodeURIComponent(id));
    const edit = canWrite() && row.can_edit && row.status === 'Active';
    const canBudget = isAdmin() && row.can_update_budget === true && row.remaining_budget != null;
    if (canBudget || edit) editableGrants.set(String(id), row);
    const canAllocate = edit && (row.labs || []).length > 0;
    const points = (row.points || []).map(x => {
      const xId = x.rearch_point_id;
      if (canAllocate) pointAllocations.set(String(xId), { labs: row.labs, equipment: x.equipment || [], chemicals: x.chemicals || [] });
      const assets = (rows, key) => rows?.length ? rows.map(a => shown(a[key])).join(', ') : 'Chưa phân bổ';
      return '<article class="point-card"><div class="section-header"><h4>' + shown(x.point_name) + '</h4>' + badge(x.status) + '</div>' +
        '<p>' + date(x.start_date) + ' – ' + date(x.end_date) + '</p>' + (x.description ? '<p>' + shown(x.description) + '</p>' : '') +
        details([['Thiết bị', assets(x.equipment, 'equipment_name')], ['Hóa chất', assets(x.chemicals, 'chemical_name')]]) +
        (canAllocate ? '<div class="quick-links">' + button('allocate-equipment', 'Gắn thiết bị', { id: xId, label: x.point_name, glyph: 'plus', small: true }) +
        button('allocate-chemical', 'Gắn hóa chất', { id: xId, label: x.point_name, glyph: 'plus', small: true }) + '</div>' : '') + '</article>';
    }).join('');
    const fields = [
      ['Chủ nhiệm', shown(row.principal_investigator || row.investigator_name || row.pi_name)], ['Trạng thái', badge(row.status)],
      ['Bắt đầu', date(row.start_date)], ['Kết thúc', date(row.end_date)],
      ['Phòng được cấp', row.labs?.map(x => shown(x.lab_name)).join(', ') || 'Chưa cấp phòng'],
    ];
    if (row.total_budget != null) fields.push(['Tổng ngân sách', money(row.total_budget)]);
    if (row.remaining_budget != null) fields.push(['Ngân sách còn lại', money(row.remaining_budget)]);
    const notice = readOnly() ? readOnlyText : row.status !== 'Active' ? 'Chỉ có thể thêm hạng mục hoặc phân bổ tài sản khi đề tài đang hoạt động.' :
      !edit ? 'Chỉ chủ nhiệm đề tài hoặc quản trị nghiên cứu được sửa hạng mục và phân bổ tài sản.' :
      !canAllocate ? 'Đề tài chưa được cấp phòng nên chưa thể phân bổ tài sản.' : '';
    return () => modal(row.grant_title, details(fields) + actionNote(notice) + part('Hạng mục nghiên cứu',
      points || empty('Chưa có hạng mục', '', 'grants'),
      edit ? button('new-point', 'Thêm hạng mục', { id, label: row.grant_title, glyph: 'plus', kind: 'primary', small: true }) : ''),
      canBudget ? button('grant-budget', 'Cập nhật ngân sách', { id, label: row.remaining_budget, glyph: 'grants' }) : '', { wide: true });
  });
}
async function showAccessForm(approved, search = '', draft = {}) {
  const title = approved ? 'Phê duyệt lượt vào' : 'Ghi lượt vào phòng';
  await modalLoad(title, async () => {
    const [roomsResult, students] = await Promise.all([request('/labs'), approved ? list('/students', new URLSearchParams({ q: search })) : []]);
    const rooms = asRows(roomsResult);
    if (!approved && !rooms.some(room => room.can_enter === true)) return () => modal(title,
      empty('Bạn hiện không thể tự ghi lượt vào phòng', rooms.find(room => room.entry_block_reason)?.entry_block_reason || 'Không có phòng đủ điều kiện truy cập.', 'lock'));
    const searchForm = approved ? '<form data-form="student-search" class="filters"><label class="search-field">' + icon('search', 17) +
      input('q', 'search', { value: search, placeholder: 'Tìm họ tên hoặc mã sinh viên', 'aria-label': 'Tìm sinh viên' }) +
      '</label><button type="submit" class="btn btn-secondary secondary">Tìm sinh viên</button></form>' : '';
    const visitors = asRows(students);
    const options = [['', 'Chọn sinh viên'], ...visitors.map(x => [x.person_id || x.student_id, (x.full_name || x.name) + ' · ' + x.student_code])];
    const approvalRooms = roomChoicesForVisitor(rooms, visitors, draft.visitor_id);
    const roomChoices = approved ? approvalRooms : [['', 'Chọn phòng thí nghiệm'], ...rooms.map(x => [x.lab_id,
      x.lab_name + ' · ' + (x.can_enter === true ? status[x.safety_level]?.[0] || x.safety_level : x.entry_block_reason || 'Không đủ điều kiện'),
      x.can_enter !== true])];
    const facultyReason = !approved && role() === 'faculty';
    const reasonRequired = facultyReason && rooms.some(room => room.requires_out_of_hours_reason === true);
    const fields = (approved ? field('Sinh viên', select('visitor_id', 'Sinh viên', options, draft.visitor_id, true), true) : '') +
      field('Phòng thí nghiệm', select('lab_id', 'Phòng thí nghiệm', roomChoices, draft.lab_id, true), true) +
      field('Mục đích', textArea('purpose', { limit: facultyReason ? 300 : 500, placeholder: 'Ví dụ: thực hành theo đề tài', value: draft.purpose }), true) +
      (facultyReason ? field('Lý do ngoài giờ' + (reasonRequired ? ' · Bắt buộc' : ''),
        textArea('out_of_hours_reason', { limit: 170, required: reasonRequired, placeholder: 'Nêu lý do cần vào phòng ngoài giờ', value: draft.out_of_hours_reason }), true,
        'Giảng viên phải nêu lý do trước 06:00 hoặc từ 22:00 trở đi, theo giờ Việt Nam.') : '');
    const guide = approved
      ? 'Chọn sinh viên và phòng phù hợp với các chứng nhận còn hiệu lực. Danh tính người phê duyệt được ghi theo tài khoản của bạn.'
      : role() === 'student'
        ? 'Sinh viên tự ghi lượt vào từ 07:00 đến trước 17:00. Ngoài giờ, nhờ giảng viên hoặc kỹ thuật viên phê duyệt.'
        : 'Giờ vào do hệ thống ghi nhận. Điều kiện truy cập được kiểm tra khi xác nhận.';
    return () => {
      modal(title, searchForm + mutationForm(approved ? '/access-logs/approved' : '/access-logs', fields,
        approved ? 'Đã phê duyệt lượt vào.' : 'Đã ghi nhận lượt vào.', approved ? 'Phê duyệt và ghi lượt vào' : 'Ghi lượt vào', guide));
      if (approved) dialog.querySelector('[name="visitor_id"]')?.addEventListener('change', event => {
        const room = dialog.querySelector('[name="lab_id"]');
        replaceOptions(room, roomChoicesForVisitor(rooms, visitors, event.target.value), room.value);
      });
    };
  });
}
function replaceOptions(control, choices, value = '') {
  control.innerHTML = choices.map(([id, label, disabled]) => option(id, label, value, disabled)).join('');
  control.value = choices.some(([id, , disabled]) => String(id) === String(value) && !disabled) ? value : '';
}
function roomChoicesForVisitor(rooms, visitors, visitorId) {
  const visitor = visitors.find(x => String(x.person_id || x.student_id) === String(visitorId));
  return [['', 'Chọn phòng thí nghiệm'], ...rooms.map(room => {
    const required = ['Restricted', 'Hazardous'].includes(room.safety_level);
    const certified = room.safety_level === 'Hazardous' ? visitor?.has_hazardous_lab_certification : visitor?.has_valid_lab_certification;
    const blocked = required && certified !== true;
    const label = blocked ? (visitor ? 'Sinh viên chưa đủ loại chứng nhận bắt buộc còn hiệu lực' : 'Chọn sinh viên trước') : status[room.safety_level]?.[0] || room.safety_level;
    return [room.lab_id, room.lab_name + ' · ' + label, blocked];
  })];
}
async function showChemicalForm(id, label, receipt) {
  const title = (receipt ? 'Nhập kho: ' : 'Xuất kho: ') + label;
  const row = catalog.get(String(id));
  if (receipt ? !canOperate() || row?.can_receive !== true : !canWrite() || row?.can_issue !== true) return;
  await modalLoad(title, async () => {
    const points = receipt ? [] : asRows(await request('/chemicals/' + encodeURIComponent(id) + '/points'));
    return () => {
      if (!receipt && !points.length) return modal(title, empty('Chưa có hạng mục phù hợp', 'Hóa chất phải được phân bổ vào hạng mục của đề tài đang hoạt động trước khi xuất kho.', 'grants'));
      const fields = (receipt ? '' : field('Hạng mục nghiên cứu', select('rearch_point_id', 'Hạng mục nghiên cứu', [['', 'Chọn hạng mục'], ...points.map(x => [x.rearch_point_id, (x.point_name || x.name) + (x.grant_title ? ' · ' + x.grant_title : '')])], '', true), true)) +
        field('Số lượng' + (row.unit ? ' (' + row.unit + ')' : ''), input('quantity', 'number', { required: true, min: '0.001', max: receipt ? '99999999999.999' : row.quantity_in_stock, step: '0.001', placeholder: 'Ví dụ: 2,5' }), true) +
        field('Lý do', textArea('reason', { placeholder: 'Nhập lý do nhập hoặc xuất kho' }), true);
      modal(title, mutationForm(receipt ? '/chemical-receipts' : '/chemical-issues', fields, receipt ? 'Đã ghi phiếu nhập kho.' : 'Đã ghi phiếu xuất kho.', receipt ? 'Nhập kho' : 'Xuất kho',
        'Tồn kho được cập nhật sau khi giao dịch thành công.', { chemical_id: id }));
    };
  });
}
async function showMaintenanceForm(id, label, preselectEquipment) {
  if (!canOperate()) return;
  const title = id ? 'Kết thúc bảo trì' : 'Tạo phiếu bảo trì';
  await modalLoad(title, async () => {
    const data = id ? [] : asRows(await list('/equipment', new URLSearchParams({ status: 'Available', page_size: '100' })));
    if (!id && !data.length) return () => modal(title, empty('Không có thiết bị khả dụng', 'Chỉ có thể mở phiếu bảo trì cho thiết bị đang khả dụng.', 'maintenance'));
    const fields = (id ? '' : field('Thiết bị khả dụng', select('equipment_id', 'Thiết bị khả dụng', [['', 'Chọn thiết bị'], ...data.map(x => [x.equipment_id, x.equipment_name])], preselectEquipment, true), true)) +
      field(id ? 'Nội dung cập nhật (không bắt buộc)' : 'Nội dung bảo trì', textArea('description', { limit: 1000, required: !id }), true) +
      field(id ? 'Chi phí cập nhật (không bắt buộc)' : 'Chi phí (đồng)', input('cost', 'number', { min: '0', step: '0.01', required: !id, value: id ? undefined : 0 }), true);
    return () => modal(title, mutationForm(id ? '/maintenance/' + encodeURIComponent(id) + '/complete' : '/maintenance', fields,
      id ? 'Đã kết thúc bảo trì.' : 'Đã tạo phiếu bảo trì.', id ? 'Kết thúc bảo trì' : 'Tạo phiếu', label ? 'Thiết bị: ' + label : ''));
  });
}
async function showAllocation(id, label, chemical) {
  const title = (chemical ? 'Gắn hóa chất: ' : 'Gắn thiết bị: ') + label;
  await modalLoad(title, async () => {
    const context = pointAllocations.get(String(id));
    const path = chemical ? '/chemicals' : '/equipment';
    const idKey = chemical ? 'chemical_id' : 'equipment_id', nameKey = chemical ? 'chemical_name' : 'equipment_name';
    if (!context?.labs.length) return () => modal(title, empty('Đề tài chưa được cấp phòng', 'Cần cấp phòng thí nghiệm cho đề tài trước khi phân bổ tài sản.', 'lab'));
    const attached = new Set(context[chemical ? 'chemicals' : 'equipment'].map(row => String(row[idKey])));
    const byRoom = await Promise.all(context.labs.map(async room => {
      const filters = new URLSearchParams({ lab_id: room.lab_id, page_size: '100' });
      const firstPage = await list(path, filters);
      const rows = [...asRows(firstPage)];
      const count = Math.ceil(firstPage.total / firstPage.page_size);
      for (let page = 2; page <= count; page++) {
        filters.set('page', page);
        rows.push(...asRows(await list(path, filters)));
      }
      return rows;
    }));
    const rows = byRoom.flat().filter(row => !attached.has(String(row[idKey])));
    if (!rows.length) return () => modal(title, empty('Không có tài sản để gắn', 'Các phòng được cấp chưa có tài sản loại này, hoặc hạng mục đã được gắn tất cả tài sản phù hợp. Hãy thử một hạng mục khác.', 'grants'));
    const opts = [['', 'Chọn tài sản'], ...rows.map(x => [x[idKey], x[nameKey] + (x.lab_name ? ' · ' + x.lab_name : '')])];
    return () => modal(title, mutationForm('/points/' + encodeURIComponent(id) + '/' + (chemical ? 'chemical' : 'equipment') + '-allocations',
      field('Tài sản', select(idKey, 'Tài sản', opts, '', true), true), 'Đã cập nhật phân bổ.', 'Phân bổ',
      'Danh sách chỉ gồm tài sản trong phòng đã cấp và chưa gắn vào hạng mục này.'));
  });
}

async function showRoomSafety() {
  await modalLoad('Cập nhật mức an toàn', async () => {
    const rooms = asRows(await request('/labs'));
    const choices = [['', 'Chọn phòng thí nghiệm'], ...rooms.map(room => [room.lab_id, room.lab_name +
      (room.can_change_safety === true ? '' : ' · ' + (room.safety_block_reason || 'Không có mức thay thế phù hợp')), room.can_change_safety !== true])];
    if (!rooms.some(room => room.can_change_safety === true)) return () => modal('Cập nhật mức an toàn',
      empty('Không có phòng đủ điều kiện đổi mức an toàn', 'Phòng lưu trữ hóa chất yêu cầu mức an toàn tương ứng.', 'lock'));
    const fields = field('Phòng thí nghiệm', select('lab_id', 'Phòng thí nghiệm', choices, '', true), true) +
      field('Mức an toàn', select('safety_level', 'Mức an toàn', [['', 'Chọn phòng trước']], '', true), true);
    return () => {
      modal('Cập nhật mức an toàn', mutationForm('/labs/:lab_id/safety', fields, 'Đã cập nhật mức an toàn.', 'Lưu mức an toàn'));
      dialog.querySelector('[name="lab_id"]')?.addEventListener('change', event => {
        const selected = rooms.find(room => String(room.lab_id) === event.target.value);
        replaceOptions(dialog.querySelector('[name="safety_level"]'), enumOptions(selected?.allowed_safety_levels || [], 'Chọn mức an toàn'));
      });
    };
  });
}
function downloadReport() {
  if (!reportData?.rows?.length) { toast('Không có dữ liệu để tải.'); return; }
  function cell(value) {
    const s = String(value ?? '');
    // Preserve spreadsheet safety for text fields while keeping negative numbers numeric.
    const t = /^[\t\r\n]|^\s*[=+@]|^\s*-(?!\d+(?:[.,]\d+)?\s*$)/.test(s) ? "'" + s : s;
    return '"' + t.replaceAll('"', '""') + '"';
  }
  const cols = reportData.columns;
  const csv = [cols.map(col => cell(col.label)).join(','), ...reportData.rows.map(row => cols.map(col => cell(row[col.key])).join(','))].join('\r\n');
  const url = URL.createObjectURL(new Blob(['\uFEFF', csv], { type: 'text/csv;charset=utf-8' }));
  const a = document.createElement('a');
  a.href = url;
  a.download = 'LabTrack-' + reportData.code + '.csv';
  a.click();
  setTimeout(() => URL.revokeObjectURL(url), 500);
  toast('Đã tải CSV của trang báo cáo hiện tại.');
}
function setFormError(form, error) {
  const target = form?.querySelector('[data-form-error]') || dialog.querySelector('[data-form-error]');
  if (target) {
    target.textContent = error || '';
    target.hidden = !error;
  } else if (error) toast(error, true);
}
async function runForm(form, operation) {
  if (modalLock) return;
  modalLock = true;
  setFormError(form, null);
  const controls = [...dialog.querySelectorAll('button:not([disabled])')];
  for (const control of controls) control.disabled = true;
  try {
    const message = await operation();
    labsCache = undefined;
    modalLock = false;
    closeDialog();
    if (message) toast(message);
    await loadPage({ preserve: true });
  } catch (error) {
    setFormError(form, error.message);
    if (error.status === 401 && user) {
      user = null;
      labsCache = undefined;
      syncHeader();
    }
  } finally {
    modalLock = false;
    for (const control of controls) control.disabled = false;
  }
}
async function action(control) {
  const { action, id, label } = control.dataset;
  if (modalLock && action !== 'close-menu') return;
  switch (action) {
    case 'toggle-menu': {
      const open = document.body.classList.toggle('menu-open');
      document.querySelector('#menu-toggle')?.setAttribute('aria-expanded', String(open));
      break;
    }
    case 'close-menu': closeMenu(); break;
    case 'account': showAccount(); break;
    case 'close-dialog': closeDialog(); break;
    case 'demo-login': await doLogin(dialog.querySelector('[data-form="login"]'), { email: id + '@lab.local', password: 'DemoLab2026!' }); break;
    case 'logout': await runForm(dialog, async () => {
      await post('/auth/logout');
      user = null;
      reportData = null;
      catalog.clear();
      pointAllocations.clear();
      editableGrants.clear();
      return 'Đã đăng xuất.';
    }); break;
    case 'reload': await loadPage(); break;
    case 'clear-filters': go(current.page, current.params.has('code') ? new URLSearchParams({ code: current.params.get('code') }) : undefined); break;
    case 'paginate': {
      const params = currentParams();
      params.set('page', id);
      go(current.page, params);
      break;
    }
    case 'equipment-detail': await showEquipmentDetail(id); break;
    case 'grant-detail': await showGrantDetail(id); break;
    case 'chemical-detail': showChemicalDetail(id, label); break;
    case 'borrow': {
      const today = isoToday();
      modal('Mượn thiết bị', mutationForm('/borrows',
        field('Ngày dự kiến trả', input('expected_return_date', 'date', { min: today, value: today, required: true }), true),
        'Đã ghi nhận lượt mượn.', 'Xác nhận mượn', 'Thiết bị: ' + label, { equipment_id: id }));
      break;
    }
    case 'return': confirm('Trả thiết bị', 'Xác nhận đã trả: ' + label + '. Hệ thống sẽ ghi ngày trả hiện tại.', '/borrows/' + encodeURIComponent(id) + '/return', 'Đã ghi nhận trả thiết bị.'); break;
    case 'enter-lab': await showAccessForm(false); break;
    case 'approve-access': await showAccessForm(true); break;
    case 'exit-lab': confirm('Ghi giờ ra', 'Kết thúc lượt truy cập tại ' + label + '?', '/access-logs/' + encodeURIComponent(id) + '/exit', 'Đã ghi nhận giờ ra.'); break;
    case 'chemical-issue': await showChemicalForm(id, label, false); break;
    case 'chemical-receipt': await showChemicalForm(id, label, true); break;
    case 'chemical-location': {
      const chemical = catalog.get(String(id));
      if (!isAdmin() || chemical?.can_relocate !== true) return;
      await modalLoad('Đổi phòng lưu trữ', async () => {
        const rooms = await labs();
        const allowed = new Set(chemical.allowed_relocation_lab_ids?.map(String));
        const choices = rooms.filter(room => allowed.has(String(room.lab_id)));
        if (!choices.length) return () => modal('Đổi phòng lưu trữ', empty('Không có phòng phù hợp', 'Hãy tải lại danh sách để kiểm tra điều kiện lưu trữ mới nhất.', 'lock'));
        return () => modal('Đổi phòng lưu trữ', mutationForm('/chemicals/' + encodeURIComponent(id) + '/location',
          field('Phòng mới', select('lab_id', 'Phòng mới', labOptions(choices, false), '', true), true),
          'Đã cập nhật phòng lưu trữ.', 'Lưu thay đổi', 'Hóa chất: ' + label));
      });
      break;
    }
    case 'lab-safety': if (isAdmin()) await showRoomSafety(); break;
    case 'new-maintenance': await showMaintenanceForm(undefined, undefined, id); break;
    case 'complete-maintenance': await showMaintenanceForm(id, label); break;
    case 'new-point': {
      const grant = editableGrants.get(String(id));
      if (!canWrite() || !grant?.can_edit) return;
      const fields = field('Tên hạng mục', input('point_name', 'text', { maxlength: 200, required: true }), true) +
        field('Ngày bắt đầu', input('start_date', 'date', { required: true, min: grant.start_date, max: grant.end_date })) + field('Ngày kết thúc', input('end_date', 'date', { required: true, min: grant.start_date, max: grant.end_date })) +
        field('Trạng thái', select('status', 'Trạng thái hạng mục', ['Planned','Active','Completed','Suspended'].map(x => [x, status[x][0]]), 'Planned'), true) +
        field('Mô tả (không bắt buộc)', textArea('description', { limit: 1000, required: false }), true);
      modal('Thêm hạng mục', mutationForm('/grants/' + encodeURIComponent(id) + '/points', fields, 'Đã thêm hạng mục.', 'Thêm hạng mục', 'Đề tài: ' + label));
      break;
    }
    case 'grant-budget': {
      const grant = editableGrants.get(String(id));
      if (!isAdmin() || grant?.can_update_budget !== true) return;
      modal('Cập nhật ngân sách', mutationForm('/grants/' + encodeURIComponent(id) + '/budget',
        field('Ngân sách còn lại (đồng)', input('remaining_budget', 'number', { min: '0', max: grant.total_budget, step: '0.01', required: true, value: grant.remaining_budget }), true),
        'Đã cập nhật ngân sách.', 'Lưu ngân sách'));
      break;
    }
    case 'allocate-equipment': await showAllocation(id, label, false); break;
    case 'allocate-chemical': await showAllocation(id, label, true); break;
    case 'export-report': downloadReport(); break;
  }
}
document.addEventListener('click', event => {
  const pageLink = event.target.closest('[data-page]');
  if (pageLink && !event.ctrlKey && !event.metaKey && !event.shiftKey && !event.altKey) {
    event.preventDefault();
    go(pageLink.dataset.page, new URLSearchParams(pageLink.dataset.query || ''));
    return;
  }
  const control = event.target.closest('[data-action]');
  if (!control) return;
  event.preventDefault();
  action(control).catch(error => toast(error.message, true));
});
document.addEventListener('submit', event => {
  const form = event.target;
  if (!form.dataset.form) return;
  event.preventDefault();
  const data = Object.fromEntries([...new FormData(form)].map(([key, value]) => [key, String(value).trim()]));
  if (form.dataset.form === 'filters') {
    go(current.page, new URLSearchParams(Object.entries(data).filter(([, value]) => value)));
  } else if (form.dataset.form === 'login') {
    data.password = String(new FormData(form).get('password') || '');
    void doLogin(form, data);
  } else if (form.dataset.form === 'mutation') {
    void runForm(form, async () => {
      let endpoint = form.dataset.endpoint;
      if (endpoint.includes(':lab_id')) {
        endpoint = endpoint.replace(':lab_id', encodeURIComponent(data.lab_id));
        delete data.lab_id;
      }
      const result = await post(endpoint, Object.fromEntries(Object.entries(data).filter(([, value]) => value !== '')));
      const suffix = result?.movement_id
        ? ' Mã phiếu #' + result.movement_id + '. Tồn mới: ' + fmt(result.balance_after) + (result.unit ? ' ' + result.unit : '') + '.'
        : endpoint === '/access-logs/approved' && result?.log_id
          ? ' Lượt #' + result.log_id + ' nằm trong nhật ký của sinh viên.' : '';
      return form.dataset.success + suffix;
    });
  } else if (form.dataset.form === 'student-search') {
    const draft = dialog.querySelector('[data-form="mutation"]');
    const fields = draft ? Object.fromEntries(new FormData(draft)) : {};
    void showAccessForm(true, data.q, fields);
  }
});
dialog.addEventListener('cancel', event => { if (modalLock) event.preventDefault(); });
dialog.addEventListener('close', () => {
  modalSerial++;
  if (lastFocus?.isConnected) lastFocus.focus();
});
window.addEventListener('hashchange', () => {
  current = getRoute();
  closeDialog();
  void loadPage();
});
current = initialPage;
syncHeader();
try {
  user = await request('/auth/me');
} catch (error) {
  if (error.status !== 401) toast('Không thể kiểm tra phiên. Bạn vẫn có thể mở bản trình diễn.', true);
}
await loadPage();
