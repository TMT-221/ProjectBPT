SET search_path = lab_tracker, pg_catalog;
SET TIME ZONE 'Asia/Ho_Chi_Minh';

-- Q09: Đối soát tồn kho với sổ nhập xuất
SELECT c.chemical_id,c.chemical_name,c.unit,
 sum(m.quantity) FILTER(WHERE m.movement_type='Receipt') AS total_received,
 coalesce(sum(m.quantity) FILTER(WHERE m.movement_type='Issue'),0) AS total_issued,
 c.quantity_in_stock,a.ledger_balance,a.reconciled
 FROM chemical c JOIN v_chemical_movement m USING(chemical_id) JOIN v_chemical_stock_audit a USING(chemical_id)
 GROUP BY c.chemical_id,a.ledger_balance,a.reconciled ORDER BY c.chemical_id;
