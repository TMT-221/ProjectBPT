SET search_path = lab_tracker, pg_catalog;
SET TIME ZONE 'Asia/Ho_Chi_Minh';

-- Q03: Hóa chất sắp hết hạn trong 30 ngày
SELECT c.chemical_id,c.chemical_name,l.lab_name,c.quantity_in_stock,c.unit,c.expiry_date-CURRENT_DATE AS days_to_expiry
 FROM chemical c JOIN laboratory l USING(lab_id)
 WHERE c.expiry_date BETWEEN CURRENT_DATE AND CURRENT_DATE+30 AND c.quantity_in_stock>0 ORDER BY c.expiry_date,c.chemical_id;
