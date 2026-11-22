-- Synthetic dataset. Run after 01_schema.sql on an empty lab_tracker schema.
SET search_path=lab_tracker,pg_catalog;
SET TIME ZONE 'Asia/Ho_Chi_Minh';
BEGIN;
INSERT INTO person(person_id,full_name,email,phone,date_of_birth,status) VALUES
 (1,'Nguyễn Minh An','seed182@lab.example',NULL,'1980-04-15','Active'),
 (2,'Trần Thu Bình','seed269@lab.example',NULL,'1985-09-20','Active'),
 (3,'Lê Quang Chi','seed355@lab.example',NULL,'1978-01-05','Active'),
 (4,'Phạm Hải Dương','seed440@lab.example',NULL,'2005-06-12','Active'),
 (5,'Võ Ngọc Hân','seed526@lab.example',NULL,'2006-11-08','Active'),
 (6,'Đặng Đức Khoa','seed610@lab.example',NULL,'2004-03-17','Active'),
 (7,'Bùi Thanh Lam','seed697@lab.example',NULL,'2005-07-21','Active'),
 (8,'Đỗ Anh Minh','seed780@lab.example',NULL,'2006-05-10','Inactive'),
 (9,'Nguyễn Hoàng Nam','seed870@lab.example',NULL,'1990-12-25','Active'),
 (10,'Trần Bảo Ngọc','seed959@lab.example',NULL,'1993-10-03','Active'),
 (11,'Lê Minh Phúc','seed1046@lab.example',NULL,'1995-08-18','Active'),
 (12,'Phan Thảo Vy','seed1131@lab.example',NULL,'2005-02-28','Active');
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

BEGIN;
INSERT INTO person(person_id,full_name,email,phone,date_of_birth,status) VALUES
(13,'Nguyễn Minh An','user013@lab.example',NULL,'2004-02-14','Active'),
(14,'Trần Minh An','user014@lab.example',NULL,'2005-03-15','Active'),
(15,'Lê Minh An','user015@lab.example',NULL,'2006-04-16','Active'),
(16,'Phạm Minh An','user016@lab.example',NULL,'2003-05-17','Active'),
(17,'Hoàng Minh An','user017@lab.example',NULL,'2004-06-18','Active'),
(18,'Võ Minh An','user018@lab.example',NULL,'2005-07-19','Active'),
(19,'Đặng Minh An','user019@lab.example',NULL,'2006-08-20','Active'),
(20,'Bùi Minh An','user020@lab.example',NULL,'2003-09-21','Active'),
(21,'Đỗ Minh An','user021@lab.example',NULL,'2004-10-22','Active'),
(22,'Phan Minh An','user022@lab.example',NULL,'2005-11-23','Active'),
(23,'Vũ Minh An','user023@lab.example',NULL,'2006-12-24','Active'),
(24,'Nguyễn Thu Bình','user024@lab.example',NULL,'2003-01-25','Active'),
(25,'Trần Thu Bình','user025@lab.example',NULL,'2004-02-26','Active'),
(26,'Lê Thu Bình','user026@lab.example',NULL,'2005-03-27','Active'),
(27,'Phạm Thu Bình','user027@lab.example',NULL,'2006-04-01','Active'),
(28,'Hoàng Thu Bình','user028@lab.example',NULL,'2003-05-02','Active'),
(29,'Võ Thu Bình','user029@lab.example',NULL,'2004-06-03','Active'),
(30,'Đặng Thu Bình','user030@lab.example',NULL,'2005-07-04','Active'),
(31,'Bùi Thu Bình','user031@lab.example',NULL,'2006-08-05','Active'),
(32,'Đỗ Thu Bình','user032@lab.example',NULL,'2003-09-06','Active'),
(33,'Phan Thu Bình','user033@lab.example',NULL,'2004-10-07','Active'),
(34,'Vũ Thu Bình','user034@lab.example',NULL,'2005-11-08','Active'),
(35,'Nguyễn Quang Chi','user035@lab.example',NULL,'2006-12-09','Active'),
(36,'Trần Quang Chi','user036@lab.example',NULL,'2003-01-10','Active'),
(37,'Lê Quang Chi','user037@lab.example',NULL,'2004-02-11','Active'),
(38,'Phạm Quang Chi','user038@lab.example',NULL,'2005-03-12','Active'),
(39,'Hoàng Quang Chi','user039@lab.example',NULL,'2006-04-13','Active'),
(40,'Võ Quang Chi','user040@lab.example',NULL,'2003-05-14','Active'),
(41,'Đặng Quang Chi','user041@lab.example',NULL,'2004-06-15','Active'),
(42,'Bùi Quang Chi','user042@lab.example',NULL,'2005-07-16','Active'),
(43,'Đỗ Quang Chi','user043@lab.example',NULL,'2006-08-17','Active'),
(44,'Phan Quang Chi','user044@lab.example',NULL,'2003-09-18','Active'),
(45,'Vũ Quang Chi','user045@lab.example',NULL,'2004-10-19','Active'),
(46,'Nguyễn Hải Dương','user046@lab.example',NULL,'2005-11-20','Active'),
(47,'Trần Hải Dương','user047@lab.example',NULL,'2006-12-21','Active'),
(48,'Lê Hải Dương','user048@lab.example',NULL,'2003-01-22','Active'),
(49,'Phạm Hải Dương','user049@lab.example',NULL,'2004-02-23','Active'),
(50,'Hoàng Hải Dương','user050@lab.example',NULL,'2005-03-24','Active'),
(51,'Võ Hải Dương','user051@lab.example',NULL,'2006-04-25','Active'),
(52,'Đặng Hải Dương','user052@lab.example',NULL,'2003-05-26','Active'),
(53,'Bùi Hải Dương','user053@lab.example',NULL,'2004-06-27','Active'),
(54,'Đỗ Hải Dương','user054@lab.example',NULL,'2005-07-01','Active'),
(55,'Phan Hải Dương','user055@lab.example',NULL,'2006-08-02','Active'),
(56,'Vũ Hải Dương','user056@lab.example',NULL,'2003-09-03','Active'),
(57,'Nguyễn Ngọc Hân','user057@lab.example',NULL,'2004-10-04','Active'),
(58,'Trần Ngọc Hân','user058@lab.example',NULL,'2005-11-05','Active'),
(59,'Lê Ngọc Hân','user059@lab.example',NULL,'2006-12-06','Active'),
(60,'Phạm Ngọc Hân','user060@lab.example',NULL,'2003-01-07','Active'),
(61,'Hoàng Ngọc Hân','user061@lab.example',NULL,'2004-02-08','Active'),
(62,'Võ Ngọc Hân','user062@lab.example',NULL,'2005-03-09','Active'),
(63,'Đặng Ngọc Hân','user063@lab.example',NULL,'1987-04-10','Active'),
(64,'Bùi Ngọc Hân','user064@lab.example',NULL,'1988-05-11','Active'),
(65,'Đỗ Ngọc Hân','user065@lab.example',NULL,'1989-06-12','Active'),
(66,'Phan Ngọc Hân','user066@lab.example',NULL,'1990-07-13','Active'),
(67,'Vũ Ngọc Hân','user067@lab.example',NULL,'1991-08-14','Active'),
(68,'Nguyễn Đức Khoa','user068@lab.example',NULL,'1975-09-15','Active'),
(69,'Trần Đức Khoa','user069@lab.example',NULL,'1976-10-16','Active'),
(70,'Lê Đức Khoa','user070@lab.example',NULL,'1977-11-17','Active'),
(71,'Phạm Đức Khoa','user071@lab.example',NULL,'1978-12-18','Active'),
(72,'Hoàng Đức Khoa','user072@lab.example',NULL,'1979-01-19','Active'),
(73,'Võ Đức Khoa','user073@lab.example',NULL,'1980-02-20','Active'),
(74,'Đặng Đức Khoa','user074@lab.example',NULL,'1981-03-21','Active'),
(75,'Bùi Đức Khoa','user075@lab.example',NULL,'1982-04-22','Active'),
(76,'Đỗ Đức Khoa','user076@lab.example',NULL,'1983-05-23','Active'),
(77,'Phan Đức Khoa','user077@lab.example',NULL,'1984-06-24','Active'),
(78,'Vũ Đức Khoa','user078@lab.example',NULL,'1985-07-25','Active'),
(79,'Nguyễn Thanh Lam','user079@lab.example',NULL,'1986-08-26','Active'),
(80,'Trần Thanh Lam','user080@lab.example',NULL,'1987-09-27','Active'),
(81,'Lê Thanh Lam','user081@lab.example',NULL,'1988-10-01','Active'),
(82,'Phạm Thanh Lam','user082@lab.example',NULL,'1989-11-02','Active'),
(83,'Hoàng Thanh Lam','user083@lab.example',NULL,'1990-12-03','Active'),
(84,'Võ Thanh Lam','user084@lab.example',NULL,'1991-01-04','Active'),
(85,'Đặng Thanh Lam','user085@lab.example',NULL,'1992-02-05','Active'),
(86,'Bùi Thanh Lam','user086@lab.example',NULL,'1993-03-06','Active'),
(87,'Đỗ Thanh Lam','user087@lab.example',NULL,'1994-04-07','Active'),
(88,'Phan Thanh Lam','user088@lab.example',NULL,'1995-05-08','Active'),
(89,'Vũ Thanh Lam','user089@lab.example',NULL,'1996-06-09','Active'),
(90,'Nguyễn Anh Minh','user090@lab.example',NULL,'1997-07-10','Active'),
(91,'Trần Anh Minh','user091@lab.example',NULL,'1985-08-11','Active'),
(92,'Lê Anh Minh','user092@lab.example',NULL,'1986-09-12','Active'),
(93,'Phạm Anh Minh','user093@lab.example',NULL,'1987-10-13','Active'),
(94,'Hoàng Anh Minh','user094@lab.example',NULL,'1988-11-14','Active'),
(95,'Võ Anh Minh','user095@lab.example',NULL,'1989-12-15','Active'),
(96,'Đặng Anh Minh','user096@lab.example',NULL,'1990-01-16','Active'),
(97,'Bùi Anh Minh','user097@lab.example',NULL,'1991-02-17','Active'),
(98,'Đỗ Anh Minh','user098@lab.example',NULL,'1992-03-18','Active'),
(99,'Phan Anh Minh','user099@lab.example',NULL,'1993-04-19','Active'),
(100,'Vũ Anh Minh','user100@lab.example',NULL,'1994-05-20','Active');
INSERT INTO student VALUES(13,'SIM00013','Hóa học',2);
INSERT INTO student VALUES(14,'SIM00014','Điện tử',3);
INSERT INTO student VALUES(15,'SIM00015','Công nghệ thông tin',4);
INSERT INTO student VALUES(16,'SIM00016','Hóa học',1);
INSERT INTO student VALUES(17,'SIM00017','Điện tử',2);
INSERT INTO student VALUES(18,'SIM00018','Công nghệ thông tin',3);
INSERT INTO student VALUES(19,'SIM00019','Hóa học',4);
INSERT INTO student VALUES(20,'SIM00020','Điện tử',1);
INSERT INTO student VALUES(21,'SIM00021','Công nghệ thông tin',2);
INSERT INTO student VALUES(22,'SIM00022','Hóa học',3);
INSERT INTO student VALUES(23,'SIM00023','Điện tử',4);
INSERT INTO student VALUES(24,'SIM00024','Công nghệ thông tin',1);
INSERT INTO student VALUES(25,'SIM00025','Hóa học',2);
INSERT INTO student VALUES(26,'SIM00026','Điện tử',3);
INSERT INTO student VALUES(27,'SIM00027','Công nghệ thông tin',4);
INSERT INTO student VALUES(28,'SIM00028','Hóa học',1);
INSERT INTO student VALUES(29,'SIM00029','Điện tử',2);
INSERT INTO student VALUES(30,'SIM00030','Công nghệ thông tin',3);
INSERT INTO student VALUES(31,'SIM00031','Hóa học',4);
INSERT INTO student VALUES(32,'SIM00032','Điện tử',1);
INSERT INTO student VALUES(33,'SIM00033','Công nghệ thông tin',2);
INSERT INTO student VALUES(34,'SIM00034','Hóa học',3);
INSERT INTO student VALUES(35,'SIM00035','Điện tử',4);
INSERT INTO student VALUES(36,'SIM00036','Công nghệ thông tin',1);
INSERT INTO student VALUES(37,'SIM00037','Hóa học',2);
INSERT INTO student VALUES(38,'SIM00038','Điện tử',3);
INSERT INTO student VALUES(39,'SIM00039','Công nghệ thông tin',4);
INSERT INTO student VALUES(40,'SIM00040','Hóa học',1);
INSERT INTO student VALUES(41,'SIM00041','Điện tử',2);
INSERT INTO student VALUES(42,'SIM00042','Công nghệ thông tin',3);
INSERT INTO student VALUES(43,'SIM00043','Hóa học',4);
INSERT INTO student VALUES(44,'SIM00044','Điện tử',1);
INSERT INTO student VALUES(45,'SIM00045','Công nghệ thông tin',2);
INSERT INTO student VALUES(46,'SIM00046','Hóa học',3);
INSERT INTO student VALUES(47,'SIM00047','Điện tử',4);
INSERT INTO student VALUES(48,'SIM00048','Công nghệ thông tin',1);
INSERT INTO student VALUES(49,'SIM00049','Hóa học',2);
INSERT INTO student VALUES(50,'SIM00050','Điện tử',3);
INSERT INTO student VALUES(51,'SIM00051','Công nghệ thông tin',4);
INSERT INTO student VALUES(52,'SIM00052','Hóa học',1);
INSERT INTO student VALUES(53,'SIM00053','Điện tử',2);
INSERT INTO student VALUES(54,'SIM00054','Công nghệ thông tin',3);
INSERT INTO student VALUES(55,'SIM00055','Hóa học',4);
INSERT INTO student VALUES(56,'SIM00056','Điện tử',1);
INSERT INTO student VALUES(57,'SIM00057','Công nghệ thông tin',2);
INSERT INTO student VALUES(58,'SIM00058','Hóa học',3);
INSERT INTO student VALUES(59,'SIM00059','Điện tử',4);
INSERT INTO student VALUES(60,'SIM00060','Công nghệ thông tin',1);
INSERT INTO student VALUES(61,'SIM00061','Hóa học',2);
INSERT INTO student VALUES(62,'SIM00062','Điện tử',3);
INSERT INTO faculty VALUES(63,'Công nghệ thông tin','Tiến sĩ','A-263');
INSERT INTO faculty VALUES(64,'Hóa học','Tiến sĩ','B-264');
INSERT INTO faculty VALUES(65,'Điện tử','Tiến sĩ','C-265');
INSERT INTO faculty VALUES(66,'Công nghệ thông tin','Tiến sĩ','A-266');
INSERT INTO faculty VALUES(67,'Hóa học','Tiến sĩ','B-267');
INSERT INTO faculty VALUES(68,'Điện tử','Tiến sĩ','C-268');
INSERT INTO faculty VALUES(69,'Công nghệ thông tin','Tiến sĩ','A-269');
INSERT INTO faculty VALUES(70,'Hóa học','Tiến sĩ','B-270');
INSERT INTO faculty VALUES(71,'Điện tử','Tiến sĩ','C-271');
INSERT INTO faculty VALUES(72,'Công nghệ thông tin','Tiến sĩ','A-272');
INSERT INTO faculty VALUES(73,'Hóa học','Tiến sĩ','B-273');
INSERT INTO faculty VALUES(74,'Điện tử','Tiến sĩ','C-274');
INSERT INTO faculty VALUES(75,'Công nghệ thông tin','Tiến sĩ','A-275');
INSERT INTO faculty VALUES(76,'Hóa học','Tiến sĩ','B-276');
INSERT INTO faculty VALUES(77,'Điện tử','Tiến sĩ','C-277');
INSERT INTO faculty VALUES(78,'Công nghệ thông tin','Tiến sĩ','A-278');
INSERT INTO faculty VALUES(79,'Hóa học','Tiến sĩ','B-279');
INSERT INTO faculty VALUES(80,'Điện tử','Tiến sĩ','C-280');
INSERT INTO faculty VALUES(81,'Công nghệ thông tin','Tiến sĩ','A-281');
INSERT INTO faculty VALUES(82,'Hóa học','Tiến sĩ','B-282');
INSERT INTO technician VALUES(83,'SIMKT83','Điện tử và hiệu chuẩn');
INSERT INTO technician VALUES(84,'SIMKT84','Thiết bị phân tích');
INSERT INTO technician VALUES(85,'SIMKT85','An toàn hóa chất');
INSERT INTO technician VALUES(86,'SIMKT86','Điện tử và hiệu chuẩn');
INSERT INTO technician VALUES(87,'SIMKT87','Thiết bị phân tích');
INSERT INTO technician VALUES(88,'SIMKT88','An toàn hóa chất');
INSERT INTO technician VALUES(89,'SIMKT89','Điện tử và hiệu chuẩn');
INSERT INTO technician VALUES(90,'SIMKT90','Thiết bị phân tích');
INSERT INTO technician VALUES(91,'SIMKT91','An toàn hóa chất');
INSERT INTO technician VALUES(92,'SIMKT92','Điện tử và hiệu chuẩn');
INSERT INTO technician VALUES(93,'SIMKT93','Thiết bị phân tích');
INSERT INTO technician VALUES(94,'SIMKT94','An toàn hóa chất');
INSERT INTO technician VALUES(95,'SIMKT95','Điện tử và hiệu chuẩn');
INSERT INTO technician VALUES(96,'SIMKT96','Thiết bị phân tích');
INSERT INTO technician VALUES(97,'SIMKT97','An toàn hóa chất');
INSERT INTO technician VALUES(98,'SIMKT98','Điện tử và hiệu chuẩn');
INSERT INTO technician VALUES(99,'SIMKT99','Thiết bị phân tích');
INSERT INTO technician VALUES(100,'SIMKT100','An toàn hóa chất');
COMMIT;

INSERT INTO has_certification(person_id,cert_id,issue_date,expiry_date)
SELECT person_id,1,CURRENT_DATE-35,CURRENT_DATE+330 FROM person WHERE person_id>=13;
INSERT INTO has_certification(person_id,cert_id,issue_date,expiry_date)
SELECT person_id,2,CURRENT_DATE-100,CURRENT_DATE+260 FROM person WHERE person_id BETWEEN 13 AND 24;

UPDATE has_certification h SET expiry_date=(h.issue_date+make_interval(months=>c.validity_period_months))::date FROM certification c WHERE c.cert_id=h.cert_id;

INSERT INTO access_log(person_id,lab_id,entry_time,exit_time,purpose,approved_by) VALUES(13,1,CURRENT_DATE-1+time '18:00',CURRENT_DATE-1+time '19:30','Nghiên cứu cảm biến',1);

INSERT INTO access_log(person_id,lab_id,entry_time,exit_time,purpose,approved_by) VALUES(14,2,CURRENT_DATE-1+time '9:00',CURRENT_DATE-1+time '10:30','Phân tích mẫu vật liệu',NULL);

INSERT INTO access_log(person_id,lab_id,entry_time,exit_time,purpose,approved_by) VALUES(15,2,CURRENT_DATE-1+time '10:00',CURRENT_DATE-1+time '11:30','Thực hành thiết bị',NULL);

INSERT INTO access_log(person_id,lab_id,entry_time,exit_time,purpose,approved_by) VALUES(16,1,CURRENT_DATE-1+time '11:00',CURRENT_DATE-1+time '12:30','Kiểm kê phòng thí nghiệm',NULL);

INSERT INTO access_log(person_id,lab_id,entry_time,exit_time,purpose,approved_by) VALUES(17,2,CURRENT_DATE-1+time '12:00',CURRENT_DATE-1+time '13:30','Nghiên cứu cảm biến',NULL);

INSERT INTO access_log(person_id,lab_id,entry_time,exit_time,purpose,approved_by) VALUES(18,2,CURRENT_DATE-1+time '13:00',CURRENT_DATE-1+time '14:30','Phân tích mẫu vật liệu',NULL);

INSERT INTO access_log(person_id,lab_id,entry_time,exit_time,purpose,approved_by) VALUES(19,1,CURRENT_DATE-1+time '14:00',CURRENT_DATE-1+time '15:30','Thực hành thiết bị',NULL);

INSERT INTO access_log(person_id,lab_id,entry_time,exit_time,purpose,approved_by) VALUES(20,2,CURRENT_DATE-1+time '8:00',CURRENT_DATE-1+time '9:30','Kiểm kê phòng thí nghiệm',NULL);

INSERT INTO access_log(person_id,lab_id,entry_time,exit_time,purpose,approved_by) VALUES(21,2,CURRENT_DATE-2+time '9:00',CURRENT_DATE-2+time '10:30','Nghiên cứu cảm biến',NULL);

INSERT INTO access_log(person_id,lab_id,entry_time,exit_time,purpose,approved_by) VALUES(22,1,CURRENT_DATE-2+time '10:00',CURRENT_DATE-2+time '11:30','Phân tích mẫu vật liệu',NULL);

INSERT INTO access_log(person_id,lab_id,entry_time,exit_time,purpose,approved_by) VALUES(23,2,CURRENT_DATE-2+time '18:00',CURRENT_DATE-2+time '19:30','Thực hành thiết bị',1);

INSERT INTO access_log(person_id,lab_id,entry_time,exit_time,purpose,approved_by) VALUES(24,2,CURRENT_DATE-2+time '12:00',CURRENT_DATE-2+time '13:30','Kiểm kê phòng thí nghiệm',NULL);

INSERT INTO access_log(person_id,lab_id,entry_time,exit_time,purpose,approved_by) VALUES(25,1,CURRENT_DATE-2+time '13:00',CURRENT_DATE-2+time '14:30','Nghiên cứu cảm biến',NULL);

INSERT INTO access_log(person_id,lab_id,entry_time,exit_time,purpose,approved_by) VALUES(26,2,CURRENT_DATE-2+time '14:00',CURRENT_DATE-2+time '15:30','Phân tích mẫu vật liệu',NULL);

