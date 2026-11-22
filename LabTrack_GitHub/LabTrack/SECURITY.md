# Bảo mật LabTrack

LabTrack dùng phân quyền SQL kết hợp kiểm tra quyền tại API. Máy chủ lắng nghe trên `127.0.0.1` khi chạy cục bộ và trong Codespaces. Các tài khoản trình diễn chỉ sử dụng dữ liệu mẫu; không nhập dữ liệu cá nhân, thông tin bí mật hoặc thông tin xác thực thật vào môi trường demo.

## Chạy trong GitHub Codespaces

GitHub cung cấp HTTPS bên ngoài cho cổng chuyển tiếp; kết nối từ proxy tới máy chủ loopback dùng HTTP. Giữ cổng **4173** ở chế độ **Private** để chỉ chủ codespace truy cập. Ứng dụng xác định địa chỉ gốc chuẩn (canonical origin) từ các biến môi trường Codespaces tin cậy, kiểm tra Origin/CSRF theo địa chỉ này và đặt cookie `Secure` khi người dùng truy cập qua HTTPS của GitHub. Máy chủ không tin cậy tùy ý các header `X-Forwarded-*` do yêu cầu gửi tới. Không cần dùng chứng thư kiểm thử để mở ứng dụng qua Codespaces.

Mỗi codespace có cơ sở dữ liệu và tài khoản mẫu riêng. Repository công khai giúp người khác tạo môi trường riêng; không đồng nghĩa với việc công khai cổng ứng dụng đang chạy. Xem [cơ chế chuyển tiếp cổng của GitHub](https://docs.github.com/en/codespaces/developing-in-a-codespace/forwarding-ports-in-your-codespace).

## Kiểm soát đã triển khai

| Phạm vi | Cơ chế |
|---|---|
| Quyền dữ liệu | DAC/RBAC, cấp quyền theo bảng/cột/view; tách `lab_web_auth` và `lab_web_demo`; chặn ghi trực tiếp tồn kho và chứng từ. |
| Phạm vi người dùng | API lấy danh tính từ phiên, lọc lịch sử cá nhân và giới hạn ngân sách theo chủ nhiệm/quản trị. Không dùng RLS. |
| Xác thực | Mật khẩu băm scrypt với salt riêng; mã phiên ngẫu nhiên chỉ lưu dạng băm SHA-256; thu hồi phiên khi đăng xuất. |
| Phiên | Hết hạn sau 8 giờ hoặc 30 phút không hoạt động; cookie `HttpOnly`, `SameSite=Strict`, thêm `Secure` khi chạy HTTPS. |
| Đầu vào | Tham số SQL, danh sách cột/hướng sắp xếp cho phép, kiểm tra kiểu/giới hạn; CSRF và Origin cho thao tác ghi; giới hạn đăng nhập sai. |
| Nhật ký | Ghi nối tiếp JSONL, đồng bộ xuống tệp; ghi đăng nhập, từ chối quyền, ghi API và sao lưu. Không lưu mật khẩu, cookie, mã phiên, CSRF hoặc nội dung yêu cầu. |
| Sao lưu | Chụp nhất quán; kiểm tra bằng bản phục hồi riêng; lịch 23 giờ khi ứng dụng chạy, giữ bảy bản; mã hóa AES-256-GCM khi có mật khẩu sao lưu. |

Nhật ký mặc định ở `.logs/security-events.jsonl`; có thể đổi bằng `LABTRACK_AUDIT_FILE`. Tệp không có API sửa/xóa; người quản trị hệ điều hành vẫn có thể sửa hoặc xóa tệp. Cần bảo vệ thư mục dữ liệu, nhật ký và bản sao bằng quyền của hệ điều hành. Thư mục `.data` đang chạy không được ứng dụng mã hóa.

## HTTPS tùy chọn

Đặt đồng thời `LABTRACK_TLS_CERT` và `LABTRACK_TLS_KEY` trỏ tới tệp PEM chứng thư/khóa riêng, rồi mở ứng dụng. Máy chủ sử dụng TLS từ 1.2 và in URL `https://127.0.0.1:4173/`. Chứng thư phải được máy người dùng tin cậy và phù hợp địa chỉ truy cập. Nếu chỉ đặt một biến, ứng dụng từ chối khởi động. Không đưa khóa riêng vào Git.

Chứng thư trong `test/fixtures/tls/` chỉ phục vụ kiểm thử tự động, không dùng cho triển khai. Mặc định HTTP chỉ phục vụ loopback; kiểm thử HTTPS cục bộ không chứng minh an toàn của một triển khai công khai.

## Sao lưu và phục hồi

Đặt `LABTRACK_BACKUP_PASSPHRASE` với ít nhất 12 ký tự để mã hóa các bản sao mới. Mật khẩu này cần được giữ riêng để có thể phục hồi; không ghi vào mã nguồn. Xem [hướng dẫn sao lưu](BACKUP.md) để cấu hình thư mục, tạo bản sao thủ công và phục hồi sang thư mục mới.

Lịch tự động dừng khi tiến trình đóng. Diễn tập trên 1.200 bản ghi xác nhận dữ liệu nghiệp vụ, tài khoản, quyền và phiên được khôi phục đúng; thời gian đo chưa gồm khởi động lại máy chủ/giao diện hoặc khắc phục hệ điều hành. Kết quả này không xác nhận RPO/RTO liên tục của một hệ thống vận hành.

## Chạy kiểm chứng

```powershell
node test/run_validation.mjs
node sql/run_validation.mjs
node sql/run_security.mjs
node benchmark/run_recovery.mjs
```

Các phép thử dùng CSDL riêng; không sửa `.data` đang sử dụng. Kết quả nằm ở `test/results/` và `evidence/`:

- SQL nghiệp vụ/phân quyền: S01–S12 cùng 64 ca nghiệp vụ trong `sql_validation_results.json`.
- Quyền dữ liệu nhạy cảm và GRANT/REVOKE: S13–S20 trong `security_results.json`.
- HTTP/SQL Injection: S21–S29; nhật ký, HTTPS, mã hóa và lịch sao lưu trong `api_acceptance.json`/`.tap`.
- Diễn tập phục hồi: `recovery_results.json`.

Các ca T14/H13 với hai kết nối PostgreSQL máy chủ chưa được thực hiện. Sản phẩm không triển khai phân lớp bí mật MAC; chính sách hiện tại dùng DAC/RBAC và kiểm tra tại API.
