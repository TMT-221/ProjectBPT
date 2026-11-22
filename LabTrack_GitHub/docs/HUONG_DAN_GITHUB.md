# Đưa LabTrack lên GitHub và chạy thử

Repository sử dụng: [TMT-221/ProjectBPT](https://github.com/TMT-221/ProjectBPT). Hướng dẫn này dùng **GitHub Codespaces** để chạy ứng dụng trong trình duyệt. GitHub lưu mã nguồn; codespace cung cấp môi trường chạy Node.js và cơ sở dữ liệu riêng.

## 1. Đưa gói mã nguồn lên repository

### Chuẩn bị repository hiện có

1. Đăng nhập tài khoản **TMT-221** và mở repository **ProjectBPT** đang công khai.
2. Repository hiện có `Readme.md`. Mở tệp này, chọn **Edit file**, đổi tên thành **README.md** rồi lưu commit. Khi tải gói mới, thay nội dung bằng README mới để chỉ giữ một tệp giới thiệu.
3. Giữ các PDF và ảnh EER hiện có để đối chiếu; báo cáo hiện hành trong gói này là `ProjectDatabase.docx`.

Repository công khai cho phép người khác xem mã nguồn và báo cáo mà không cần được thêm vào nhóm cộng tác. Để chạy bằng Codespaces, mỗi người cần đăng nhập GitHub bằng tài khoản của mình.

### Tải đúng nội dung gói

1. Giải nén gói `LabTrack_GitHub.zip`, mở thư mục `LabTrack_GitHub` đã giải nén.
2. Trong File Explorer, bật **View → Show → Hidden items** nếu cần. Kiểm tra có cả `.devcontainer`, `.github` và `.gitignore`.
3. Trên trang repository, chọn **Add file → Upload files**; với repository trống, chọn **uploading an existing file**.
4. Kéo **nội dung bên trong** `LabTrack_GitHub` vào vùng tải lên. Không tải riêng tệp ZIP và không bọc thêm một thư mục `LabTrack_GitHub` ở gốc repository.
5. Nhập lời nhắn commit, chẳng hạn `Add LabTrack demo and report`, rồi chọn **Commit changes**. Nếu vượt giới hạn 100 tệp mỗi lượt của trình duyệt, chia hai lượt: tải thư mục `LabTrack` trước, rồi tải các tệp/thư mục ở gốc còn lại.

Cấu trúc ở gốc repository phải có dạng:

```text
ProjectBPT/
├── .devcontainer/
│   ├── devcontainer.json
│   └── start.mjs
├── .github/
├── docs/
│   └── HUONG_DAN_GITHUB.md
├── LabTrack/
│   ├── public/
│   ├── sql/
│   ├── test/
│   ├── package.json
│   ├── package-lock.json
│   └── server.mjs
├── .gitignore
├── package.json
├── README.md
├── ProjectDatabase.docx
└── BPT_Du_lieu_mau_1200_ban_ghi.docx
```

Không tải `node_modules`, `.data`, `.logs`, `.backups`, tệp `.env` hoặc bản sao lưu chứa dữ liệu phát sinh. Thư viện sẽ được cài bằng `package-lock.json` khi tạo codespace. Giữ báo cáo cùng cấp với thư mục `LabTrack` để không làm hỏng liên kết tương đối.

Nếu trình duyệt không tải đủ thư mục cấu hình hoặc từ chối tệp workflow trong `.github/workflows`, dùng Git thay cho upload. Với repository đã có, clone về máy rồi chép nội dung gói vào thư mục vừa clone, giữ thư mục `.git` của repository:

```bash
git clone https://github.com/TMT-221/ProjectBPT.git
cd ProjectBPT
# Chép nội dung đã giải nén vào thư mục này trước khi chạy ba lệnh dưới.
git add .
git commit -m "Add LabTrack demo and report"
git push
```

Nếu Git yêu cầu xác thực, hoàn tất đăng nhập GitHub theo hướng dẫn hiển thị; không ghi thông tin xác thực vào mã nguồn. Xem [hướng dẫn thêm tệp của GitHub](https://docs.github.com/en/repositories/working-with-files/managing-files/adding-a-file-to-a-repository).

## 2. Mở ứng dụng bằng Codespaces

1. Mở [ProjectBPT](https://github.com/TMT-221/ProjectBPT), chọn **Code → Codespaces → Create codespace on main**. Bạn cũng có thể nhấn nút **Mở bằng GitHub Codespaces** trong README.
2. Chờ môi trường tạo xong. Cấu hình dự án cài Node.js 24, cài thư viện bằng `npm ci` và tự khởi động LabTrack mỗi lần codespace mở lại. Lần đầu thường cần vài phút.
3. Nếu trang LabTrack chưa tự mở, chọn thẻ **PORTS** ở phía dưới, tìm **4173** rồi nhấn biểu tượng **Open in Browser**.
4. Giữ **Port Visibility: Private**. Giao thức nội bộ của cổng là **HTTP**; trình duyệt truy cập bằng đường dẫn HTTPS do Codespaces cung cấp.
5. Tại LabTrack, chọn **Đăng nhập**, dùng tài khoản mẫu trong [README](../README.md#tài-khoản-và-thao-tác-thử), mật khẩu chung `DemoLab2026!`.

Mỗi codespace mới có cơ sở dữ liệu riêng gồm đúng 1.200 bản ghi nghiệp vụ lúc khởi tạo. Thao tác trong codespace của giảng viên không sửa dữ liệu trong codespace của nhóm. Cổng Private thuộc về chủ codespace; giảng viên nên mở codespace của mình từ repository, không dùng đường dẫn cổng riêng của nhóm. Xem [tạo codespace](https://docs.github.com/en/codespaces/developing-in-a-codespace/creating-a-codespace-for-a-repository) và [cổng chuyển tiếp](https://docs.github.com/en/codespaces/developing-in-a-codespace/forwarding-ports-in-your-codespace).

## 3. Trình tự trình diễn ngắn

Mỗi lần đổi vai trò, đăng xuất tài khoản hiện tại rồi đăng nhập tài khoản tiếp theo. Các điều kiện nghiệp vụ vẫn được kiểm tra khi xác nhận thao tác.

| Bước | Tài khoản | Thao tác |
|---|---|---|
| 1 | `student@lab.local` | Vào **Thiết bị**, tìm **Bộ cảm biến môi trường**, chọn **Mượn thiết bị** và ngày trả dự kiến hợp lệ; sau đó vào **Mượn trả của tôi → Trả thiết bị**. |
| 2 | `faculty@lab.local` | Xem đề tài phụ trách tại **Đề tài nghiên cứu**. Tại **Ra vào phòng → Phê duyệt lượt vào**, chọn sinh viên và phòng **Thông thường (Normal)** phù hợp. |
| 3 | `technician@lab.local` | Vào **Kho hóa chất**, mở **Natri clorua → Nhập kho**. Thử **Xuất kho** với hạng mục hợp lệ và lượng nhỏ hơn hoặc bằng tồn kho; đối chiếu số lượng mới. |
| 4 | `admin@lab.local` | Mở đề tài và điều chỉnh ngân sách còn lại trong khoảng từ 0 đến tổng ngân sách. |
| 5 | `auditor@lab.local` | Vào **Báo cáo**, chọn truy vấn, xem kết quả và tải dữ liệu theo quyền; kiểm tra giao diện chỉ đọc. |

Kỹ thuật viên cũng có thể tạo phiếu trong **Bảo trì**, chọn thiết bị khả dụng rồi **Kết thúc** phiếu của mình. Nếu một tài sản đã được sử dụng ở lần thử trước, chọn tài sản khác đủ điều kiện hoặc hoàn tất thao tác đang mở. Các bảng trên giao diện áp dụng phạm vi quyền; bộ Q01–Q12 trong SQL phục vụ báo cáo quản trị toàn cục.

## 4. Kiểm tra và xử lý lỗi

Mở **Terminal → New Terminal** tại thư mục gốc repository:

```bash
npm test
npm run validate
npm run security
```

Các kiểm thử dùng cơ sở dữ liệu riêng, không sửa dữ liệu trình diễn đang mở. Bằng chứng đã lưu tại `LabTrack/evidence` ghi nhận các lần chạy của báo cáo; kết quả mới cần đọc từ lần thực thi hiện tại.

| Hiện tượng | Cách xử lý |
|---|---|
| Môi trường đang tạo, chưa có cổng 4173 | Chờ bước cài thư viện hoàn tất; xem tiến trình thiết lập trong terminal. |
| Không thấy trang ứng dụng sau khi thiết lập | Mở **PORTS → 4173 → Open in Browser**. Nếu chưa có cổng, chọn **Add port** và nhập `4173`. |
| Máy chủ chưa chạy | Tại terminal gốc, chạy `npm start` và giữ terminal mở. |
| Báo thiếu thư viện | Chạy `npm --prefix LabTrack ci`, sau đó `npm start`. Cần kết nối Internet để tải gói. |
| Báo cổng 4173 đã được sử dụng | Máy chủ có thể đã tự chạy; mở lại cổng 4173, không khởi động thêm tiến trình. |
| Cần xem lỗi tự khởi động | Mở `.devcontainer/runtime/server.log` trong Explorer của codespace. |
| Nút thao tác không xuất hiện hoặc bị từ chối | Kiểm tra vai trò, trạng thái tài sản, chứng nhận, giờ truy cập và điều kiện trong biểu mẫu. |
| Codespace có mã nguồn cũ | Lưu công việc cần giữ, cập nhật từ repository rồi chạy **Codespaces: Rebuild Container** khi cấu hình môi trường đã thay đổi. |
| GitHub báo hết hạn mức | Xem trang Billing/Usage của tài khoản; chờ hạn mức được cấp lại, tự cấu hình thanh toán nếu muốn, hoặc chạy cục bộ. |

## 5. Dừng, mở lại và giữ dữ liệu

- Sau khi dùng, mở [Your codespaces](https://github.com/codespaces), chọn dấu **… → Stop codespace**. Đóng thẻ trình duyệt không đồng nghĩa với dừng ngay máy chạy.
- Khi dùng tiếp, mở **codespace đã có** để giữ dữ liệu trong `LabTrack/.data`. Tạo codespace mới sẽ khởi tạo cơ sở dữ liệu riêng từ bộ mẫu.
- Trước khi xóa codespace, tải bản sao lưu cần giữ về máy theo [hướng dẫn sao lưu](../LabTrack/BACKUP.md). Dữ liệu trong `.data` không được đưa lên GitHub bằng commit.
- Xóa codespace sẽ xóa dữ liệu cục bộ của nó. Dừng codespace giữ dữ liệu nhưng vẫn chiếm dung lượng lưu trữ.

Codespaces có hạn mức tính toán và lưu trữ theo tài khoản; không mặc định miễn phí không giới hạn. Kiểm tra [vòng đời codespace](https://docs.github.com/en/codespaces/about-codespaces/understanding-the-codespace-lifecycle) và [chính sách thanh toán](https://docs.github.com/en/billing/concepts/product-billing/github-codespaces).

## 6. Chạy trên Windows khi không dùng Codespaces

1. Cài Node.js 24, tải mã nguồn từ **Code → Download ZIP** rồi giải nén.
2. Mở PowerShell ở thư mục gốc có `README.md` và thư mục `LabTrack`.
3. Chạy:

```powershell
npm.cmd --prefix LabTrack ci
npm.cmd start
```

4. Mở [http://127.0.0.1:4173/](http://127.0.0.1:4173/), đăng nhập bằng cùng tài khoản mẫu.
5. Nhấn **Ctrl+C** trong terminal để dừng máy chủ. Dữ liệu được giữ trong `LabTrack/.data` cho lần mở tiếp theo.

Không chạy trực tiếp từ bên trong tệp ZIP. Gói GitHub không kèm thư viện; lần cài đầu cần Internet. Sau khi cài xong, cũng có thể mở `LabTrack/Mo-LabTrack.cmd` để chạy trên Windows.
