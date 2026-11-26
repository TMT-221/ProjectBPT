# UniLab — University Research & Lab Asset Tracker

**UniLab** là sản phẩm phần mềm quản lý phòng thí nghiệm và tài sản nghiên cứu đại học, được xây dựng trong khuôn khổ **Đề tài số 4 — môn Cơ sở dữ liệu** của **Nhóm BPT** (Học viện Công nghệ Bưu chính Viễn thông). Hệ thống số hóa toàn bộ quy trình quản lý đề tài nghiên cứu, thiết bị, kho hóa chất, chứng nhận an toàn, bảo trì và nhật ký ra vào phòng theo thời gian thực.

> **Cài đặt & khởi chạy chi tiết từng bước:** xem tại **[HUONG_DAN_CAI_DAT.md](./HUONG_DAN_CAI_DAT.md)**.

---

## 1. Thông tin dự án

| Hạng mục | Thông tin |
| --- | --- |
| **Đơn vị đào tạo** | Học viện Công nghệ Bưu chính Viễn thông — Khoa Công nghệ Thông tin |
| **Học phần** | Cơ sở dữ liệu (Học kỳ 1, năm học 2026–2027) |
| **Đề tài** | Đề tài số 4 — *University Research & Lab Asset Tracker* |
| **Tên sản phẩm** | **UniLab** — Hệ thống Quản lý Phòng thí nghiệm |
| **Giảng viên hướng dẫn** | Lê Hà Thanh |
| **Lớp** | `D24CQCN02-N` |
| **Nhóm thực hiện** | **Nhóm BPT** |

### Thành viên nhóm

| STT | Họ và tên | MSSV | Phụ trách chính |
| :---: | --- | :---: | --- |
| 1 | **Trần Minh Trọng** | `N24DCCN177` |
| 2 | **Nguyễn Trà Cao Quốc Bảo** | `N24DCCN096` |
| 3 | **Hoàng Gia Phúc** | `N24DCCN152` |

---

## 2. Mục tiêu & phạm vi sản phẩm

UniLab quản lý tập trung đề tài nghiên cứu, chủ nhiệm đề tài, hạng mục công việc, phòng thí nghiệm, thiết bị, hóa chất, chứng nhận an toàn và toàn bộ lịch sử vận hành trong môi trường đại học.

Mọi điều kiện an toàn và toàn vẹn dữ liệu (**8 nhóm yêu cầu chức năng `FR01–FR08`** và **28 quy tắc nghiệp vụ `BR01–BR28`**) được kiểm tra chặt chẽ ngay khi ghi dữ liệu và thực thi đồng bộ ở cả 3 tầng: **Cơ sở dữ liệu PostgreSQL → API Backend → Giao diện Web**.

### Các phân hệ chức năng chính