INSERT INTO access_log(person_id,lab_id,entry_time,exit_time,purpose,approved_by) VALUES(27,2,CURRENT_DATE-2+time '8:00',CURRENT_DATE-2+time '9:30','Thực hành thiết bị',NULL);

INSERT INTO access_log(person_id,lab_id,entry_time,exit_time,purpose,approved_by) VALUES(28,1,CURRENT_DATE-2+time '9:00',CURRENT_DATE-2+time '10:30','Kiểm kê phòng thí nghiệm',NULL);

INSERT INTO access_log(person_id,lab_id,entry_time,exit_time,purpose,approved_by) VALUES(29,2,CURRENT_DATE-3+time '10:00',CURRENT_DATE-3+time '11:30','Nghiên cứu cảm biến',NULL);

INSERT INTO access_log(person_id,lab_id,entry_time,exit_time,purpose,approved_by) VALUES(30,2,CURRENT_DATE-3+time '11:00',CURRENT_DATE-3+time '12:30','Phân tích mẫu vật liệu',NULL);

INSERT INTO access_log(person_id,lab_id,entry_time,exit_time,purpose,approved_by) VALUES(31,1,CURRENT_DATE-3+time '12:00',CURRENT_DATE-3+time '13:30','Thực hành thiết bị',NULL);

INSERT INTO access_log(person_id,lab_id,entry_time,exit_time,purpose,approved_by) VALUES(32,2,CURRENT_DATE-3+time '13:00',CURRENT_DATE-3+time '14:30','Kiểm kê phòng thí nghiệm',NULL);

INSERT INTO access_log(person_id,lab_id,entry_time,exit_time,purpose,approved_by) VALUES(33,2,CURRENT_DATE-3+time '18:00',CURRENT_DATE-3+time '19:30','Nghiên cứu cảm biến',1);

INSERT INTO access_log(person_id,lab_id,entry_time,exit_time,purpose,approved_by) VALUES(34,1,CURRENT_DATE-3+time '8:00',CURRENT_DATE-3+time '9:30','Phân tích mẫu vật liệu',NULL);

INSERT INTO access_log(person_id,lab_id,entry_time,exit_time,purpose,approved_by) VALUES(35,2,CURRENT_DATE-3+time '9:00',CURRENT_DATE-3+time '10:30','Thực hành thiết bị',NULL);

INSERT INTO access_log(person_id,lab_id,entry_time,exit_time,purpose,approved_by) VALUES(36,2,CURRENT_DATE-3+time '10:00',CURRENT_DATE-3+time '11:30','Kiểm kê phòng thí nghiệm',NULL);

INSERT INTO access_log(person_id,lab_id,entry_time,exit_time,purpose,approved_by) VALUES(37,1,CURRENT_DATE-4+time '11:00',CURRENT_DATE-4+time '12:30','Nghiên cứu cảm biến',NULL);

INSERT INTO access_log(person_id,lab_id,entry_time,exit_time,purpose,approved_by) VALUES(38,2,CURRENT_DATE-4+time '12:00',CURRENT_DATE-4+time '13:30','Phân tích mẫu vật liệu',NULL);

INSERT INTO access_log(person_id,lab_id,entry_time,exit_time,purpose,approved_by) VALUES(39,2,CURRENT_DATE-4+time '13:00',CURRENT_DATE-4+time '14:30','Thực hành thiết bị',NULL);

INSERT INTO access_log(person_id,lab_id,entry_time,exit_time,purpose,approved_by) VALUES(40,1,CURRENT_DATE-4+time '14:00',CURRENT_DATE-4+time '15:30','Kiểm kê phòng thí nghiệm',NULL);

INSERT INTO access_log(person_id,lab_id,entry_time,exit_time,purpose,approved_by) VALUES(41,2,CURRENT_DATE-4+time '8:00',CURRENT_DATE-4+time '9:30','Nghiên cứu cảm biến',NULL);

INSERT INTO access_log(person_id,lab_id,entry_time,exit_time,purpose,approved_by) VALUES(42,2,CURRENT_DATE-4+time '9:00',CURRENT_DATE-4+time '10:30','Phân tích mẫu vật liệu',NULL);

INSERT INTO access_log(person_id,lab_id,entry_time,exit_time,purpose,approved_by) VALUES(43,1,CURRENT_DATE-4+time '18:00',CURRENT_DATE-4+time '19:30','Thực hành thiết bị',1);

INSERT INTO access_log(person_id,lab_id,entry_time,exit_time,purpose,approved_by) VALUES(44,2,CURRENT_DATE-4+time '11:00',CURRENT_DATE-4+time '12:30','Kiểm kê phòng thí nghiệm',NULL);

INSERT INTO access_log(person_id,lab_id,entry_time,exit_time,purpose,approved_by) VALUES(45,2,CURRENT_DATE-5+time '12:00',CURRENT_DATE-5+time '13:30','Nghiên cứu cảm biến',NULL);

INSERT INTO access_log(person_id,lab_id,entry_time,exit_time,purpose,approved_by) VALUES(46,1,CURRENT_DATE-5+time '13:00',CURRENT_DATE-5+time '14:30','Phân tích mẫu vật liệu',NULL);

INSERT INTO access_log(person_id,lab_id,entry_time,exit_time,purpose,approved_by) VALUES(47,2,CURRENT_DATE-5+time '14:00',CURRENT_DATE-5+time '15:30','Thực hành thiết bị',NULL);

INSERT INTO access_log(person_id,lab_id,entry_time,exit_time,purpose,approved_by) VALUES(48,2,CURRENT_DATE-5+time '8:00',CURRENT_DATE-5+time '9:30','Kiểm kê phòng thí nghiệm',NULL);

INSERT INTO access_log(person_id,lab_id,entry_time,exit_time,purpose,approved_by) VALUES(49,1,CURRENT_DATE-5+time '9:00',CURRENT_DATE-5+time '10:30','Nghiên cứu cảm biến',NULL);

INSERT INTO access_log(person_id,lab_id,entry_time,exit_time,purpose,approved_by) VALUES(50,2,CURRENT_DATE-5+time '10:00',CURRENT_DATE-5+time '11:30','Phân tích mẫu vật liệu',NULL);

INSERT INTO access_log(person_id,lab_id,entry_time,exit_time,purpose,approved_by) VALUES(51,2,CURRENT_DATE-5+time '11:00',CURRENT_DATE-5+time '12:30','Thực hành thiết bị',NULL);

INSERT INTO access_log(person_id,lab_id,entry_time,exit_time,purpose,approved_by) VALUES(52,1,CURRENT_DATE-5+time '12:00',CURRENT_DATE-5+time '13:30','Kiểm kê phòng thí nghiệm',NULL);

INSERT INTO access_log(person_id,lab_id,entry_time,exit_time,purpose,approved_by) VALUES(53,2,CURRENT_DATE-6+time '18:00',CURRENT_DATE-6+time '19:30','Nghiên cứu cảm biến',1);

INSERT INTO access_log(person_id,lab_id,entry_time,exit_time,purpose,approved_by) VALUES(54,2,CURRENT_DATE-6+time '14:00',CURRENT_DATE-6+time '15:30','Phân tích mẫu vật liệu',NULL);

INSERT INTO access_log(person_id,lab_id,entry_time,exit_time,purpose,approved_by) VALUES(55,1,CURRENT_DATE-6+time '8:00',CURRENT_DATE-6+time '9:30','Thực hành thiết bị',NULL);

INSERT INTO access_log(person_id,lab_id,entry_time,exit_time,purpose,approved_by) VALUES(56,2,CURRENT_DATE-6+time '9:00',CURRENT_DATE-6+time '10:30','Kiểm kê phòng thí nghiệm',NULL);

INSERT INTO access_log(person_id,lab_id,entry_time,exit_time,purpose,approved_by) VALUES(57,2,CURRENT_DATE-6+time '10:00',CURRENT_DATE-6+time '11:30','Nghiên cứu cảm biến',NULL);

INSERT INTO access_log(person_id,lab_id,entry_time,exit_time,purpose,approved_by) VALUES(58,1,CURRENT_DATE-6+time '11:00',CURRENT_DATE-6+time '12:30','Phân tích mẫu vật liệu',NULL);

INSERT INTO access_log(person_id,lab_id,entry_time,exit_time,purpose,approved_by) VALUES(59,2,CURRENT_DATE-6+time '12:00',CURRENT_DATE-6+time '13:30','Thực hành thiết bị',NULL);

INSERT INTO access_log(person_id,lab_id,entry_time,exit_time,purpose,approved_by) VALUES(60,2,CURRENT_DATE-6+time '13:00',CURRENT_DATE-6+time '14:30','Kiểm kê phòng thí nghiệm',NULL);

INSERT INTO access_log(person_id,lab_id,entry_time,exit_time,purpose,approved_by) VALUES(61,1,CURRENT_DATE-7+time '14:00',CURRENT_DATE-7+time '15:30','Nghiên cứu cảm biến',NULL);

INSERT INTO access_log(person_id,lab_id,entry_time,exit_time,purpose,approved_by) VALUES(62,2,CURRENT_DATE-7+time '8:00',CURRENT_DATE-7+time '9:30','Phân tích mẫu vật liệu',NULL);

INSERT INTO access_log(person_id,lab_id,entry_time,exit_time,purpose,approved_by) VALUES(63,2,CURRENT_DATE-7+time '18:00',CURRENT_DATE-7+time '19:30','Thực hành thiết bị',NULL);

INSERT INTO access_log(person_id,lab_id,entry_time,exit_time,purpose,approved_by) VALUES(64,1,CURRENT_DATE-7+time '10:00',CURRENT_DATE-7+time '11:30','Kiểm kê phòng thí nghiệm',NULL);

INSERT INTO access_log(person_id,lab_id,entry_time,exit_time,purpose,approved_by) VALUES(65,2,CURRENT_DATE-7+time '11:00',CURRENT_DATE-7+time '12:30','Nghiên cứu cảm biến',NULL);

INSERT INTO access_log(person_id,lab_id,entry_time,exit_time,purpose,approved_by) VALUES(66,2,CURRENT_DATE-7+time '12:00',CURRENT_DATE-7+time '13:30','Phân tích mẫu vật liệu',NULL);

INSERT INTO access_log(person_id,lab_id,entry_time,exit_time,purpose,approved_by) VALUES(67,1,CURRENT_DATE-7+time '13:00',CURRENT_DATE-7+time '14:30','Thực hành thiết bị',NULL);

INSERT INTO access_log(person_id,lab_id,entry_time,exit_time,purpose,approved_by) VALUES(68,2,CURRENT_DATE-7+time '14:00',CURRENT_DATE-7+time '15:30','Kiểm kê phòng thí nghiệm',NULL);

INSERT INTO access_log(person_id,lab_id,entry_time,exit_time,purpose,approved_by) VALUES(69,2,CURRENT_DATE-8+time '8:00',CURRENT_DATE-8+time '9:30','Nghiên cứu cảm biến',NULL);

INSERT INTO access_log(person_id,lab_id,entry_time,exit_time,purpose,approved_by) VALUES(70,1,CURRENT_DATE-8+time '9:00',CURRENT_DATE-8+time '10:30','Phân tích mẫu vật liệu',NULL);

INSERT INTO access_log(person_id,lab_id,entry_time,exit_time,purpose,approved_by) VALUES(71,2,CURRENT_DATE-8+time '10:00',CURRENT_DATE-8+time '11:30','Thực hành thiết bị',NULL);

INSERT INTO access_log(person_id,lab_id,entry_time,exit_time,purpose,approved_by) VALUES(72,2,CURRENT_DATE-8+time '11:00',CURRENT_DATE-8+time '12:30','Kiểm kê phòng thí nghiệm',NULL);

INSERT INTO access_log(person_id,lab_id,entry_time,exit_time,purpose,approved_by) VALUES(73,1,CURRENT_DATE-8+time '18:00',CURRENT_DATE-8+time '19:30','Nghiên cứu cảm biến',NULL);

INSERT INTO access_log(person_id,lab_id,entry_time,exit_time,purpose,approved_by) VALUES(74,2,CURRENT_DATE-8+time '13:00',CURRENT_DATE-8+time '14:30','Phân tích mẫu vật liệu',NULL);

INSERT INTO access_log(person_id,lab_id,entry_time,exit_time,purpose,approved_by) VALUES(75,2,CURRENT_DATE-8+time '14:00',CURRENT_DATE-8+time '15:30','Thực hành thiết bị',NULL);

INSERT INTO access_log(person_id,lab_id,entry_time,exit_time,purpose,approved_by) VALUES(76,1,CURRENT_DATE-8+time '8:00',CURRENT_DATE-8+time '9:30','Kiểm kê phòng thí nghiệm',NULL);

INSERT INTO access_log(person_id,lab_id,entry_time,exit_time,purpose,approved_by) VALUES(77,2,CURRENT_DATE-9+time '9:00',CURRENT_DATE-9+time '10:30','Nghiên cứu cảm biến',NULL);

INSERT INTO access_log(person_id,lab_id,entry_time,exit_time,purpose,approved_by) VALUES(78,2,CURRENT_DATE-9+time '10:00',CURRENT_DATE-9+time '11:30','Phân tích mẫu vật liệu',NULL);

INSERT INTO access_log(person_id,lab_id,entry_time,exit_time,purpose,approved_by) VALUES(79,1,CURRENT_DATE-9+time '11:00',CURRENT_DATE-9+time '12:30','Thực hành thiết bị',NULL);

INSERT INTO access_log(person_id,lab_id,entry_time,exit_time,purpose,approved_by) VALUES(80,2,CURRENT_DATE-9+time '12:00',CURRENT_DATE-9+time '13:30','Kiểm kê phòng thí nghiệm',NULL);

INSERT INTO access_log(person_id,lab_id,entry_time,exit_time,purpose,approved_by) VALUES(81,2,CURRENT_DATE-9+time '13:00',CURRENT_DATE-9+time '14:30','Nghiên cứu cảm biến',NULL);

INSERT INTO access_log(person_id,lab_id,entry_time,exit_time,purpose,approved_by) VALUES(82,1,CURRENT_DATE-9+time '14:00',CURRENT_DATE-9+time '15:30','Phân tích mẫu vật liệu',NULL);

INSERT INTO access_log(person_id,lab_id,entry_time,exit_time,purpose,approved_by) VALUES(83,2,CURRENT_DATE-9+time '18:00',CURRENT_DATE-9+time '19:30','Thực hành thiết bị',NULL);

INSERT INTO access_log(person_id,lab_id,entry_time,exit_time,purpose,approved_by) VALUES(84,2,CURRENT_DATE-9+time '9:00',CURRENT_DATE-9+time '10:30','Kiểm kê phòng thí nghiệm',NULL);

INSERT INTO access_log(person_id,lab_id,entry_time,exit_time,purpose,approved_by) VALUES(85,1,CURRENT_DATE-10+time '10:00',CURRENT_DATE-10+time '11:30','Nghiên cứu cảm biến',NULL);

INSERT INTO access_log(person_id,lab_id,entry_time,exit_time,purpose,approved_by) VALUES(86,2,CURRENT_DATE-10+time '11:00',CURRENT_DATE-10+time '12:30','Phân tích mẫu vật liệu',NULL);

INSERT INTO access_log(person_id,lab_id,entry_time,exit_time,purpose,approved_by) VALUES(87,2,CURRENT_DATE-10+time '12:00',CURRENT_DATE-10+time '13:30','Thực hành thiết bị',NULL);

INSERT INTO access_log(person_id,lab_id,entry_time,exit_time,purpose,approved_by) VALUES(88,1,CURRENT_DATE-10+time '13:00',CURRENT_DATE-10+time '14:30','Kiểm kê phòng thí nghiệm',NULL);

INSERT INTO access_log(person_id,lab_id,entry_time,exit_time,purpose,approved_by) VALUES(89,2,CURRENT_DATE-10+time '14:00',CURRENT_DATE-10+time '15:30','Nghiên cứu cảm biến',NULL);

INSERT INTO access_log(person_id,lab_id,entry_time,exit_time,purpose,approved_by) VALUES(90,2,CURRENT_DATE-10+time '8:00',CURRENT_DATE-10+time '9:30','Phân tích mẫu vật liệu',NULL);

INSERT INTO access_log(person_id,lab_id,entry_time,exit_time,purpose,approved_by) VALUES(91,1,CURRENT_DATE-10+time '9:00',CURRENT_DATE-10+time '10:30','Thực hành thiết bị',NULL);

INSERT INTO access_log(person_id,lab_id,entry_time,exit_time,purpose,approved_by) VALUES(92,2,CURRENT_DATE-10+time '10:00',CURRENT_DATE-10+time '11:30','Kiểm kê phòng thí nghiệm',NULL);

INSERT INTO access_log(person_id,lab_id,entry_time,exit_time,purpose,approved_by) VALUES(93,2,CURRENT_DATE-11+time '18:00',CURRENT_DATE-11+time '19:30','Nghiên cứu cảm biến',NULL);

INSERT INTO access_log(person_id,lab_id,entry_time,exit_time,purpose,approved_by) VALUES(94,1,CURRENT_DATE-11+time '12:00',CURRENT_DATE-11+time '13:30','Phân tích mẫu vật liệu',NULL);

INSERT INTO access_log(person_id,lab_id,entry_time,exit_time,purpose,approved_by) VALUES(95,2,CURRENT_DATE-11+time '13:00',CURRENT_DATE-11+time '14:30','Thực hành thiết bị',NULL);

INSERT INTO access_log(person_id,lab_id,entry_time,exit_time,purpose,approved_by) VALUES(96,2,CURRENT_DATE-11+time '14:00',CURRENT_DATE-11+time '15:30','Kiểm kê phòng thí nghiệm',NULL);

INSERT INTO access_log(person_id,lab_id,entry_time,exit_time,purpose,approved_by) VALUES(97,1,CURRENT_DATE-11+time '8:00',CURRENT_DATE-11+time '9:30','Nghiên cứu cảm biến',NULL);

INSERT INTO access_log(person_id,lab_id,entry_time,exit_time,purpose,approved_by) VALUES(98,2,CURRENT_DATE-11+time '9:00',CURRENT_DATE-11+time '10:30','Phân tích mẫu vật liệu',NULL);

INSERT INTO access_log(person_id,lab_id,entry_time,exit_time,purpose,approved_by) VALUES(99,2,CURRENT_DATE-11+time '10:00',CURRENT_DATE-11+time '11:30','Thực hành thiết bị',NULL);

INSERT INTO access_log(person_id,lab_id,entry_time,exit_time,purpose,approved_by) VALUES(100,1,CURRENT_DATE-11+time '11:00',CURRENT_DATE-11+time '12:30','Kiểm kê phòng thí nghiệm',NULL);

INSERT INTO access_log(person_id,lab_id,entry_time,exit_time,purpose,approved_by) VALUES(13,2,CURRENT_DATE-12+time '12:00',CURRENT_DATE-12+time '13:30','Nghiên cứu cảm biến',NULL);

INSERT INTO access_log(person_id,lab_id,entry_time,exit_time,purpose,approved_by) VALUES(14,2,CURRENT_DATE-12+time '13:00',CURRENT_DATE-12+time '14:30','Phân tích mẫu vật liệu',NULL);

INSERT INTO access_log(person_id,lab_id,entry_time,exit_time,purpose,approved_by) VALUES(15,1,CURRENT_DATE-12+time '18:00',CURRENT_DATE-12+time '19:30','Thực hành thiết bị',1);

INSERT INTO access_log(person_id,lab_id,entry_time,exit_time,purpose,approved_by) VALUES(16,2,CURRENT_DATE-12+time '8:00',CURRENT_DATE-12+time '9:30','Kiểm kê phòng thí nghiệm',NULL);

INSERT INTO access_log(person_id,lab_id,entry_time,exit_time,purpose,approved_by) VALUES(17,2,CURRENT_DATE-12+time '9:00',CURRENT_DATE-12+time '10:30','Nghiên cứu cảm biến',NULL);

INSERT INTO access_log(person_id,lab_id,entry_time,exit_time,purpose,approved_by) VALUES(18,1,CURRENT_DATE-12+time '10:00',CURRENT_DATE-12+time '11:30','Phân tích mẫu vật liệu',NULL);

INSERT INTO access_log(person_id,lab_id,entry_time,exit_time,purpose,approved_by) VALUES(19,2,CURRENT_DATE-12+time '11:00',CURRENT_DATE-12+time '12:30','Thực hành thiết bị',NULL);

INSERT INTO access_log(person_id,lab_id,entry_time,exit_time,purpose,approved_by) VALUES(20,2,CURRENT_DATE-12+time '12:00',CURRENT_DATE-12+time '13:30','Kiểm kê phòng thí nghiệm',NULL);

INSERT INTO access_log(person_id,lab_id,entry_time,exit_time,purpose,approved_by) VALUES(21,1,CURRENT_DATE-13+time '13:00',CURRENT_DATE-13+time '14:30','Nghiên cứu cảm biến',NULL);

INSERT INTO access_log(person_id,lab_id,entry_time,exit_time,purpose,approved_by) VALUES(22,2,CURRENT_DATE-13+time '14:00',CURRENT_DATE-13+time '15:30','Phân tích mẫu vật liệu',NULL);

INSERT INTO access_log(person_id,lab_id,entry_time,exit_time,purpose,approved_by) VALUES(23,2,CURRENT_DATE-13+time '8:00',CURRENT_DATE-13+time '9:30','Thực hành thiết bị',NULL);

INSERT INTO access_log(person_id,lab_id,entry_time,exit_time,purpose,approved_by) VALUES(24,1,CURRENT_DATE-13+time '9:00',CURRENT_DATE-13+time '10:30','Kiểm kê phòng thí nghiệm',NULL);

INSERT INTO access_log(person_id,lab_id,entry_time,exit_time,purpose,approved_by) VALUES(25,2,CURRENT_DATE-13+time '18:00',CURRENT_DATE-13+time '19:30','Nghiên cứu cảm biến',1);

