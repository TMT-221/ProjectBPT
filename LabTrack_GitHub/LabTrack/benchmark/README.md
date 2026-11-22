# Tái lập kết quả truy vấn và hiệu năng

Các tập lệnh chỉ tạo cơ sở dữ liệu trong bộ nhớ. Chúng không mở hoặc sửa thư mục `.data` đang dùng cho trình diễn.

Chạy tại thư mục `LabTrack`, sau khi đã có thư viện theo `package.json`:

```powershell
node benchmark/run_query_performance.mjs
node benchmark/export_dataset.mjs
node benchmark/run_nfr02.mjs
```

## Truy vấn trên bộ dữ liệu 1.200 bản ghi

`run_query_performance.mjs` nạp `sql/01_schema.sql`, `sql/02_dataset_1200.sql`, `sql/04_rbac.sql`; kiểm tra đủ 19 bảng, 98 cột, 1.200 bản ghi và tồn kho khớp sổ. Sau đó chạy `ANALYZE`, chuyển sang vai trò `lab_manager` và thực thi Q01–Q12 trong `sql/03_queries.sql`. Mỗi câu lệnh phải khớp tệp tương ứng trong `sql/queries/`. Đây là cùng bộ dữ liệu dùng để khởi tạo sản phẩm và lập bảng kết quả trong báo cáo; bộ 127 bản ghi chỉ phục vụ kiểm thử hồi quy nghiệp vụ.

Mỗi truy vấn làm nóng 3 lần; sau đó đo xen kẽ 15 lần gọi trực tiếp và 15 lần `EXPLAIN (ANALYZE, BUFFERS, FORMAT JSON)`. Tổng cộng có 180 mẫu trực tiếp và 180 mẫu kế hoạch. Trung vị lấy mẫu thứ 8 trong 15 mẫu tăng dần; p95 theo thứ hạng gần nhất lấy mẫu thứ 15. Kết quả từng lần gọi phải giống nhau.

Với mẫu thời gian đã sắp tăng dần `t(1) ≤ ... ≤ t(n)`, trung vị khi `n` lẻ là `t((n+1)/2)` và `p95 = t(ceil(0,95 × n))`. Thời gian phía gọi của lượt `i` là `t_i = thời điểm hoàn tất − thời điểm bắt đầu` (ms). Trung vị SQL áp dụng cùng công thức cho các giá trị `Execution Time`.

Thời gian phía máy khách đo bằng `performance.now()` gồm cầu nối JavaScript/WASM và tạo kết quả. `Execution Time` lấy từ PostgreSQL có chi phí thu thập kế hoạch. Hai phép đo được lưu và báo riêng.

Kết quả nằm trong `evidence/query_results.json` và `evidence/query_performance_results.json`: toàn bộ dữ liệu trả về, số dòng từng truy vấn và từng bảng nguồn, mẫu thời gian, kế hoạch đầu tiên, môi trường, ngày chạy và SHA-256 của dữ liệu/SQL trước và sau phép đo. Ngày tương đối được tính theo `Asia/Ho_Chi_Minh` tại ngày khởi tạo.

## Bộ tải theo NFR02

`run_nfr02.mjs` khởi tạo một bộ dữ liệu riêng gồm 100.000 thiết bị, đúng 30.000 thiết bị Available, 1.000.000 lượt truy cập và 10 phòng Normal. Các lượt truy cập thuộc giảng viên Active, trong giờ làm việc; mọi ràng buộc và trigger được giữ khi nạp. Đây là dữ liệu tổng hợp phục vụ phép đo, tách biệt với bộ 1.200 bản ghi trình diễn.

Hai truy vấn có tham số cố định: thiết bị theo `lab_id=1`, `current_status='Available'`, tối đa 20 dòng; lịch sử `lab_id=1` trong 30 ngày gần nhất, mới nhất trước, tối đa 50 dòng. Mỗi truy vấn làm nóng 10 lần rồi lấy 100 kế hoạch có `Execution Time`. p95 là mẫu thứ 95 trong 100 mẫu tăng dần. Ngưỡng so sánh SQL là dưới 200 ms. Thời gian phía máy khách được báo riêng.

`evidence/nfr02_embedded_results.json` chứa quy mô thực nạp, thời gian nạp, SQL/tham số, 100 mẫu, kế hoạch, thống kê bộ đệm và dữ liệu trả về. Kết quả xác nhận phép đo trên PGlite nhúng một kết nối và dữ liệu nóng. Nó không xác nhận PostgreSQL máy chủ, mạng, API, dữ liệu lạnh hoặc nhiều người dùng đồng thời.

## Dữ liệu mẫu 1.200 bản ghi

`export_dataset.mjs` nạp DDL và `sql/02_dataset_1200.sql` riêng, xuất đủ 19 bảng nghiệp vụ và 98 cột cơ sở vào `evidence/dataset_1200.json`. Giá trị ngày được thể hiện theo ngày khởi tạo; NULL được giữ nguyên. Tệp Word dữ liệu đi kèm được dựng từ chính bản xuất này. Trạng thái chứng nhận, trạng thái mượn trả và loại nhập/xuất là giá trị tính qua view, không xuất như cột cơ sở.
