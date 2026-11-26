# UniLab — Hệ thống Quản lý Phòng thí nghiệm

**UniLab** là ứng dụng web quản lý đề tài nghiên cứu, thiết bị, kho hóa chất, chứng nhận an toàn và nhật ký ra vào phòng thí nghiệm. Toàn bộ 28 quy tắc nghiệp vụ (`BR01–BR28`) được thực thi đồng bộ ở cả ba tầng **Cơ sở dữ liệu PostgreSQL (trigger, ràng buộc, view, hàm) → API Backend → Giao diện Web**.

Hệ thống sử dụng **PGlite** (PostgreSQL chạy nhúng cục bộ trong Node.js) nên người dùng tải về từ GitHub có thể chạy trực tiếp ngay trên máy mà **không cần cài đặt PostgreSQL Server hay Docker**.

> **Hướng dẫn cài đặt từng bước:** xem chi tiết tại [HUONG_DAN_CAI_DAT.md](./HUONG_DAN_CAI_DAT.md).

---

## Tính năng nổi bật

* **Quản lý đề tài & phân bổ nguồn lực (`BR08–BR12`, `BR24`)**: theo dõi đề tài, chủ nhiệm, hạng mục nghiên cứu, ngân sách và ràng buộc phân bổ thiết bị/hóa chất đúng phòng đã cấp cho đề tài đang hoạt động.
* **Quản lý thiết bị, mượn trả & bảo trì (`BR05`, `BR13–BR16`)**: tra cứu theo phòng và trạng thái, tự động cập nhật trạng thái `Khả dụng / Đang sử dụng / Đang bảo trì`, giới hạn tối đa 3 lượt mượn mở (tính cả lượt quá hạn), tự tính trạng thái quá hạn (`Overdue`) theo ngày thực tế và chặn mượn thiết bị thuộc phòng `Hạn chế / Nguy hiểm` khi thiếu chứng nhận an toàn.
* **Kho hóa chất theo sổ kho bất biến (`BR06`, `BR17–BR20`)**: ghi nhận nhập kho (kỹ thuật viên) và xuất kho theo hạng mục nghiên cứu, tự động đối chiếu tồn kho, chặn xuất hóa chất hết hạn, kiểm tra đầy đủ chứng nhận bắt buộc cho hóa chất mức `Cao / Rất cao` và bảo đảm hóa chất `Rất cao` chỉ lưu trong phòng `Nguy hiểm`.
* **Ra vào phòng theo thời gian thực (`BR04`, `BR05`, `BR21`, `BR23`, `BR27`, `BR28`)**:
  * Vận hành theo đồng hồ thời gian thực múi giờ Việt Nam (`Asia/Ho_Chi_Minh`, `UTC+7`) với đồng hồ hiển thị trực tiếp trên thanh đầu trang.
  * Nút **Vào phòng / Ra khỏi phòng** trực tiếp trên từng thẻ phòng, tự động đóng lượt cũ khi chuyển sang phòng khác và tự ghi giờ ra khi đăng xuất.
  * Áp dụng đúng khung giờ: Sinh viên tự vào `07:00–17:00` (ngoài giờ cần giảng viên/kỹ thuật viên phê duyệt), Giảng viên vào trước `06:00` hoặc từ `22:00` trở đi phải nêu lý do ngoài giờ, Kỹ thuật viên ra vào `24/7`.
* **12 báo cáo quản trị (`Q01–Q12`)**: tổng hợp đề tài, lượt mượn, hóa chất sắp hết hạn, chứng nhận, lượt dùng phòng, chi phí bảo trì, đối chiếu sổ kho, phê duyệt ngoài giờ và xếp hạng sử dụng thiết bị; hỗ trợ lọc dữ liệu và xuất tệp `CSV`.
* **Bảo mật & sao lưu dữ liệu**: mật khẩu băm `scrypt`, cookie phiên `HttpOnly` + `SameSite=Strict`, kiểm tra `CSRF` & `Origin`, truy vấn tham số hóa chống SQL Injection, phân quyền tối thiểu ở tầng CSDL, nhật ký bảo mật bền vững và sao lưu/phục hồi mã hóa `AES-256-GCM`.

---

## Chạy nhanh

Xem hướng dẫn chi tiết từng bước (kèm cách cài Node.js và xử lý lỗi) tại **[HUONG_DAN_CAI_DAT.md](./HUONG_DAN_CAI_DAT.md)**.

