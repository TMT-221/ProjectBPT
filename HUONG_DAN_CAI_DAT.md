# Hướng dẫn cài đặt và chạy UniLab từng bước

Tài liệu này hướng dẫn chi tiết cách tải mã nguồn **UniLab** từ GitHub và khởi chạy ứng dụng web trên máy cá nhân hoặc trực tiếp trên GitHub Codespaces.

> **Điểm tiện lợi:** UniLab dùng **PGlite** (PostgreSQL nhúng trực tiếp trong Node.js), nên bạn **không cần cài PostgreSQL Server, không cần Docker và không cần tạo cơ sở dữ liệu thủ công**.

---

## 1. Yêu cầu trước khi bắt đầu

* **Node.js phiên bản 22 trở lên** (khuyên dùng bản LTS 22 hoặc 24).
* **Trình duyệt web hiện đại** (Chrome, Edge, Firefox hoặc Safari).
* **Kết nối Internet ở lần chạy đầu tiên** (khoảng 10–20 giây) để tự động tải duy nhất thư viện `@electric-sql/pglite`. Từ lần chạy thứ 2 trở đi có thể dùng hoàn toàn ngoại tuyến.

---

## 2. Cài đặt Node.js (nếu máy chưa có)

Kiểm tra nhanh xem máy đã có Node.js chưa bằng cách mở **Command Prompt / PowerShell** (Windows) hoặc **Terminal** (macOS/Linux) và gõ:

```bash
node -v
```

