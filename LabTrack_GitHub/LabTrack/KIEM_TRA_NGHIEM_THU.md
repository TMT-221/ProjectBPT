# Kết quả nghiệm thu LabTrack

SQL chuẩn hóa và sản phẩm Windows sử dụng chung bộ dữ liệu 1.200 bản ghi. Dữ liệu kiểm thử được khởi tạo riêng; dữ liệu ứng dụng đang sử dụng không bị thay đổi bởi bộ thử.

## Lược đồ và dữ liệu

Lược đồ nghiệp vụ có **19 bảng, 98 cột cơ sở, 27 khóa ngoại, 7 view, 22 trigger, 18 hàm và 15 chỉ mục tường minh**. Ứng dụng bổ sung các bảng xác thực trong schema `app_auth` và các hàm `web_*`; chúng được đếm riêng với lược đồ nghiệp vụ trong báo cáo. Khởi tạo mới, kết quả Q01–Q12 và phép đo 12 truy vấn cùng dùng **1.200 bản ghi**. Bộ **127 bản ghi** phục vụ kiểm thử nghiệp vụ và phân quyền riêng.

Trạng thái chứng nhận, trạng thái mượn trả và loại nhập/xuất được tính qua ba view tương ứng. Bộ thử xác nhận ba cột này không còn trong bảng cơ sở.

## Kiểm thử ứng dụng

[Log kiểm thử](test/results/api_acceptance.tap) và [kết quả JSON](test/results/api_acceptance.json) ghi nhận **45/45 mục kiểm thử đạt**, không bỏ qua mục nào. Tổng gồm 34 ca con và 11 mục cấp ngoài của bộ chạy Node.js; không cộng lại các ca con lần thứ hai. Môi trường là Node.js/PGlite trên Windows.

| Nhóm kiểm tra | Kết quả đã xác nhận |
|---|---|
| Dữ liệu và báo cáo | Khởi tạo mặc định đúng 1.200 bản ghi trên 19 bảng/98 cột; cả 12 báo cáo API đọc được theo quyền. Q09 trên API khớp các giá trị của truy vấn SQL quản trị chạy trên cùng dữ liệu. Bộ 127 bản ghi được kiểm thử riêng. |
| Mượn trả | Ghi nhận mượn/trả khớp trạng thái thiết bị; tối đa ba lượt chưa trả, tính cả lượt quá hạn; chặn mượn thiết bị không khả dụng. |
| Truy cập | Danh tính người phê duyệt theo phiên; sinh viên ngoài giờ cần phê duyệt; Restricted cần cơ bản, Hazardous cần đủ ba loại; chứng nhận hết hạn bị từ chối. |
| Faculty ngoài giờ | API từ chối lý do thiếu/rỗng/chỉ khoảng trắng và lưu lý do hợp lệ cùng mục đích. Phép thử API điều khiển riêng truy vấn đồng hồ; các biên giờ SQL được kiểm chứng trong bộ thử SQL. |
| Kho và bảo trì | Xuất kho cần đủ chứng nhận, phân bổ và số tồn; nhập/xuất khớp sổ, lỗi được rollback; chỉ kỹ thuật viên vận hành bảo trì. |
| Phân bổ và ngân sách | Chặn sai phòng, đề tài đã đóng, số dư âm/vượt tổng và lưu trữ Extreme sai mức an toàn. |
| Bảo mật | S21–S29: SQL Injection, danh sách cột sắp xếp, dữ liệu cá nhân, ngân sách, phiên, CSRF/Origin và thu hồi phiên; nhật ký bền vững không lưu bí mật; TLS và cookie Secure thực tế. |
| Sao lưu và nâng cấp | AES-256-GCM, mật khẩu sai/tệp bị sửa, snapshot nhất quán, lịch 23 giờ và giữ bảy bản; phục hồi đủ dữ liệu nghiệp vụ, tài khoản, quyền và phiên; không ghi đè thư mục có sẵn. Nâng cấp dữ liệu cũ giữ số dòng và giao dịch; mở lại không nạp trùng. |

Hai yêu cầu HTTP song song đã trả một thành công và một xung đột cho cùng thiết bị. Các yêu cầu này dùng **một PGlite**, chưa chứng minh hành vi khóa giữa hai kết nối PostgreSQL máy chủ.

## Bằng chứng SQL và hiệu năng

- [Kiểm thử nghiệp vụ và phân quyền](evidence/sql_validation_results.json)
- [Quyền dữ liệu nhạy cảm và GRANT/REVOKE, S13–S20 đạt 8/8](evidence/security_results.json)
- [Diễn tập phục hồi bản sao mã hóa trên 1.200 bản ghi](evidence/recovery_results.json)
- [Kiểm thử nâng cấp lược đồ nghiệp vụ](evidence/business_migration_results.json)
- [Kết quả 12 truy vấn quản trị](evidence/query_results.json)
- [Thời gian, kế hoạch thực thi và số liệu thô](evidence/query_performance_results.json)
- [Phép đo bộ tải NFR02 trong môi trường nhúng](evidence/nfr02_embedded_results.json)

Mỗi tệp ghi phạm vi, thời điểm và môi trường của lần chạy. Kết quả tải lớn trên PGlite được đánh giá trong môi trường nhúng, không suy rộng thành hiệu năng triển khai PostgreSQL máy chủ hoặc thời gian API qua mạng.

## Phạm vi còn mở

Hai kết nối PostgreSQL độc lập cho T14/H13 và một triển khai mạng công khai chưa được nghiệm thu. HTTPS đã được kiểm thử trên máy cục bộ bằng chứng thư thử; khi vận hành phải cấu hình chứng thư tin cậy. Lịch sao lưu đã được kiểm tra bằng đồng hồ điều khiển và chỉ hoạt động khi tiến trình mở.

Diễn tập thực tế đo tạo bản sao mã hóa 0,940 giây, phục hồi/đối chiếu 0,994 giây và tuổi snapshot tại sự cố 1,117 giây. Cả 1.200 bản ghi, sáu tài khoản và một phiên khớp giá trị băm; tồn khớp sổ. Đây là phục hồi vào bộ nhớ, chưa gồm thay thế dữ liệu vận hành hoặc khởi động lại máy chủ/giao diện, chưa xác nhận RPO/RTO liên tục cho môi trường máy chủ. Xem [bảo mật](SECURITY.md) và [phương pháp sao lưu/khôi phục](BACKUP.md).

Các nhật ký cũ được giữ nguyên khi nâng cấp. Chúng phản ánh chính sách tại thời điểm ghi; quy tắc BR05 hiện tại áp dụng cho thao tác ghi mới theo SQL đã cập nhật.