### Cách 1: Tải ZIP trên Windows (1 cú nhấp)
1. Bấm **Code → Download ZIP** trên GitHub và **giải nén toàn bộ thư mục**.
2. Đảm bảo máy đã cài **Node.js 22 trở lên** ([nodejs.org](https://nodejs.org)).
3. Nhấp đúp tệp **`Mo-UniLab.cmd`** (lần đầu cần kết nối mạng khoảng 10–20 giây để tự tải thư viện `PGlite`; các lần sau chạy ngoại tuyến).
4. Trình duyệt sẽ tự mở tại **`http://127.0.0.1:4173/`**.

### Cách 2: Chạy bằng dòng lệnh (Windows / macOS / Linux)
```bash
npm run setup
npm start
```
Sau đó mở trình duyệt tại **`http://127.0.0.1:4173/`**.

### Cách 3: Mở trực tiếp trên GitHub Codespaces (không cần cài trên máy)
Bấm **Code → Codespaces → Create codespace on main** — môi trường sẽ tự cài đặt thư viện, khởi chạy máy chủ và chuyển tiếp cổng `4173`.

---

## Tài khoản trình diễn

Tất cả tài khoản dưới đây dùng chung mật khẩu **`DemoLab2026!`** (cũng có thể bấm chọn nhanh vai trò ngay trên hộp thoại **Đăng nhập**):

| Vai trò | Email | Họ tên | Quyền & chứng nhận mẫu |
| --- | --- | --- | --- |
| **Sinh viên** | `student@lab.local` | Bùi Thanh Lam | Chưa có chứng nhận an toàn (vào phòng Thường `07:00–17:00`, bị chặn phòng Hạn chế/Nguy hiểm) |
| **Giảng viên** | `faculty@lab.local` | Nguyễn Minh An | Có chứng nhận cơ bản; chủ nhiệm đề tài `ĐT-2`; quản lý hạng mục & phê duyệt lượt vào |
| **Kỹ thuật viên** | `technician@lab.local` | Trần Bảo Ngọc | Đủ 3 chứng nhận an toàn; vào mọi phòng `24/7`; nhập kho hóa chất & bảo trì thiết bị |
| **Quản trị nghiên cứu** | `admin@lab.local` | Trần Thu Bình | Đủ 3 chứng nhận; cập nhật ngân sách, điều chuyển hóa chất & mức an toàn phòng |
| **Kiểm toán viên** | `auditor@lab.local` | Lê Quang Chi | Chỉ xem dữ liệu và mở đầy đủ 12 báo cáo (`Q01–Q12`) |
| **Ngừng hoạt động** | `inactive@lab.local` | Đỗ Anh Minh | Dùng kiểm chứng `BR23` — bị hệ thống từ chối đăng nhập |

---

## Kiến trúc & cấu trúc thư mục

* **Cơ sở dữ liệu**: lược đồ chuẩn hóa `lab_tracker` gồm **19 bảng, 98 cột, 27 khóa ngoại, 7 view, 22 trigger, 18 hàm** và bộ dữ liệu mẫu **1.200 bản ghi** khởi tạo tự động vào thư mục cục bộ `UniLab/.data/`.
* **Công nghệ**: Node.js `>= 22` (ESM thuần), `@electric-sql/pglite` `0.5.10`, HTML5 / CSS3 / JavaScript thuần (không dùng framework giao diện ngoài).

```text
.
├── Mo-UniLab.cmd                  # Trình khởi chạy nhanh trên Windows
├── README.md                      # Giới thiệu tổng quan sản phẩm
├── HUONG_DAN_CAI_DAT.md           # Hướng dẫn cài đặt & sử dụng từng bước
├── package.json                   # Các lệnh setup / start / test / validate / security
├── .devcontainer/                 # Cấu hình chạy sẵn trên GitHub Codespaces
├── .github/workflows/verify.yml   # Quy trình kiểm thử tự động CI
└── UniLab/
    ├── server.mjs                 # Máy chủ HTTP/HTTPS, xác thực phiên, CSRF, nhật ký bảo mật
    ├── api.mjs                    # API nghiệp vụ, báo cáo Q01–Q12 và kiểm soát phạm vi dữ liệu
    ├── db.mjs                     # Khởi tạo PGlite, múi giờ Asia/Ho_Chi_Minh, nâng cấp lược đồ
    ├── backup_service.mjs         # Sao lưu định kỳ và mã hóa AES-256-GCM
    ├── public/                    # Giao diện web (index.html, app.js, style.css, icons.js)
    ├── sql/                       # Lược đồ 01_schema.sql, dữ liệu 1.200 bản ghi, truy vấn Q01–Q12
    └── test/                      # Bộ kiểm thử tự động SQL, RBAC, HTTP, bảo mật và sao lưu
```

---

## Kiểm thử tự động

Sau khi chạy `npm run setup`, có thể chạy toàn bộ bộ kiểm thử tự động:

```bash
npm test          # 48 ca kiểm thử HTTP, nghiệm thu AT01–AT14, bảo mật S21–S29, sao lưu & nâng cấp
npm run validate  # 67 ca kiểm thử quy tắc nghiệp vụ SQL, 12 ca bảo mật S01–S12, 12 báo cáo Q01–Q12
npm run security  # 8 ca kiểm thử cô lập quyền và tính toàn vẹn RBAC SQL (S13–S20)
```
