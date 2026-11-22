SET search_path = lab_tracker, pg_catalog;
SET TIME ZONE 'Asia/Ho_Chi_Minh';

-- Q01: Tổng hợp đề tài đang thực hiện
SELECT g.grant_id,g.grant_title,p.full_name AS principal_investigator,g.remaining_budget,
 round(100*(g.total_budget-g.remaining_budget)/nullif(g.total_budget,0),2) AS used_budget_pct,
 s.equipment_count,s.chemical_count
 FROM research_grant g JOIN person p ON p.person_id=g.principal_investigator_id
 JOIN v_grant_asset_summary s USING(grant_id) WHERE g.status='Active' ORDER BY g.grant_id;

-- Q02: Người đang giữ thiết bị và số lượt quá hạn
SELECT r.person_id,r.full_name,r.person_role,count(b.borrow_id) AS open_loans,
 count(b.borrow_id) FILTER (WHERE b.expected_return_date<CURRENT_DATE) AS overdue_loans
 FROM v_person_role r LEFT JOIN borrow_transaction b ON b.person_id=r.person_id AND b.actual_return_date IS NULL
 GROUP BY r.person_id,r.full_name,r.person_role HAVING count(b.borrow_id)>0 ORDER BY r.person_id;

-- Q03: Hóa chất sắp hết hạn trong 30 ngày
SELECT c.chemical_id,c.chemical_name,l.lab_name,c.quantity_in_stock,c.unit,c.expiry_date-CURRENT_DATE AS days_to_expiry
 FROM chemical c JOIN laboratory l USING(lab_id)
 WHERE c.expiry_date BETWEEN CURRENT_DATE AND CURRENT_DATE+30 AND c.quantity_in_stock>0 ORDER BY c.expiry_date,c.chemical_id;

-- Q04: Người Active chưa có chứng nhận hợp lệ
SELECT p.person_id,p.full_name FROM person p
 WHERE p.status='Active' AND NOT EXISTS(
 SELECT 1 FROM v_certification_current h WHERE h.person_id=p.person_id AND h.status='Valid' AND CURRENT_DATE BETWEEN h.issue_date AND h.expiry_date
 ) ORDER BY p.person_id;

-- Q05: Lượt truy cập và tổng giờ người theo phòng
SELECT l.lab_id,l.lab_name,count(a.log_id) AS visits,
 round(coalesce(sum(extract(epoch FROM(a.exit_time-a.entry_time))/3600),0)::numeric,2) AS completed_person_hours
 FROM laboratory l LEFT JOIN access_log a ON a.lab_id=l.lab_id AND a.entry_time>=CURRENT_DATE-7
 GROUP BY l.lab_id,l.lab_name ORDER BY l.lab_id;

-- Q06: Tình trạng thiết bị theo phòng
SELECT l.lab_id,l.lab_name,count(e.equipment_id) AS total_equipment,
 count(e.equipment_id) FILTER(WHERE e.current_status='Available') AS available,
 count(e.equipment_id) FILTER(WHERE e.current_status='In Use') AS in_use,
 count(e.equipment_id) FILTER(WHERE e.current_status='Under Maintenance') AS under_maintenance,
 count(e.equipment_id) FILTER(WHERE e.current_status='Retired') AS retired
 FROM laboratory l LEFT JOIN equipment e USING(lab_id) GROUP BY l.lab_id,l.lab_name ORDER BY l.lab_id;

-- Q07: Xếp hạng chi phí bảo trì trong từng phòng
WITH costs AS (
 SELECT e.equipment_id,e.equipment_name,e.lab_id,coalesce(sum(m.cost),0) AS maintenance_cost
 FROM equipment e LEFT JOIN maintenance_log m USING(equipment_id) GROUP BY e.equipment_id
), ranked AS (
 SELECT *,dense_rank() OVER(PARTITION BY lab_id ORDER BY maintenance_cost DESC) AS cost_rank FROM costs
) SELECT equipment_id,equipment_name,lab_id,maintenance_cost,cost_rank FROM ranked WHERE maintenance_cost>0 ORDER BY lab_id,cost_rank,equipment_id;

-- Q08: Người có đủ chứng nhận hóa chất High/Extreme
SELECT p.person_id,p.full_name,c.chemical_id,c.chemical_name
 FROM person p CROSS JOIN chemical c
 WHERE p.status='Active' AND c.hazard_level IN('High','Extreme') AND c.expiry_date>=CURRENT_DATE
 AND EXISTS(SELECT 1 FROM chemical_certification r WHERE r.chemical_id=c.chemical_id)
 AND NOT EXISTS(SELECT 1 FROM chemical_certification r WHERE r.chemical_id=c.chemical_id AND NOT EXISTS(
 SELECT 1 FROM v_certification_current h WHERE h.person_id=p.person_id AND h.cert_id=r.cert_id AND h.status='Valid' AND CURRENT_DATE BETWEEN h.issue_date AND h.expiry_date
 )) ORDER BY p.person_id,c.chemical_id;

-- Q09: Đối soát tồn kho với sổ nhập xuất
SELECT c.chemical_id,c.chemical_name,c.unit,
 sum(m.quantity) FILTER(WHERE m.movement_type='Receipt') AS total_received,
 coalesce(sum(m.quantity) FILTER(WHERE m.movement_type='Issue'),0) AS total_issued,
 c.quantity_in_stock,a.ledger_balance,a.reconciled
 FROM chemical c JOIN v_chemical_movement m USING(chemical_id) JOIN v_chemical_stock_audit a USING(chemical_id)
 GROUP BY c.chemical_id,a.ledger_balance,a.reconciled ORDER BY c.chemical_id;

-- Q10: Đề tài có thiết bị cho mọi hạng mục Active
SELECT g.grant_id,g.grant_title FROM research_grant g WHERE g.status='Active'
 AND NOT EXISTS(SELECT 1 FROM research_point p WHERE p.grant_id=g.grant_id AND p.status='Active' AND NOT EXISTS(
 SELECT 1 FROM allocated_equip a WHERE a.rearch_point_id=p.rearch_point_id
 )) ORDER BY g.grant_id;

-- Q11: Kiểm toán sinh viên truy cập ngoài giờ
SELECT a.log_id,p.full_name,l.lab_name,to_char(a.entry_time,'YYYY-MM-DD HH24:MI:SS') AS entry_time,a.approved_by,q.full_name AS approver
 FROM access_log a JOIN student s ON s.student_id=a.person_id JOIN person p USING(person_id)
 JOIN laboratory l USING(lab_id) JOIN person q ON q.person_id=a.approved_by
 WHERE a.entry_time::time<time '07:00' OR a.entry_time::time>=time '17:00' ORDER BY a.log_id;

-- Q12: Mức sử dụng và tỷ lệ quá hạn thiết bị
WITH usage AS (
 SELECT e.equipment_id,e.equipment_name,count(b.borrow_id) AS loan_count,
 count(b.borrow_id) FILTER(WHERE b.status='Overdue') AS late_count
 FROM equipment e LEFT JOIN v_borrow_current b USING(equipment_id) GROUP BY e.equipment_id
) SELECT equipment_id,equipment_name,loan_count,late_count,
 round(100.0*late_count/nullif(loan_count,0),2) AS late_pct,
 rank() OVER(ORDER BY loan_count DESC) AS usage_rank
 FROM usage WHERE loan_count>0 ORDER BY usage_rank,equipment_id;
