SET search_path = lab_tracker, pg_catalog;
SET TIME ZONE 'Asia/Ho_Chi_Minh';

-- Q01: Tổng hợp đề tài đang thực hiện
SELECT g.grant_id,g.grant_title,p.full_name AS principal_investigator,g.remaining_budget,
 round(100*(g.total_budget-g.remaining_budget)/nullif(g.total_budget,0),2) AS used_budget_pct,
 s.equipment_count,s.chemical_count
 FROM research_grant g JOIN person p ON p.person_id=g.principal_investigator_id
 JOIN v_grant_asset_summary s USING(grant_id) WHERE g.status='Active' ORDER BY g.grant_id;
