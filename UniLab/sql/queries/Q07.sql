SET search_path = lab_tracker, pg_catalog;
SET TIME ZONE 'Asia/Ho_Chi_Minh';

-- Q07: Xếp hạng chi phí bảo trì trong từng phòng
WITH costs AS (
    SELECT e.equipment_id, e.equipment_name, e.lab_id,
        coalesce(sum(m.cost),0) AS maintenance_cost
    FROM equipment e
    LEFT JOIN maintenance_log m USING(equipment_id)
    GROUP BY e.equipment_id
), ranked AS (
    SELECT *, dense_rank() OVER(
        PARTITION BY lab_id
        ORDER BY maintenance_cost DESC
    ) AS cost_rank
    FROM costs
)
SELECT equipment_id, equipment_name, lab_id, maintenance_cost, cost_rank
FROM ranked
WHERE maintenance_cost>0
ORDER BY lab_id, cost_rank, equipment_id;
