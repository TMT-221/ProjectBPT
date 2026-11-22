SET search_path = lab_tracker, pg_catalog;
SET TIME ZONE 'Asia/Ho_Chi_Minh';

-- Q06: Tình trạng thiết bị theo phòng
SELECT l.lab_id,l.lab_name,count(e.equipment_id) AS total_equipment,
 count(e.equipment_id) FILTER(WHERE e.current_status='Available') AS available,
 count(e.equipment_id) FILTER(WHERE e.current_status='In Use') AS in_use,
 count(e.equipment_id) FILTER(WHERE e.current_status='Under Maintenance') AS under_maintenance,
 count(e.equipment_id) FILTER(WHERE e.current_status='Retired') AS retired
 FROM laboratory l LEFT JOIN equipment e USING(lab_id) GROUP BY l.lab_id,l.lab_name ORDER BY l.lab_id;
