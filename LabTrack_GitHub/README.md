# LabTrack — Quản lý phòng thí nghiệm và nghiên cứu

LabTrack hỗ trợ quản lý đề tài, phòng thí nghiệm, thiết bị, hóa chất và quyền sử dụng theo vai trò. Ứng dụng dùng PostgreSQL nhúng qua PGlite, khởi tạo **1.200 bản ghi trong 19 bảng nghiệp vụ**; không cần cài máy chủ PostgreSQL riêng.

[![Mở bằng GitHub Codespaces](https://github.com/codespaces/badge.svg)](https://codespaces.new/TMT-221/ProjectBPT?quickstart=1)

## Chạy trên GitHub

1. Đăng nhập GitHub, nhấn **Mở bằng GitHub Codespaces** ở trên và xác nhận tạo codespace.
2. Chờ vài phút để môi trường cài thư viện và khởi động ứng dụng. Lần đầu có thể lâu hơn.
3. Khi trình duyệt mở LabTrack, chọn **Đăng nhập**. Nếu chưa có trang ứng dụng, mở thẻ **PORTS**, tìm cổng **4173** rồi chọn **Open in Browser**. Giữ **Port Visibility: Private**.
4. Chọn tài khoản bên dưới; mật khẩu chung là **`DemoLab2026!`**.

Mỗi người tạo codespace riêng sẽ có cơ sở dữ liệu riêng, bắt đầu từ cùng 1.200 bản ghi. Repository công khai cho phép giảng viên xem mã nguồn và tạo codespace bằng tài khoản GitHub của mình, không cần lời mời cộng tác. Cổng ứng dụng riêng tư chỉ mở cho chủ codespace. Xem [hướng dẫn tạo codespace](https://docs.github.com/en/codespaces/developing-in-a-codespace/creating-a-codespace-for-a-repository) và [quản lý cổng](https://docs.github.com/en/codespaces/developing-in-a-codespace/forwarding-ports-in-your-codespace).

Nếu ứng dụng chưa chạy, mở **Terminal → New Terminal** tại thư mục gốc repository và nhập:

```bash
npm start
```

Giữ terminal đó mở trong khi sử dụng. Hướng dẫn đưa gói lên repository, xử lý lỗi và chạy trên Windows nằm trong [Hướng dẫn GitHub](docs/HUONG_DAN_GITHUB.md).

## Tài khoản và thao tác thử

| Vai trò | Tài khoản | Thao tác gợi ý |
|---|---|---|
| Sinh viên | `student@lab.local` | Vào **Thiết bị**, tìm **Bộ cảm biến môi trường**, mượn với ngày trả dự kiến hợp lệ; vào **Mượn trả của tôi** để trả. |
| Giảng viên | `faculty@lab.local` | Vào **Đề tài nghiên cứu** để xem đề tài phụ trách; tại **Ra vào phòng**, thử phê duyệt sinh viên vào phòng **Thông thường (Normal)**. |
| Kỹ thuật viên | `technician@lab.local` | Vào **Kho hóa chất**, chọn **Natri clorua** để nhập kho; thử xuất cho một hạng mục hợp lệ với lượng không vượt tồn kho. |
| Quản trị nghiên cứu | `admin@lab.local` | Mở đề tài, thử điều chỉnh ngân sách còn lại trong giới hạn tổng ngân sách. |
| Kiểm toán viên | `auditor@lab.local` | Mở **Báo cáo**, chạy truy vấn và xem kết quả; tài khoản này chỉ có quyền đọc. |

Thao tác phụ thuộc dữ liệu và quyền tại thời điểm sử dụng; các biểu mẫu hiển thị điều kiện cần đáp ứng. Đăng xuất trước khi đổi vai trò. Các tài khoản trên là tài khoản trình diễn dùng chung trong từng cơ sở dữ liệu mẫu.

## Chạy trên máy cá nhân

Cài **Node.js 24**, mở terminal tại thư mục gốc repository rồi chạy:

```bash
npm --prefix LabTrack ci
npm start
```

Truy cập [LabTrack cục bộ](http://127.0.0.1:4173/). Trên PowerShell, có thể dùng `npm.cmd` thay cho `npm` nếu chính sách chạy script chặn `npm.ps1`. Lần cài thư viện đầu tiên cần Internet; gói mã nguồn không kèm `node_modules`.

## Báo cáo và mã nguồn

| Nội dung | Tệp/thư mục |
|---|---|
| Báo cáo dự án | [ProjectDatabase.docx](ProjectDatabase.docx) |
| Bộ dữ liệu mô tả trong Word | [BPT_Du_lieu_mau_1200_ban_ghi.docx](BPT_Du_lieu_mau_1200_ban_ghi.docx) |
| Lược đồ và dữ liệu khởi tạo | [DDL](LabTrack/sql/01_schema.sql), [1.200 bản ghi SQL](LabTrack/sql/02_dataset_1200.sql) |
| Bộ truy vấn Q01–Q12 | [03_queries.sql](LabTrack/sql/03_queries.sql), [từng truy vấn](LabTrack/sql/queries) |
| Phân quyền và kiểm thử SQL | [04_rbac.sql](LabTrack/sql/04_rbac.sql), [05_tests.sql](LabTrack/sql/05_tests.sql) |
| Hướng dẫn ứng dụng | [LabTrack/README.md](LabTrack/README.md) |
| Bảo mật, API và sao lưu | [SECURITY.md](LabTrack/SECURITY.md), [API.md](LabTrack/API.md), [BACKUP.md](LabTrack/BACKUP.md) |

Giữ báo cáo và thư mục `LabTrack` cùng cấp khi tải về để các liên kết tệp tương đối trong báo cáo tiếp tục hoạt động.

## Kiểm chứng

Chạy các lệnh sau từ thư mục gốc sau khi đã cài thư viện:

```bash
npm test
npm run validate
npm run security
```

`npm test` kiểm tra ứng dụng và API. `validate` kiểm tra SQL trên các cơ sở dữ liệu thử độc lập, gồm bộ 1.200 bản ghi và Q01–Q12. `security` kiểm tra các quyền SQL nhạy cảm. Các phép thử không sửa dữ liệu bạn đang dùng trên giao diện.

[benchmark](LabTrack/benchmark) chứa mã đo; [evidence](LabTrack/evidence) chứa bằng chứng được lưu cùng báo cáo. Đây là kết quả của những lần chạy được ghi trong tệp, không phải số đo tự động của codespace mới. Phép thử đồng thời bằng PostgreSQL máy chủ tại [06_concurrency.mjs](LabTrack/sql/06_concurrency.mjs) cần môi trường PostgreSQL riêng.

## Dữ liệu và kết thúc phiên

Dữ liệu phát sinh nằm trong `LabTrack/.data` và được giữ khi dừng rồi mở lại **cùng codespace**. Xóa codespace sẽ xóa dữ liệu cục bộ; tải bản sao lưu về trước nếu cần giữ. Sau khi dùng, vào [Your codespaces](https://github.com/codespaces), chọn dấu **… → Stop codespace**. Xem [vòng đời codespace](https://docs.github.com/en/codespaces/about-codespaces/understanding-the-codespace-lifecycle).

Codespaces có hạn mức sử dụng theo tài khoản; thời gian chạy và dung lượng lưu trữ có thể phát sinh phí khi vượt hạn mức. Dừng codespace ngừng phần tính toán, còn dung lượng vẫn được tính khi codespace tồn tại. Kiểm tra [chính sách sử dụng và thanh toán của GitHub](https://docs.github.com/en/billing/concepts/product-billing/github-codespaces).

## Nhóm thực hiện

- Trần Minh Trọng — N24DCCN177
- Nguyễn Trà Cao Quốc Bảo — N24DCCN102
- Hoàng Gia Phúc — N24DCCN152
