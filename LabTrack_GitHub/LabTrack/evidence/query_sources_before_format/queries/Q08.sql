SET search_path = lab_tracker, pg_catalog;
SET TIME ZONE 'Asia/Ho_Chi_Minh';

-- Q08: Người có đủ chứng nhận hóa chất High/Extreme
SELECT p.person_id,p.full_name,c.chemical_id,c.chemical_name
 FROM person p CROSS JOIN chemical c
 WHERE p.status='Active' AND c.hazard_level IN('High','Extreme') AND c.expiry_date>=CURRENT_DATE
 AND EXISTS(SELECT 1 FROM chemical_certification r WHERE r.chemical_id=c.chemical_id)
 AND NOT EXISTS(SELECT 1 FROM chemical_certification r WHERE r.chemical_id=c.chemical_id AND NOT EXISTS(
 SELECT 1 FROM v_certification_current h WHERE h.person_id=p.person_id AND h.cert_id=r.cert_id AND h.status='Valid' AND CURRENT_DATE BETWEEN h.issue_date AND h.expiry_date
 )) ORDER BY p.person_id,c.chemical_id;
