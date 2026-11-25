SET search_path=lab_tracker,pg_catalog;
BEGIN;
CREATE TEMP TABLE phase3_test_result(test_id text PRIMARY KEY,passed boolean,actual text);
CREATE FUNCTION pg_temp.expect_reject(p_id text,p_sql text,p_pattern text) RETURNS void LANGUAGE plpgsql AS $$
DECLARE v_message text; v_rejected boolean:=false;
BEGIN
 BEGIN
  EXECUTE p_sql;
  SET CONSTRAINTS ALL IMMEDIATE;
 EXCEPTION WHEN OTHERS THEN
  GET STACKED DIAGNOSTICS v_message=MESSAGE_TEXT;
  v_rejected:=true;
 END;
 IF NOT v_rejected THEN RAISE EXCEPTION 'TEST % FAILED: statement was accepted',p_id; END IF;
 IF position(lower(p_pattern) IN lower(v_message))=0 THEN RAISE EXCEPTION 'TEST % FAILED: unexpected rejection %',p_id,v_message; END IF;
 INSERT INTO phase3_test_result VALUES(p_id,true,v_message);
END $$;
CREATE FUNCTION pg_temp.expect_true(p_id text,p_sql text) RETURNS void LANGUAGE plpgsql AS $$
DECLARE v_ok boolean;
BEGIN
 EXECUTE p_sql INTO v_ok;
 IF v_ok IS DISTINCT FROM true THEN RAISE EXCEPTION 'TEST % FAILED',p_id; END IF;
 INSERT INTO phase3_test_result VALUES(p_id,true,'Assertion true');
