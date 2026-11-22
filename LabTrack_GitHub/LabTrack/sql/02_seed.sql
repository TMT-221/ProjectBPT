SET search_path=lab_tracker,pg_catalog;
SET TIME ZONE 'Asia/Ho_Chi_Minh';
BEGIN;
INSERT INTO person(person_id,full_name,email,phone,date_of_birth,status) VALUES
 (1,'Nguyễn Minh An','an.nguyen@university.edu.vn','0901000001','1980-04-15','Active'),
 (2,'Trần Thu Bình','binh.tran@university.edu.vn','0901000002','1985-09-20','Active'),
 (3,'Lê Quang Chi','chi.le@university.edu.vn','0901000003','1978-01-05','Active'),
 (4,'Phạm Hải Dương','duong.pham@university.edu.vn','0901000004','2005-06-12','Active'),
 (5,'Võ Ngọc Hân','han.vo@university.edu.vn','0901000005','2006-11-08','Active'),
 (6,'Đặng Đức Khoa','khoa.dang@university.edu.vn','0901000006','2004-03-17','Active'),
 (7,'Bùi Thanh Lam','lam.bui@university.edu.vn','0901000007','2005-07-21','Active'),
 (8,'Đỗ Anh Minh','minh.do@university.edu.vn','0901000008','2006-05-10','Inactive'),
 (9,'Nguyễn Hoàng Nam','nam.nguyen@university.edu.vn','0901000009','1990-12-25','Active'),
 (10,'Trần Bảo Ngọc','ngoc.tran@university.edu.vn','0901000010','1993-10-03','Active'),
 (11,'Lê Minh Phúc','phuc.le@university.edu.vn','0901000011','1995-08-18','Active'),
 (12,'Phan Thảo Vy','vy.phan@university.edu.vn','0901000012','2005-02-28','Active');
INSERT INTO faculty VALUES (1,'Công nghệ thông tin','Tiến sĩ','A-201'),(2,'Hóa học','Phó giáo sư','B-301'),(3,'Điện tử','Tiến sĩ','C-401');
INSERT INTO student VALUES (4,'N24DCCN101','Công nghệ thông tin',3),(5,'N24DCCN102','Hóa học',2),(6,'N23DCCN103','Điện tử',4),(7,'N24DCCN104','Công nghệ thông tin',3),(8,'N25DCCN105','Hóa học',2),(12,'N24DCCN106','Hóa học',3);
INSERT INTO technician VALUES (9,'KT001','Thiết bị phân tích'),(10,'KT002','An toàn hóa chất'),(11,'KT003','Điện tử và hiệu chuẩn');
COMMIT;
INSERT INTO laboratory VALUES
 (1,'Phòng máy tính nghiên cứu','A','101',30,'Normal'),
 (2,'Phòng phân tích vật liệu','B','201',15,'Restricted'),
 (3,'Phòng phản ứng hóa học','B','202',8,'Hazardous');
INSERT INTO research_grant VALUES
 (1,'Phân tích vật liệu cảm biến',2,CURRENT_DATE-180,CURRENT_DATE+180,500000000,320000000,'Active'),
 (2,'Hệ thống giám sát phòng thí nghiệm',1,CURRENT_DATE-90,CURRENT_DATE+270,250000000,190000000,'Active'),
 (3,'Mẫu thử điện tử công suất',3,CURRENT_DATE-400,CURRENT_DATE-30,300000000,20000000,'Completed'),
 (4,'Vật liệu lưu trữ năng lượng',2,CURRENT_DATE-60,CURRENT_DATE+300,450000000,410000000,'Suspended');
INSERT INTO research_point VALUES
 (1,1,'Tổng hợp mẫu','Tạo vật liệu cảm biến',CURRENT_DATE-150,CURRENT_DATE+60,'Active'),
 (2,1,'Đo và phân tích','Đánh giá đặc tính mẫu',CURRENT_DATE-30,CURRENT_DATE+150,'Active'),
 (3,2,'Thu thập dữ liệu','Kết nối cảm biến phòng',CURRENT_DATE-60,CURRENT_DATE+90,'Active'),
 (4,2,'Phân tích dữ liệu','Xây dựng chỉ số vận hành',CURRENT_DATE+1,CURRENT_DATE+240,'Planned'),
 (5,3,'Đo kiểm mẫu thử','Đã hoàn tất nghiệm thu',CURRENT_DATE-350,CURRENT_DATE-60,'Completed'),
 (6,4,'Khảo sát vật liệu','Tạm dừng theo quyết định đề tài',CURRENT_DATE-45,CURRENT_DATE+200,'Suspended');
