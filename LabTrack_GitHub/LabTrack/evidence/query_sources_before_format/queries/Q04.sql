SET search_path = lab_tracker, pg_catalog;
SET TIME ZONE 'Asia/Ho_Chi_Minh';

-- Q04: Người Active chưa có chứng nhận hợp lệ
SELECT p.person_id,p.full_name FROM person p
 WHERE p.status='Active' AND NOT EXISTS(
 SELECT 1 FROM v_certification_current h WHERE h.person_id=p.person_id AND h.status='Valid' AND CURRENT_DATE BETWEEN h.issue_date AND h.expiry_date
 ) ORDER BY p.person_id;
