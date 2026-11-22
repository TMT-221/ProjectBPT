# Hợp đồng API LabTrack

Tiền tố `/api/v1`. Các kết quả bên dưới là trường `data` của phản hồi thành công. Mã BIGINT và giá trị thập phân truyền dưới dạng chuỗi. Ngày `YYYY-MM-DD`, thời điểm ISO 8601 `+07:00`.

## Xác thực và phiên làm việc

| Phương thức và đường dẫn | Yêu cầu | Kết quả |
|---|---|---|
| `POST /auth/login` | JSON gồm `email`, `password` | HTTP 200; trả `person_id`, `name`, `role`, `email`, `permissions`, `csrf` và đặt cookie phiên. |
| `GET /auth/me` | Cookie phiên hợp lệ | HTTP 200; trả thông tin tài khoản và mã CSRF của phiên. |
| `POST /auth/logout` | Cookie phiên và `X-CSRF-Token` | HTTP 204; xóa phiên phía máy chủ và hết hạn cookie. |

Cookie có `HttpOnly`, `SameSite=Strict` và thêm `Secure` khi dùng HTTPS. Phiên hết hạn sau tối đa tám giờ hoặc 30 phút không hoạt động. Các yêu cầu POST sau đăng nhập phải gửi `X-CSRF-Token` lấy từ phản hồi xác thực; nếu gửi `Origin`, giá trị phải khớp giao thức, máy và cổng của máy chủ.

HTTP 401 biểu thị đăng nhập sai hoặc phiên không hợp lệ; 403 biểu thị thiếu quyền, CSRF sai hoặc Origin không hợp lệ; 429 biểu thị giới hạn số lần đăng nhập. Phản hồi lỗi có dạng `{error:{code,message},request_id}`. Cấu hình HTTPS, nhật ký và phạm vi bảo vệ được mô tả trong [hướng dẫn bảo mật](SECURITY.md).

## Tra cứu dữ liệu

| GET | Dữ liệu trả về |
|---|---|
| `/preview` | Tổng quan cho bản dùng thử chưa đăng nhập, với số liệu tổng hợp và mô tả hoạt động không định danh. |
| `/dashboard` | `{stats,labs,activities,borrow_chart}`. Chỉ số: equipment_total, equipment_available, open_borrows, active_grants, chemicals_expiring, certifications_expiring, labs_total. Labs như /labs. Activities: `{type,title,subtitle,date,status}`. Biểu đồ: `{label,total,returned}`. |
| `/labs` | Danh sách phòng và `can_enter`, `entry_block_reason`, `requires_out_of_hours_reason`, `can_change_safety`, `allowed_safety_levels` theo tài khoản. BR05 đối chiếu đúng loại chứng nhận và hiệu lực. |
| `/equipment` | Trang thiết bị; lọc q (tên, seri), lab_id, status/current_status. |
| `/equipment/:id` | Thiết bị, lịch sử và `can_borrow`, `borrow_block_reason`, `can_start_maintenance`. |
| `/grants` | Trang đề tài; lọc q, status, principal_investigator_id, from, to. Ngân sách chỉ trả về chủ nhiệm/quản trị. Có can_edit. |
| `/grants/:id` | Đề tài, `labs`, `points`, `can_edit` và `can_update_budget`. |
| `/chemicals` | Trang kho; lọc q, lab_id, hazard_level, expiry/status; mỗi dòng có `can_issue`, `issue_block_reason`, `can_receive`, `can_relocate`, `relocation_block_reason`, `allowed_relocation_lab_ids`. |
| `/chemicals/:id/points` | Mảng hạng mục đã được phân bổ hóa chất, thuộc đề tài Active; có grant_title. |
| `/me/borrows` | Trang mượn trả, chỉ của phiên; lọc status `open`, `closed`, `overdue`; actual_return_date nhận ngày chính xác, `null` hoặc `not_null`. |
| `/me/access` | Trang lượt vào phòng, chỉ của phiên; lọc status `open`, `closed`. |
| `/me/certifications` | Trang chứng nhận, chỉ của phiên; có cert_name, issuing_authority, status/effective_status; lọc `valid`, `expiring`, `expired`. |
| `/maintenance` | Trang bảo trì, có can_complete của phiên; lọc status `open`, `closed` hoặc equipment_id. |
| `/students` | Tối đa 20 sinh viên Active cho cán bộ duyệt, tìm theo tên/mã. `has_valid_lab_certification` cho biết đủ chứng nhận cơ bản cho Restricted; `has_hazardous_lab_certification` cho biết đủ cả ba loại cho Hazardous. Không trả chi tiết chứng nhận, email hay điện thoại. |
| `/reports` | Mảng `{code,title,description,filters}`; từng báo cáo được giới hạn quyền hoặc phạm vi bản ghi. |
| `/reports/:code` | `{code,title,description,filters,columns:[{key,label}],rows,total,page,page_size}`. from bao gồm, to không bao gồm đối với báo cáo hỗ trợ lọc ngày. |

