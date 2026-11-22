# LabTrack

Ứng dụng quản lý đề tài nghiên cứu, phòng thí nghiệm, thiết bị và hóa chất của nhóm BPT. Lược đồ gồm **19 bảng nghiệp vụ, 98 cột cơ sở và 27 khóa ngoại**. Cơ sở dữ liệu mới nạp **1.200 bản ghi nghiệp vụ** từ `sql/02_dataset_1200.sql`; dữ liệu phát sinh được lưu trong `.data`.

## Chạy ứng dụng

Cách nhanh trên GitHub là nhấn **Mở bằng GitHub Codespaces** trong [README gốc](../README.md). Môi trường dùng Node.js 24, tự cài thư viện và khởi động ứng dụng; mở cổng **4173** ở thẻ **PORTS** với **Visibility: Private**. Xem [hướng dẫn đầy đủ](../docs/HUONG_DAN_GITHUB.md).

Để chạy cục bộ, cài Node.js 24 rồi nhập các lệnh sau trong thư mục `LabTrack`:

```bash
npm ci
npm start
```

Mở [LabTrack cục bộ](http://127.0.0.1:4173/) và giữ terminal máy chủ mở. Trên PowerShell, dùng `npm.cmd` nếu `npm.ps1` bị chặn. Sau khi cài thư viện, Windows cũng có thể chạy bằng `Mo-LabTrack.cmd`. Gói mã nguồn không kèm `node_modules`; lần cài đầu cần Internet. PostgreSQL chạy nhúng qua PGlite, không cần cài dịch vụ PostgreSQL riêng.

## Tài khoản mẫu

Mật khẩu chung: **`DemoLab2026!`**. Đăng xuất trước khi chuyển tài khoản.

| Vai trò | Tài khoản | Phạm vi sử dụng |
|---|---|---|
| Sinh viên | `student@lab.local` | Tra cứu, mượn/trả thiết bị; ghi lượt vào/ra; xem chứng nhận cá nhân. |
| Giảng viên | `faculty@lab.local` | Quản lý hạng mục và phân bổ tài sản cho đề tài phụ trách; phê duyệt sinh viên vào phòng. |
| Kỹ thuật viên | `technician@lab.local` | Nhập/xuất hóa chất, mở/kết thúc bảo trì; phê duyệt sinh viên vào phòng. |
| Quản trị nghiên cứu | `admin@lab.local` | Điều chỉnh ngân sách, mức an toàn và vị trí lưu trữ theo ràng buộc. |
| Kiểm toán viên | `auditor@lab.local` | Xem báo cáo và dữ liệu theo quyền; không ghi dữ liệu. |

Sinh viên có thể mượn **Bộ cảm biến môi trường** rồi trả tại **Mượn trả của tôi**. Kỹ thuật viên thử nhập/xuất **Natri clorua** với hạng mục hợp lệ; giảng viên thử phê duyệt sinh viên vào phòng **Thông thường (Normal)**. Quản trị nghiên cứu thử điều chỉnh ngân sách còn lại; kiểm toán viên xem **Báo cáo**. Máy chủ kiểm tra quyền và điều kiện nghiệp vụ khi xác nhận từng thao tác.

## Chính sách truy cập

- Phòng **Hạn chế (Restricted)** cần chứng nhận **An toàn phòng thí nghiệm cơ bản** còn hiệu lực.
- Phòng **Nguy hiểm (Hazardous)** cần đủ chứng nhận cơ bản, **Xử lý dung môi dễ cháy** và **Xử lý axit oxy hóa mạnh** còn hiệu lực.
- Sinh viên tự vào trong `[07:00,17:00)`; ngoài khoảng này cần giảng viên hoặc kỹ thuật viên phê duyệt.
- Giảng viên vào ngoài `[06:00,22:00)` phải nhập lý do ngoài giờ. Kỹ thuật viên được vào 24/7 và vẫn phải đáp ứng điều kiện an toàn.

Các mốc giờ nghiệp vụ dùng `Asia/Ho_Chi_Minh`. Trạng thái chứng nhận, trạng thái mượn trả và loại nhập/xuất được tính khi đọc qua khung nhìn (view); ứng dụng lưu dữ liệu gốc.

## Báo cáo, dữ liệu và SQL

- [Báo cáo dự án](../ProjectDatabase.docx) và [bộ dữ liệu trong Word](../BPT_Du_lieu_mau_1200_ban_ghi.docx).
- [Lược đồ](sql/01_schema.sql), [dữ liệu khởi tạo 1.200 bản ghi](sql/02_dataset_1200.sql), [Q01–Q12](sql/03_queries.sql), [phân quyền](sql/04_rbac.sql) và [kiểm thử SQL](sql/05_tests.sql).
- [Hợp đồng API](API.md), [hồ sơ nghiệm thu](KIEM_TRA_NGHIEM_THU.md), [bảo mật](SECURITY.md) và [sao lưu/khôi phục](BACKUP.md).

Báo cáo trên giao diện áp dụng phạm vi quyền của tài khoản. `sql/03_queries.sql` chứa truy vấn quản trị toàn cục dùng cho báo cáo học phần. Cả hai dùng cùng dữ liệu khởi tạo 1.200 bản ghi. `sql/02_seed.sql` gồm 127 bản ghi, dùng riêng cho kiểm thử nghiệp vụ và phân quyền trong cơ sở dữ liệu thử độc lập.

## Kiểm chứng

Chạy trong thư mục `LabTrack`:

```bash
npm test
node sql/run_validation.mjs
node sql/run_security.mjs
```

`npm test` kiểm tra API, SQL Injection, quyền dữ liệu, nhật ký, HTTPS, sao lưu và nâng cấp. Hai lệnh tiếp theo kiểm chứng SQL, dữ liệu và quyền SQL. Các phép thử sử dụng cơ sở dữ liệu riêng. Để lưu kết quả HTTP/PGlite tại `test/results`, chạy `node test/run_validation.mjs`.

Thư mục [benchmark](benchmark) chứa mã đo; [evidence](evidence) chứa bằng chứng đã lưu cùng báo cáo. Kết quả trong đó thuộc lần chạy được mô tả trong tệp, không phải kết quả tự động của máy hoặc codespace hiện tại. Phép thử đồng thời tại `sql/06_concurrency.mjs` cần PostgreSQL máy chủ và mô-đun `pg`, được thực hiện riêng.

## Dữ liệu và sao lưu

Trong Codespaces, mở lại cùng codespace giữ dữ liệu; xóa codespace sẽ xóa dữ liệu cục bộ. Cơ sở dữ liệu, nhật ký và bản sao lưu không đưa vào Git. Để sao lưu thủ công, dừng máy chủ rồi chạy trong thư mục `LabTrack`:

```bash
node backup.mjs save labtrack-backup.labbackup
node backup.mjs verify labtrack-backup.labbackup
```

Tải bản sao lưu về máy nếu cần giữ trước khi xóa codespace. Ứng dụng có cơ chế sao lưu tự động khi khởi động và theo chu kỳ khi đang chạy; xem [BACKUP.md](BACKUP.md) về vị trí lưu, mã hóa và khôi phục. Hướng dẫn HTTPS nằm trong [SECURITY.md](SECURITY.md).