INSERT INTO access_log(person_id,lab_id,entry_time,exit_time,purpose,approved_by) VALUES(26,2,CURRENT_DATE-13+time '11:00',CURRENT_DATE-13+time '12:30','Phân tích mẫu vật liệu',NULL);

INSERT INTO access_log(person_id,lab_id,entry_time,exit_time,purpose,approved_by) VALUES(27,1,CURRENT_DATE-13+time '12:00',CURRENT_DATE-13+time '13:30','Thực hành thiết bị',NULL);

INSERT INTO access_log(person_id,lab_id,entry_time,exit_time,purpose,approved_by) VALUES(28,2,CURRENT_DATE-13+time '13:00',CURRENT_DATE-13+time '14:30','Kiểm kê phòng thí nghiệm',NULL);

INSERT INTO access_log(person_id,lab_id,entry_time,exit_time,purpose,approved_by) VALUES(29,2,CURRENT_DATE-14+time '14:00',CURRENT_DATE-14+time '15:30','Nghiên cứu cảm biến',NULL);

INSERT INTO access_log(person_id,lab_id,entry_time,exit_time,purpose,approved_by) VALUES(30,1,CURRENT_DATE-14+time '8:00',CURRENT_DATE-14+time '9:30','Phân tích mẫu vật liệu',NULL);

INSERT INTO access_log(person_id,lab_id,entry_time,exit_time,purpose,approved_by) VALUES(31,2,CURRENT_DATE-14+time '9:00',CURRENT_DATE-14+time '10:30','Thực hành thiết bị',NULL);

INSERT INTO access_log(person_id,lab_id,entry_time,exit_time,purpose,approved_by) VALUES(32,2,CURRENT_DATE-14+time '10:00',CURRENT_DATE-14+time '11:30','Kiểm kê phòng thí nghiệm',NULL);

INSERT INTO access_log(person_id,lab_id,entry_time,exit_time,purpose,approved_by) VALUES(33,1,CURRENT_DATE-14+time '11:00',CURRENT_DATE-14+time '12:30','Nghiên cứu cảm biến',NULL);

INSERT INTO access_log(person_id,lab_id,entry_time,exit_time,purpose,approved_by) VALUES(34,2,CURRENT_DATE-14+time '12:00',CURRENT_DATE-14+time '13:30','Phân tích mẫu vật liệu',NULL);

INSERT INTO access_log(person_id,lab_id,entry_time,exit_time,purpose,approved_by) VALUES(35,2,CURRENT_DATE-14+time '18:00',CURRENT_DATE-14+time '19:30','Thực hành thiết bị',1);

INSERT INTO access_log(person_id,lab_id,entry_time,exit_time,purpose,approved_by) VALUES(36,1,CURRENT_DATE-14+time '14:00',CURRENT_DATE-14+time '15:30','Kiểm kê phòng thí nghiệm',NULL);

INSERT INTO access_log(person_id,lab_id,entry_time,exit_time,purpose,approved_by) VALUES(37,2,CURRENT_DATE-15+time '8:00',CURRENT_DATE-15+time '9:30','Nghiên cứu cảm biến',NULL);

INSERT INTO access_log(person_id,lab_id,entry_time,exit_time,purpose,approved_by) VALUES(38,2,CURRENT_DATE-15+time '9:00',CURRENT_DATE-15+time '10:30','Phân tích mẫu vật liệu',NULL);

INSERT INTO access_log(person_id,lab_id,entry_time,exit_time,purpose,approved_by) VALUES(39,1,CURRENT_DATE-15+time '10:00',CURRENT_DATE-15+time '11:30','Thực hành thiết bị',NULL);

INSERT INTO access_log(person_id,lab_id,entry_time,exit_time,purpose,approved_by) VALUES(40,2,CURRENT_DATE-15+time '11:00',CURRENT_DATE-15+time '12:30','Kiểm kê phòng thí nghiệm',NULL);

INSERT INTO access_log(person_id,lab_id,entry_time,exit_time,purpose,approved_by) VALUES(41,2,CURRENT_DATE-15+time '12:00',CURRENT_DATE-15+time '13:30','Nghiên cứu cảm biến',NULL);

INSERT INTO access_log(person_id,lab_id,entry_time,exit_time,purpose,approved_by) VALUES(42,1,CURRENT_DATE-15+time '13:00',CURRENT_DATE-15+time '14:30','Phân tích mẫu vật liệu',NULL);

INSERT INTO access_log(person_id,lab_id,entry_time,exit_time,purpose,approved_by) VALUES(43,2,CURRENT_DATE-15+time '14:00',CURRENT_DATE-15+time '15:30','Thực hành thiết bị',NULL);

INSERT INTO access_log(person_id,lab_id,entry_time,exit_time,purpose,approved_by) VALUES(44,2,CURRENT_DATE-15+time '8:00',CURRENT_DATE-15+time '9:30','Kiểm kê phòng thí nghiệm',NULL);

INSERT INTO access_log(person_id,lab_id,entry_time,exit_time,purpose,approved_by) VALUES(45,1,CURRENT_DATE-16+time '18:00',CURRENT_DATE-16+time '19:30','Nghiên cứu cảm biến',1);

INSERT INTO access_log(person_id,lab_id,entry_time,exit_time,purpose,approved_by) VALUES(46,2,CURRENT_DATE-16+time '10:00',CURRENT_DATE-16+time '11:30','Phân tích mẫu vật liệu',NULL);

INSERT INTO access_log(person_id,lab_id,entry_time,exit_time,purpose,approved_by) VALUES(47,2,CURRENT_DATE-16+time '11:00',CURRENT_DATE-16+time '12:30','Thực hành thiết bị',NULL);

INSERT INTO access_log(person_id,lab_id,entry_time,exit_time,purpose,approved_by) VALUES(48,1,CURRENT_DATE-16+time '12:00',CURRENT_DATE-16+time '13:30','Kiểm kê phòng thí nghiệm',NULL);

INSERT INTO access_log(person_id,lab_id,entry_time,exit_time,purpose,approved_by) VALUES(49,2,CURRENT_DATE-16+time '13:00',CURRENT_DATE-16+time '14:30','Nghiên cứu cảm biến',NULL);

INSERT INTO access_log(person_id,lab_id,entry_time,exit_time,purpose,approved_by) VALUES(50,2,CURRENT_DATE-16+time '14:00',CURRENT_DATE-16+time '15:30','Phân tích mẫu vật liệu',NULL);

INSERT INTO access_log(person_id,lab_id,entry_time,exit_time,purpose,approved_by) VALUES(51,1,CURRENT_DATE-16+time '8:00',CURRENT_DATE-16+time '9:30','Thực hành thiết bị',NULL);

INSERT INTO access_log(person_id,lab_id,entry_time,exit_time,purpose,approved_by) VALUES(52,2,CURRENT_DATE-16+time '9:00',CURRENT_DATE-16+time '10:30','Kiểm kê phòng thí nghiệm',NULL);

INSERT INTO access_log(person_id,lab_id,entry_time,exit_time,purpose,approved_by) VALUES(53,2,CURRENT_DATE-17+time '10:00',CURRENT_DATE-17+time '11:30','Nghiên cứu cảm biến',NULL);

INSERT INTO access_log(person_id,lab_id,entry_time,exit_time,purpose,approved_by) VALUES(54,1,CURRENT_DATE-17+time '11:00',CURRENT_DATE-17+time '12:30','Phân tích mẫu vật liệu',NULL);

INSERT INTO access_log(person_id,lab_id,entry_time,exit_time,purpose,approved_by) VALUES(55,2,CURRENT_DATE-17+time '18:00',CURRENT_DATE-17+time '19:30','Thực hành thiết bị',1);

INSERT INTO access_log(person_id,lab_id,entry_time,exit_time,purpose,approved_by) VALUES(56,2,CURRENT_DATE-17+time '13:00',CURRENT_DATE-17+time '14:30','Kiểm kê phòng thí nghiệm',NULL);

INSERT INTO access_log(person_id,lab_id,entry_time,exit_time,purpose,approved_by) VALUES(57,1,CURRENT_DATE-17+time '14:00',CURRENT_DATE-17+time '15:30','Nghiên cứu cảm biến',NULL);

INSERT INTO access_log(person_id,lab_id,entry_time,exit_time,purpose,approved_by) VALUES(58,2,CURRENT_DATE-17+time '8:00',CURRENT_DATE-17+time '9:30','Phân tích mẫu vật liệu',NULL);

INSERT INTO access_log(person_id,lab_id,entry_time,exit_time,purpose,approved_by) VALUES(59,2,CURRENT_DATE-17+time '9:00',CURRENT_DATE-17+time '10:30','Thực hành thiết bị',NULL);

INSERT INTO access_log(person_id,lab_id,entry_time,exit_time,purpose,approved_by) VALUES(60,1,CURRENT_DATE-17+time '10:00',CURRENT_DATE-17+time '11:30','Kiểm kê phòng thí nghiệm',NULL);

INSERT INTO access_log(person_id,lab_id,entry_time,exit_time,purpose,approved_by) VALUES(61,2,CURRENT_DATE-18+time '11:00',CURRENT_DATE-18+time '12:30','Nghiên cứu cảm biến',NULL);

INSERT INTO access_log(person_id,lab_id,entry_time,exit_time,purpose,approved_by) VALUES(62,2,CURRENT_DATE-18+time '12:00',CURRENT_DATE-18+time '13:30','Phân tích mẫu vật liệu',NULL);

INSERT INTO access_log(person_id,lab_id,entry_time,exit_time,purpose,approved_by) VALUES(63,1,CURRENT_DATE-18+time '13:00',CURRENT_DATE-18+time '14:30','Thực hành thiết bị',NULL);

INSERT INTO access_log(person_id,lab_id,entry_time,exit_time,purpose,approved_by) VALUES(64,2,CURRENT_DATE-18+time '14:00',CURRENT_DATE-18+time '15:30','Kiểm kê phòng thí nghiệm',NULL);

INSERT INTO access_log(person_id,lab_id,entry_time,exit_time,purpose,approved_by) VALUES(65,2,CURRENT_DATE-18+time '18:00',CURRENT_DATE-18+time '19:30','Nghiên cứu cảm biến',NULL);

INSERT INTO access_log(person_id,lab_id,entry_time,exit_time,purpose,approved_by) VALUES(66,1,CURRENT_DATE-18+time '9:00',CURRENT_DATE-18+time '10:30','Phân tích mẫu vật liệu',NULL);

INSERT INTO access_log(person_id,lab_id,entry_time,exit_time,purpose,approved_by) VALUES(67,2,CURRENT_DATE-18+time '10:00',CURRENT_DATE-18+time '11:30','Thực hành thiết bị',NULL);

INSERT INTO access_log(person_id,lab_id,entry_time,exit_time,purpose,approved_by) VALUES(68,2,CURRENT_DATE-18+time '11:00',CURRENT_DATE-18+time '12:30','Kiểm kê phòng thí nghiệm',NULL);

INSERT INTO access_log(person_id,lab_id,entry_time,exit_time,purpose,approved_by) VALUES(69,1,CURRENT_DATE-19+time '12:00',CURRENT_DATE-19+time '13:30','Nghiên cứu cảm biến',NULL);

INSERT INTO access_log(person_id,lab_id,entry_time,exit_time,purpose,approved_by) VALUES(70,2,CURRENT_DATE-19+time '13:00',CURRENT_DATE-19+time '14:30','Phân tích mẫu vật liệu',NULL);

INSERT INTO access_log(person_id,lab_id,entry_time,exit_time,purpose,approved_by) VALUES(71,2,CURRENT_DATE-19+time '14:00',CURRENT_DATE-19+time '15:30','Thực hành thiết bị',NULL);

INSERT INTO access_log(person_id,lab_id,entry_time,exit_time,purpose,approved_by) VALUES(72,1,CURRENT_DATE-19+time '8:00',CURRENT_DATE-19+time '9:30','Kiểm kê phòng thí nghiệm',NULL);

INSERT INTO access_log(person_id,lab_id,entry_time,exit_time,purpose,approved_by) VALUES(73,2,CURRENT_DATE-19+time '9:00',CURRENT_DATE-19+time '10:30','Nghiên cứu cảm biến',NULL);

INSERT INTO access_log(person_id,lab_id,entry_time,exit_time,purpose,approved_by) VALUES(74,2,CURRENT_DATE-19+time '10:00',CURRENT_DATE-19+time '11:30','Phân tích mẫu vật liệu',NULL);

INSERT INTO access_log(person_id,lab_id,entry_time,exit_time,purpose,approved_by) VALUES(75,1,CURRENT_DATE-19+time '18:00',CURRENT_DATE-19+time '19:30','Thực hành thiết bị',NULL);

INSERT INTO access_log(person_id,lab_id,entry_time,exit_time,purpose,approved_by) VALUES(76,2,CURRENT_DATE-19+time '12:00',CURRENT_DATE-19+time '13:30','Kiểm kê phòng thí nghiệm',NULL);

INSERT INTO access_log(person_id,lab_id,entry_time,exit_time,purpose,approved_by) VALUES(77,2,CURRENT_DATE-20+time '13:00',CURRENT_DATE-20+time '14:30','Nghiên cứu cảm biến',NULL);

INSERT INTO access_log(person_id,lab_id,entry_time,exit_time,purpose,approved_by) VALUES(78,1,CURRENT_DATE-20+time '14:00',CURRENT_DATE-20+time '15:30','Phân tích mẫu vật liệu',NULL);

INSERT INTO access_log(person_id,lab_id,entry_time,exit_time,purpose,approved_by) VALUES(79,2,CURRENT_DATE-20+time '8:00',CURRENT_DATE-20+time '9:30','Thực hành thiết bị',NULL);

INSERT INTO access_log(person_id,lab_id,entry_time,exit_time,purpose,approved_by) VALUES(80,2,CURRENT_DATE-20+time '9:00',CURRENT_DATE-20+time '10:30','Kiểm kê phòng thí nghiệm',NULL);

INSERT INTO access_log(person_id,lab_id,entry_time,exit_time,purpose,approved_by) VALUES(81,1,CURRENT_DATE-20+time '10:00',CURRENT_DATE-20+time '11:30','Nghiên cứu cảm biến',NULL);

INSERT INTO access_log(person_id,lab_id,entry_time,exit_time,purpose,approved_by) VALUES(82,2,CURRENT_DATE-20+time '11:00',CURRENT_DATE-20+time '12:30','Phân tích mẫu vật liệu',NULL);

INSERT INTO access_log(person_id,lab_id,entry_time,exit_time,purpose,approved_by) VALUES(83,2,CURRENT_DATE-20+time '12:00',CURRENT_DATE-20+time '13:30','Thực hành thiết bị',NULL);

INSERT INTO access_log(person_id,lab_id,entry_time,exit_time,purpose,approved_by) VALUES(84,1,CURRENT_DATE-20+time '13:00',CURRENT_DATE-20+time '14:30','Kiểm kê phòng thí nghiệm',NULL);

INSERT INTO access_log(person_id,lab_id,entry_time,exit_time,purpose,approved_by) VALUES(85,2,CURRENT_DATE-21+time '18:00',CURRENT_DATE-21+time '19:30','Nghiên cứu cảm biến',NULL);

INSERT INTO access_log(person_id,lab_id,entry_time,exit_time,purpose,approved_by) VALUES(86,2,CURRENT_DATE-21+time '8:00',CURRENT_DATE-21+time '9:30','Phân tích mẫu vật liệu',NULL);

INSERT INTO access_log(person_id,lab_id,entry_time,exit_time,purpose,approved_by) VALUES(87,1,CURRENT_DATE-21+time '9:00',CURRENT_DATE-21+time '10:30','Thực hành thiết bị',NULL);

INSERT INTO access_log(person_id,lab_id,entry_time,exit_time,purpose,approved_by) VALUES(88,2,CURRENT_DATE-21+time '10:00',CURRENT_DATE-21+time '11:30','Kiểm kê phòng thí nghiệm',NULL);

INSERT INTO access_log(person_id,lab_id,entry_time,exit_time,purpose,approved_by) VALUES(89,2,CURRENT_DATE-21+time '11:00',CURRENT_DATE-21+time '12:30','Nghiên cứu cảm biến',NULL);

INSERT INTO access_log(person_id,lab_id,entry_time,exit_time,purpose,approved_by) VALUES(90,1,CURRENT_DATE-21+time '12:00',CURRENT_DATE-21+time '13:30','Phân tích mẫu vật liệu',NULL);

INSERT INTO access_log(person_id,lab_id,entry_time,exit_time,purpose,approved_by) VALUES(91,2,CURRENT_DATE-21+time '13:00',CURRENT_DATE-21+time '14:30','Thực hành thiết bị',NULL);

INSERT INTO access_log(person_id,lab_id,entry_time,exit_time,purpose,approved_by) VALUES(92,2,CURRENT_DATE-21+time '14:00',CURRENT_DATE-21+time '15:30','Kiểm kê phòng thí nghiệm',NULL);

INSERT INTO access_log(person_id,lab_id,entry_time,exit_time,purpose,approved_by) VALUES(93,1,CURRENT_DATE-22+time '8:00',CURRENT_DATE-22+time '9:30','Nghiên cứu cảm biến',NULL);

INSERT INTO access_log(person_id,lab_id,entry_time,exit_time,purpose,approved_by) VALUES(94,2,CURRENT_DATE-22+time '9:00',CURRENT_DATE-22+time '10:30','Phân tích mẫu vật liệu',NULL);

INSERT INTO access_log(person_id,lab_id,entry_time,exit_time,purpose,approved_by) VALUES(95,2,CURRENT_DATE-22+time '18:00',CURRENT_DATE-22+time '19:30','Thực hành thiết bị',NULL);

INSERT INTO access_log(person_id,lab_id,entry_time,exit_time,purpose,approved_by) VALUES(96,1,CURRENT_DATE-22+time '11:00',CURRENT_DATE-22+time '12:30','Kiểm kê phòng thí nghiệm',NULL);

INSERT INTO access_log(person_id,lab_id,entry_time,exit_time,purpose,approved_by) VALUES(97,2,CURRENT_DATE-22+time '12:00',CURRENT_DATE-22+time '13:30','Nghiên cứu cảm biến',NULL);

INSERT INTO access_log(person_id,lab_id,entry_time,exit_time,purpose,approved_by) VALUES(98,2,CURRENT_DATE-22+time '13:00',CURRENT_DATE-22+time '14:30','Phân tích mẫu vật liệu',NULL);

INSERT INTO access_log(person_id,lab_id,entry_time,exit_time,purpose,approved_by) VALUES(99,1,CURRENT_DATE-22+time '14:00',CURRENT_DATE-22+time '15:30','Thực hành thiết bị',NULL);

INSERT INTO access_log(person_id,lab_id,entry_time,exit_time,purpose,approved_by) VALUES(100,2,CURRENT_DATE-22+time '8:00',CURRENT_DATE-22+time '9:30','Kiểm kê phòng thí nghiệm',NULL);

INSERT INTO access_log(person_id,lab_id,entry_time,exit_time,purpose,approved_by) VALUES(13,2,CURRENT_DATE-23+time '9:00',CURRENT_DATE-23+time '10:30','Nghiên cứu cảm biến',NULL);

INSERT INTO access_log(person_id,lab_id,entry_time,exit_time,purpose,approved_by) VALUES(14,1,CURRENT_DATE-23+time '10:00',CURRENT_DATE-23+time '11:30','Phân tích mẫu vật liệu',NULL);

INSERT INTO access_log(person_id,lab_id,entry_time,exit_time,purpose,approved_by) VALUES(15,2,CURRENT_DATE-23+time '11:00',CURRENT_DATE-23+time '12:30','Thực hành thiết bị',NULL);

INSERT INTO access_log(person_id,lab_id,entry_time,exit_time,purpose,approved_by) VALUES(16,2,CURRENT_DATE-23+time '12:00',CURRENT_DATE-23+time '13:30','Kiểm kê phòng thí nghiệm',NULL);

INSERT INTO access_log(person_id,lab_id,entry_time,exit_time,purpose,approved_by) VALUES(17,1,CURRENT_DATE-23+time '18:00',CURRENT_DATE-23+time '19:30','Nghiên cứu cảm biến',1);

INSERT INTO access_log(person_id,lab_id,entry_time,exit_time,purpose,approved_by) VALUES(18,2,CURRENT_DATE-23+time '14:00',CURRENT_DATE-23+time '15:30','Phân tích mẫu vật liệu',NULL);

INSERT INTO access_log(person_id,lab_id,entry_time,exit_time,purpose,approved_by) VALUES(19,2,CURRENT_DATE-23+time '8:00',CURRENT_DATE-23+time '9:30','Thực hành thiết bị',NULL);

INSERT INTO access_log(person_id,lab_id,entry_time,exit_time,purpose,approved_by) VALUES(20,1,CURRENT_DATE-23+time '9:00',CURRENT_DATE-23+time '10:30','Kiểm kê phòng thí nghiệm',NULL);

INSERT INTO access_log(person_id,lab_id,entry_time,exit_time,purpose,approved_by) VALUES(21,2,CURRENT_DATE-24+time '10:00',CURRENT_DATE-24+time '11:30','Nghiên cứu cảm biến',NULL);

INSERT INTO access_log(person_id,lab_id,entry_time,exit_time,purpose,approved_by) VALUES(22,2,CURRENT_DATE-24+time '11:00',CURRENT_DATE-24+time '12:30','Phân tích mẫu vật liệu',NULL);

INSERT INTO access_log(person_id,lab_id,entry_time,exit_time,purpose,approved_by) VALUES(23,1,CURRENT_DATE-24+time '12:00',CURRENT_DATE-24+time '13:30','Thực hành thiết bị',NULL);

INSERT INTO access_log(person_id,lab_id,entry_time,exit_time,purpose,approved_by) VALUES(24,2,CURRENT_DATE-24+time '13:00',CURRENT_DATE-24+time '14:30','Kiểm kê phòng thí nghiệm',NULL);

