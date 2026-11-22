SET search_path = lab_tracker, pg_catalog;
SET TIME ZONE 'Asia/Ho_Chi_Minh';

-- Q12: Mức sử dụng và tỷ lệ quá hạn thiết bị
WITH usage AS (
 SELECT e.equipment_id,e.equipment_name,count(b.borrow_id) AS loan_count,
 count(b.borrow_id) FILTER(WHERE b.status='Overdue') AS late_count
 FROM equipment e LEFT JOIN v_borrow_current b USING(equipment_id) GROUP BY e.equipment_id
) SELECT equipment_id,equipment_name,loan_count,late_count,
 round(100.0*late_count/nullif(loan_count,0),2) AS late_pct,
 rank() OVER(ORDER BY loan_count DESC) AS usage_rank
 FROM usage WHERE loan_count>0 ORDER BY usage_rank,equipment_id;
