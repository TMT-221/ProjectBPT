# Kiểm chứng gói GitHub

Gói dành cho [TMT-221/ProjectBPT](https://github.com/TMT-221/ProjectBPT), nhánh `main`. Việc kiểm chứng dưới đây thực hiện cục bộ bằng Node.js 24, với cơ sở dữ liệu thử riêng.

| Nội dung | Kết quả |
|---|---|
| Cài phụ thuộc từ gói sạch bằng `npm ci` | Thành công; PGlite được cố định trong `LabTrack/package-lock.json`. |
| `npm test` | 48/48 kết quả đạt, gồm 45 ca kiểm thử và 3 nhóm bao ngoài. |
| Đăng nhập qua HTTPS của proxy Codespaces | Origin hợp lệ được chấp nhận; cookie đăng nhập và đăng xuất có `Secure`. |
| Origin giả, header proxy giả và thiếu/sai CSRF | Bị từ chối; phiên hợp lệ vẫn hoạt động. |
| Tự khởi động và gọi lại lệnh khởi động | Thành công; gọi lại nhận ra máy chủ đang chạy. |
| Năm vai trò mẫu | Đăng nhập, đọc phiên và đăng xuất thành công qua tiến trình máy chủ thực tế. |
| Cơ sở dữ liệu của tiến trình thử | 19 bảng nghiệp vụ, 1.200 bản ghi, 98 cột cơ sở, 27 khóa ngoại. |
| Báo cáo | Giữ nguyên nội dung bản đã rà soát; 32 liên kết tệp tương đối có đích tồn tại trong gói. |

Cấu hình Codespaces và GitHub Actions đã được chuẩn bị. Chưa tạo Codespace hoặc chạy Actions trên GitHub trong lần kiểm chứng này; cần tải gói lên repository rồi mở bằng nút Codespaces để xác nhận môi trường GitHub thực tế. Xem [hướng dẫn thực hiện](HUONG_DAN_GITHUB.md).

Thư mục `LabTrack/evidence` và `LabTrack/test/results` giữ bằng chứng các lần chạy đã lưu cùng báo cáo. Kết quả kiểm chứng gói mới được ghi riêng tại [verification.json](verification.json); không thay thế số đo hiệu năng trong báo cáo.