INSERT INTO grant_laboratory VALUES(1,2),(1,3),(2,1),(2,2),(3,1),(4,3);
INSERT INTO equipment VALUES
 (1,1,'Máy trạm nghiên cứu 01','WS-2025-001',CURRENT_DATE-500,42000000,'Available'),
 (2,1,'Máy trạm nghiên cứu 02','WS-2025-002',CURRENT_DATE-500,42000000,'Available'),
 (3,1,'Bộ cảm biến môi trường','IOT-2026-001',CURRENT_DATE-120,12000000,'Available'),
 (4,2,'Kính hiển vi quang học','MIC-2024-001',CURRENT_DATE-700,95000000,'Available'),
 (5,2,'Cân phân tích 01','BAL-2024-001',CURRENT_DATE-650,35000000,'Available'),
 (6,2,'Máy đo phổ UV-Vis','UV-2023-001',CURRENT_DATE-900,220000000,'Available'),
 (7,3,'Máy khuấy từ gia nhiệt','STIR-2025-001',CURRENT_DATE-400,18000000,'Available'),
 (8,3,'Tủ hút hóa chất','HOOD-2024-001',CURRENT_DATE-600,160000000,'Available'),
 (9,1,'Máy hiện sóng cũ','OSC-2018-001',CURRENT_DATE-2500,25000000,'Retired'),
 (10,2,'Cân phân tích 02','BAL-2025-002',CURRENT_DATE-300,36000000,'Available'),
 (11,1,'Bộ thu thập dữ liệu','DAQ-2026-001',CURRENT_DATE-100,28000000,'Available'),
 (12,1,'Máy tính bảng khảo sát','TAB-2026-001',CURRENT_DATE-80,15000000,'Available');
INSERT INTO chemical VALUES
 (1,3,'Ethanol 96%','64-17-5',0,'L',CURRENT_DATE+240,'High','Tủ chống cháy, tránh nguồn nhiệt'),
 (2,3,'Axit nitric 65%','7697-37-2',0,'L',CURRENT_DATE+180,'Extreme','Tủ axit thông gió, tách chất hữu cơ'),
 (3,2,'Natri clorua','7647-14-5',0,'kg',CURRENT_DATE+500,'Low','Đậy kín, nơi khô ráo'),
 (4,2,'Đồng sulfat','7758-98-7',0,'g',CURRENT_DATE+25,'Medium','Bình kín, tránh ẩm'),
 (5,3,'Methanol','67-56-1',0,'L',CURRENT_DATE-5,'High','Tủ chống cháy, khu cách ly hết hạn'),
 (6,3,'Acetone','67-64-1',0,'L',CURRENT_DATE+15,'High','Tủ chống cháy, thông gió');
INSERT INTO certification VALUES
 (1,'An toàn phòng thí nghiệm cơ bản','Trung tâm An toàn PTN',12),
 (2,'Xử lý dung môi dễ cháy','Trung tâm An toàn PTN',12),
 (3,'Xử lý axit oxy hóa mạnh','Trung tâm An toàn PTN',6);
INSERT INTO has_certification VALUES
 (1,1,CURRENT_DATE-100,CURRENT_DATE+265),
 (2,1,CURRENT_DATE-100,CURRENT_DATE+265),
 (2,2,CURRENT_DATE-100,CURRENT_DATE+265),
 (2,3,CURRENT_DATE-60,CURRENT_DATE+120),
 (4,1,CURRENT_DATE-100,CURRENT_DATE+265),
 (5,1,CURRENT_DATE-100,CURRENT_DATE+265),
 (5,2,CURRENT_DATE-100,CURRENT_DATE+265),
 (6,1,CURRENT_DATE-400,CURRENT_DATE-35),
 (9,1,CURRENT_DATE-100,CURRENT_DATE+265),
 (9,2,CURRENT_DATE-100,CURRENT_DATE+265),
 (10,1,CURRENT_DATE-100,CURRENT_DATE+265),
 (10,2,CURRENT_DATE-100,CURRENT_DATE+265),
 (10,3,CURRENT_DATE-60,CURRENT_DATE+120),
 (11,1,CURRENT_DATE-100,CURRENT_DATE+265),
 (12,1,CURRENT_DATE-100,CURRENT_DATE+265),
 (12,2,CURRENT_DATE-400,CURRENT_DATE-35);
