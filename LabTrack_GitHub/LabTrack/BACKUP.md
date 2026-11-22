# Sao lưu và phục hồi LabTrack

Khi máy chủ đang mở, LabTrack tạo bản sao đầu tiên nếu chưa có bản hợp lệ; kiểm tra mỗi 15 phút và tạo bản mới khi bản gần nhất đã 23 giờ. Thư mục mặc định là `.backups`, có thể đổi bằng `LABTRACK_BACKUP_DIR`. Hệ thống giữ bảy bản tự động gần nhất; chỉ xóa tệp mang đúng tên `labtrack-<thời-gian>-<mã-ngẫu-nhiên>.labbackup` trong thư mục này. Các tệp không thuộc mẫu tên quản lý và dữ liệu `.data` không bị xóa.

Chu kỳ 23 giờ dành khoảng dự phòng trước mục tiêu RPO 24 giờ. Tác vụ chỉ chạy khi tiến trình ứng dụng hoạt động. Máy ngủ, tiến trình dừng, ổ đĩa đầy hoặc lỗi ghi có thể làm bản sao quá hạn; đây không phải cam kết RPO vận hành 24/7. Không có tác vụ lịch hệ điều hành được cài đặt. Lỗi sao lưu được báo ở cửa sổ máy chủ.

## Nội dung và bảo vệ bản sao

Mỗi bản chứa cơ sở dữ liệu nghiệp vụ, tài khoản, mật khẩu đã băm, quyền và phiên đăng nhập. Giá trị băm SHA-256 tổng hợp được dùng để đối chiếu toàn bộ dữ liệu khi phục hồi; tồn kho cũng được đối chiếu với sổ nhập xuất. Bản sao cơ sở dữ liệu không bao gồm tệp nhật ký bảo mật JSONL bên ngoài.

Nếu đặt `LABTRACK_BACKUP_PASSPHRASE` có ít nhất 12 ký tự trước khi mở máy chủ, bản sao được mã hóa bằng AES-256-GCM với khóa scrypt, salt và nonce ngẫu nhiên cho từng tệp. Sai mật khẩu hoặc thay đổi tệp mã hóa sẽ bị từ chối. Khi không đặt biến này, nội dung bản sao không được mã hóa; SHA-256 phát hiện hỏng dữ liệu nhưng không thay thế xác thực mật mã.

Có thể nhập mật khẩu trong PowerShell mà không hiện ra màn hình:

```powershell
$secret = Read-Host 'Mật khẩu sao lưu' -AsSecureString
$credential = [PSCredential]::new('backup', $secret)
$env:LABTRACK_BACKUP_PASSPHRASE = $credential.GetNetworkCredential().Password
node server.mjs
```

Sau khi dừng máy chủ, xóa biến khỏi phiên PowerShell bằng `Remove-Item Env:LABTRACK_BACKUP_PASSPHRASE`. Không lưu mật khẩu vào mã nguồn, báo cáo hoặc thư mục sao lưu; giữ một bản bí mật riêng để có thể giải mã sau sự cố. Giới hạn quyền NTFS của `.data`, `.backups` và bản sao xuất ra cho tài khoản vận hành. Chế độ tệp 0600/thư mục 0700 là yêu cầu trên hệ hỗ trợ POSIX, không thay thế cấu hình ACL trên Windows. Bản sao cùng ổ đĩa không bảo vệ khi cả ổ bị mất; cần chép bản đã mã hóa sang thiết bị hoặc kho riêng.

## Tạo và kiểm tra thủ công

Dừng máy chủ trước khi dùng lệnh thủ công để tránh hai tiến trình cùng mở `.data`. Các lệnh sau chạy từ thư mục `LabTrack`:

```powershell
node backup.mjs save ban-sao.labbackup
node backup.mjs verify ban-sao.labbackup
node backup.mjs drill ban-sao.labbackup
```

`save` dùng thư mục dữ liệu hiện hành, hoặc đường dẫn `LABTRACK_DATA_DIR` nếu có. Lệnh từ chối ghi đè tệp đã tồn tại. `verify` và `drill` phục hồi vào cơ sở dữ liệu trong bộ nhớ, kiểm tra đầy đủ bảng nghiệp vụ, tài khoản/quyền/phiên và tồn kho; không ghi vào `.data`. Đặt cùng `LABTRACK_BACKUP_PASSPHRASE` khi đọc bản đã mã hóa. Tệp gzip cũ vẫn được `verify`/`drill` chấp nhận. `save ten.tar.gz` không có mật khẩu giữ định dạng gzip cũ; bản này không có mốc snapshot và manifest đối chiếu như định dạng mới.

## Phục hồi sang thư mục mới

1. Dừng máy chủ; giữ nguyên `.data` hiện hành và bản sao lưu.
2. Kiểm tra bản sao bằng `verify`.
3. Chạy `node backup.mjs restore ban-sao.labbackup .data-phuc-hoi`. Tên đích phải chưa tồn tại; lệnh không xóa hoặc thay thế thư mục cũ.
4. Đặt `$env:LABTRACK_DATA_DIR = (Resolve-Path '.data-phuc-hoi').Path`, mở lại `node server.mjs`, rồi kiểm tra đăng nhập, báo cáo và sổ kho. Chỉ chuyển sử dụng bản phục hồi sau khi đã xác nhận kết quả.

Nếu lỗi ghi xảy ra, giữ thư mục phục hồi dở dang để kiểm tra và chọn một thư mục đích mới khi thử lại. Không dùng bản sao như tệp tải xuống công khai vì nó chứa thông tin tài khoản và phiên.

## Diễn tập và công thức đánh giá

`node benchmark/run_recovery.mjs` tạo cơ sở dữ liệu riêng với 1.200 bản ghi nghiệp vụ và một phiên thử; sao lưu có mã hóa, tạo một thay đổi sau snapshot rồi phục hồi bản sao vào bộ nhớ. Khóa thử được tạo ngẫu nhiên, không lưu lại. Kết quả thực chạy nằm trong `evidence/recovery_results.json`.

- Tuổi dữ liệu tại sự cố: `RPO_quan_sát = thời_điểm_sự_cố − mốc_dữ_liệu_snapshot`.
- Thời gian phục hồi đo: `RTO_diễn_tập = thời_điểm_sẵn_sàng_đã_kiểm_chứng − thời_điểm_bắt_đầu_phục_hồi`.
- Mục tiêu NFR04: `RPO ≤ 24 giờ` và `RTO ≤ 2 giờ`.

Thời gian diễn tập gồm đọc/giải mã tệp, tạo cơ sở dữ liệu phục hồi và đối chiếu toàn bộ bản ghi; không gồm phục hồi hệ điều hành, thay thế thư mục vận hành, khởi động lại giao diện hoặc xác nhận nghiệp vụ của người dùng. Tuổi snapshot trong một lần thử gần thời điểm sao lưu không chứng minh hệ thống đã duy trì RPO 24 giờ liên tục. Phép đo trên 1.200 bản ghi không bảo đảm RTO ở quy mô dữ liệu lớn hơn.

## Lưu ý khi nâng cấp thư viện

Tác vụ sao lưu sử dụng mutex `_runExclusiveTransaction` của PGlite 0.5.10 để chờ giao dịch đang thực thi kết thúc trước khi chụp dữ liệu. Đây là API nội bộ phụ thuộc phiên bản; khi đổi PGlite phải chạy lại bộ thử sao lưu, đặc biệt ca ghi đồng thời và phục hồi. Manifest được tính từ chính archive đã phục hồi riêng, tránh việc băm dữ liệu đang tiếp tục thay đổi trên ứng dụng.