| Phân hệ | Mô tả & quy tắc nghiệp vụ trọng tâm |
| --- | --- |
| **Tổng quan & Không gian phòng** | Thống kê tỷ lệ thiết bị sẵn sàng, biểu đồ mượn trả theo quý, dòng hoạt động gần nhất và thẻ trạng thái từng phòng thí nghiệm kèm nút **Vào phòng / Ra khỏi phòng**. |
| **Đề tài nghiên cứu (`FR01`, `BR08–BR12`, `BR24`)** | Quản lý đề tài (chủ nhiệm là Giảng viên), hạng mục nghiên cứu, ngân sách và phân bổ thiết bị/hóa chất đúng phòng đã cấp; chặn phân bổ mới khi đề tài đã `Hoàn thành` hoặc `Tạm dừng`. |
| **Thiết bị & Mượn trả (`FR02–FR03`, `BR05`, `BR13–BR15`)** | Lọc thiết bị theo phòng/trạng thái, giới hạn tối đa **3 lượt mượn mở** (tính cả quá hạn), tự tính trạng thái `Quá hạn` theo ngày thực tế và **chặn mượn thiết bị thuộc phòng Hạn chế/Nguy hiểm** khi thiếu chứng nhận an toàn còn hiệu lực. |
| **Kho hóa chất (`FR05`, `BR06`, `BR17–BR20`)** | Ghi nhận nhập/xuất qua sổ kho bất biến (`chemical_movement`), tự đối chiếu tồn kho, chặn xuất hóa chất hết hạn, yêu cầu đủ chứng nhận cho hóa chất mức `Cao / Rất cao` và chỉ cho phép lưu hóa chất `Rất cao` trong phòng `Nguy hiểm`. |
| **Ra vào phòng thời gian thực (`FR04`, `BR04–BR05`, `BR21`, `BR23`, `BR27–BR28`)** | Vận hành theo giờ Việt Nam thực tế (`Asia/Ho_Chi_Minh`, `UTC+7`) kèm đồng hồ trên đầu trang; hỗ trợ **Vào phòng / Ra khỏi phòng** 1 bấm trên thẻ phòng, tự đóng lượt cũ khi chuyển phòng hoặc đăng xuất; thực thi khung giờ Sinh viên (`07:00–17:00`), lý do ngoài giờ Giảng viên (`< 06:00` hoặc `>= 22:00`), Kỹ thuật viên `24/7` và phê duyệt ngoài giờ. |
| **Chứng nhận & Bảo trì (`FR06`, `BR03`, `BR07`, `BR16`)** | Tự tính hiệu lực chứng nhận (`Còn hiệu lực / Hết hạn / Chưa hiệu lực`), cảnh báo sắp hết hạn trong 30 ngày; chỉ Kỹ thuật viên có quyền vận hành được mở/kết thúc phiếu bảo trì. |
| **Báo cáo & Truy vết (`FR07–FR08`, `Q01–Q12`)** | Cung cấp **12 báo cáo quản trị** theo phạm vi quyền (tài nguyên đề tài, thiết bị đang giữ, hóa chất sắp hết hạn, chứng nhận, lượt sử dụng phòng, chi phí bảo trì, đối chiếu sổ kho, phê duyệt ngoài giờ, xếp hạng sử dụng...), hỗ trợ lọc và xuất `CSV`. |

---

## 3. Kiến trúc kỹ thuật & thông số hệ thống

* **Cơ sở dữ liệu**: PostgreSQL chuẩn hóa `3NF/BCNF` chạy nhúng cục bộ qua **PGlite (`0.5.10`)** — không cần cài đặt PostgreSQL Server riêng.
  * Cấu trúc lược đồ `lab_tracker`: **19 bảng, 98 cột, 27 khóa ngoại, 7 view, 22 trigger, 18 hàm**.
  * Dữ liệu vận hành mẫu: **1.200 bản ghi** khởi tạo tự động ngay lần chạy đầu.
* **Backend & Frontend**:
  * Backend **Node.js (`>= 22`)** thuần ESM (không dùng framework nặng), tách rõ `server.mjs`, `api.mjs`, `db.mjs`, `backup_service.mjs`, `security_audit.mjs`.
  * Frontend **HTML5 / CSS3 / JavaScript** thuần, hiển thị rõ ràng trên máy tính và thiết bị di động.
* **Bảo mật & an toàn vận hành**:
  * Mật khẩu băm `scrypt`, phiên `HttpOnly + SameSite=Strict` (tự hết hạn sau 8 giờ hoặc 30 phút không thao tác).
  * Kiểm tra `CSRF`, `Origin`, truy vấn tham số hóa chống SQL Injection, phân quyền tối thiểu ở tầng CSDL (`lab_web_auth`, `lab_web_demo`).
  * Nhật ký bảo mật ghi bền vững (`JSONL`) và sao lưu/phục hồi dữ liệu mã hóa **`AES-256-GCM`**.
* **Kết quả kiểm chứng tự động**:
  * **67/67** ca kiểm thử quy tắc nghiệp vụ SQL (`BR01–BR28`) và **12/12** báo cáo (`Q01–Q12`).
  * **20/20** ca kiểm thử phân quyền & bảo mật tầng CSDL (`S01–S20`).
  * **48/48** ca kiểm thử HTTP API, nghiệm thu (`AT01–AT14`), bảo mật ứng dụng (`S21–S29`), sao lưu mã hóa và nâng cấp dữ liệu.
  * Hiệu năng truy vấn trên bộ tải `NFR02` (`100.000` thiết bị và `1.000.000` lượt ra vào) đạt mục tiêu `p95 < 200 ms`.