Trang danh sách là `{rows,total,page,page_size}` (mặc định 20, tối đa 100). Các trường gốc dùng tên cột SQL; một số bản ghi có lab_name, equipment_name, principal_investigator, status/effective_status, can_complete. Bộ lọc q không phân biệt chữ hoa/chữ thường. Các trang danh sách nghiệp vụ chấp nhận `sort` theo các cột mô tả của từng danh sách, ví dụ `equipment_name` hoặc `-expiry_date` (giảm dần); không chấp nhận biểu thức SQL. Báo cáo giữ thứ tự được định nghĩa sẵn.

## Cập nhật dữ liệu

| POST | Trường nhận |
|---|---|
| `/borrows` | equipment_id, expected_return_date |
| `/borrows/:id/return` | Không có |
| `/access-logs` | lab_id, purpose; Faculty ngoài `[06:00,22:00)` gửi thêm `out_of_hours_reason` không rỗng. API ghép lý do vào purpose, không thêm cột lưu trữ. |
| `/access-logs/approved` | visitor_id, lab_id, purpose; chỉ cán bộ |
| `/access-logs/:id/exit` | Không có |
| `/chemical-issues` | chemical_id, rearch_point_id, quantity, reason |
| `/chemical-receipts` | chemical_id, quantity, reason; chỉ kỹ thuật viên vận hành |
| `/maintenance` | equipment_id, description, cost; chỉ kỹ thuật viên vận hành |
| `/maintenance/:id/complete` | description, cost; nếu bỏ trống dùng nội dung hiện có |
| `/grants/:id/points` | point_name, description (tùy chọn), start_date, end_date, status (mặc định Planned) |
| `/points/:id/equipment-allocations` | equipment_id |
| `/points/:id/chemical-allocations` | chemical_id |
| `/grants/:id/budget` | remaining_budget; chỉ quản trị nghiên cứu |
| `/chemicals/:id/location` | lab_id; chỉ quản trị nghiên cứu |
| `/labs/:id/safety` | safety_level (`Normal`, `Restricted`, `Hazardous`); chỉ quản trị nghiên cứu |

Thao tác ghi mượn/trả, ra/vào, nhập/xuất và bảo trì gọi hàm SQL đã chuẩn hóa. Phiên xác thực quyết định người thao tác; API không chấp nhận trường danh tính tùy ý. Chỉ chủ nhiệm hoặc quản trị được thêm hạng mục/phân bổ khi đề tài đang Active. Hạng mục phải có khoảng ngày nằm trong đề tài. Gắn hóa chất vào hạng mục không thay đổi tồn kho. Các cập nhật ngân sách và lưu trữ vẫn chịu CHECK và trigger.

Ba giá trị dẫn xuất được đọc từ `v_certification_current`, `v_borrow_current` và `v_chemical_movement`; API không ghi `has_certification.status`, `borrow_transaction.status` hoặc `chemical_movement.movement_type`. Phòng Restricted yêu cầu đúng chứng nhận cơ bản; Hazardous yêu cầu đủ cả ba loại theo BR05, từng loại thỏa `issue_date ≤ ngày vào ≤ expiry_date`. Ngoài giờ Faculty, API yêu cầu một lý do riêng đã loại khoảng trắng đầu/cuối và ghi cùng mục đích. SQL bảo đảm mục đích không rỗng; nội dung lý do tự do do người dùng cung cấp.

`/reports/Q01`–`Q12` là phiên bản phục vụ giao diện, áp dụng phạm vi quyền; Q02/Q04 chỉ trả dữ liệu cá nhân. Bộ truy vấn quản trị toàn cục và kết quả học phần nằm trong `sql/03_queries.sql`. Q10 chấp nhận trường hợp đề tài Active chưa có hạng mục Active theo logic lượng từ.

Các cờ `can_*` và danh sách lựa chọn phục vụ giao diện dựa trên trạng thái tại thời điểm đọc. API và cơ sở dữ liệu kiểm tra lại quyền và ràng buộc khi ghi.