INSERT INTO access_log(person_id,lab_id,entry_time,exit_time,purpose,approved_by) VALUES(25,2,CURRENT_DATE-24+time '14:00',CURRENT_DATE-24+time '15:30','Nghiên cứu cảm biến',NULL);

INSERT INTO access_log(person_id,lab_id,entry_time,exit_time,purpose,approved_by) VALUES(26,1,CURRENT_DATE-24+time '8:00',CURRENT_DATE-24+time '9:30','Phân tích mẫu vật liệu',NULL);

INSERT INTO access_log(person_id,lab_id,entry_time,exit_time,purpose,approved_by) VALUES(27,2,CURRENT_DATE-24+time '18:00',CURRENT_DATE-24+time '19:30','Thực hành thiết bị',1);

INSERT INTO access_log(person_id,lab_id,entry_time,exit_time,purpose,approved_by) VALUES(28,2,CURRENT_DATE-24+time '10:00',CURRENT_DATE-24+time '11:30','Kiểm kê phòng thí nghiệm',NULL);

INSERT INTO access_log(person_id,lab_id,entry_time,exit_time,purpose,approved_by) VALUES(29,1,CURRENT_DATE-25+time '11:00',CURRENT_DATE-25+time '12:30','Nghiên cứu cảm biến',NULL);

INSERT INTO access_log(person_id,lab_id,entry_time,exit_time,purpose,approved_by) VALUES(30,2,CURRENT_DATE-25+time '12:00',CURRENT_DATE-25+time '13:30','Phân tích mẫu vật liệu',NULL);

INSERT INTO access_log(person_id,lab_id,entry_time,exit_time,purpose,approved_by) VALUES(31,2,CURRENT_DATE-25+time '13:00',CURRENT_DATE-25+time '14:30','Thực hành thiết bị',NULL);

INSERT INTO access_log(person_id,lab_id,entry_time,exit_time,purpose,approved_by) VALUES(32,1,CURRENT_DATE-25+time '14:00',CURRENT_DATE-25+time '15:30','Kiểm kê phòng thí nghiệm',NULL);

INSERT INTO access_log(person_id,lab_id,entry_time,exit_time,purpose,approved_by) VALUES(33,2,CURRENT_DATE-25+time '8:00',CURRENT_DATE-25+time '9:30','Nghiên cứu cảm biến',NULL);

INSERT INTO access_log(person_id,lab_id,entry_time,exit_time,purpose,approved_by) VALUES(34,2,CURRENT_DATE-25+time '9:00',CURRENT_DATE-25+time '10:30','Phân tích mẫu vật liệu',NULL);

INSERT INTO access_log(person_id,lab_id,entry_time,exit_time,purpose,approved_by) VALUES(35,1,CURRENT_DATE-25+time '10:00',CURRENT_DATE-25+time '11:30','Thực hành thiết bị',NULL);

INSERT INTO access_log(person_id,lab_id,entry_time,exit_time,purpose,approved_by) VALUES(36,2,CURRENT_DATE-25+time '11:00',CURRENT_DATE-25+time '12:30','Kiểm kê phòng thí nghiệm',NULL);

INSERT INTO access_log(person_id,lab_id,entry_time,exit_time,purpose,approved_by) VALUES(37,2,CURRENT_DATE-26+time '18:00',CURRENT_DATE-26+time '19:30','Nghiên cứu cảm biến',1);

INSERT INTO access_log(person_id,lab_id,entry_time,exit_time,purpose,approved_by) VALUES(38,1,CURRENT_DATE-26+time '13:00',CURRENT_DATE-26+time '14:30','Phân tích mẫu vật liệu',NULL);

INSERT INTO access_log(person_id,lab_id,entry_time,exit_time,purpose,approved_by) VALUES(39,2,CURRENT_DATE-26+time '14:00',CURRENT_DATE-26+time '15:30','Thực hành thiết bị',NULL);

INSERT INTO access_log(person_id,lab_id,entry_time,exit_time,purpose,approved_by) VALUES(40,2,CURRENT_DATE-26+time '8:00',CURRENT_DATE-26+time '9:30','Kiểm kê phòng thí nghiệm',NULL);

INSERT INTO access_log(person_id,lab_id,entry_time,exit_time,purpose,approved_by) VALUES(41,1,CURRENT_DATE-26+time '9:00',CURRENT_DATE-26+time '10:30','Nghiên cứu cảm biến',NULL);

INSERT INTO access_log(person_id,lab_id,entry_time,exit_time,purpose,approved_by) VALUES(42,2,CURRENT_DATE-26+time '10:00',CURRENT_DATE-26+time '11:30','Phân tích mẫu vật liệu',NULL);

INSERT INTO access_log(person_id,lab_id,entry_time,exit_time,purpose,approved_by) VALUES(43,2,CURRENT_DATE-26+time '11:00',CURRENT_DATE-26+time '12:30','Thực hành thiết bị',NULL);

INSERT INTO access_log(person_id,lab_id,entry_time,exit_time,purpose,approved_by) VALUES(44,1,CURRENT_DATE-26+time '12:00',CURRENT_DATE-26+time '13:30','Kiểm kê phòng thí nghiệm',NULL);

INSERT INTO access_log(person_id,lab_id,entry_time,exit_time,purpose,approved_by) VALUES(45,2,CURRENT_DATE-27+time '13:00',CURRENT_DATE-27+time '14:30','Nghiên cứu cảm biến',NULL);

INSERT INTO access_log(person_id,lab_id,entry_time,exit_time,purpose,approved_by) VALUES(46,2,CURRENT_DATE-27+time '14:00',CURRENT_DATE-27+time '15:30','Phân tích mẫu vật liệu',NULL);

INSERT INTO access_log(person_id,lab_id,entry_time,exit_time,purpose,approved_by) VALUES(47,1,CURRENT_DATE-27+time '18:00',CURRENT_DATE-27+time '19:30','Thực hành thiết bị',1);

INSERT INTO access_log(person_id,lab_id,entry_time,exit_time,purpose,approved_by) VALUES(48,2,CURRENT_DATE-27+time '9:00',CURRENT_DATE-27+time '10:30','Kiểm kê phòng thí nghiệm',NULL);

INSERT INTO access_log(person_id,lab_id,entry_time,exit_time,purpose,approved_by) VALUES(49,2,CURRENT_DATE-27+time '10:00',CURRENT_DATE-27+time '11:30','Nghiên cứu cảm biến',NULL);

INSERT INTO access_log(person_id,lab_id,entry_time,exit_time,purpose,approved_by) VALUES(50,1,CURRENT_DATE-27+time '11:00',CURRENT_DATE-27+time '12:30','Phân tích mẫu vật liệu',NULL);

INSERT INTO access_log(person_id,lab_id,entry_time,exit_time,purpose,approved_by) VALUES(51,2,CURRENT_DATE-27+time '12:00',CURRENT_DATE-27+time '13:30','Thực hành thiết bị',NULL);

INSERT INTO access_log(person_id,lab_id,entry_time,exit_time,purpose,approved_by) VALUES(52,2,CURRENT_DATE-27+time '13:00',CURRENT_DATE-27+time '14:30','Kiểm kê phòng thí nghiệm',NULL);

INSERT INTO access_log(person_id,lab_id,entry_time,exit_time,purpose,approved_by) VALUES(53,1,CURRENT_DATE-28+time '14:00',CURRENT_DATE-28+time '15:30','Nghiên cứu cảm biến',NULL);

INSERT INTO access_log(person_id,lab_id,entry_time,exit_time,purpose,approved_by) VALUES(54,2,CURRENT_DATE-28+time '8:00',CURRENT_DATE-28+time '9:30','Phân tích mẫu vật liệu',NULL);

INSERT INTO access_log(person_id,lab_id,entry_time,exit_time,purpose,approved_by) VALUES(55,2,CURRENT_DATE-28+time '9:00',CURRENT_DATE-28+time '10:30','Thực hành thiết bị',NULL);

INSERT INTO access_log(person_id,lab_id,entry_time,exit_time,purpose,approved_by) VALUES(56,1,CURRENT_DATE-28+time '10:00',CURRENT_DATE-28+time '11:30','Kiểm kê phòng thí nghiệm',NULL);

INSERT INTO access_log(person_id,lab_id,entry_time,exit_time,purpose,approved_by) VALUES(57,2,CURRENT_DATE-28+time '18:00',CURRENT_DATE-28+time '19:30','Nghiên cứu cảm biến',1);

INSERT INTO access_log(person_id,lab_id,entry_time,exit_time,purpose,approved_by) VALUES(58,2,CURRENT_DATE-28+time '12:00',CURRENT_DATE-28+time '13:30','Phân tích mẫu vật liệu',NULL);

INSERT INTO access_log(person_id,lab_id,entry_time,exit_time,purpose,approved_by) VALUES(59,1,CURRENT_DATE-28+time '13:00',CURRENT_DATE-28+time '14:30','Thực hành thiết bị',NULL);

INSERT INTO access_log(person_id,lab_id,entry_time,exit_time,purpose,approved_by) VALUES(60,2,CURRENT_DATE-28+time '14:00',CURRENT_DATE-28+time '15:30','Kiểm kê phòng thí nghiệm',NULL);

INSERT INTO access_log(person_id,lab_id,entry_time,exit_time,purpose,approved_by) VALUES(61,2,CURRENT_DATE-29+time '8:00',CURRENT_DATE-29+time '9:30','Nghiên cứu cảm biến',NULL);

INSERT INTO access_log(person_id,lab_id,entry_time,exit_time,purpose,approved_by) VALUES(62,1,CURRENT_DATE-29+time '9:00',CURRENT_DATE-29+time '10:30','Phân tích mẫu vật liệu',NULL);

INSERT INTO access_log(person_id,lab_id,entry_time,exit_time,purpose,approved_by) VALUES(63,2,CURRENT_DATE-29+time '10:00',CURRENT_DATE-29+time '11:30','Thực hành thiết bị',NULL);

INSERT INTO access_log(person_id,lab_id,entry_time,exit_time,purpose,approved_by) VALUES(64,2,CURRENT_DATE-29+time '11:00',CURRENT_DATE-29+time '12:30','Kiểm kê phòng thí nghiệm',NULL);

INSERT INTO access_log(person_id,lab_id,entry_time,exit_time,purpose,approved_by) VALUES(65,1,CURRENT_DATE-29+time '12:00',CURRENT_DATE-29+time '13:30','Nghiên cứu cảm biến',NULL);

INSERT INTO access_log(person_id,lab_id,entry_time,exit_time,purpose,approved_by) VALUES(66,2,CURRENT_DATE-29+time '13:00',CURRENT_DATE-29+time '14:30','Phân tích mẫu vật liệu',NULL);

INSERT INTO access_log(person_id,lab_id,entry_time,exit_time,purpose,approved_by) VALUES(67,2,CURRENT_DATE-29+time '18:00',CURRENT_DATE-29+time '19:30','Thực hành thiết bị',NULL);

INSERT INTO access_log(person_id,lab_id,entry_time,exit_time,purpose,approved_by) VALUES(68,1,CURRENT_DATE-29+time '8:00',CURRENT_DATE-29+time '9:30','Kiểm kê phòng thí nghiệm',NULL);

INSERT INTO access_log(person_id,lab_id,entry_time,exit_time,purpose,approved_by) VALUES(69,2,CURRENT_DATE-30+time '9:00',CURRENT_DATE-30+time '10:30','Nghiên cứu cảm biến',NULL);

INSERT INTO access_log(person_id,lab_id,entry_time,exit_time,purpose,approved_by) VALUES(70,2,CURRENT_DATE-30+time '10:00',CURRENT_DATE-30+time '11:30','Phân tích mẫu vật liệu',NULL);

INSERT INTO access_log(person_id,lab_id,entry_time,exit_time,purpose,approved_by) VALUES(71,1,CURRENT_DATE-30+time '11:00',CURRENT_DATE-30+time '12:30','Thực hành thiết bị',NULL);

INSERT INTO access_log(person_id,lab_id,entry_time,exit_time,purpose,approved_by) VALUES(72,2,CURRENT_DATE-30+time '12:00',CURRENT_DATE-30+time '13:30','Kiểm kê phòng thí nghiệm',NULL);

INSERT INTO access_log(person_id,lab_id,entry_time,exit_time,purpose,approved_by) VALUES(73,2,CURRENT_DATE-30+time '13:00',CURRENT_DATE-30+time '14:30','Nghiên cứu cảm biến',NULL);

INSERT INTO access_log(person_id,lab_id,entry_time,exit_time,purpose,approved_by) VALUES(74,1,CURRENT_DATE-30+time '14:00',CURRENT_DATE-30+time '15:30','Phân tích mẫu vật liệu',NULL);

INSERT INTO access_log(person_id,lab_id,entry_time,exit_time,purpose,approved_by) VALUES(75,2,CURRENT_DATE-30+time '8:00',CURRENT_DATE-30+time '9:30','Thực hành thiết bị',NULL);

INSERT INTO access_log(person_id,lab_id,entry_time,exit_time,purpose,approved_by) VALUES(76,2,CURRENT_DATE-30+time '9:00',CURRENT_DATE-30+time '10:30','Kiểm kê phòng thí nghiệm',NULL);

INSERT INTO access_log(person_id,lab_id,entry_time,exit_time,purpose,approved_by) VALUES(77,1,CURRENT_DATE-31+time '18:00',CURRENT_DATE-31+time '19:30','Nghiên cứu cảm biến',NULL);

INSERT INTO access_log(person_id,lab_id,entry_time,exit_time,purpose,approved_by) VALUES(78,2,CURRENT_DATE-31+time '11:00',CURRENT_DATE-31+time '12:30','Phân tích mẫu vật liệu',NULL);

INSERT INTO access_log(person_id,lab_id,entry_time,exit_time,purpose,approved_by) VALUES(79,2,CURRENT_DATE-31+time '12:00',CURRENT_DATE-31+time '13:30','Thực hành thiết bị',NULL);

INSERT INTO access_log(person_id,lab_id,entry_time,exit_time,purpose,approved_by) VALUES(80,1,CURRENT_DATE-31+time '13:00',CURRENT_DATE-31+time '14:30','Kiểm kê phòng thí nghiệm',NULL);

INSERT INTO access_log(person_id,lab_id,entry_time,exit_time,purpose,approved_by) VALUES(81,2,CURRENT_DATE-31+time '14:00',CURRENT_DATE-31+time '15:30','Nghiên cứu cảm biến',NULL);

INSERT INTO access_log(person_id,lab_id,entry_time,exit_time,purpose,approved_by) VALUES(82,2,CURRENT_DATE-31+time '8:00',CURRENT_DATE-31+time '9:30','Phân tích mẫu vật liệu',NULL);

INSERT INTO access_log(person_id,lab_id,entry_time,exit_time,purpose,approved_by) VALUES(83,1,CURRENT_DATE-31+time '9:00',CURRENT_DATE-31+time '10:30','Thực hành thiết bị',NULL);

INSERT INTO access_log(person_id,lab_id,entry_time,exit_time,purpose,approved_by) VALUES(84,2,CURRENT_DATE-31+time '10:00',CURRENT_DATE-31+time '11:30','Kiểm kê phòng thí nghiệm',NULL);

INSERT INTO access_log(person_id,lab_id,entry_time,exit_time,purpose,approved_by) VALUES(85,2,CURRENT_DATE-32+time '11:00',CURRENT_DATE-32+time '12:30','Nghiên cứu cảm biến',NULL);

INSERT INTO access_log(person_id,lab_id,entry_time,exit_time,purpose,approved_by) VALUES(86,1,CURRENT_DATE-32+time '12:00',CURRENT_DATE-32+time '13:30','Phân tích mẫu vật liệu',NULL);

INSERT INTO access_log(person_id,lab_id,entry_time,exit_time,purpose,approved_by) VALUES(87,2,CURRENT_DATE-32+time '18:00',CURRENT_DATE-32+time '19:30','Thực hành thiết bị',NULL);

INSERT INTO access_log(person_id,lab_id,entry_time,exit_time,purpose,approved_by) VALUES(88,2,CURRENT_DATE-32+time '14:00',CURRENT_DATE-32+time '15:30','Kiểm kê phòng thí nghiệm',NULL);

INSERT INTO access_log(person_id,lab_id,entry_time,exit_time,purpose,approved_by) VALUES(89,1,CURRENT_DATE-32+time '8:00',CURRENT_DATE-32+time '9:30','Nghiên cứu cảm biến',NULL);

INSERT INTO access_log(person_id,lab_id,entry_time,exit_time,purpose,approved_by) VALUES(90,2,CURRENT_DATE-32+time '9:00',CURRENT_DATE-32+time '10:30','Phân tích mẫu vật liệu',NULL);

INSERT INTO access_log(person_id,lab_id,entry_time,exit_time,purpose,approved_by) VALUES(91,2,CURRENT_DATE-32+time '10:00',CURRENT_DATE-32+time '11:30','Thực hành thiết bị',NULL);

INSERT INTO access_log(person_id,lab_id,entry_time,exit_time,purpose,approved_by) VALUES(92,1,CURRENT_DATE-32+time '11:00',CURRENT_DATE-32+time '12:30','Kiểm kê phòng thí nghiệm',NULL);

INSERT INTO access_log(person_id,lab_id,entry_time,exit_time,purpose,approved_by) VALUES(93,2,CURRENT_DATE-33+time '12:00',CURRENT_DATE-33+time '13:30','Nghiên cứu cảm biến',NULL);

INSERT INTO access_log(person_id,lab_id,entry_time,exit_time,purpose,approved_by) VALUES(94,2,CURRENT_DATE-33+time '13:00',CURRENT_DATE-33+time '14:30','Phân tích mẫu vật liệu',NULL);

INSERT INTO access_log(person_id,lab_id,entry_time,exit_time,purpose,approved_by) VALUES(95,1,CURRENT_DATE-33+time '14:00',CURRENT_DATE-33+time '15:30','Thực hành thiết bị',NULL);

INSERT INTO access_log(person_id,lab_id,entry_time,exit_time,purpose,approved_by) VALUES(96,2,CURRENT_DATE-33+time '8:00',CURRENT_DATE-33+time '9:30','Kiểm kê phòng thí nghiệm',NULL);

UPDATE equipment SET purchase_date=least(purchase_date,CURRENT_DATE-900) WHERE equipment_id IN (3,4,7,8,10,11,12);

INSERT INTO borrow_transaction(person_id,equipment_id,borrow_date,expected_return_date,actual_return_date) VALUES(13,3,CURRENT_DATE-600,CURRENT_DATE-598,CURRENT_DATE-597);

INSERT INTO borrow_transaction(person_id,equipment_id,borrow_date,expected_return_date,actual_return_date) VALUES(14,4,CURRENT_DATE-600,CURRENT_DATE-598,CURRENT_DATE-599);

INSERT INTO borrow_transaction(person_id,equipment_id,borrow_date,expected_return_date,actual_return_date) VALUES(15,7,CURRENT_DATE-600,CURRENT_DATE-598,CURRENT_DATE-599);

INSERT INTO borrow_transaction(person_id,equipment_id,borrow_date,expected_return_date,actual_return_date) VALUES(16,8,CURRENT_DATE-600,CURRENT_DATE-598,CURRENT_DATE-599);

INSERT INTO borrow_transaction(person_id,equipment_id,borrow_date,expected_return_date,actual_return_date) VALUES(17,10,CURRENT_DATE-600,CURRENT_DATE-598,CURRENT_DATE-599);

INSERT INTO borrow_transaction(person_id,equipment_id,borrow_date,expected_return_date,actual_return_date) VALUES(18,11,CURRENT_DATE-600,CURRENT_DATE-598,CURRENT_DATE-597);

INSERT INTO borrow_transaction(person_id,equipment_id,borrow_date,expected_return_date,actual_return_date) VALUES(19,12,CURRENT_DATE-600,CURRENT_DATE-598,CURRENT_DATE-599);

INSERT INTO borrow_transaction(person_id,equipment_id,borrow_date,expected_return_date,actual_return_date) VALUES(20,3,CURRENT_DATE-593,CURRENT_DATE-591,CURRENT_DATE-592);

INSERT INTO borrow_transaction(person_id,equipment_id,borrow_date,expected_return_date,actual_return_date) VALUES(21,4,CURRENT_DATE-593,CURRENT_DATE-591,CURRENT_DATE-592);

INSERT INTO borrow_transaction(person_id,equipment_id,borrow_date,expected_return_date,actual_return_date) VALUES(22,7,CURRENT_DATE-593,CURRENT_DATE-591,CURRENT_DATE-592);

INSERT INTO borrow_transaction(person_id,equipment_id,borrow_date,expected_return_date,actual_return_date) VALUES(23,8,CURRENT_DATE-593,CURRENT_DATE-591,CURRENT_DATE-590);

INSERT INTO borrow_transaction(person_id,equipment_id,borrow_date,expected_return_date,actual_return_date) VALUES(24,10,CURRENT_DATE-593,CURRENT_DATE-591,CURRENT_DATE-592);

INSERT INTO borrow_transaction(person_id,equipment_id,borrow_date,expected_return_date,actual_return_date) VALUES(25,11,CURRENT_DATE-593,CURRENT_DATE-591,CURRENT_DATE-592);

INSERT INTO borrow_transaction(person_id,equipment_id,borrow_date,expected_return_date,actual_return_date) VALUES(26,12,CURRENT_DATE-593,CURRENT_DATE-591,CURRENT_DATE-592);

INSERT INTO borrow_transaction(person_id,equipment_id,borrow_date,expected_return_date,actual_return_date) VALUES(27,3,CURRENT_DATE-586,CURRENT_DATE-584,CURRENT_DATE-585);

INSERT INTO borrow_transaction(person_id,equipment_id,borrow_date,expected_return_date,actual_return_date) VALUES(28,4,CURRENT_DATE-586,CURRENT_DATE-584,CURRENT_DATE-583);