END $$;
SELECT pg_temp.expect_reject('T01A',$sql$INSERT INTO person(person_id,full_name,email) VALUES(900,'Không lớp con','no-subtype@test.edu')$sql$,'BR01');
SELECT pg_temp.expect_reject('T01B',$sql$INSERT INTO faculty VALUES(4,'CNTT','Thạc sĩ',NULL)$sql$,'BR01');
SELECT pg_temp.expect_reject('T01D',$sql$UPDATE faculty SET faculty_id=4 WHERE faculty_id=1$sql$,'BR01');
INSERT INTO person(person_id,full_name,email) VALUES(901,'Đúng một lớp con','one-subtype@test.edu');
INSERT INTO student VALUES(901,'TEST901','CNTT',1);
SET CONSTRAINTS ALL IMMEDIATE;
SELECT pg_temp.expect_true('T01C',$sql$SELECT count(*)=1 FROM student WHERE student_id=901$sql$);
SET CONSTRAINTS ALL DEFERRED;
SELECT pg_temp.expect_reject('T02A',$sql$INSERT INTO research_grant(grant_title,principal_investigator_id,start_date,end_date,total_budget,remaining_budget) VALUES('PI không hợp lệ',4,CURRENT_DATE,CURRENT_DATE+1,1,1)$sql$,'foreign key');
SELECT pg_temp.expect_reject('T02B',$sql$INSERT INTO maintenance_log(technician_id,equipment_id,start_date,end_date,description,cost) VALUES(4,12,CURRENT_DATE,CURRENT_DATE,'Sai vai trò',1)$sql$,'foreign key');
SELECT pg_temp.expect_reject('T03A',$sql$INSERT INTO access_log(person_id,lab_id,entry_time,purpose) VALUES(4,2,CURRENT_DATE+time '18:00','Thử truy cập')$sql$,'BR04');
INSERT INTO access_log(log_id,person_id,lab_id,entry_time,purpose,approved_by) VALUES(900,4,2,CURRENT_DATE+time '18:00','Thử truy cập',2);
SELECT pg_temp.expect_true('T03B',$sql$SELECT approved_by=2 FROM access_log WHERE log_id=900$sql$);
SELECT pg_temp.expect_reject('T03C',$sql$INSERT INTO access_log(person_id,lab_id,entry_time,purpose,approved_by) VALUES(4,2,CURRENT_DATE+time '18:00','Phê duyệt sai',5)$sql$,'BR04');
SELECT pg_temp.expect_reject('T03D',$sql$INSERT INTO access_log(person_id,lab_id,entry_time,purpose) VALUES(4,2,CURRENT_DATE+time '17:00','Mốc kết thúc giờ hành chính')$sql$,'BR04');
SELECT pg_temp.expect_reject('T04',$sql$INSERT INTO access_log(person_id,lab_id,entry_time,purpose) VALUES(7,3,CURRENT_DATE+time '09:00','Thiếu chứng nhận')$sql$,'BR05');
SELECT pg_temp.expect_reject('T05A',$sql$UPDATE has_certification SET expiry_date=issue_date WHERE person_id=6 AND cert_id=1$sql$,'check constraint');
SELECT pg_temp.expect_reject('T05D',$sql$UPDATE has_certification SET status='Valid' WHERE person_id=6 AND cert_id=1$sql$,'does not exist');
SELECT pg_temp.expect_true('T05B',$sql$SELECT status='Expired' FROM v_certification_current WHERE person_id=6 AND cert_id=1$sql$);
SELECT pg_temp.expect_reject('T05C',$sql$INSERT INTO access_log(person_id,lab_id,entry_time,purpose) VALUES(6,2,CURRENT_DATE+time '09:00','Chứng nhận hết hạn')$sql$,'BR05');
SELECT pg_temp.expect_reject('T06A',$sql$UPDATE chemical SET lab_id=1 WHERE chemical_id=2$sql$,'BR20');
SELECT pg_temp.expect_reject('T06B',$sql$UPDATE laboratory SET safety_level='Normal' WHERE lab_id=3$sql$,'BR20');
SELECT pg_temp.expect_reject('T07A',$sql$UPDATE research_grant SET remaining_budget=-1 WHERE grant_id=1$sql$,'check constraint');
SELECT pg_temp.expect_reject('T07B',$sql$UPDATE chemical SET quantity_in_stock=-1 WHERE chemical_id=3$sql$,'check constraint');
SELECT pg_temp.expect_reject('T08A',$sql$SELECT checkout_equipment(4,6,CURRENT_DATE+3)$sql$,'BR13');
SELECT pg_temp.expect_reject('T08B',$sql$SELECT checkout_equipment(4,9,CURRENT_DATE+3)$sql$,'BR13');
SELECT checkout_equipment(4,3,CURRENT_DATE+3);
SELECT pg_temp.expect_reject('T08C',$sql$SELECT checkout_equipment(4,11,CURRENT_DATE+3)$sql$,'BR14');
UPDATE borrow_transaction SET actual_return_date=CURRENT_DATE WHERE borrow_id=1;
SELECT pg_temp.expect_true('T09',$sql$SELECT status='Overdue' AND actual_return_date=CURRENT_DATE FROM v_borrow_current WHERE borrow_id=1$sql$);
SELECT pg_temp.expect_reject('T10A',$sql$INSERT INTO allocated_equip VALUES(5,12)$sql$,'BR12');
SELECT pg_temp.expect_reject('T10B',$sql$INSERT INTO allocated_chem VALUES(6,1)$sql$,'BR12');
SELECT pg_temp.expect_reject('T10C',$sql$INSERT INTO allocated_equip VALUES(1,12)$sql$,'BR11');
SELECT pg_temp.expect_reject('T11A',$sql$INSERT INTO has_certification VALUES(4,1,CURRENT_DATE-1,CURRENT_DATE+300)$sql$,'duplicate key');
SELECT pg_temp.expect_reject('T11B',$sql$INSERT INTO allocated_equip VALUES(3,1)$sql$,'duplicate key');
SELECT pg_temp.expect_reject('T12A',$sql$INSERT INTO access_log(person_id,lab_id,entry_time,exit_time,purpose) VALUES(4,1,CURRENT_DATE+time '09:00',CURRENT_DATE+time '08:00','Sai giờ')$sql$,'check constraint');
SELECT pg_temp.expect_reject('T12B',$sql$UPDATE research_grant SET end_date=start_date WHERE grant_id=1$sql$,'check constraint');
SELECT pg_temp.expect_reject('T13A',$sql$DO $body$ BEGIN DELETE FROM has_certification WHERE person_id=4; DELETE FROM student WHERE student_id=4; DELETE FROM person WHERE person_id=4; END $body$$sql$,'foreign key');
SELECT pg_temp.expect_reject('T13B',$sql$DO $body$ BEGIN DELETE FROM allocated_equip WHERE equipment_id=5; DELETE FROM equipment WHERE equipment_id=5; END $body$$sql$,'foreign key');
SELECT pg_temp.expect_reject('H01',$sql$SELECT issue_chemical(1,4,1,1,'Sai loại chứng nhận')$sql$,'BR06');
SELECT pg_temp.expect_reject('H02',$sql$SELECT issue_chemical(2,5,1,0.1,'Thiếu chứng nhận axit')$sql$,'BR06');
SELECT pg_temp.expect_reject('H03',$sql$SELECT issue_chemical(1,12,1,1,'Chứng nhận dung môi hết hạn')$sql$,'BR06');
SELECT pg_temp.expect_reject('H04',$sql$SELECT issue_chemical(5,5,1,0.1,'Hóa chất hết hạn')$sql$,'BR18');
SELECT pg_temp.expect_reject('H05',$sql$SELECT issue_chemical(1,5,1,999,'Vượt tồn kho')$sql$,'BR17');
SELECT pg_temp.expect_reject('H06',$sql$SELECT issue_chemical(1,5,1,0,'Số lượng bằng không')$sql$,'BR19');
SELECT pg_temp.expect_reject('H07',$sql$UPDATE chemical_movement SET quantity=quantity+1 WHERE movement_id=1$sql$,'append-only');
SELECT pg_temp.expect_reject('H08',$sql$DELETE FROM grant_laboratory WHERE grant_id=1 AND lab_id=3$sql$,'BR11');
SELECT issue_chemical(2,10,1,0.1,'Kiểm thử cấp Extreme hợp lệ');
SELECT pg_temp.expect_true('H09',$sql$SELECT quantity_in_stock=4.4 FROM chemical WHERE chemical_id=2$sql$);
SELECT pg_temp.expect_true('H10',$sql$SELECT bool_and(reconciled) FROM v_chemical_stock_audit$sql$);
SELECT pg_temp.expect_reject('H11',$sql$SELECT issue_chemical(3,8,2,1,'Người ngừng hoạt động')$sql$,'BR06');
SELECT pg_temp.expect_reject('H12',$sql$SELECT start_maintenance(4,12,'Sai vai trò',1)$sql$,'BR03');
SELECT pg_temp.expect_reject('H14',$sql$UPDATE equipment SET lab_id=3 WHERE equipment_id=1$sql$,'BR11');

