# Lược đồ SQL và cách kiểm chứng

Phiên bản bàn giao sử dụng PostgreSQL và PL/pgSQL. Múi giờ nghiệp vụ là `Asia/Ho_Chi_Minh`; tiền tệ là VND. Lược đồ nghiệp vụ có 19 bảng, 98 cột cơ sở, 27 khóa ngoại, 7 khung nhìn, 22 trigger và 18 hàm. Các đối tượng `app_auth` và hàm `web_*` của ứng dụng được cài đặt riêng.

## Tạo cơ sở dữ liệu mới

Thực thi bằng tài khoản sở hữu lược đồ trên một cơ sở dữ liệu trống:

1. `01_schema.sql`: tạo lược đồ, bảng, ràng buộc, hàm, trigger, view và 15 chỉ mục tường minh.
2. `02_dataset_1200.sql`: nạp đúng 1.200 bản ghi dùng chung cho sản phẩm, kết quả Q01–Q12 và phép đo 12 truy vấn trong báo cáo.
3. `04_rbac.sql`: thiết lập các vai trò cơ sở dữ liệu và quyền truy cập.
4. `03_queries.sql`: thực thi 12 truy vấn quản trị. Thư mục `queries/` chứa từng truy vấn Q01–Q12 để đọc và chạy riêng.
Tệp `05_tests.sql` gồm 64 ca kiểm thử ràng buộc, sử dụng `02_seed.sql` gồm 127 bản ghi trong một cơ sở dữ liệu kiểm thử riêng. Các thao tác thử được hoàn tác; không nạp chồng hai bộ dữ liệu.

Chạy `node sql/run_validation.mjs` từ thư mục ứng dụng để tạo hai cơ sở dữ liệu PGlite trong bộ nhớ và lưu `evidence/sql_validation_results.json`. Bộ 127 bản ghi phục vụ 64 kiểm thử nghiệp vụ và 12 kiểm thử phân quyền. Bộ 1.200 bản ghi được đối soát tồn kho và chạy đủ Q01–Q12 bằng vai trò `lab_manager`. Các cơ sở dữ liệu trong bộ nhớ được đóng khi hoàn tất; dữ liệu ứng dụng không bị thay đổi.

## Các thuộc tính dẫn xuất

Ba giá trị không còn lưu trong bảng cơ sở:

| Giá trị | Khung nhìn cung cấp |
| --- | --- |
| Trạng thái chứng nhận | `v_certification_current.status` |
| Trạng thái mượn trả | `v_borrow_current.status` |
| Loại nhập/xuất hóa chất | `v_chemical_movement.movement_type` |

Thao tác ghi gửi dữ liệu gốc; ứng dụng đọc trạng thái qua các view. `faculty_id`, `student_id` và `technician_id` được giữ nguyên; mỗi khóa cũng tham chiếu `person.person_id`.

## Chính sách truy cập

BR05 được kiểm tra theo từng loại chứng nhận. Phòng Restricted yêu cầu “An toàn phòng thí nghiệm cơ bản”. Phòng Hazardous yêu cầu đồng thời chứng nhận cơ bản, “Xử lý dung môi dễ cháy” và “Xử lý axit oxy hóa mạnh”. Từng chứng nhận phải thỏa `issue_date <= ngày vào <= expiry_date`; thiếu loại trong danh mục hoặc thiếu chứng nhận còn hiệu lực đều bị từ chối. Phòng Normal không bắt buộc chứng nhận.

Sinh viên được tự vào trong `[07:00,17:00)`; ngoài khoảng này cần một Faculty hoặc Technician Active khác phê duyệt. Faculty có khung giờ `[06:00,22:00)`; ngoài giờ phải nêu lý do tại `purpose`. SQL kiểm tra lý do không rỗng; giao diện và API thu lý do riêng theo ngữ cảnh. Hệ thống không suy diễn ngữ nghĩa của văn bản tự do. Technician được truy cập 24/7 nhưng vẫn phải đáp ứng trạng thái Active và BR05.

Các dòng nhật ký trong bộ dữ liệu mẫu được phân phòng phù hợp với tập chứng nhận của người tham gia. Dữ liệu lịch sử đã có từ bản cũ được giữ nguyên khi nâng cấp, không viết lại để giả lập việc đã đáp ứng chính sách mới.

## Nâng cấp dữ liệu cũ

Ứng dụng tự chạy `07_upgrade_normalized.sql` trong một giao dịch khi mở cơ sở dữ liệu cũ. Tập lệnh loại ba cột dẫn xuất, thay các hàm liên quan và bổ sung chính sách truy cập hiện hành. Không nạp lại dữ liệu mẫu và không xóa nhật ký. Có thể chạy lại tập lệnh này trên lược đồ đã chuẩn hóa.

Khi thực thi thủ công, dừng ứng dụng, sao lưu dữ liệu và chạy tập lệnh bằng chủ sở hữu lược đồ trong `BEGIN`/`COMMIT`; sau đó áp dụng phần tích hợp và quyền của ứng dụng.

## Kiểm thử đồng thời PostgreSQL máy chủ

`06_concurrency.mjs` kiểm tra T14/H13 bằng hai kết nối độc lập và quan sát cạnh tranh khóa. Tập lệnh cần PostgreSQL máy chủ, gói Node `pg` và biến `DATABASE_URL` trỏ tới cơ sở dữ liệu kiểm thử riêng đã nạp `01_schema.sql` + `02_seed.sql`. Tập lệnh tạo giao dịch lịch sử trong cơ sở dữ liệu kiểm thử.

Kết quả PGlite một kết nối không thay thế kết quả T14/H13. Chỉ ghi nhận kiểm thử đồng thời đã đạt khi tệp kết quả có `executed: true`, quan sát chờ khóa và cả hai ca đạt.