INSERT INTO borrow_transaction(person_id,equipment_id,borrow_date,expected_return_date,actual_return_date) VALUES(29,7,CURRENT_DATE-586,CURRENT_DATE-584,CURRENT_DATE-585);

INSERT INTO borrow_transaction(person_id,equipment_id,borrow_date,expected_return_date,actual_return_date) VALUES(30,8,CURRENT_DATE-586,CURRENT_DATE-584,CURRENT_DATE-585);

INSERT INTO borrow_transaction(person_id,equipment_id,borrow_date,expected_return_date,actual_return_date) VALUES(31,10,CURRENT_DATE-586,CURRENT_DATE-584,CURRENT_DATE-585);

INSERT INTO borrow_transaction(person_id,equipment_id,borrow_date,expected_return_date,actual_return_date) VALUES(32,11,CURRENT_DATE-586,CURRENT_DATE-584,CURRENT_DATE-585);

INSERT INTO borrow_transaction(person_id,equipment_id,borrow_date,expected_return_date,actual_return_date) VALUES(33,12,CURRENT_DATE-586,CURRENT_DATE-584,CURRENT_DATE-583);

INSERT INTO borrow_transaction(person_id,equipment_id,borrow_date,expected_return_date,actual_return_date) VALUES(34,3,CURRENT_DATE-579,CURRENT_DATE-577,CURRENT_DATE-578);

INSERT INTO borrow_transaction(person_id,equipment_id,borrow_date,expected_return_date,actual_return_date) VALUES(35,4,CURRENT_DATE-579,CURRENT_DATE-577,CURRENT_DATE-578);

INSERT INTO borrow_transaction(person_id,equipment_id,borrow_date,expected_return_date,actual_return_date) VALUES(36,7,CURRENT_DATE-579,CURRENT_DATE-577,CURRENT_DATE-578);

INSERT INTO borrow_transaction(person_id,equipment_id,borrow_date,expected_return_date,actual_return_date) VALUES(37,8,CURRENT_DATE-579,CURRENT_DATE-577,CURRENT_DATE-578);

INSERT INTO borrow_transaction(person_id,equipment_id,borrow_date,expected_return_date,actual_return_date) VALUES(38,10,CURRENT_DATE-579,CURRENT_DATE-577,CURRENT_DATE-576);

INSERT INTO borrow_transaction(person_id,equipment_id,borrow_date,expected_return_date,actual_return_date) VALUES(39,11,CURRENT_DATE-579,CURRENT_DATE-577,CURRENT_DATE-578);

INSERT INTO borrow_transaction(person_id,equipment_id,borrow_date,expected_return_date,actual_return_date) VALUES(40,12,CURRENT_DATE-579,CURRENT_DATE-577,CURRENT_DATE-578);

INSERT INTO borrow_transaction(person_id,equipment_id,borrow_date,expected_return_date,actual_return_date) VALUES(41,3,CURRENT_DATE-572,CURRENT_DATE-570,CURRENT_DATE-571);

INSERT INTO borrow_transaction(person_id,equipment_id,borrow_date,expected_return_date,actual_return_date) VALUES(42,4,CURRENT_DATE-572,CURRENT_DATE-570,CURRENT_DATE-571);

INSERT INTO borrow_transaction(person_id,equipment_id,borrow_date,expected_return_date,actual_return_date) VALUES(43,7,CURRENT_DATE-572,CURRENT_DATE-570,CURRENT_DATE-569);

INSERT INTO borrow_transaction(person_id,equipment_id,borrow_date,expected_return_date,actual_return_date) VALUES(44,8,CURRENT_DATE-572,CURRENT_DATE-570,CURRENT_DATE-571);

INSERT INTO borrow_transaction(person_id,equipment_id,borrow_date,expected_return_date,actual_return_date) VALUES(45,10,CURRENT_DATE-572,CURRENT_DATE-570,CURRENT_DATE-571);

INSERT INTO borrow_transaction(person_id,equipment_id,borrow_date,expected_return_date,actual_return_date) VALUES(46,11,CURRENT_DATE-572,CURRENT_DATE-570,CURRENT_DATE-571);

INSERT INTO borrow_transaction(person_id,equipment_id,borrow_date,expected_return_date,actual_return_date) VALUES(47,12,CURRENT_DATE-572,CURRENT_DATE-570,CURRENT_DATE-571);

INSERT INTO borrow_transaction(person_id,equipment_id,borrow_date,expected_return_date,actual_return_date) VALUES(48,3,CURRENT_DATE-565,CURRENT_DATE-563,CURRENT_DATE-562);

INSERT INTO borrow_transaction(person_id,equipment_id,borrow_date,expected_return_date,actual_return_date) VALUES(49,4,CURRENT_DATE-565,CURRENT_DATE-563,CURRENT_DATE-564);

INSERT INTO borrow_transaction(person_id,equipment_id,borrow_date,expected_return_date,actual_return_date) VALUES(50,7,CURRENT_DATE-565,CURRENT_DATE-563,CURRENT_DATE-564);

INSERT INTO borrow_transaction(person_id,equipment_id,borrow_date,expected_return_date,actual_return_date) VALUES(51,8,CURRENT_DATE-565,CURRENT_DATE-563,CURRENT_DATE-564);

INSERT INTO borrow_transaction(person_id,equipment_id,borrow_date,expected_return_date,actual_return_date) VALUES(52,10,CURRENT_DATE-565,CURRENT_DATE-563,CURRENT_DATE-564);

INSERT INTO borrow_transaction(person_id,equipment_id,borrow_date,expected_return_date,actual_return_date) VALUES(53,11,CURRENT_DATE-565,CURRENT_DATE-563,CURRENT_DATE-562);

INSERT INTO borrow_transaction(person_id,equipment_id,borrow_date,expected_return_date,actual_return_date) VALUES(54,12,CURRENT_DATE-565,CURRENT_DATE-563,CURRENT_DATE-564);

INSERT INTO borrow_transaction(person_id,equipment_id,borrow_date,expected_return_date,actual_return_date) VALUES(55,3,CURRENT_DATE-558,CURRENT_DATE-556,CURRENT_DATE-557);

INSERT INTO borrow_transaction(person_id,equipment_id,borrow_date,expected_return_date,actual_return_date) VALUES(56,4,CURRENT_DATE-558,CURRENT_DATE-556,CURRENT_DATE-557);

INSERT INTO borrow_transaction(person_id,equipment_id,borrow_date,expected_return_date,actual_return_date) VALUES(57,7,CURRENT_DATE-558,CURRENT_DATE-556,CURRENT_DATE-557);

INSERT INTO borrow_transaction(person_id,equipment_id,borrow_date,expected_return_date,actual_return_date) VALUES(58,8,CURRENT_DATE-558,CURRENT_DATE-556,CURRENT_DATE-555);

INSERT INTO borrow_transaction(person_id,equipment_id,borrow_date,expected_return_date,actual_return_date) VALUES(59,10,CURRENT_DATE-558,CURRENT_DATE-556,CURRENT_DATE-557);

INSERT INTO borrow_transaction(person_id,equipment_id,borrow_date,expected_return_date,actual_return_date) VALUES(60,11,CURRENT_DATE-558,CURRENT_DATE-556,CURRENT_DATE-557);

INSERT INTO borrow_transaction(person_id,equipment_id,borrow_date,expected_return_date,actual_return_date) VALUES(61,12,CURRENT_DATE-558,CURRENT_DATE-556,CURRENT_DATE-557);

INSERT INTO borrow_transaction(person_id,equipment_id,borrow_date,expected_return_date,actual_return_date) VALUES(62,3,CURRENT_DATE-551,CURRENT_DATE-549,CURRENT_DATE-550);

INSERT INTO borrow_transaction(person_id,equipment_id,borrow_date,expected_return_date,actual_return_date) VALUES(63,4,CURRENT_DATE-551,CURRENT_DATE-549,CURRENT_DATE-548);

INSERT INTO borrow_transaction(person_id,equipment_id,borrow_date,expected_return_date,actual_return_date) VALUES(64,7,CURRENT_DATE-551,CURRENT_DATE-549,CURRENT_DATE-550);

INSERT INTO borrow_transaction(person_id,equipment_id,borrow_date,expected_return_date,actual_return_date) VALUES(65,8,CURRENT_DATE-551,CURRENT_DATE-549,CURRENT_DATE-550);

INSERT INTO borrow_transaction(person_id,equipment_id,borrow_date,expected_return_date,actual_return_date) VALUES(66,10,CURRENT_DATE-551,CURRENT_DATE-549,CURRENT_DATE-550);

INSERT INTO borrow_transaction(person_id,equipment_id,borrow_date,expected_return_date,actual_return_date) VALUES(67,11,CURRENT_DATE-551,CURRENT_DATE-549,CURRENT_DATE-550);

INSERT INTO borrow_transaction(person_id,equipment_id,borrow_date,expected_return_date,actual_return_date) VALUES(68,12,CURRENT_DATE-551,CURRENT_DATE-549,CURRENT_DATE-548);

INSERT INTO borrow_transaction(person_id,equipment_id,borrow_date,expected_return_date,actual_return_date) VALUES(69,3,CURRENT_DATE-544,CURRENT_DATE-542,CURRENT_DATE-543);

INSERT INTO borrow_transaction(person_id,equipment_id,borrow_date,expected_return_date,actual_return_date) VALUES(70,4,CURRENT_DATE-544,CURRENT_DATE-542,CURRENT_DATE-543);

INSERT INTO borrow_transaction(person_id,equipment_id,borrow_date,expected_return_date,actual_return_date) VALUES(71,7,CURRENT_DATE-544,CURRENT_DATE-542,CURRENT_DATE-543);

INSERT INTO borrow_transaction(person_id,equipment_id,borrow_date,expected_return_date,actual_return_date) VALUES(72,8,CURRENT_DATE-544,CURRENT_DATE-542,CURRENT_DATE-543);

INSERT INTO borrow_transaction(person_id,equipment_id,borrow_date,expected_return_date,actual_return_date) VALUES(73,10,CURRENT_DATE-544,CURRENT_DATE-542,CURRENT_DATE-541);

INSERT INTO borrow_transaction(person_id,equipment_id,borrow_date,expected_return_date,actual_return_date) VALUES(74,11,CURRENT_DATE-544,CURRENT_DATE-542,CURRENT_DATE-543);

INSERT INTO borrow_transaction(person_id,equipment_id,borrow_date,expected_return_date,actual_return_date) VALUES(75,12,CURRENT_DATE-544,CURRENT_DATE-542,CURRENT_DATE-543);

INSERT INTO borrow_transaction(person_id,equipment_id,borrow_date,expected_return_date,actual_return_date) VALUES(76,3,CURRENT_DATE-537,CURRENT_DATE-535,CURRENT_DATE-536);

INSERT INTO borrow_transaction(person_id,equipment_id,borrow_date,expected_return_date,actual_return_date) VALUES(77,4,CURRENT_DATE-537,CURRENT_DATE-535,CURRENT_DATE-536);

INSERT INTO borrow_transaction(person_id,equipment_id,borrow_date,expected_return_date,actual_return_date) VALUES(78,7,CURRENT_DATE-537,CURRENT_DATE-535,CURRENT_DATE-534);

INSERT INTO borrow_transaction(person_id,equipment_id,borrow_date,expected_return_date,actual_return_date) VALUES(79,8,CURRENT_DATE-537,CURRENT_DATE-535,CURRENT_DATE-536);

INSERT INTO borrow_transaction(person_id,equipment_id,borrow_date,expected_return_date,actual_return_date) VALUES(80,10,CURRENT_DATE-537,CURRENT_DATE-535,CURRENT_DATE-536);

INSERT INTO borrow_transaction(person_id,equipment_id,borrow_date,expected_return_date,actual_return_date) VALUES(81,11,CURRENT_DATE-537,CURRENT_DATE-535,CURRENT_DATE-536);

INSERT INTO borrow_transaction(person_id,equipment_id,borrow_date,expected_return_date,actual_return_date) VALUES(82,12,CURRENT_DATE-537,CURRENT_DATE-535,CURRENT_DATE-536);

INSERT INTO borrow_transaction(person_id,equipment_id,borrow_date,expected_return_date,actual_return_date) VALUES(83,3,CURRENT_DATE-530,CURRENT_DATE-528,CURRENT_DATE-527);

INSERT INTO borrow_transaction(person_id,equipment_id,borrow_date,expected_return_date,actual_return_date) VALUES(84,4,CURRENT_DATE-530,CURRENT_DATE-528,CURRENT_DATE-529);

INSERT INTO borrow_transaction(person_id,equipment_id,borrow_date,expected_return_date,actual_return_date) VALUES(85,7,CURRENT_DATE-530,CURRENT_DATE-528,CURRENT_DATE-529);

INSERT INTO borrow_transaction(person_id,equipment_id,borrow_date,expected_return_date,actual_return_date) VALUES(86,8,CURRENT_DATE-530,CURRENT_DATE-528,CURRENT_DATE-529);

INSERT INTO borrow_transaction(person_id,equipment_id,borrow_date,expected_return_date,actual_return_date) VALUES(87,10,CURRENT_DATE-530,CURRENT_DATE-528,CURRENT_DATE-529);

INSERT INTO borrow_transaction(person_id,equipment_id,borrow_date,expected_return_date,actual_return_date) VALUES(88,11,CURRENT_DATE-530,CURRENT_DATE-528,CURRENT_DATE-527);

INSERT INTO borrow_transaction(person_id,equipment_id,borrow_date,expected_return_date,actual_return_date) VALUES(89,12,CURRENT_DATE-530,CURRENT_DATE-528,CURRENT_DATE-529);

INSERT INTO borrow_transaction(person_id,equipment_id,borrow_date,expected_return_date,actual_return_date) VALUES(90,3,CURRENT_DATE-523,CURRENT_DATE-521,CURRENT_DATE-522);

INSERT INTO borrow_transaction(person_id,equipment_id,borrow_date,expected_return_date,actual_return_date) VALUES(91,4,CURRENT_DATE-523,CURRENT_DATE-521,CURRENT_DATE-522);

INSERT INTO borrow_transaction(person_id,equipment_id,borrow_date,expected_return_date,actual_return_date) VALUES(92,7,CURRENT_DATE-523,CURRENT_DATE-521,CURRENT_DATE-522);

INSERT INTO borrow_transaction(person_id,equipment_id,borrow_date,expected_return_date,actual_return_date) VALUES(93,8,CURRENT_DATE-523,CURRENT_DATE-521,CURRENT_DATE-520);

INSERT INTO borrow_transaction(person_id,equipment_id,borrow_date,expected_return_date,actual_return_date) VALUES(94,10,CURRENT_DATE-523,CURRENT_DATE-521,CURRENT_DATE-522);

INSERT INTO borrow_transaction(person_id,equipment_id,borrow_date,expected_return_date,actual_return_date) VALUES(95,11,CURRENT_DATE-523,CURRENT_DATE-521,CURRENT_DATE-522);

INSERT INTO borrow_transaction(person_id,equipment_id,borrow_date,expected_return_date,actual_return_date) VALUES(96,12,CURRENT_DATE-523,CURRENT_DATE-521,CURRENT_DATE-522);

INSERT INTO borrow_transaction(person_id,equipment_id,borrow_date,expected_return_date,actual_return_date) VALUES(97,3,CURRENT_DATE-516,CURRENT_DATE-514,CURRENT_DATE-515);

INSERT INTO borrow_transaction(person_id,equipment_id,borrow_date,expected_return_date,actual_return_date) VALUES(98,4,CURRENT_DATE-516,CURRENT_DATE-514,CURRENT_DATE-513);

INSERT INTO borrow_transaction(person_id,equipment_id,borrow_date,expected_return_date,actual_return_date) VALUES(99,7,CURRENT_DATE-516,CURRENT_DATE-514,CURRENT_DATE-515);

INSERT INTO borrow_transaction(person_id,equipment_id,borrow_date,expected_return_date,actual_return_date) VALUES(100,8,CURRENT_DATE-516,CURRENT_DATE-514,CURRENT_DATE-515);

INSERT INTO borrow_transaction(person_id,equipment_id,borrow_date,expected_return_date,actual_return_date) VALUES(13,10,CURRENT_DATE-516,CURRENT_DATE-514,CURRENT_DATE-515);

INSERT INTO borrow_transaction(person_id,equipment_id,borrow_date,expected_return_date,actual_return_date) VALUES(14,11,CURRENT_DATE-516,CURRENT_DATE-514,CURRENT_DATE-515);

INSERT INTO borrow_transaction(person_id,equipment_id,borrow_date,expected_return_date,actual_return_date) VALUES(15,12,CURRENT_DATE-516,CURRENT_DATE-514,CURRENT_DATE-513);

INSERT INTO borrow_transaction(person_id,equipment_id,borrow_date,expected_return_date,actual_return_date) VALUES(16,3,CURRENT_DATE-509,CURRENT_DATE-507,CURRENT_DATE-508);

INSERT INTO borrow_transaction(person_id,equipment_id,borrow_date,expected_return_date,actual_return_date) VALUES(17,4,CURRENT_DATE-509,CURRENT_DATE-507,CURRENT_DATE-508);

INSERT INTO borrow_transaction(person_id,equipment_id,borrow_date,expected_return_date,actual_return_date) VALUES(18,7,CURRENT_DATE-509,CURRENT_DATE-507,CURRENT_DATE-508);

INSERT INTO borrow_transaction(person_id,equipment_id,borrow_date,expected_return_date,actual_return_date) VALUES(19,8,CURRENT_DATE-509,CURRENT_DATE-507,CURRENT_DATE-508);

INSERT INTO borrow_transaction(person_id,equipment_id,borrow_date,expected_return_date,actual_return_date) VALUES(20,10,CURRENT_DATE-509,CURRENT_DATE-507,CURRENT_DATE-506);

INSERT INTO borrow_transaction(person_id,equipment_id,borrow_date,expected_return_date,actual_return_date) VALUES(21,11,CURRENT_DATE-509,CURRENT_DATE-507,CURRENT_DATE-508);

INSERT INTO borrow_transaction(person_id,equipment_id,borrow_date,expected_return_date,actual_return_date) VALUES(22,12,CURRENT_DATE-509,CURRENT_DATE-507,CURRENT_DATE-508);

INSERT INTO borrow_transaction(person_id,equipment_id,borrow_date,expected_return_date,actual_return_date) VALUES(23,3,CURRENT_DATE-502,CURRENT_DATE-500,CURRENT_DATE-501);

INSERT INTO borrow_transaction(person_id,equipment_id,borrow_date,expected_return_date,actual_return_date) VALUES(24,4,CURRENT_DATE-502,CURRENT_DATE-500,CURRENT_DATE-501);

INSERT INTO borrow_transaction(person_id,equipment_id,borrow_date,expected_return_date,actual_return_date) VALUES(25,7,CURRENT_DATE-502,CURRENT_DATE-500,CURRENT_DATE-499);

INSERT INTO borrow_transaction(person_id,equipment_id,borrow_date,expected_return_date,actual_return_date) VALUES(26,8,CURRENT_DATE-502,CURRENT_DATE-500,CURRENT_DATE-501);

INSERT INTO borrow_transaction(person_id,equipment_id,borrow_date,expected_return_date,actual_return_date) VALUES(27,10,CURRENT_DATE-502,CURRENT_DATE-500,CURRENT_DATE-501);

INSERT INTO borrow_transaction(person_id,equipment_id,borrow_date,expected_return_date,actual_return_date) VALUES(28,11,CURRENT_DATE-502,CURRENT_DATE-500,CURRENT_DATE-501);

INSERT INTO borrow_transaction(person_id,equipment_id,borrow_date,expected_return_date,actual_return_date) VALUES(29,12,CURRENT_DATE-502,CURRENT_DATE-500,CURRENT_DATE-501);

INSERT INTO borrow_transaction(person_id,equipment_id,borrow_date,expected_return_date,actual_return_date) VALUES(30,3,CURRENT_DATE-495,CURRENT_DATE-493,CURRENT_DATE-492);

INSERT INTO borrow_transaction(person_id,equipment_id,borrow_date,expected_return_date,actual_return_date) VALUES(31,4,CURRENT_DATE-495,CURRENT_DATE-493,CURRENT_DATE-494);

INSERT INTO borrow_transaction(person_id,equipment_id,borrow_date,expected_return_date,actual_return_date) VALUES(32,7,CURRENT_DATE-495,CURRENT_DATE-493,CURRENT_DATE-494);

INSERT INTO borrow_transaction(person_id,equipment_id,borrow_date,expected_return_date,actual_return_date) VALUES(33,8,CURRENT_DATE-495,CURRENT_DATE-493,CURRENT_DATE-494);

INSERT INTO borrow_transaction(person_id,equipment_id,borrow_date,expected_return_date,actual_return_date) VALUES(34,10,CURRENT_DATE-495,CURRENT_DATE-493,CURRENT_DATE-494);

INSERT INTO borrow_transaction(person_id,equipment_id,borrow_date,expected_return_date,actual_return_date) VALUES(35,11,CURRENT_DATE-495,CURRENT_DATE-493,CURRENT_DATE-492);

INSERT INTO borrow_transaction(person_id,equipment_id,borrow_date,expected_return_date,actual_return_date) VALUES(36,12,CURRENT_DATE-495,CURRENT_DATE-493,CURRENT_DATE-494);

INSERT INTO borrow_transaction(person_id,equipment_id,borrow_date,expected_return_date,actual_return_date) VALUES(37,3,CURRENT_DATE-488,CURRENT_DATE-486,CURRENT_DATE-487);

INSERT INTO borrow_transaction(person_id,equipment_id,borrow_date,expected_return_date,actual_return_date) VALUES(38,4,CURRENT_DATE-488,CURRENT_DATE-486,CURRENT_DATE-487);

INSERT INTO borrow_transaction(person_id,equipment_id,borrow_date,expected_return_date,actual_return_date) VALUES(39,7,CURRENT_DATE-488,CURRENT_DATE-486,CURRENT_DATE-487);

