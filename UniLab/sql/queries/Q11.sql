SET search_path = lab_tracker, pg_catalog;
SET TIME ZONE 'Asia/Ho_Chi_Minh';

-- Q11: Kiểm toán sinh viên truy cập ngoài giờ
SELECT a.log_id,p.full_name,l.lab_name,to_char(a.entry_time,'YYYY-MM-DD HH24:MI:SS') AS entry_time,a.approved_by,q.full_name AS approver
 FROM access_log a JOIN student s ON s.student_id=a.person_id JOIN person p USING(person_id)
 JOIN laboratory l USING(lab_id) JOIN person q ON q.person_id=a.approved_by
 WHERE a.entry_time::time<time '07:00' OR a.entry_time::time>=time '17:00' ORDER BY a.log_id;
