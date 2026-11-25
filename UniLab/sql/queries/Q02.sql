SET search_path = lab_tracker, pg_catalog;
SET TIME ZONE 'Asia/Ho_Chi_Minh';

-- Q02: Người đang giữ thiết bị và số lượt quá hạn
SELECT r.person_id,r.full_name,r.person_role,count(b.borrow_id) AS open_loans,
 count(b.borrow_id) FILTER (WHERE b.expected_return_date<CURRENT_DATE) AS overdue_loans
 FROM v_person_role r LEFT JOIN borrow_transaction b ON b.person_id=r.person_id AND b.actual_return_date IS NULL
 GROUP BY r.person_id,r.full_name,r.person_role HAVING count(b.borrow_id)>0 ORDER BY r.person_id;
