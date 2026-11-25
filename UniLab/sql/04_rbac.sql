CREATE ROLE lab_reader NOLOGIN;
CREATE ROLE lab_app NOLOGIN;
CREATE ROLE lab_technician NOLOGIN;
CREATE ROLE lab_manager NOLOGIN;
GRANT lab_app TO lab_technician;
GRANT lab_reader TO lab_manager;
GRANT USAGE ON SCHEMA lab_tracker TO lab_reader,lab_app,lab_technician,lab_manager;
GRANT SELECT ON lab_tracker.v_open_loans,lab_tracker.v_grant_asset_summary,
 lab_tracker.v_chemical_stock_audit,lab_tracker.v_certification_current TO lab_reader,lab_app;
GRANT SELECT ON lab_tracker.laboratory,lab_tracker.equipment,lab_tracker.chemical,
 lab_tracker.certification,lab_tracker.research_grant,lab_tracker.research_point TO lab_reader,lab_app;
GRANT EXECUTE ON FUNCTION lab_tracker.issue_chemical(bigint,bigint,bigint,numeric,text),
 lab_tracker.checkout_equipment(bigint,bigint,date),lab_tracker.return_equipment(bigint,bigint),
 lab_tracker.record_access(bigint,bigint,text,bigint),lab_tracker.close_access(bigint,bigint) TO lab_app;
GRANT EXECUTE ON FUNCTION lab_tracker.receive_chemical(bigint,bigint,numeric,text),
 lab_tracker.start_maintenance(bigint,bigint,text,numeric),
 lab_tracker.finish_maintenance(bigint,bigint,text,numeric) TO lab_technician;
GRANT SELECT ON ALL TABLES IN SCHEMA lab_tracker TO lab_manager;
GRANT INSERT,UPDATE,DELETE ON lab_tracker.person,lab_tracker.faculty,lab_tracker.student,
 lab_tracker.technician,lab_tracker.laboratory,lab_tracker.research_grant,lab_tracker.research_point,
 lab_tracker.certification,lab_tracker.has_certification,lab_tracker.allocated_equip,
 lab_tracker.allocated_chem,lab_tracker.grant_laboratory,lab_tracker.chemical_certification TO lab_manager;
GRANT INSERT ON lab_tracker.equipment,lab_tracker.chemical TO lab_manager;
GRANT UPDATE(lab_id,equipment_name,serial_number,purchase_date,purchase_cost) ON lab_tracker.equipment TO lab_manager;
GRANT UPDATE(lab_id,chemical_name,cas_number,unit,expiry_date,hazard_level,storage_condition) ON lab_tracker.chemical TO lab_manager;
GRANT USAGE,SELECT ON ALL SEQUENCES IN SCHEMA lab_tracker TO lab_manager;
GRANT SELECT ON lab_tracker.v_borrow_current,lab_tracker.v_chemical_movement TO lab_reader,lab_app;
REVOKE INSERT,UPDATE,DELETE ON lab_tracker.chemical_movement FROM lab_reader,lab_app,lab_technician,lab_manager;
REVOKE UPDATE(quantity_in_stock) ON lab_tracker.chemical FROM lab_reader,lab_app,lab_technician,lab_manager;
REVOKE INSERT,UPDATE,DELETE ON lab_tracker.access_log,lab_tracker.borrow_transaction,lab_tracker.maintenance_log FROM lab_reader,lab_app,lab_technician,lab_manager;
ALTER ROLE lab_reader SET search_path=lab_tracker,pg_catalog;
ALTER ROLE lab_app SET search_path=lab_tracker,pg_catalog;
ALTER ROLE lab_technician SET search_path=lab_tracker,pg_catalog;
ALTER ROLE lab_manager SET search_path=lab_tracker,pg_catalog;
ALTER ROLE lab_reader SET timezone='Asia/Ho_Chi_Minh';
ALTER ROLE lab_app SET timezone='Asia/Ho_Chi_Minh';
ALTER ROLE lab_technician SET timezone='Asia/Ho_Chi_Minh';
ALTER ROLE lab_manager SET timezone='Asia/Ho_Chi_Minh';