INSERT INTO chemical_certification VALUES(1,2),(2,1),(2,3),(5,2),(6,2);
INSERT INTO allocated_equip VALUES(1,7),(1,8),(2,4),(2,5),(2,6),(3,1),(3,2),(3,3),(3,11),(4,1);
INSERT INTO allocated_chem VALUES(1,1),(1,2),(1,3),(1,4),(1,5),(1,6),(2,3);
SELECT receive_chemical(1,10,20,'Nhập kho đầu kỳ');
SELECT receive_chemical(2,10,5,'Nhập kho đầu kỳ');
SELECT receive_chemical(3,10,10,'Nhập kho đầu kỳ');
SELECT receive_chemical(4,10,1000,'Nhập kho đầu kỳ');
SELECT receive_chemical(5,10,3,'Tiếp nhận tồn cần cách ly');
SELECT receive_chemical(6,10,8,'Nhập kho đầu kỳ');
SELECT issue_chemical(1,5,1,2.5,'Tổng hợp mẫu cảm biến');
SELECT issue_chemical(2,10,1,0.5,'Chuẩn bị phản ứng có kiểm soát');
SELECT issue_chemical(3,4,2,1,'Pha dung dịch chuẩn');
SELECT issue_chemical(4,2,1,50,'Chuẩn bị mẫu phân tích');
INSERT INTO access_log(person_id,lab_id,entry_time,exit_time,purpose,approved_by) VALUES
 (4,1,CURRENT_DATE-3+time '08:00',CURRENT_DATE-3+time '11:00','Thu thập dữ liệu',NULL),
 (4,2,CURRENT_DATE-2+time '18:00',CURRENT_DATE-2+time '20:00','Đo kiểm theo lịch bổ sung',2),
 (5,2,CURRENT_DATE-2+time '09:00',CURRENT_DATE-2+time '11:30','Tổng hợp mẫu',NULL),
 (10,3,CURRENT_DATE-2+time '22:30',CURRENT_DATE-1+time '00:30','Kiểm tra an toàn cuối ca',NULL),
 (2,3,CURRENT_DATE-1+time '09:00',CURRENT_DATE-1+time '12:00','Giám sát phản ứng',NULL),
 (1,1,CURRENT_DATE-1+time '23:00',CURRENT_DATE+time '00:10','Khắc phục sự cố máy chủ',NULL),
 (9,2,CURRENT_DATE+time '06:00',NULL,'Kiểm tra thiết bị trước ca',NULL);
INSERT INTO borrow_transaction(borrow_id,person_id,equipment_id,borrow_date,expected_return_date,actual_return_date) VALUES
 (1,4,1,CURRENT_DATE-10,CURRENT_DATE-5,NULL),
 (2,4,2,CURRENT_DATE-2,CURRENT_DATE+5,NULL),
 (3,5,4,CURRENT_DATE-20,CURRENT_DATE-15,CURRENT_DATE-14),
 (4,6,3,CURRENT_DATE-8,CURRENT_DATE-3,CURRENT_DATE-4),
 (5,5,5,CURRENT_DATE-1,CURRENT_DATE+6,NULL);
INSERT INTO maintenance_log(maintenance_id,technician_id,equipment_id,start_date,end_date,description,cost) VALUES
 (1,9,6,CURRENT_DATE-2,NULL,'Hiệu chuẩn bước sóng',1500000),
 (2,11,11,CURRENT_DATE-30,CURRENT_DATE-29,'Thay cáp và kiểm tra kết nối',300000),
 (3,9,4,CURRENT_DATE-60,CURRENT_DATE-59,'Vệ sinh hệ quang học',700000);
SELECT setval(pg_get_serial_sequence('person','person_id'),(SELECT max(person_id) FROM person));
SELECT setval(pg_get_serial_sequence('laboratory','lab_id'),(SELECT max(lab_id) FROM laboratory));
SELECT setval(pg_get_serial_sequence('research_grant','grant_id'),(SELECT max(grant_id) FROM research_grant));
SELECT setval(pg_get_serial_sequence('research_point','rearch_point_id'),(SELECT max(rearch_point_id) FROM research_point));
SELECT setval(pg_get_serial_sequence('equipment','equipment_id'),(SELECT max(equipment_id) FROM equipment));
SELECT setval(pg_get_serial_sequence('chemical','chemical_id'),(SELECT max(chemical_id) FROM chemical));
SELECT setval(pg_get_serial_sequence('certification','cert_id'),(SELECT max(cert_id) FROM certification));
SELECT setval(pg_get_serial_sequence('borrow_transaction','borrow_id'),(SELECT max(borrow_id) FROM borrow_transaction));
SELECT setval(pg_get_serial_sequence('maintenance_log','maintenance_id'),(SELECT max(maintenance_id) FROM maintenance_log));