INSERT INTO borrow_transaction(person_id,equipment_id,borrow_date,expected_return_date,actual_return_date) VALUES(40,8,CURRENT_DATE-488,CURRENT_DATE-486,CURRENT_DATE-485);

INSERT INTO borrow_transaction(person_id,equipment_id,borrow_date,expected_return_date,actual_return_date) VALUES(41,10,CURRENT_DATE-488,CURRENT_DATE-486,CURRENT_DATE-487);

INSERT INTO borrow_transaction(person_id,equipment_id,borrow_date,expected_return_date,actual_return_date) VALUES(42,11,CURRENT_DATE-488,CURRENT_DATE-486,CURRENT_DATE-487);

INSERT INTO borrow_transaction(person_id,equipment_id,borrow_date,expected_return_date,actual_return_date) VALUES(43,12,CURRENT_DATE-488,CURRENT_DATE-486,CURRENT_DATE-487);

INSERT INTO borrow_transaction(person_id,equipment_id,borrow_date,expected_return_date,actual_return_date) VALUES(44,3,CURRENT_DATE-481,CURRENT_DATE-479,CURRENT_DATE-480);

INSERT INTO borrow_transaction(person_id,equipment_id,borrow_date,expected_return_date,actual_return_date) VALUES(45,4,CURRENT_DATE-481,CURRENT_DATE-479,CURRENT_DATE-478);

INSERT INTO borrow_transaction(person_id,equipment_id,borrow_date,expected_return_date,actual_return_date) VALUES(46,7,CURRENT_DATE-481,CURRENT_DATE-479,CURRENT_DATE-480);

INSERT INTO borrow_transaction(person_id,equipment_id,borrow_date,expected_return_date,actual_return_date) VALUES(47,8,CURRENT_DATE-481,CURRENT_DATE-479,CURRENT_DATE-480);

INSERT INTO borrow_transaction(person_id,equipment_id,borrow_date,expected_return_date,actual_return_date) VALUES(48,10,CURRENT_DATE-481,CURRENT_DATE-479,CURRENT_DATE-480);

INSERT INTO borrow_transaction(person_id,equipment_id,borrow_date,expected_return_date,actual_return_date) VALUES(49,11,CURRENT_DATE-481,CURRENT_DATE-479,CURRENT_DATE-480);

INSERT INTO borrow_transaction(person_id,equipment_id,borrow_date,expected_return_date,actual_return_date) VALUES(50,12,CURRENT_DATE-481,CURRENT_DATE-479,CURRENT_DATE-478);

INSERT INTO borrow_transaction(person_id,equipment_id,borrow_date,expected_return_date,actual_return_date) VALUES(51,3,CURRENT_DATE-474,CURRENT_DATE-472,CURRENT_DATE-473);

INSERT INTO borrow_transaction(person_id,equipment_id,borrow_date,expected_return_date,actual_return_date) VALUES(52,4,CURRENT_DATE-474,CURRENT_DATE-472,CURRENT_DATE-473);

INSERT INTO borrow_transaction(person_id,equipment_id,borrow_date,expected_return_date,actual_return_date) VALUES(53,7,CURRENT_DATE-474,CURRENT_DATE-472,CURRENT_DATE-473);

INSERT INTO borrow_transaction(person_id,equipment_id,borrow_date,expected_return_date,actual_return_date) VALUES(54,8,CURRENT_DATE-474,CURRENT_DATE-472,CURRENT_DATE-473);

INSERT INTO borrow_transaction(person_id,equipment_id,borrow_date,expected_return_date,actual_return_date) VALUES(55,10,CURRENT_DATE-474,CURRENT_DATE-472,CURRENT_DATE-471);

INSERT INTO borrow_transaction(person_id,equipment_id,borrow_date,expected_return_date,actual_return_date) VALUES(56,11,CURRENT_DATE-474,CURRENT_DATE-472,CURRENT_DATE-473);

INSERT INTO borrow_transaction(person_id,equipment_id,borrow_date,expected_return_date,actual_return_date) VALUES(57,12,CURRENT_DATE-474,CURRENT_DATE-472,CURRENT_DATE-473);

INSERT INTO borrow_transaction(person_id,equipment_id,borrow_date,expected_return_date,actual_return_date) VALUES(58,3,CURRENT_DATE-467,CURRENT_DATE-465,CURRENT_DATE-466);

INSERT INTO borrow_transaction(person_id,equipment_id,borrow_date,expected_return_date,actual_return_date) VALUES(59,4,CURRENT_DATE-467,CURRENT_DATE-465,CURRENT_DATE-466);

INSERT INTO borrow_transaction(person_id,equipment_id,borrow_date,expected_return_date,actual_return_date) VALUES(60,7,CURRENT_DATE-467,CURRENT_DATE-465,CURRENT_DATE-464);

INSERT INTO borrow_transaction(person_id,equipment_id,borrow_date,expected_return_date,actual_return_date) VALUES(61,8,CURRENT_DATE-467,CURRENT_DATE-465,CURRENT_DATE-466);

INSERT INTO borrow_transaction(person_id,equipment_id,borrow_date,expected_return_date,actual_return_date) VALUES(62,10,CURRENT_DATE-467,CURRENT_DATE-465,CURRENT_DATE-466);

INSERT INTO borrow_transaction(person_id,equipment_id,borrow_date,expected_return_date,actual_return_date) VALUES(63,11,CURRENT_DATE-467,CURRENT_DATE-465,CURRENT_DATE-466);

INSERT INTO borrow_transaction(person_id,equipment_id,borrow_date,expected_return_date,actual_return_date) VALUES(64,12,CURRENT_DATE-467,CURRENT_DATE-465,CURRENT_DATE-466);

INSERT INTO borrow_transaction(person_id,equipment_id,borrow_date,expected_return_date,actual_return_date) VALUES(65,3,CURRENT_DATE-460,CURRENT_DATE-458,CURRENT_DATE-457);

INSERT INTO borrow_transaction(person_id,equipment_id,borrow_date,expected_return_date,actual_return_date) VALUES(66,4,CURRENT_DATE-460,CURRENT_DATE-458,CURRENT_DATE-459);

INSERT INTO borrow_transaction(person_id,equipment_id,borrow_date,expected_return_date,actual_return_date) VALUES(67,7,CURRENT_DATE-460,CURRENT_DATE-458,CURRENT_DATE-459);

INSERT INTO borrow_transaction(person_id,equipment_id,borrow_date,expected_return_date,actual_return_date) VALUES(68,8,CURRENT_DATE-460,CURRENT_DATE-458,CURRENT_DATE-459);

INSERT INTO borrow_transaction(person_id,equipment_id,borrow_date,expected_return_date,actual_return_date) VALUES(69,10,CURRENT_DATE-460,CURRENT_DATE-458,CURRENT_DATE-459);

INSERT INTO borrow_transaction(person_id,equipment_id,borrow_date,expected_return_date,actual_return_date) VALUES(70,11,CURRENT_DATE-460,CURRENT_DATE-458,CURRENT_DATE-457);

INSERT INTO borrow_transaction(person_id,equipment_id,borrow_date,expected_return_date,actual_return_date) VALUES(71,12,CURRENT_DATE-460,CURRENT_DATE-458,CURRENT_DATE-459);

INSERT INTO borrow_transaction(person_id,equipment_id,borrow_date,expected_return_date,actual_return_date) VALUES(72,3,CURRENT_DATE-453,CURRENT_DATE-451,CURRENT_DATE-452);

INSERT INTO borrow_transaction(person_id,equipment_id,borrow_date,expected_return_date,actual_return_date) VALUES(73,4,CURRENT_DATE-453,CURRENT_DATE-451,CURRENT_DATE-452);

INSERT INTO borrow_transaction(person_id,equipment_id,borrow_date,expected_return_date,actual_return_date) VALUES(74,7,CURRENT_DATE-453,CURRENT_DATE-451,CURRENT_DATE-452);

INSERT INTO borrow_transaction(person_id,equipment_id,borrow_date,expected_return_date,actual_return_date) VALUES(75,8,CURRENT_DATE-453,CURRENT_DATE-451,CURRENT_DATE-450);

INSERT INTO borrow_transaction(person_id,equipment_id,borrow_date,expected_return_date,actual_return_date) VALUES(76,10,CURRENT_DATE-453,CURRENT_DATE-451,CURRENT_DATE-452);

INSERT INTO borrow_transaction(person_id,equipment_id,borrow_date,expected_return_date,actual_return_date) VALUES(77,11,CURRENT_DATE-453,CURRENT_DATE-451,CURRENT_DATE-452);

INSERT INTO borrow_transaction(person_id,equipment_id,borrow_date,expected_return_date,actual_return_date) VALUES(78,12,CURRENT_DATE-453,CURRENT_DATE-451,CURRENT_DATE-452);

INSERT INTO borrow_transaction(person_id,equipment_id,borrow_date,expected_return_date,actual_return_date) VALUES(79,3,CURRENT_DATE-446,CURRENT_DATE-444,CURRENT_DATE-445);

INSERT INTO borrow_transaction(person_id,equipment_id,borrow_date,expected_return_date,actual_return_date) VALUES(80,4,CURRENT_DATE-446,CURRENT_DATE-444,CURRENT_DATE-443);

INSERT INTO borrow_transaction(person_id,equipment_id,borrow_date,expected_return_date,actual_return_date) VALUES(81,7,CURRENT_DATE-446,CURRENT_DATE-444,CURRENT_DATE-445);

INSERT INTO borrow_transaction(person_id,equipment_id,borrow_date,expected_return_date,actual_return_date) VALUES(82,8,CURRENT_DATE-446,CURRENT_DATE-444,CURRENT_DATE-445);

INSERT INTO borrow_transaction(person_id,equipment_id,borrow_date,expected_return_date,actual_return_date) VALUES(83,10,CURRENT_DATE-446,CURRENT_DATE-444,CURRENT_DATE-445);

INSERT INTO borrow_transaction(person_id,equipment_id,borrow_date,expected_return_date,actual_return_date) VALUES(84,11,CURRENT_DATE-446,CURRENT_DATE-444,CURRENT_DATE-445);

INSERT INTO borrow_transaction(person_id,equipment_id,borrow_date,expected_return_date,actual_return_date) VALUES(85,12,CURRENT_DATE-446,CURRENT_DATE-444,CURRENT_DATE-443);

INSERT INTO borrow_transaction(person_id,equipment_id,borrow_date,expected_return_date,actual_return_date) VALUES(86,3,CURRENT_DATE-439,CURRENT_DATE-437,CURRENT_DATE-438);

INSERT INTO borrow_transaction(person_id,equipment_id,borrow_date,expected_return_date,actual_return_date) VALUES(87,4,CURRENT_DATE-439,CURRENT_DATE-437,CURRENT_DATE-438);

INSERT INTO borrow_transaction(person_id,equipment_id,borrow_date,expected_return_date,actual_return_date) VALUES(88,7,CURRENT_DATE-439,CURRENT_DATE-437,CURRENT_DATE-438);

INSERT INTO borrow_transaction(person_id,equipment_id,borrow_date,expected_return_date,actual_return_date) VALUES(89,8,CURRENT_DATE-439,CURRENT_DATE-437,CURRENT_DATE-438);

INSERT INTO borrow_transaction(person_id,equipment_id,borrow_date,expected_return_date,actual_return_date) VALUES(90,10,CURRENT_DATE-439,CURRENT_DATE-437,CURRENT_DATE-436);

INSERT INTO borrow_transaction(person_id,equipment_id,borrow_date,expected_return_date,actual_return_date) VALUES(91,11,CURRENT_DATE-439,CURRENT_DATE-437,CURRENT_DATE-438);

INSERT INTO borrow_transaction(person_id,equipment_id,borrow_date,expected_return_date,actual_return_date) VALUES(92,12,CURRENT_DATE-439,CURRENT_DATE-437,CURRENT_DATE-438);

INSERT INTO borrow_transaction(person_id,equipment_id,borrow_date,expected_return_date,actual_return_date) VALUES(93,3,CURRENT_DATE-432,CURRENT_DATE-430,CURRENT_DATE-431);

INSERT INTO borrow_transaction(person_id,equipment_id,borrow_date,expected_return_date,actual_return_date) VALUES(94,4,CURRENT_DATE-432,CURRENT_DATE-430,CURRENT_DATE-431);

INSERT INTO borrow_transaction(person_id,equipment_id,borrow_date,expected_return_date,actual_return_date) VALUES(95,7,CURRENT_DATE-432,CURRENT_DATE-430,CURRENT_DATE-429);

INSERT INTO borrow_transaction(person_id,equipment_id,borrow_date,expected_return_date,actual_return_date) VALUES(96,8,CURRENT_DATE-432,CURRENT_DATE-430,CURRENT_DATE-431);

INSERT INTO borrow_transaction(person_id,equipment_id,borrow_date,expected_return_date,actual_return_date) VALUES(97,10,CURRENT_DATE-432,CURRENT_DATE-430,CURRENT_DATE-431);

INSERT INTO borrow_transaction(person_id,equipment_id,borrow_date,expected_return_date,actual_return_date) VALUES(98,11,CURRENT_DATE-432,CURRENT_DATE-430,CURRENT_DATE-431);

INSERT INTO borrow_transaction(person_id,equipment_id,borrow_date,expected_return_date,actual_return_date) VALUES(99,12,CURRENT_DATE-432,CURRENT_DATE-430,CURRENT_DATE-431);

INSERT INTO borrow_transaction(person_id,equipment_id,borrow_date,expected_return_date,actual_return_date) VALUES(100,3,CURRENT_DATE-425,CURRENT_DATE-423,CURRENT_DATE-422);

INSERT INTO borrow_transaction(person_id,equipment_id,borrow_date,expected_return_date,actual_return_date) VALUES(13,4,CURRENT_DATE-425,CURRENT_DATE-423,CURRENT_DATE-424);

INSERT INTO borrow_transaction(person_id,equipment_id,borrow_date,expected_return_date,actual_return_date) VALUES(14,7,CURRENT_DATE-425,CURRENT_DATE-423,CURRENT_DATE-424);

INSERT INTO borrow_transaction(person_id,equipment_id,borrow_date,expected_return_date,actual_return_date) VALUES(15,8,CURRENT_DATE-425,CURRENT_DATE-423,CURRENT_DATE-424);

INSERT INTO borrow_transaction(person_id,equipment_id,borrow_date,expected_return_date,actual_return_date) VALUES(16,10,CURRENT_DATE-425,CURRENT_DATE-423,CURRENT_DATE-424);

INSERT INTO borrow_transaction(person_id,equipment_id,borrow_date,expected_return_date,actual_return_date) VALUES(17,11,CURRENT_DATE-425,CURRENT_DATE-423,CURRENT_DATE-422);

INSERT INTO borrow_transaction(person_id,equipment_id,borrow_date,expected_return_date,actual_return_date) VALUES(18,12,CURRENT_DATE-425,CURRENT_DATE-423,CURRENT_DATE-424);

INSERT INTO borrow_transaction(person_id,equipment_id,borrow_date,expected_return_date,actual_return_date) VALUES(19,3,CURRENT_DATE-418,CURRENT_DATE-416,CURRENT_DATE-417);

INSERT INTO borrow_transaction(person_id,equipment_id,borrow_date,expected_return_date,actual_return_date) VALUES(20,4,CURRENT_DATE-418,CURRENT_DATE-416,CURRENT_DATE-417);

INSERT INTO borrow_transaction(person_id,equipment_id,borrow_date,expected_return_date,actual_return_date) VALUES(21,7,CURRENT_DATE-418,CURRENT_DATE-416,CURRENT_DATE-417);

INSERT INTO borrow_transaction(person_id,equipment_id,borrow_date,expected_return_date,actual_return_date) VALUES(22,8,CURRENT_DATE-418,CURRENT_DATE-416,CURRENT_DATE-415);

INSERT INTO borrow_transaction(person_id,equipment_id,borrow_date,expected_return_date,actual_return_date) VALUES(23,10,CURRENT_DATE-418,CURRENT_DATE-416,CURRENT_DATE-417);

INSERT INTO borrow_transaction(person_id,equipment_id,borrow_date,expected_return_date,actual_return_date) VALUES(24,11,CURRENT_DATE-418,CURRENT_DATE-416,CURRENT_DATE-417);

INSERT INTO borrow_transaction(person_id,equipment_id,borrow_date,expected_return_date,actual_return_date) VALUES(25,12,CURRENT_DATE-418,CURRENT_DATE-416,CURRENT_DATE-417);

INSERT INTO borrow_transaction(person_id,equipment_id,borrow_date,expected_return_date,actual_return_date) VALUES(26,3,CURRENT_DATE-411,CURRENT_DATE-409,CURRENT_DATE-410);

INSERT INTO borrow_transaction(person_id,equipment_id,borrow_date,expected_return_date,actual_return_date) VALUES(27,4,CURRENT_DATE-411,CURRENT_DATE-409,CURRENT_DATE-408);

INSERT INTO borrow_transaction(person_id,equipment_id,borrow_date,expected_return_date,actual_return_date) VALUES(28,7,CURRENT_DATE-411,CURRENT_DATE-409,CURRENT_DATE-410);

INSERT INTO borrow_transaction(person_id,equipment_id,borrow_date,expected_return_date,actual_return_date) VALUES(29,8,CURRENT_DATE-411,CURRENT_DATE-409,CURRENT_DATE-410);

INSERT INTO borrow_transaction(person_id,equipment_id,borrow_date,expected_return_date,actual_return_date) VALUES(30,10,CURRENT_DATE-411,CURRENT_DATE-409,CURRENT_DATE-410);

INSERT INTO borrow_transaction(person_id,equipment_id,borrow_date,expected_return_date,actual_return_date) VALUES(31,11,CURRENT_DATE-411,CURRENT_DATE-409,CURRENT_DATE-410);

INSERT INTO borrow_transaction(person_id,equipment_id,borrow_date,expected_return_date,actual_return_date) VALUES(32,12,CURRENT_DATE-411,CURRENT_DATE-409,CURRENT_DATE-408);

INSERT INTO borrow_transaction(person_id,equipment_id,borrow_date,expected_return_date,actual_return_date) VALUES(33,3,CURRENT_DATE-404,CURRENT_DATE-402,CURRENT_DATE-403);

INSERT INTO borrow_transaction(person_id,equipment_id,borrow_date,expected_return_date,actual_return_date) VALUES(34,4,CURRENT_DATE-404,CURRENT_DATE-402,CURRENT_DATE-403);

INSERT INTO borrow_transaction(person_id,equipment_id,borrow_date,expected_return_date,actual_return_date) VALUES(35,7,CURRENT_DATE-404,CURRENT_DATE-402,CURRENT_DATE-403);

INSERT INTO borrow_transaction(person_id,equipment_id,borrow_date,expected_return_date,actual_return_date) VALUES(36,8,CURRENT_DATE-404,CURRENT_DATE-402,CURRENT_DATE-403);

INSERT INTO maintenance_log(technician_id,equipment_id,start_date,end_date,description,cost) VALUES(83,3,CURRENT_DATE-595,CURRENT_DATE-595,'Vệ sinh và kiểm tra định kỳ',100000);

INSERT INTO maintenance_log(technician_id,equipment_id,start_date,end_date,description,cost) VALUES(84,4,CURRENT_DATE-595,CURRENT_DATE-595,'Hiệu chuẩn bộ đo',150000);

INSERT INTO maintenance_log(technician_id,equipment_id,start_date,end_date,description,cost) VALUES(85,7,CURRENT_DATE-595,CURRENT_DATE-595,'Kiểm tra nguồn và dây nối',200000);

INSERT INTO maintenance_log(technician_id,equipment_id,start_date,end_date,description,cost) VALUES(86,8,CURRENT_DATE-595,CURRENT_DATE-595,'Thay linh kiện hao mòn',250000);

INSERT INTO maintenance_log(technician_id,equipment_id,start_date,end_date,description,cost) VALUES(87,10,CURRENT_DATE-595,CURRENT_DATE-595,'Vệ sinh và kiểm tra định kỳ',300000);

INSERT INTO maintenance_log(technician_id,equipment_id,start_date,end_date,description,cost) VALUES(88,11,CURRENT_DATE-595,CURRENT_DATE-595,'Hiệu chuẩn bộ đo',350000);

INSERT INTO maintenance_log(technician_id,equipment_id,start_date,end_date,description,cost) VALUES(89,12,CURRENT_DATE-595,CURRENT_DATE-595,'Kiểm tra nguồn và dây nối',400000);

INSERT INTO maintenance_log(technician_id,equipment_id,start_date,end_date,description,cost) VALUES(90,3,CURRENT_DATE-588,CURRENT_DATE-588,'Thay linh kiện hao mòn',450000);

INSERT INTO maintenance_log(technician_id,equipment_id,start_date,end_date,description,cost) VALUES(91,4,CURRENT_DATE-588,CURRENT_DATE-588,'Vệ sinh và kiểm tra định kỳ',500000);

INSERT INTO maintenance_log(technician_id,equipment_id,start_date,end_date,description,cost) VALUES(92,7,CURRENT_DATE-588,CURRENT_DATE-588,'Hiệu chuẩn bộ đo',100000);

INSERT INTO maintenance_log(technician_id,equipment_id,start_date,end_date,description,cost) VALUES(93,8,CURRENT_DATE-588,CURRENT_DATE-588,'Kiểm tra nguồn và dây nối',150000);

INSERT INTO maintenance_log(technician_id,equipment_id,start_date,end_date,description,cost) VALUES(94,10,CURRENT_DATE-588,CURRENT_DATE-588,'Thay linh kiện hao mòn',200000);

INSERT INTO maintenance_log(technician_id,equipment_id,start_date,end_date,description,cost) VALUES(95,11,CURRENT_DATE-588,CURRENT_DATE-588,'Vệ sinh và kiểm tra định kỳ',250000);

INSERT INTO maintenance_log(technician_id,equipment_id,start_date,end_date,description,cost) VALUES(96,12,CURRENT_DATE-588,CURRENT_DATE-588,'Hiệu chuẩn bộ đo',300000);

