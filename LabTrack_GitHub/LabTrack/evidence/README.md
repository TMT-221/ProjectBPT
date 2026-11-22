# Nguồn truy vấn và bằng chứng thực thi

Q04, Q07, Q08 và Q10 được chỉnh khoảng trắng, xuống dòng và thụt dòng để dễ đọc. Không đổi từ khóa, chữ hoa/thường, tên, giá trị, toán tử hoặc logic. [Kết quả kiểm chứng định dạng](sql_formatting_verification.json) xác nhận chuỗi token giữ nguyên và kết quả đầy đủ Q01–Q12 trước/sau giống nhau khi chạy trên cùng cơ sở dữ liệu 1.200 bản ghi. Bốn tệp truy vấn riêng khớp các câu tương ứng trong `sql/03_queries.sql`; tám truy vấn còn lại giữ nguyên từng byte.

Các tệp `query_results.json` và `query_performance_results.json` giữ nguyên kết quả, thời gian và SHA-256 của lần chạy ban đầu. Năm tệp SQL trước khi định dạng được lưu nguyên byte tại [query_sources_before_format](query_sources_before_format/) để đối chiếu các giá trị băm lịch sử. Tệp kiểm chứng ghi cả băm cũ/mới và quan hệ tương đương; không có phép đo hiệu năng mới được gán cho dữ liệu đo cũ.
