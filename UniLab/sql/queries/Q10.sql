SET search_path = lab_tracker, pg_catalog;
SET TIME ZONE 'Asia/Ho_Chi_Minh';

-- Q10: Đề tài có thiết bị cho mọi hạng mục Active
SELECT g.grant_id, g.grant_title
FROM research_grant g
WHERE g.status='Active'
    AND NOT EXISTS (
        SELECT 1
        FROM research_point p
        WHERE p.grant_id=g.grant_id
            AND p.status='Active'
            AND NOT EXISTS (
                SELECT 1
                FROM allocated_equip a
                WHERE a.rearch_point_id=p.rearch_point_id
            )
    )
ORDER BY g.grant_id;