INSERT INTO maintenance_log(technician_id,equipment_id,start_date,end_date,description,cost) VALUES(97,3,CURRENT_DATE-581,CURRENT_DATE-581,'Kiểm tra nguồn và dây nối',350000);

INSERT INTO maintenance_log(technician_id,equipment_id,start_date,end_date,description,cost) VALUES(98,4,CURRENT_DATE-581,CURRENT_DATE-581,'Thay linh kiện hao mòn',400000);

INSERT INTO maintenance_log(technician_id,equipment_id,start_date,end_date,description,cost) VALUES(99,7,CURRENT_DATE-581,CURRENT_DATE-581,'Vệ sinh và kiểm tra định kỳ',450000);

INSERT INTO maintenance_log(technician_id,equipment_id,start_date,end_date,description,cost) VALUES(100,8,CURRENT_DATE-581,CURRENT_DATE-581,'Hiệu chuẩn bộ đo',500000);

INSERT INTO maintenance_log(technician_id,equipment_id,start_date,end_date,description,cost) VALUES(83,10,CURRENT_DATE-581,CURRENT_DATE-581,'Kiểm tra nguồn và dây nối',100000);

INSERT INTO maintenance_log(technician_id,equipment_id,start_date,end_date,description,cost) VALUES(84,11,CURRENT_DATE-581,CURRENT_DATE-581,'Thay linh kiện hao mòn',150000);

INSERT INTO maintenance_log(technician_id,equipment_id,start_date,end_date,description,cost) VALUES(85,12,CURRENT_DATE-581,CURRENT_DATE-581,'Vệ sinh và kiểm tra định kỳ',200000);

INSERT INTO maintenance_log(technician_id,equipment_id,start_date,end_date,description,cost) VALUES(86,3,CURRENT_DATE-574,CURRENT_DATE-574,'Hiệu chuẩn bộ đo',250000);

INSERT INTO maintenance_log(technician_id,equipment_id,start_date,end_date,description,cost) VALUES(87,4,CURRENT_DATE-574,CURRENT_DATE-574,'Kiểm tra nguồn và dây nối',300000);

INSERT INTO maintenance_log(technician_id,equipment_id,start_date,end_date,description,cost) VALUES(88,7,CURRENT_DATE-574,CURRENT_DATE-574,'Thay linh kiện hao mòn',350000);

INSERT INTO maintenance_log(technician_id,equipment_id,start_date,end_date,description,cost) VALUES(89,8,CURRENT_DATE-574,CURRENT_DATE-574,'Vệ sinh và kiểm tra định kỳ',400000);

INSERT INTO maintenance_log(technician_id,equipment_id,start_date,end_date,description,cost) VALUES(90,10,CURRENT_DATE-574,CURRENT_DATE-574,'Hiệu chuẩn bộ đo',450000);

INSERT INTO maintenance_log(technician_id,equipment_id,start_date,end_date,description,cost) VALUES(91,11,CURRENT_DATE-574,CURRENT_DATE-574,'Kiểm tra nguồn và dây nối',500000);

INSERT INTO maintenance_log(technician_id,equipment_id,start_date,end_date,description,cost) VALUES(92,12,CURRENT_DATE-574,CURRENT_DATE-574,'Thay linh kiện hao mòn',100000);

INSERT INTO maintenance_log(technician_id,equipment_id,start_date,end_date,description,cost) VALUES(93,3,CURRENT_DATE-567,CURRENT_DATE-567,'Vệ sinh và kiểm tra định kỳ',150000);

INSERT INTO maintenance_log(technician_id,equipment_id,start_date,end_date,description,cost) VALUES(94,4,CURRENT_DATE-567,CURRENT_DATE-567,'Hiệu chuẩn bộ đo',200000);

INSERT INTO maintenance_log(technician_id,equipment_id,start_date,end_date,description,cost) VALUES(95,7,CURRENT_DATE-567,CURRENT_DATE-567,'Kiểm tra nguồn và dây nối',250000);

INSERT INTO maintenance_log(technician_id,equipment_id,start_date,end_date,description,cost) VALUES(96,8,CURRENT_DATE-567,CURRENT_DATE-567,'Thay linh kiện hao mòn',300000);

INSERT INTO maintenance_log(technician_id,equipment_id,start_date,end_date,description,cost) VALUES(97,10,CURRENT_DATE-567,CURRENT_DATE-567,'Vệ sinh và kiểm tra định kỳ',350000);

INSERT INTO maintenance_log(technician_id,equipment_id,start_date,end_date,description,cost) VALUES(98,11,CURRENT_DATE-567,CURRENT_DATE-567,'Hiệu chuẩn bộ đo',400000);

INSERT INTO maintenance_log(technician_id,equipment_id,start_date,end_date,description,cost) VALUES(99,12,CURRENT_DATE-567,CURRENT_DATE-567,'Kiểm tra nguồn và dây nối',450000);

INSERT INTO maintenance_log(technician_id,equipment_id,start_date,end_date,description,cost) VALUES(100,3,CURRENT_DATE-560,CURRENT_DATE-560,'Thay linh kiện hao mòn',500000);

INSERT INTO maintenance_log(technician_id,equipment_id,start_date,end_date,description,cost) VALUES(83,4,CURRENT_DATE-560,CURRENT_DATE-560,'Vệ sinh và kiểm tra định kỳ',100000);

INSERT INTO maintenance_log(technician_id,equipment_id,start_date,end_date,description,cost) VALUES(84,7,CURRENT_DATE-560,CURRENT_DATE-560,'Hiệu chuẩn bộ đo',150000);

INSERT INTO maintenance_log(technician_id,equipment_id,start_date,end_date,description,cost) VALUES(85,8,CURRENT_DATE-560,CURRENT_DATE-560,'Kiểm tra nguồn và dây nối',200000);

INSERT INTO maintenance_log(technician_id,equipment_id,start_date,end_date,description,cost) VALUES(86,10,CURRENT_DATE-560,CURRENT_DATE-560,'Thay linh kiện hao mòn',250000);

INSERT INTO maintenance_log(technician_id,equipment_id,start_date,end_date,description,cost) VALUES(87,11,CURRENT_DATE-560,CURRENT_DATE-560,'Vệ sinh và kiểm tra định kỳ',300000);

INSERT INTO maintenance_log(technician_id,equipment_id,start_date,end_date,description,cost) VALUES(88,12,CURRENT_DATE-560,CURRENT_DATE-560,'Hiệu chuẩn bộ đo',350000);

INSERT INTO maintenance_log(technician_id,equipment_id,start_date,end_date,description,cost) VALUES(89,3,CURRENT_DATE-553,CURRENT_DATE-553,'Kiểm tra nguồn và dây nối',400000);

INSERT INTO maintenance_log(technician_id,equipment_id,start_date,end_date,description,cost) VALUES(90,4,CURRENT_DATE-553,CURRENT_DATE-553,'Thay linh kiện hao mòn',450000);

INSERT INTO maintenance_log(technician_id,equipment_id,start_date,end_date,description,cost) VALUES(91,7,CURRENT_DATE-553,CURRENT_DATE-553,'Vệ sinh và kiểm tra định kỳ',500000);

INSERT INTO maintenance_log(technician_id,equipment_id,start_date,end_date,description,cost) VALUES(92,8,CURRENT_DATE-553,CURRENT_DATE-553,'Hiệu chuẩn bộ đo',100000);

INSERT INTO maintenance_log(technician_id,equipment_id,start_date,end_date,description,cost) VALUES(93,10,CURRENT_DATE-553,CURRENT_DATE-553,'Kiểm tra nguồn và dây nối',150000);

INSERT INTO maintenance_log(technician_id,equipment_id,start_date,end_date,description,cost) VALUES(94,11,CURRENT_DATE-553,CURRENT_DATE-553,'Thay linh kiện hao mòn',200000);

INSERT INTO maintenance_log(technician_id,equipment_id,start_date,end_date,description,cost) VALUES(95,12,CURRENT_DATE-553,CURRENT_DATE-553,'Vệ sinh và kiểm tra định kỳ',250000);

INSERT INTO maintenance_log(technician_id,equipment_id,start_date,end_date,description,cost) VALUES(96,3,CURRENT_DATE-546,CURRENT_DATE-546,'Hiệu chuẩn bộ đo',300000);

INSERT INTO maintenance_log(technician_id,equipment_id,start_date,end_date,description,cost) VALUES(97,4,CURRENT_DATE-546,CURRENT_DATE-546,'Kiểm tra nguồn và dây nối',350000);

INSERT INTO maintenance_log(technician_id,equipment_id,start_date,end_date,description,cost) VALUES(98,7,CURRENT_DATE-546,CURRENT_DATE-546,'Thay linh kiện hao mòn',400000);

INSERT INTO maintenance_log(technician_id,equipment_id,start_date,end_date,description,cost) VALUES(99,8,CURRENT_DATE-546,CURRENT_DATE-546,'Vệ sinh và kiểm tra định kỳ',450000);

INSERT INTO maintenance_log(technician_id,equipment_id,start_date,end_date,description,cost) VALUES(100,10,CURRENT_DATE-546,CURRENT_DATE-546,'Hiệu chuẩn bộ đo',500000);

INSERT INTO maintenance_log(technician_id,equipment_id,start_date,end_date,description,cost) VALUES(83,11,CURRENT_DATE-546,CURRENT_DATE-546,'Kiểm tra nguồn và dây nối',100000);

INSERT INTO maintenance_log(technician_id,equipment_id,start_date,end_date,description,cost) VALUES(84,12,CURRENT_DATE-546,CURRENT_DATE-546,'Thay linh kiện hao mòn',150000);

INSERT INTO maintenance_log(technician_id,equipment_id,start_date,end_date,description,cost) VALUES(85,3,CURRENT_DATE-539,CURRENT_DATE-539,'Vệ sinh và kiểm tra định kỳ',200000);

INSERT INTO maintenance_log(technician_id,equipment_id,start_date,end_date,description,cost) VALUES(86,4,CURRENT_DATE-539,CURRENT_DATE-539,'Hiệu chuẩn bộ đo',250000);

INSERT INTO maintenance_log(technician_id,equipment_id,start_date,end_date,description,cost) VALUES(87,7,CURRENT_DATE-539,CURRENT_DATE-539,'Kiểm tra nguồn và dây nối',300000);

INSERT INTO maintenance_log(technician_id,equipment_id,start_date,end_date,description,cost) VALUES(88,8,CURRENT_DATE-539,CURRENT_DATE-539,'Thay linh kiện hao mòn',350000);

INSERT INTO maintenance_log(technician_id,equipment_id,start_date,end_date,description,cost) VALUES(89,10,CURRENT_DATE-539,CURRENT_DATE-539,'Vệ sinh và kiểm tra định kỳ',400000);

INSERT INTO maintenance_log(technician_id,equipment_id,start_date,end_date,description,cost) VALUES(90,11,CURRENT_DATE-539,CURRENT_DATE-539,'Hiệu chuẩn bộ đo',450000);

INSERT INTO maintenance_log(technician_id,equipment_id,start_date,end_date,description,cost) VALUES(91,12,CURRENT_DATE-539,CURRENT_DATE-539,'Kiểm tra nguồn và dây nối',500000);

INSERT INTO maintenance_log(technician_id,equipment_id,start_date,end_date,description,cost) VALUES(92,3,CURRENT_DATE-532,CURRENT_DATE-532,'Thay linh kiện hao mòn',100000);

INSERT INTO maintenance_log(technician_id,equipment_id,start_date,end_date,description,cost) VALUES(93,4,CURRENT_DATE-532,CURRENT_DATE-532,'Vệ sinh và kiểm tra định kỳ',150000);

INSERT INTO maintenance_log(technician_id,equipment_id,start_date,end_date,description,cost) VALUES(94,7,CURRENT_DATE-532,CURRENT_DATE-532,'Hiệu chuẩn bộ đo',200000);

INSERT INTO maintenance_log(technician_id,equipment_id,start_date,end_date,description,cost) VALUES(95,8,CURRENT_DATE-532,CURRENT_DATE-532,'Kiểm tra nguồn và dây nối',250000);

INSERT INTO maintenance_log(technician_id,equipment_id,start_date,end_date,description,cost) VALUES(96,10,CURRENT_DATE-532,CURRENT_DATE-532,'Thay linh kiện hao mòn',300000);

INSERT INTO maintenance_log(technician_id,equipment_id,start_date,end_date,description,cost) VALUES(97,11,CURRENT_DATE-532,CURRENT_DATE-532,'Vệ sinh và kiểm tra định kỳ',350000);

INSERT INTO maintenance_log(technician_id,equipment_id,start_date,end_date,description,cost) VALUES(98,12,CURRENT_DATE-532,CURRENT_DATE-532,'Hiệu chuẩn bộ đo',400000);

INSERT INTO maintenance_log(technician_id,equipment_id,start_date,end_date,description,cost) VALUES(99,3,CURRENT_DATE-525,CURRENT_DATE-525,'Kiểm tra nguồn và dây nối',450000);

INSERT INTO maintenance_log(technician_id,equipment_id,start_date,end_date,description,cost) VALUES(100,4,CURRENT_DATE-525,CURRENT_DATE-525,'Thay linh kiện hao mòn',500000);

INSERT INTO maintenance_log(technician_id,equipment_id,start_date,end_date,description,cost) VALUES(83,7,CURRENT_DATE-525,CURRENT_DATE-525,'Vệ sinh và kiểm tra định kỳ',100000);

INSERT INTO maintenance_log(technician_id,equipment_id,start_date,end_date,description,cost) VALUES(84,8,CURRENT_DATE-525,CURRENT_DATE-525,'Hiệu chuẩn bộ đo',150000);

INSERT INTO maintenance_log(technician_id,equipment_id,start_date,end_date,description,cost) VALUES(85,10,CURRENT_DATE-525,CURRENT_DATE-525,'Kiểm tra nguồn và dây nối',200000);

INSERT INTO maintenance_log(technician_id,equipment_id,start_date,end_date,description,cost) VALUES(86,11,CURRENT_DATE-525,CURRENT_DATE-525,'Thay linh kiện hao mòn',250000);

INSERT INTO maintenance_log(technician_id,equipment_id,start_date,end_date,description,cost) VALUES(87,12,CURRENT_DATE-525,CURRENT_DATE-525,'Vệ sinh và kiểm tra định kỳ',300000);

INSERT INTO maintenance_log(technician_id,equipment_id,start_date,end_date,description,cost) VALUES(88,3,CURRENT_DATE-518,CURRENT_DATE-518,'Hiệu chuẩn bộ đo',350000);

INSERT INTO maintenance_log(technician_id,equipment_id,start_date,end_date,description,cost) VALUES(89,4,CURRENT_DATE-518,CURRENT_DATE-518,'Kiểm tra nguồn và dây nối',400000);

INSERT INTO maintenance_log(technician_id,equipment_id,start_date,end_date,description,cost) VALUES(90,7,CURRENT_DATE-518,CURRENT_DATE-518,'Thay linh kiện hao mòn',450000);

INSERT INTO maintenance_log(technician_id,equipment_id,start_date,end_date,description,cost) VALUES(91,8,CURRENT_DATE-518,CURRENT_DATE-518,'Vệ sinh và kiểm tra định kỳ',500000);

INSERT INTO maintenance_log(technician_id,equipment_id,start_date,end_date,description,cost) VALUES(92,10,CURRENT_DATE-518,CURRENT_DATE-518,'Hiệu chuẩn bộ đo',100000);

INSERT INTO maintenance_log(technician_id,equipment_id,start_date,end_date,description,cost) VALUES(93,11,CURRENT_DATE-518,CURRENT_DATE-518,'Kiểm tra nguồn và dây nối',150000);

INSERT INTO maintenance_log(technician_id,equipment_id,start_date,end_date,description,cost) VALUES(94,12,CURRENT_DATE-518,CURRENT_DATE-518,'Thay linh kiện hao mòn',200000);

INSERT INTO maintenance_log(technician_id,equipment_id,start_date,end_date,description,cost) VALUES(95,3,CURRENT_DATE-511,CURRENT_DATE-511,'Vệ sinh và kiểm tra định kỳ',250000);

INSERT INTO maintenance_log(technician_id,equipment_id,start_date,end_date,description,cost) VALUES(96,4,CURRENT_DATE-511,CURRENT_DATE-511,'Hiệu chuẩn bộ đo',300000);

INSERT INTO maintenance_log(technician_id,equipment_id,start_date,end_date,description,cost) VALUES(97,7,CURRENT_DATE-511,CURRENT_DATE-511,'Kiểm tra nguồn và dây nối',350000);

INSERT INTO maintenance_log(technician_id,equipment_id,start_date,end_date,description,cost) VALUES(98,8,CURRENT_DATE-511,CURRENT_DATE-511,'Thay linh kiện hao mòn',400000);

INSERT INTO maintenance_log(technician_id,equipment_id,start_date,end_date,description,cost) VALUES(99,10,CURRENT_DATE-511,CURRENT_DATE-511,'Vệ sinh và kiểm tra định kỳ',450000);

INSERT INTO maintenance_log(technician_id,equipment_id,start_date,end_date,description,cost) VALUES(100,11,CURRENT_DATE-511,CURRENT_DATE-511,'Hiệu chuẩn bộ đo',500000);

INSERT INTO maintenance_log(technician_id,equipment_id,start_date,end_date,description,cost) VALUES(83,12,CURRENT_DATE-511,CURRENT_DATE-511,'Kiểm tra nguồn và dây nối',100000);

INSERT INTO maintenance_log(technician_id,equipment_id,start_date,end_date,description,cost) VALUES(84,3,CURRENT_DATE-504,CURRENT_DATE-504,'Thay linh kiện hao mòn',150000);

INSERT INTO maintenance_log(technician_id,equipment_id,start_date,end_date,description,cost) VALUES(85,4,CURRENT_DATE-504,CURRENT_DATE-504,'Vệ sinh và kiểm tra định kỳ',200000);

INSERT INTO maintenance_log(technician_id,equipment_id,start_date,end_date,description,cost) VALUES(86,7,CURRENT_DATE-504,CURRENT_DATE-504,'Hiệu chuẩn bộ đo',250000);

INSERT INTO maintenance_log(technician_id,equipment_id,start_date,end_date,description,cost) VALUES(87,8,CURRENT_DATE-504,CURRENT_DATE-504,'Kiểm tra nguồn và dây nối',300000);

INSERT INTO maintenance_log(technician_id,equipment_id,start_date,end_date,description,cost) VALUES(88,10,CURRENT_DATE-504,CURRENT_DATE-504,'Thay linh kiện hao mòn',350000);

INSERT INTO maintenance_log(technician_id,equipment_id,start_date,end_date,description,cost) VALUES(89,11,CURRENT_DATE-504,CURRENT_DATE-504,'Vệ sinh và kiểm tra định kỳ',400000);

INSERT INTO maintenance_log(technician_id,equipment_id,start_date,end_date,description,cost) VALUES(90,12,CURRENT_DATE-504,CURRENT_DATE-504,'Hiệu chuẩn bộ đo',450000);

INSERT INTO maintenance_log(technician_id,equipment_id,start_date,end_date,description,cost) VALUES(91,3,CURRENT_DATE-497,CURRENT_DATE-497,'Kiểm tra nguồn và dây nối',500000);

INSERT INTO maintenance_log(technician_id,equipment_id,start_date,end_date,description,cost) VALUES(92,4,CURRENT_DATE-497,CURRENT_DATE-497,'Thay linh kiện hao mòn',100000);

SELECT receive_chemical(1,83,10,'Nhập bổ sung lô mô phỏng 1');

SELECT issue_chemical(1,14,1,2,'Xuất mẫu cảm biến lô mô phỏng 2');

SELECT receive_chemical(2,85,12,'Nhập bổ sung lô mô phỏng 3');

SELECT issue_chemical(1,16,1,4,'Xuất mẫu cảm biến lô mô phỏng 4');

SELECT receive_chemical(3,87,14,'Nhập bổ sung lô mô phỏng 5');

SELECT issue_chemical(1,18,1,2,'Xuất mẫu cảm biến lô mô phỏng 6');

SELECT receive_chemical(4,89,16,'Nhập bổ sung lô mô phỏng 7');

SELECT issue_chemical(1,20,1,4,'Xuất mẫu cảm biến lô mô phỏng 8');

SELECT receive_chemical(6,91,18,'Nhập bổ sung lô mô phỏng 9');

SELECT issue_chemical(1,22,1,2,'Xuất mẫu cảm biến lô mô phỏng 10');

SELECT receive_chemical(1,93,20,'Nhập bổ sung lô mô phỏng 11');

SELECT issue_chemical(1,24,1,4,'Xuất mẫu cảm biến lô mô phỏng 12');

SELECT receive_chemical(2,95,22,'Nhập bổ sung lô mô phỏng 13');

SELECT issue_chemical(1,14,1,2,'Xuất mẫu cảm biến lô mô phỏng 14');

SELECT receive_chemical(3,97,24,'Nhập bổ sung lô mô phỏng 15');

SELECT issue_chemical(1,16,1,4,'Xuất mẫu cảm biến lô mô phỏng 16');

SELECT receive_chemical(4,99,26,'Nhập bổ sung lô mô phỏng 17');

SELECT issue_chemical(1,18,1,2,'Xuất mẫu cảm biến lô mô phỏng 18');

SELECT receive_chemical(6,83,11,'Nhập bổ sung lô mô phỏng 19');

SELECT issue_chemical(1,20,1,4,'Xuất mẫu cảm biến lô mô phỏng 20');

SELECT receive_chemical(1,85,13,'Nhập bổ sung lô mô phỏng 21');

SELECT issue_chemical(1,22,1,2,'Xuất mẫu cảm biến lô mô phỏng 22');

SELECT receive_chemical(2,87,15,'Nhập bổ sung lô mô phỏng 23');

SELECT issue_chemical(1,24,1,4,'Xuất mẫu cảm biến lô mô phỏng 24');