* Nếu hiện kết quả từ **`v22.x.x`** trở lên (ví dụ `v24.19.0`) → bỏ qua bước này, chuyển sang **Mục 3**.
* Nếu báo chưa có lệnh `node` hoặc phiên bản thấp hơn `v22`:
  1. Truy cập [https://nodejs.org](https://nodejs.org).
  2. Tải bộ cài **LTS** (khuyên dùng phiên bản 22 hoặc 24).
  3. Chạy tệp cài đặt và bấm **Next** giữ nguyên thiết lập mặc định cho tới khi hoàn tất.
  4. **Đóng rồi mở lại** cửa sổ Terminal/PowerShell, gõ lại `node -v` để xác nhận đã đạt từ `v22` trở lên.

---

## 3. Cách 1 (Khuyên dùng cho Windows): Tải ZIP và mở bằng 1 cú nhấp

### Bước 1: Tải mã nguồn từ GitHub
1. Mở trang GitHub của dự án UniLab.
2. Bấm nút xanh **`<> Code`** → chọn **`Download ZIP`**.

### Bước 2: Giải nén toàn bộ tệp ZIP
1. Chuột phải vào tệp `.zip` vừa tải → chọn **`Extract All...`** *(Giải nén tất cả)*.
2. Chọn thư mục đích (ví dụ `Downloads\UniLab`) và bấm **Extract**.

> **Lưu ý quan trọng:** Phải giải nén xong mới chạy. Không nhấp mở tệp `.cmd` trực tiếp bên trong cửa sổ xem trước của tệp `.zip`.

### Bước 3: Khởi chạy UniLab
1. Mở thư mục vừa giải nén (bên trong có tệp **`Mo-UniLab.cmd`** và thư mục **`UniLab`**).
2. Nhấp đúp vào tệp **`Mo-UniLab.cmd`**.
   * Nếu Windows SmartScreen hiện cảnh báo *"Windows protected your PC"*: bấm **`More info`** *(Thông tin thêm)* → bấm **`Run anyway`** *(Vẫn chạy)*.
3. Ở lần chạy đầu tiên, cửa sổ dòng lệnh sẽ tự động:
   * Kiểm tra phiên bản Node.js (`>= 22`).
   * Tải và cài thư viện `@electric-sql/pglite`.
   * Khởi tạo lược đồ 19 bảng cùng bộ dữ liệu mẫu 1.200 bản ghi vào thư mục `UniLab\.data`.
   * Tự mở trình duyệt web tới địa chỉ **`http://127.0.0.1:4173/`**.
4. **Giữ cửa sổ dòng lệnh mở** trong suốt quá trình sử dụng web. Khi muốn tắt ứng dụng, đóng cửa sổ này hoặc nhấn **`Ctrl + C`**.

---

## 4. Cách 2 (Windows / macOS / Linux): Chạy bằng dòng lệnh

Phù hợp khi dùng `git clone` hoặc chạy trên macOS / Linux:

### Bước 1: Lấy mã nguồn
* Tải ZIP và giải nén như Mục 3, **hoặc** dùng Git:
  ```bash
  git clone <URL_REPO_GITHUB>
  cd <TEN_THU_MUC_REPO>
  ```

### Bước 2: Cài thư viện (chỉ cần chạy 1 lần đầu)
```bash
npm run setup
```
*(Lệnh này tương đương `npm --prefix UniLab ci --no-audit --no-fund`.)*

### Bước 3: Khởi chạy máy chủ web
```bash
npm start
```
Khi màn hình hiện:
```text
UniLab • http://127.0.0.1:4173
```
Hãy mở trình duyệt và truy cập **`http://127.0.0.1:4173/`**.

---

## 5. Cách 3: Chạy ngay trên GitHub Codespaces (không cần cài đặt)

Nếu không muốn cài Node.js trên máy cá nhân:
1. Mở trang GitHub của dự án.
2. Bấm nút xanh **`<> Code`** → chuyển sang tab **`Codespaces`**.
3. Bấm **`Create codespace on main`**.
4. Chờ khoảng 1–2 phút để GitHub tự cài thư viện và khởi động máy chủ UniLab; khi thấy thông báo cổng `4173` sẵn sàng, bấm **`Open in Browser`** để mở web.

---

## 6. Đăng nhập và trải nghiệm nhanh

1. Trên giao diện web UniLab, bấm nút **Đăng nhập** ở góc trên bên phải.
2. Chọn nhanh một tài khoản trình diễn (hoặc nhập email và mật khẩu **`DemoLab2026!`**):
   * **Sinh viên (`student@lab.local`)**: chưa có chứng nhận an toàn — thử lọc **Thiết bị** theo *Phòng phản ứng hóa học* hoặc vào **Ra vào phòng** để thấy hệ thống chặn phòng thiếu chứng nhận (`BR05`) và chặn tự vào ngoài khung `07:00–17:00` (`BR04`).
   * **Giảng viên (`faculty@lab.local`)**: có chứng nhận cơ bản — thử vào phòng thường/hạn chế (tự ghi nhận nhật ký theo giờ Việt Nam thực tế; nếu sau `22:00` hoặc trước `06:00` sẽ bắt buộc nhập lý do ngoài giờ theo `BR27`), phê duyệt lượt vào cho sinh viên và thêm hạng mục cho đề tài `ĐT-2`.
   * **Kỹ thuật viên (`technician@lab.local`)**: có đủ 3 chứng nhận — bấm **Vào phòng** rồi chuyển sang phòng khác để thấy hệ thống tự ghi giờ ra cho phòng cũ; nhập/xuất hóa chất và tạo phiếu bảo trì thiết bị.
   * **Quản trị nghiên cứu (`admin@lab.local`)**: cập nhật ngân sách đề tài, đổi phòng hóa chất chưa phân bổ và kiểm tra chặn hạ mức an toàn phòng đang chứa hóa chất `Rất cao` (`BR20`).
   * **Kiểm toán viên (`auditor@lab.local`)**: chỉ đọc dữ liệu và mở đầy đủ **12 báo cáo (`Q01–Q12`)**, tải kết quả ra tệp `CSV`.

---

## 7. Dừng ứng dụng, làm mới dữ liệu và chạy kiểm thử

* **Dừng ứng dụng**: nhấn `Ctrl + C` trong cửa sổ dòng lệnh (hoặc đóng cửa sổ `Mo-UniLab.cmd`).
* **Làm mới dữ liệu về trạng thái ban đầu**:
  1. Dừng UniLab trước.
  2. Xóa thư mục `UniLab/.data` (và `UniLab/.logs` nếu muốn xóa nhật ký cũ).
  3. Mở lại `Mo-UniLab.cmd` (hoặc chạy `npm start`) — hệ thống sẽ tự tạo lại bộ dữ liệu mẫu 1.200 bản ghi mới nhất tính theo ngày hiện tại.
* **Chạy bộ kiểm thử tự động**:
  ```bash
  npm test          # Kiểm thử HTTP API, nghiệm thu, bảo mật web, sao lưu và nâng cấp
  npm run validate  # Kiểm thử 67 quy tắc nghiệp vụ SQL, 12 ca bảo mật SQL và 12 báo cáo
  npm run security  # Kiểm thử 8 ca bảo mật phân quyền RBAC trên CSDL
  ```

---

## 8. Xử lý sự cố thường gặp

| Tình huống | Cách khắc phục |
| --- | --- |
| Báo *"Không tìm thấy đủ tệp nguồn"* | Bạn đang mở `Mo-UniLab.cmd` trực tiếp bên trong tệp `.zip`. Hãy giải nén toàn bộ `.zip` ra thư mục riêng rồi chạy lại. |
| Báo *"Chưa tìm thấy Node.js"* hoặc phiên bản `< 22` | Cài đặt Node.js phiên bản 22 trở lên tại [nodejs.org](https://nodejs.org), đóng cửa sổ cũ rồi mở lại `Mo-UniLab.cmd`. |
| Lỗi cài đặt `@electric-sql/pglite` ở lần chạy đầu | Kiểm tra kết nối Internet hoặc tắt tạm VPN/proxy rồi mở lại `Mo-UniLab.cmd` (hoặc chạy `npm run setup`). |
| Báo *"Cổng 4173 đang được chương trình khác sử dụng"* | Đóng ứng dụng đang dùng cổng `4173`, hoặc đổi cổng bằng lệnh PowerShell `$env:LABTRACK_PORT=4174; npm start` (CMD: `set LABTRACK_PORT=4174 && Mo-UniLab.cmd`). |
| Giao diện trình duyệt chưa hiện thay đổi mới sau khi cập nhật mã | Khởi động lại máy chủ UniLab, sau đó nhấn **`Ctrl + F5`** trên trình duyệt để tải lại trang sạch bộ nhớ đệm. |