---

## 4. Tài khoản trình diễn

Mật khẩu chung cho các tài khoản mẫu là **`DemoLab2026!`** (có thể chọn nhanh ngay trên hộp thoại **Đăng nhập**):

| Vai trò | Email | Họ tên | Quyền & trạng thái mẫu |
| --- | --- | --- | --- |
| **Sinh viên** | `student@lab.local` | Bùi Thanh Lam | Chưa có chứng nhận an toàn; tự vào phòng Thường trong `07:00–17:00` |
| **Giảng viên** | `faculty@lab.local` | Nguyễn Minh An | Có chứng nhận cơ bản; chủ nhiệm đề tài `ĐT-2`; phê duyệt lượt vào |
| **Kỹ thuật viên** | `technician@lab.local` | Trần Bảo Ngọc | Đủ 3 chứng nhận an toàn; ra vào `24/7`; nhập kho hóa chất & bảo trì |
| **Quản trị nghiên cứu** | `admin@lab.local` | Trần Thu Bình | Đủ 3 chứng nhận; cập nhật ngân sách, điều chuyển hóa chất & mức an toàn phòng |
| **Kiểm toán viên** | `auditor@lab.local` | Lê Quang Chi | Chỉ xem dữ liệu và mở đầy đủ 12 báo cáo (`Q01–Q12`) |
| **Ngừng hoạt động** | `inactive@lab.local` | Đỗ Anh Minh | Tài khoản `Inactive` — dùng kiểm chứng chặn đăng nhập (`BR23`) |

---

## 5. Cấu trúc mã nguồn

```text
.
├── README.md                      # Thông tin dự án & giới thiệu sản phẩm
├── HUONG_DAN_CAI_DAT.md           # Hướng dẫn cài đặt và chạy từng bước
├── Mo-UniLab.cmd                  # Trình khởi chạy nhanh 1 cú nhấp trên Windows
├── package.json                   # Các lệnh setup / start / test / validate / security
├── .devcontainer/                 # Cấu hình môi trường chạy sẵn trên GitHub Codespaces
├── .github/workflows/verify.yml   # Kiểm thử tự động CI
└── UniLab/
    ├── server.mjs                 # Máy chủ HTTP/HTTPS, phiên đăng nhập, CSRF, nhật ký bảo mật
    ├── api.mjs                    # API nghiệp vụ, báo cáo Q01–Q12 và kiểm soát phạm vi dữ liệu
    ├── db.mjs                     # Khởi tạo PGlite, múi giờ Asia/Ho_Chi_Minh, nâng cấp dữ liệu
    ├── backup_service.mjs         # Sao lưu định kỳ & mã hóa AES-256-GCM
    ├── public/                    # Giao diện web (index.html, app.js, style.css, icons.js)
    ├── sql/                       # Lược đồ 01_schema.sql, dữ liệu 1.200 bản ghi, Q01–Q12
    └── test/                      # Bộ kiểm thử tự động SQL, RBAC, HTTP, bảo mật và sao lưu
```

---

## 6. Khởi chạy nhanh

Chi tiết cài đặt Node.js, tải ZIP, chạy trên macOS/Linux và xử lý lỗi xem đầy đủ tại **[HUONG_DAN_CAI_DAT.md](./HUONG_DAN_CAI_DAT.md)**.

* **Windows (tải ZIP):** giải nén toàn bộ → nhấp đúp **`Mo-UniLab.cmd`** (cần Node.js ≥ 22; lần đầu có mạng để tự cài `PGlite`).
* **Dòng lệnh (Windows / macOS / Linux):** chạy `npm run setup` (lần đầu) rồi `npm start`, mở `http://127.0.0.1:4173/`.
* **GitHub Codespaces:** bấm **Code → Codespaces → Create codespace on main** để chạy trực tiếp trên trình duyệt.
* **Kiểm thử tự động:** `npm test`, `npm run validate`, `npm run security`.