SELECT receive_chemical(3,89,17,'Nhập bổ sung lô mô phỏng 25');

SELECT issue_chemical(1,14,1,2,'Xuất mẫu cảm biến lô mô phỏng 26');

SELECT receive_chemical(4,91,19,'Nhập bổ sung lô mô phỏng 27');

SELECT issue_chemical(1,16,1,4,'Xuất mẫu cảm biến lô mô phỏng 28');

SELECT receive_chemical(6,93,21,'Nhập bổ sung lô mô phỏng 29');

SELECT issue_chemical(1,18,1,2,'Xuất mẫu cảm biến lô mô phỏng 30');

SELECT receive_chemical(1,95,23,'Nhập bổ sung lô mô phỏng 31');

SELECT issue_chemical(1,20,1,4,'Xuất mẫu cảm biến lô mô phỏng 32');

SELECT receive_chemical(2,97,25,'Nhập bổ sung lô mô phỏng 33');

SELECT issue_chemical(1,22,1,2,'Xuất mẫu cảm biến lô mô phỏng 34');

SELECT receive_chemical(3,99,10,'Nhập bổ sung lô mô phỏng 35');

SELECT issue_chemical(1,24,1,4,'Xuất mẫu cảm biến lô mô phỏng 36');

SELECT receive_chemical(4,83,12,'Nhập bổ sung lô mô phỏng 37');

SELECT issue_chemical(1,14,1,2,'Xuất mẫu cảm biến lô mô phỏng 38');

SELECT receive_chemical(6,85,14,'Nhập bổ sung lô mô phỏng 39');

SELECT issue_chemical(1,16,1,4,'Xuất mẫu cảm biến lô mô phỏng 40');

SELECT receive_chemical(1,87,16,'Nhập bổ sung lô mô phỏng 41');

SELECT issue_chemical(1,18,1,2,'Xuất mẫu cảm biến lô mô phỏng 42');

SELECT receive_chemical(2,89,18,'Nhập bổ sung lô mô phỏng 43');

SELECT issue_chemical(1,20,1,4,'Xuất mẫu cảm biến lô mô phỏng 44');

SELECT receive_chemical(3,91,20,'Nhập bổ sung lô mô phỏng 45');

SELECT issue_chemical(1,22,1,2,'Xuất mẫu cảm biến lô mô phỏng 46');

SELECT receive_chemical(4,93,22,'Nhập bổ sung lô mô phỏng 47');

SELECT issue_chemical(1,24,1,4,'Xuất mẫu cảm biến lô mô phỏng 48');

SELECT receive_chemical(6,95,24,'Nhập bổ sung lô mô phỏng 49');

SELECT issue_chemical(1,14,1,2,'Xuất mẫu cảm biến lô mô phỏng 50');

SELECT receive_chemical(1,97,26,'Nhập bổ sung lô mô phỏng 51');

SELECT issue_chemical(1,16,1,4,'Xuất mẫu cảm biến lô mô phỏng 52');

SELECT receive_chemical(2,99,11,'Nhập bổ sung lô mô phỏng 53');

SELECT issue_chemical(1,18,1,2,'Xuất mẫu cảm biến lô mô phỏng 54');

SELECT receive_chemical(3,83,13,'Nhập bổ sung lô mô phỏng 55');

SELECT issue_chemical(1,20,1,4,'Xuất mẫu cảm biến lô mô phỏng 56');

SELECT receive_chemical(4,85,15,'Nhập bổ sung lô mô phỏng 57');

SELECT issue_chemical(1,22,1,2,'Xuất mẫu cảm biến lô mô phỏng 58');

SELECT receive_chemical(6,87,17,'Nhập bổ sung lô mô phỏng 59');

SELECT issue_chemical(1,24,1,4,'Xuất mẫu cảm biến lô mô phỏng 60');

SELECT receive_chemical(1,89,19,'Nhập bổ sung lô mô phỏng 61');

SELECT issue_chemical(1,14,1,2,'Xuất mẫu cảm biến lô mô phỏng 62');

SELECT receive_chemical(2,91,21,'Nhập bổ sung lô mô phỏng 63');

SELECT issue_chemical(1,16,1,4,'Xuất mẫu cảm biến lô mô phỏng 64');

SELECT receive_chemical(3,93,23,'Nhập bổ sung lô mô phỏng 65');

SELECT issue_chemical(1,18,1,2,'Xuất mẫu cảm biến lô mô phỏng 66');

SELECT receive_chemical(4,95,25,'Nhập bổ sung lô mô phỏng 67');

SELECT issue_chemical(1,20,1,4,'Xuất mẫu cảm biến lô mô phỏng 68');

SELECT receive_chemical(6,97,10,'Nhập bổ sung lô mô phỏng 69');

SELECT issue_chemical(1,22,1,2,'Xuất mẫu cảm biến lô mô phỏng 70');

SELECT receive_chemical(1,99,12,'Nhập bổ sung lô mô phỏng 71');

SELECT issue_chemical(1,24,1,4,'Xuất mẫu cảm biến lô mô phỏng 72');

SELECT receive_chemical(2,83,14,'Nhập bổ sung lô mô phỏng 73');

SELECT issue_chemical(1,14,1,2,'Xuất mẫu cảm biến lô mô phỏng 74');

SELECT receive_chemical(3,85,16,'Nhập bổ sung lô mô phỏng 75');

SELECT issue_chemical(1,16,1,4,'Xuất mẫu cảm biến lô mô phỏng 76');

SELECT receive_chemical(4,87,18,'Nhập bổ sung lô mô phỏng 77');

SELECT issue_chemical(1,18,1,2,'Xuất mẫu cảm biến lô mô phỏng 78');

SELECT receive_chemical(6,89,20,'Nhập bổ sung lô mô phỏng 79');

SELECT issue_chemical(1,20,1,4,'Xuất mẫu cảm biến lô mô phỏng 80');

SELECT receive_chemical(1,91,22,'Nhập bổ sung lô mô phỏng 81');

SELECT issue_chemical(1,22,1,2,'Xuất mẫu cảm biến lô mô phỏng 82');

SELECT receive_chemical(2,93,24,'Nhập bổ sung lô mô phỏng 83');

SELECT issue_chemical(1,24,1,4,'Xuất mẫu cảm biến lô mô phỏng 84');

SELECT receive_chemical(3,95,26,'Nhập bổ sung lô mô phỏng 85');

SELECT issue_chemical(1,14,1,2,'Xuất mẫu cảm biến lô mô phỏng 86');

SELECT receive_chemical(4,97,11,'Nhập bổ sung lô mô phỏng 87');

SELECT issue_chemical(1,16,1,4,'Xuất mẫu cảm biến lô mô phỏng 88');

SELECT receive_chemical(6,99,13,'Nhập bổ sung lô mô phỏng 89');

SELECT issue_chemical(1,18,1,2,'Xuất mẫu cảm biến lô mô phỏng 90');

SELECT receive_chemical(1,83,15,'Nhập bổ sung lô mô phỏng 91');

SELECT issue_chemical(1,20,1,4,'Xuất mẫu cảm biến lô mô phỏng 92');

SELECT receive_chemical(2,85,17,'Nhập bổ sung lô mô phỏng 93');

SELECT issue_chemical(1,22,1,2,'Xuất mẫu cảm biến lô mô phỏng 94');

SELECT receive_chemical(3,87,19,'Nhập bổ sung lô mô phỏng 95');

SELECT issue_chemical(1,24,1,4,'Xuất mẫu cảm biến lô mô phỏng 96');

SELECT receive_chemical(4,89,21,'Nhập bổ sung lô mô phỏng 97');

SELECT issue_chemical(1,14,1,2,'Xuất mẫu cảm biến lô mô phỏng 98');

SELECT receive_chemical(6,91,23,'Nhập bổ sung lô mô phỏng 99');

SELECT issue_chemical(1,16,1,4,'Xuất mẫu cảm biến lô mô phỏng 100');

SELECT receive_chemical(1,93,25,'Nhập bổ sung lô mô phỏng 101');

SELECT issue_chemical(1,18,1,2,'Xuất mẫu cảm biến lô mô phỏng 102');

SELECT receive_chemical(2,95,10,'Nhập bổ sung lô mô phỏng 103');

SELECT issue_chemical(1,20,1,4,'Xuất mẫu cảm biến lô mô phỏng 104');

SELECT receive_chemical(3,97,12,'Nhập bổ sung lô mô phỏng 105');

SELECT issue_chemical(1,22,1,2,'Xuất mẫu cảm biến lô mô phỏng 106');

SELECT receive_chemical(4,99,14,'Nhập bổ sung lô mô phỏng 107');

SELECT issue_chemical(1,24,1,4,'Xuất mẫu cảm biến lô mô phỏng 108');

SELECT receive_chemical(6,83,16,'Nhập bổ sung lô mô phỏng 109');

SELECT issue_chemical(1,14,1,2,'Xuất mẫu cảm biến lô mô phỏng 110');

SELECT receive_chemical(1,85,18,'Nhập bổ sung lô mô phỏng 111');

SELECT issue_chemical(1,16,1,4,'Xuất mẫu cảm biến lô mô phỏng 112');

SELECT receive_chemical(2,87,20,'Nhập bổ sung lô mô phỏng 113');

SELECT issue_chemical(1,18,1,2,'Xuất mẫu cảm biến lô mô phỏng 114');

SELECT receive_chemical(3,89,22,'Nhập bổ sung lô mô phỏng 115');

SELECT issue_chemical(1,20,1,4,'Xuất mẫu cảm biến lô mô phỏng 116');

SELECT receive_chemical(4,91,24,'Nhập bổ sung lô mô phỏng 117');

SELECT issue_chemical(1,22,1,2,'Xuất mẫu cảm biến lô mô phỏng 118');

SELECT receive_chemical(6,93,26,'Nhập bổ sung lô mô phỏng 119');

SELECT issue_chemical(1,24,1,4,'Xuất mẫu cảm biến lô mô phỏng 120');

SELECT receive_chemical(1,95,11,'Nhập bổ sung lô mô phỏng 121');

SELECT issue_chemical(1,14,1,2,'Xuất mẫu cảm biến lô mô phỏng 122');

SELECT receive_chemical(2,97,13,'Nhập bổ sung lô mô phỏng 123');

SELECT issue_chemical(1,16,1,4,'Xuất mẫu cảm biến lô mô phỏng 124');

SELECT receive_chemical(3,99,15,'Nhập bổ sung lô mô phỏng 125');

SELECT issue_chemical(1,18,1,2,'Xuất mẫu cảm biến lô mô phỏng 126');

SELECT receive_chemical(4,83,17,'Nhập bổ sung lô mô phỏng 127');

SELECT issue_chemical(1,20,1,4,'Xuất mẫu cảm biến lô mô phỏng 128');

SELECT receive_chemical(6,85,19,'Nhập bổ sung lô mô phỏng 129');

SELECT issue_chemical(1,22,1,2,'Xuất mẫu cảm biến lô mô phỏng 130');

SELECT receive_chemical(1,87,21,'Nhập bổ sung lô mô phỏng 131');

SELECT issue_chemical(1,24,1,4,'Xuất mẫu cảm biến lô mô phỏng 132');

SELECT receive_chemical(2,89,23,'Nhập bổ sung lô mô phỏng 133');

SELECT issue_chemical(1,14,1,2,'Xuất mẫu cảm biến lô mô phỏng 134');

SELECT receive_chemical(3,91,25,'Nhập bổ sung lô mô phỏng 135');

SELECT issue_chemical(1,16,1,4,'Xuất mẫu cảm biến lô mô phỏng 136');

SELECT receive_chemical(4,93,10,'Nhập bổ sung lô mô phỏng 137');

SELECT issue_chemical(1,18,1,2,'Xuất mẫu cảm biến lô mô phỏng 138');

SELECT receive_chemical(6,95,12,'Nhập bổ sung lô mô phỏng 139');

SELECT issue_chemical(1,20,1,4,'Xuất mẫu cảm biến lô mô phỏng 140');

SELECT receive_chemical(1,97,14,'Nhập bổ sung lô mô phỏng 141');

SELECT issue_chemical(1,22,1,2,'Xuất mẫu cảm biến lô mô phỏng 142');

SELECT receive_chemical(2,99,16,'Nhập bổ sung lô mô phỏng 143');

SELECT issue_chemical(1,24,1,4,'Xuất mẫu cảm biến lô mô phỏng 144');

SELECT receive_chemical(3,83,18,'Nhập bổ sung lô mô phỏng 145');

SELECT issue_chemical(1,14,1,2,'Xuất mẫu cảm biến lô mô phỏng 146');

SELECT receive_chemical(4,85,20,'Nhập bổ sung lô mô phỏng 147');

SELECT issue_chemical(1,16,1,4,'Xuất mẫu cảm biến lô mô phỏng 148');

SELECT receive_chemical(6,87,22,'Nhập bổ sung lô mô phỏng 149');

SELECT issue_chemical(1,18,1,2,'Xuất mẫu cảm biến lô mô phỏng 150');

SELECT receive_chemical(1,89,24,'Nhập bổ sung lô mô phỏng 151');

SELECT issue_chemical(1,20,1,4,'Xuất mẫu cảm biến lô mô phỏng 152');

SELECT receive_chemical(2,91,26,'Nhập bổ sung lô mô phỏng 153');

SELECT issue_chemical(1,22,1,2,'Xuất mẫu cảm biến lô mô phỏng 154');

SELECT receive_chemical(3,93,11,'Nhập bổ sung lô mô phỏng 155');

SELECT issue_chemical(1,24,1,4,'Xuất mẫu cảm biến lô mô phỏng 156');

SELECT receive_chemical(4,95,13,'Nhập bổ sung lô mô phỏng 157');

SELECT issue_chemical(1,14,1,2,'Xuất mẫu cảm biến lô mô phỏng 158');

SELECT receive_chemical(6,97,15,'Nhập bổ sung lô mô phỏng 159');

SELECT issue_chemical(1,16,1,4,'Xuất mẫu cảm biến lô mô phỏng 160');

SELECT receive_chemical(1,99,17,'Nhập bổ sung lô mô phỏng 161');

SELECT issue_chemical(1,18,1,2,'Xuất mẫu cảm biến lô mô phỏng 162');

SELECT receive_chemical(2,83,19,'Nhập bổ sung lô mô phỏng 163');

SELECT issue_chemical(1,20,1,4,'Xuất mẫu cảm biến lô mô phỏng 164');

SELECT receive_chemical(3,85,21,'Nhập bổ sung lô mô phỏng 165');

SELECT issue_chemical(1,22,1,2,'Xuất mẫu cảm biến lô mô phỏng 166');

SELECT receive_chemical(4,87,23,'Nhập bổ sung lô mô phỏng 167');

SELECT issue_chemical(1,24,1,4,'Xuất mẫu cảm biến lô mô phỏng 168');

SELECT receive_chemical(6,89,25,'Nhập bổ sung lô mô phỏng 169');

SELECT issue_chemical(1,14,1,2,'Xuất mẫu cảm biến lô mô phỏng 170');

SELECT receive_chemical(1,91,10,'Nhập bổ sung lô mô phỏng 171');

SELECT issue_chemical(1,16,1,4,'Xuất mẫu cảm biến lô mô phỏng 172');

SELECT receive_chemical(2,93,12,'Nhập bổ sung lô mô phỏng 173');

SELECT issue_chemical(1,18,1,2,'Xuất mẫu cảm biến lô mô phỏng 174');

SELECT receive_chemical(3,95,14,'Nhập bổ sung lô mô phỏng 175');

SELECT issue_chemical(1,20,1,4,'Xuất mẫu cảm biến lô mô phỏng 176');

SELECT receive_chemical(4,97,16,'Nhập bổ sung lô mô phỏng 177');

SELECT issue_chemical(1,22,1,2,'Xuất mẫu cảm biến lô mô phỏng 178');

SELECT receive_chemical(6,99,18,'Nhập bổ sung lô mô phỏng 179');

SELECT issue_chemical(1,24,1,4,'Xuất mẫu cảm biến lô mô phỏng 180');

SELECT receive_chemical(1,83,20,'Nhập bổ sung lô mô phỏng 181');

SELECT issue_chemical(1,14,1,2,'Xuất mẫu cảm biến lô mô phỏng 182');

SELECT receive_chemical(2,85,22,'Nhập bổ sung lô mô phỏng 183');

SELECT issue_chemical(1,16,1,4,'Xuất mẫu cảm biến lô mô phỏng 184');

SELECT receive_chemical(3,87,24,'Nhập bổ sung lô mô phỏng 185');

SELECT issue_chemical(1,18,1,2,'Xuất mẫu cảm biến lô mô phỏng 186');

SELECT receive_chemical(4,89,26,'Nhập bổ sung lô mô phỏng 187');

SELECT issue_chemical(1,20,1,4,'Xuất mẫu cảm biến lô mô phỏng 188');

SELECT receive_chemical(6,91,11,'Nhập bổ sung lô mô phỏng 189');

SELECT issue_chemical(1,22,1,2,'Xuất mẫu cảm biến lô mô phỏng 190');

SELECT receive_chemical(1,93,13,'Nhập bổ sung lô mô phỏng 191');

SELECT issue_chemical(1,24,1,4,'Xuất mẫu cảm biến lô mô phỏng 192');

SELECT receive_chemical(2,95,15,'Nhập bổ sung lô mô phỏng 193');

SELECT issue_chemical(1,14,1,2,'Xuất mẫu cảm biến lô mô phỏng 194');

SELECT receive_chemical(3,97,17,'Nhập bổ sung lô mô phỏng 195');

SELECT issue_chemical(1,16,1,4,'Xuất mẫu cảm biến lô mô phỏng 196');

SELECT receive_chemical(4,99,19,'Nhập bổ sung lô mô phỏng 197');

SELECT issue_chemical(1,18,1,2,'Xuất mẫu cảm biến lô mô phỏng 198');

SELECT receive_chemical(6,83,21,'Nhập bổ sung lô mô phỏng 199');

SELECT issue_chemical(1,20,1,4,'Xuất mẫu cảm biến lô mô phỏng 200');

SELECT receive_chemical(1,85,23,'Nhập bổ sung lô mô phỏng 201');

SELECT issue_chemical(1,22,1,2,'Xuất mẫu cảm biến lô mô phỏng 202');

SELECT receive_chemical(2,87,25,'Nhập bổ sung lô mô phỏng 203');

SELECT issue_chemical(1,24,1,4,'Xuất mẫu cảm biến lô mô phỏng 204');

SELECT receive_chemical(3,89,10,'Nhập bổ sung lô mô phỏng 205');

SELECT issue_chemical(1,14,1,2,'Xuất mẫu cảm biến lô mô phỏng 206');

SELECT receive_chemical(4,91,12,'Nhập bổ sung lô mô phỏng 207');

SELECT issue_chemical(1,16,1,4,'Xuất mẫu cảm biến lô mô phỏng 208');

SELECT receive_chemical(6,93,14,'Nhập bổ sung lô mô phỏng 209');

SELECT issue_chemical(1,18,1,2,'Xuất mẫu cảm biến lô mô phỏng 210');

SELECT receive_chemical(1,95,16,'Nhập bổ sung lô mô phỏng 211');

SELECT issue_chemical(1,20,1,4,'Xuất mẫu cảm biến lô mô phỏng 212');

SELECT receive_chemical(2,97,18,'Nhập bổ sung lô mô phỏng 213');

SELECT issue_chemical(1,22,1,2,'Xuất mẫu cảm biến lô mô phỏng 214');

SELECT receive_chemical(3,99,20,'Nhập bổ sung lô mô phỏng 215');

SELECT issue_chemical(1,24,1,4,'Xuất mẫu cảm biến lô mô phỏng 216');

SELECT receive_chemical(4,83,22,'Nhập bổ sung lô mô phỏng 217');

SELECT issue_chemical(1,14,1,2,'Xuất mẫu cảm biến lô mô phỏng 218');

SELECT receive_chemical(6,85,24,'Nhập bổ sung lô mô phỏng 219');

SELECT issue_chemical(1,16,1,4,'Xuất mẫu cảm biến lô mô phỏng 220');

SELECT receive_chemical(1,87,26,'Nhập bổ sung lô mô phỏng 221');

SELECT issue_chemical(1,18,1,2,'Xuất mẫu cảm biến lô mô phỏng 222');

SELECT receive_chemical(2,89,11,'Nhập bổ sung lô mô phỏng 223');

SELECT issue_chemical(1,20,1,4,'Xuất mẫu cảm biến lô mô phỏng 224');

SELECT receive_chemical(3,91,13,'Nhập bổ sung lô mô phỏng 225');

SELECT issue_chemical(1,22,1,2,'Xuất mẫu cảm biến lô mô phỏng 226');

SELECT receive_chemical(4,93,15,'Nhập bổ sung lô mô phỏng 227');

SELECT issue_chemical(1,24,1,4,'Xuất mẫu cảm biến lô mô phỏng 228');

SELECT receive_chemical(6,95,17,'Nhập bổ sung lô mô phỏng 229');

SELECT issue_chemical(1,14,1,2,'Xuất mẫu cảm biến lô mô phỏng 230');

SELECT receive_chemical(1,97,19,'Nhập bổ sung lô mô phỏng 231');

SELECT issue_chemical(1,16,1,4,'Xuất mẫu cảm biến lô mô phỏng 232');

SELECT receive_chemical(2,99,21,'Nhập bổ sung lô mô phỏng 233');

SELECT issue_chemical(1,18,1,2,'Xuất mẫu cảm biến lô mô phỏng 234');

SELECT receive_chemical(3,83,23,'Nhập bổ sung lô mô phỏng 235');

SELECT issue_chemical(1,20,1,4,'Xuất mẫu cảm biến lô mô phỏng 236');

SELECT receive_chemical(4,85,25,'Nhập bổ sung lô mô phỏng 237');

SELECT setval(pg_get_serial_sequence('person','person_id'),(SELECT max(person_id) FROM person));