-- BR05: the type, complete set, catalog entry, and inclusive dates matter.
SELECT pg_temp.expect_reject('BR05_wrong_type',$sql$DO $body$ BEGIN UPDATE has_certification SET cert_id=3 WHERE person_id=4 AND cert_id=1; INSERT INTO access_log(person_id,lab_id,entry_time,purpose) VALUES(4,2,CURRENT_DATE+TIME '09:00','Wrong type'); END $body$$sql$,'BR05');
SELECT pg_temp.expect_reject('BR05_missing_one',$sql$INSERT INTO access_log(person_id,lab_id,entry_time,purpose) VALUES(9,3,CURRENT_DATE+TIME '09:00','Missing acid certificate')$sql$,'BR05');
SELECT pg_temp.expect_reject('BR05_one_expired',$sql$DO $body$ BEGIN UPDATE has_certification SET issue_date=CURRENT_DATE-100,expiry_date=CURRENT_DATE-1 WHERE person_id=10 AND cert_id=3; INSERT INTO access_log(person_id,lab_id,entry_time,purpose) VALUES(10,3,CURRENT_DATE+TIME '09:00','Expired one certificate'); END $body$$sql$,'BR05');
SELECT pg_temp.expect_reject('BR05_missing_catalog',$sql$DO $body$ BEGIN UPDATE certification SET cert_name='Temporarily unavailable' WHERE cert_id=3; INSERT INTO access_log(person_id,lab_id,entry_time,purpose) VALUES(10,3,CURRENT_DATE+TIME '09:00','Missing configured type'); END $body$$sql$,'BR05');
INSERT INTO access_log(log_id,person_id,lab_id,entry_time,purpose) VALUES(910,10,3,CURRENT_DATE+TIME '09:00','All three valid');
SELECT pg_temp.expect_true('BR05_all_three',$sql$SELECT person_id=10 AND lab_id=3 FROM access_log WHERE log_id=910$sql$);
UPDATE has_certification SET issue_date=CURRENT_DATE,expiry_date=CURRENT_DATE+1 WHERE person_id=4 AND cert_id=1;
INSERT INTO access_log(log_id,person_id,lab_id,entry_time,purpose) VALUES(911,4,2,CURRENT_DATE+TIME '09:00','Issue date inclusive');
SELECT pg_temp.expect_true('BR05_issue_inclusive',$sql$SELECT person_id=4 FROM access_log WHERE log_id=911$sql$);
UPDATE has_certification SET issue_date=CURRENT_DATE-1,expiry_date=CURRENT_DATE WHERE person_id=4 AND cert_id=1;
INSERT INTO access_log(log_id,person_id,lab_id,entry_time,purpose) VALUES(912,4,2,CURRENT_DATE+TIME '09:00','Expiry date inclusive');
SELECT pg_temp.expect_true('BR05_expiry_inclusive',$sql$SELECT person_id=4 FROM access_log WHERE log_id=912$sql$);
INSERT INTO access_log(log_id,person_id,lab_id,entry_time,purpose) VALUES(913,7,1,CURRENT_DATE+TIME '09:00','Normal without certification');
SELECT pg_temp.expect_true('BR05_normal_no_cert',$sql$SELECT person_id=7 FROM access_log WHERE log_id=913$sql$);
-- Student [07:00,17:00), Faculty [06:00,22:00); purpose remains free text.
SELECT pg_temp.expect_reject('BR04_0659',$sql$INSERT INTO access_log(person_id,lab_id,entry_time,purpose) VALUES(4,1,CURRENT_DATE+TIME '06:59','Early student')$sql$,'BR04');
INSERT INTO access_log(log_id,person_id,lab_id,entry_time,purpose) VALUES(914,4,1,CURRENT_DATE+TIME '07:00','Start inclusive'),(915,4,1,CURRENT_DATE+TIME '16:59','Before end');
SELECT pg_temp.expect_true('BR04_0700',$sql$SELECT person_id=4 FROM access_log WHERE log_id=914$sql$);
SELECT pg_temp.expect_true('BR04_1659',$sql$SELECT person_id=4 FROM access_log WHERE log_id=915$sql$);
SELECT pg_temp.expect_reject('BR27_0559_empty',$sql$INSERT INTO access_log(person_id,lab_id,entry_time,purpose) VALUES(1,1,CURRENT_DATE+TIME '05:59','   ')$sql$,'BR27');
SELECT pg_temp.expect_reject('BR27_2200_empty',$sql$INSERT INTO access_log(person_id,lab_id,entry_time,purpose) VALUES(1,1,CURRENT_DATE+TIME '22:00','   ')$sql$,'BR27');
INSERT INTO access_log(log_id,person_id,lab_id,entry_time,purpose) VALUES
 (916,1,1,CURRENT_DATE+TIME '05:59','Khắc phục sự cố máy chủ'),
 (917,1,1,CURRENT_DATE+TIME '06:00','Nghiên cứu'),
 (918,1,1,CURRENT_DATE+TIME '21:59','Nghiên cứu'),
 (919,1,1,CURRENT_DATE+TIME '22:00','Xử lý sự cố điện');
SELECT pg_temp.expect_true('BR27_0559_reason',$sql$SELECT person_id=1 FROM access_log WHERE log_id=916$sql$);
SELECT pg_temp.expect_true('BR27_0600',$sql$SELECT person_id=1 FROM access_log WHERE log_id=917$sql$);
SELECT pg_temp.expect_true('BR27_2159',$sql$SELECT person_id=1 FROM access_log WHERE log_id=918$sql$);
SELECT pg_temp.expect_true('BR27_2200_reason',$sql$SELECT person_id=1 FROM access_log WHERE log_id=919$sql$);
SELECT pg_temp.expect_reject('DERIVED_borrow_write',$sql$UPDATE borrow_transaction SET status='Returned' WHERE borrow_id=1$sql$,'does not exist');
SELECT pg_temp.expect_reject('DERIVED_movement_write',$sql$UPDATE chemical_movement SET movement_type='Issue' WHERE movement_id=1$sql$,'does not exist');

SELECT test_id,passed,actual FROM phase3_test_result ORDER BY test_id;
ROLLBACK;
