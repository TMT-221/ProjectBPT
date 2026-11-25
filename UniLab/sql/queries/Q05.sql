SET search_path = lab_tracker, pg_catalog;
SET TIME ZONE 'Asia/Ho_Chi_Minh';

-- Q05: Lượt truy cập và tổng giờ người theo phòng
SELECT l.lab_id,l.lab_name,count(a.log_id) AS visits,
 round(coalesce(sum(extract(epoch FROM(a.exit_time-a.entry_time))/3600),0)::numeric,2) AS completed_person_hours
 FROM laboratory l LEFT JOIN access_log a ON a.lab_id=l.lab_id AND a.entry_time>=CURRENT_DATE-7
 GROUP BY l.lab_id,l.lab_name ORDER BY l.lab_id;
