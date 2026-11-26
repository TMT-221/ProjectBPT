-- LabTrack normalized business schema and current access policy.
-- Run in an existing transaction as schema owner; do not reseed existing data.
SET LOCAL search_path = lab_tracker, pg_catalog;
SET LOCAL TIME ZONE 'Asia/Ho_Chi_Minh';
DO $$
BEGIN
 IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema='lab_tracker'
            AND table_name='has_certification' AND column_name='status') THEN
  DROP VIEW IF EXISTS v_certification_current;
  DROP VIEW IF EXISTS v_open_loans;
  DROP VIEW IF EXISTS v_chemical_stock_audit;
  DROP TRIGGER IF EXISTS tr_cert_status ON has_certification;
  DROP FUNCTION IF EXISTS sync_cert_status();
  DROP FUNCTION IF EXISTS refresh_temporal_status();
  ALTER TABLE has_certification DROP COLUMN status;
  ALTER TABLE borrow_transaction DROP COLUMN status;
  ALTER TABLE chemical_movement DROP COLUMN movement_type;
 END IF;
END $$;
CREATE OR REPLACE FUNCTION enforce_person_subtype() RETURNS trigger LANGUAGE plpgsql SET search_path = lab_tracker, pg_catalog, pg_temp AS $$
DECLARE v_id bigint; v_count integer;
BEGIN
 v_id := coalesce(to_jsonb(NEW),to_jsonb(OLD))->>(TG_TABLE_NAME||'_id');
 IF EXISTS (SELECT 1 FROM person WHERE person_id = v_id) THEN
  PERFORM 1 FROM person WHERE person_id = v_id FOR UPDATE;
  SELECT (EXISTS(SELECT 1 FROM faculty WHERE faculty_id=v_id))::integer
       + (EXISTS(SELECT 1 FROM student WHERE student_id=v_id))::integer
       + (EXISTS(SELECT 1 FROM technician WHERE technician_id=v_id))::integer INTO v_count;
  IF v_count <> 1 THEN RAISE EXCEPTION 'BR01: person % must have exactly one subtype',v_id USING ERRCODE='23514'; END IF;
 END IF;
 RETURN NULL;
END $$;

CREATE OR REPLACE FUNCTION immutable_person_key() RETURNS trigger LANGUAGE plpgsql SET search_path=lab_tracker,pg_catalog,pg_temp AS $$
BEGIN
 IF (to_jsonb(NEW)->>(TG_TABLE_NAME||'_id')) IS DISTINCT FROM (to_jsonb(OLD)->>(TG_TABLE_NAME||'_id')) THEN
  RAISE EXCEPTION 'BR01: person and subtype identifiers are immutable';
 END IF;
 RETURN NEW;
END $$;

CREATE OR REPLACE FUNCTION enforce_access() RETURNS trigger LANGUAGE plpgsql SET search_path=lab_tracker,pg_catalog,pg_temp AS $$
DECLARE v_level text; v_day date; v_name text; v_cert_id bigint; v_required text[];
BEGIN
 IF TG_OP='UPDATE' AND (NEW.person_id,NEW.lab_id,NEW.entry_time,NEW.purpose,NEW.approved_by) IS DISTINCT FROM (OLD.person_id,OLD.lab_id,OLD.entry_time,OLD.purpose,OLD.approved_by) THEN
  RAISE EXCEPTION 'BR21: access identity and approval are immutable';
 END IF;
 IF TG_OP='UPDATE' THEN RETURN NEW; END IF;
 PERFORM 1 FROM person WHERE person_id=NEW.person_id AND status='Active' FOR SHARE;
 IF NOT FOUND THEN RAISE EXCEPTION 'BR23: inactive or missing person'; END IF;
 SELECT safety_level INTO v_level FROM laboratory WHERE lab_id=NEW.lab_id FOR SHARE;
 IF NOT FOUND THEN RAISE EXCEPTION 'BR25: laboratory not found'; END IF;
 v_day := NEW.entry_time::date;
 IF NEW.approved_by IS NOT NULL THEN
  PERFORM 1 FROM person p WHERE p.person_id=NEW.approved_by AND p.status='Active'
   AND (EXISTS(SELECT 1 FROM faculty WHERE faculty_id=p.person_id) OR EXISTS(SELECT 1 FROM technician WHERE technician_id=p.person_id)) FOR SHARE;
  IF NOT FOUND OR NEW.approved_by=NEW.person_id THEN RAISE EXCEPTION 'BR04: approval must be from another active faculty or technician'; END IF;
 END IF;
 IF EXISTS(SELECT 1 FROM student WHERE student_id=NEW.person_id)
  AND (NEW.entry_time::time < time '07:00' OR NEW.entry_time::time >= time '17:00') AND NEW.approved_by IS NULL THEN
  RAISE EXCEPTION 'BR04: student out-of-hours approval required';
 END IF;
 -- BR27: purpose stores the declared reason for Faculty access outside [06:00,22:00).
 IF EXISTS (SELECT 1 FROM faculty WHERE faculty_id = NEW.person_id)
    AND (NEW.entry_time::time < TIME '06:00' OR NEW.entry_time::time >= TIME '22:00')
    AND btrim(COALESCE(NEW.purpose, '')) = '' THEN
  RAISE EXCEPTION 'BR27: an out-of-hours reason is required';
 END IF;
 -- BR05: each configured certificate type is mandatory and valid on the entry day.
 IF v_level = 'Restricted' THEN
  v_required := ARRAY['An toàn phòng thí nghiệm cơ bản'];
 ELSIF v_level = 'Hazardous' THEN
  v_required := ARRAY['An toàn phòng thí nghiệm cơ bản',
                      'Xử lý dung môi dễ cháy', 'Xử lý axit oxy hóa mạnh'];
 ELSE
  v_required := ARRAY[]::text[];
 END IF;
 FOREACH v_name IN ARRAY v_required LOOP
  SELECT cert_id INTO v_cert_id FROM certification
  WHERE cert_name = v_name FOR SHARE;
  IF NOT FOUND THEN
   RAISE EXCEPTION 'BR05: required certificate type is not configured: %', v_name;
  END IF;
  PERFORM 1 FROM has_certification
  WHERE person_id = NEW.person_id AND cert_id = v_cert_id
    AND issue_date <= v_day AND expiry_date >= v_day FOR SHARE;
  IF NOT FOUND THEN
   RAISE EXCEPTION 'BR05: required certificate is missing or expired: %', v_name;
  END IF;
 END LOOP;
 RETURN NEW;
END $$;

CREATE OR REPLACE FUNCTION enforce_borrow() RETURNS trigger LANGUAGE plpgsql SET search_path=lab_tracker,pg_catalog,pg_temp AS $$
DECLARE v_state text; v_lab bigint; v_level text; v_name text; v_cert_id bigint; v_required text[]; v_count integer;
BEGIN
 IF TG_OP='UPDATE' AND (NEW.person_id,NEW.equipment_id,NEW.borrow_date,NEW.expected_return_date) IS DISTINCT FROM (OLD.person_id,OLD.equipment_id,OLD.borrow_date,OLD.expected_return_date) THEN
  RAISE EXCEPTION 'BR21: loan identity and original due date are immutable';
 END IF;
 IF TG_OP='UPDATE' AND OLD.actual_return_date IS NOT NULL AND NEW.actual_return_date IS DISTINCT FROM OLD.actual_return_date THEN
  RAISE EXCEPTION 'BR21: completed loan is immutable';
 END IF;
 UPDATE person SET status=status WHERE person_id=NEW.person_id AND status='Active';
 IF NOT FOUND AND TG_OP='INSERT' THEN RAISE EXCEPTION 'BR14: active borrower required'; END IF;
 SELECT current_status, lab_id INTO v_state, v_lab FROM equipment WHERE equipment_id=NEW.equipment_id FOR UPDATE;
 IF NOT FOUND THEN RAISE EXCEPTION 'BR25: equipment not found'; END IF;
 IF TG_OP='INSERT' AND NEW.actual_return_date IS NULL THEN
  IF v_state<>'Available' THEN RAISE EXCEPTION 'BR13: equipment unavailable: %',v_state; END IF;
  SELECT safety_level INTO v_level FROM laboratory WHERE lab_id=v_lab FOR SHARE;
  IF NOT FOUND THEN RAISE EXCEPTION 'BR25: laboratory not found'; END IF;
  IF v_level = 'Restricted' THEN
   v_required := ARRAY['An toàn phòng thí nghiệm cơ bản'];
  ELSIF v_level = 'Hazardous' THEN
   v_required := ARRAY['An toàn phòng thí nghiệm cơ bản',
                       'Xử lý dung môi dễ cháy', 'Xử lý axit oxy hóa mạnh'];
  ELSE
   v_required := ARRAY[]::text[];
  END IF;
  FOREACH v_name IN ARRAY v_required LOOP
   SELECT cert_id INTO v_cert_id FROM certification
   WHERE cert_name = v_name FOR SHARE;
   IF NOT FOUND THEN
    RAISE EXCEPTION 'BR05: required certificate type is not configured: %', v_name;
   END IF;
   PERFORM 1 FROM has_certification
   WHERE person_id = NEW.person_id AND cert_id = v_cert_id
     AND issue_date <= NEW.borrow_date AND expiry_date >= NEW.borrow_date FOR SHARE;
   IF NOT FOUND THEN
    RAISE EXCEPTION 'BR05: required certificate is missing or expired: %', v_name;
   END IF;
  END LOOP;
  SELECT count(*) INTO v_count FROM borrow_transaction WHERE person_id=NEW.person_id AND actual_return_date IS NULL;
  IF v_count>=3 THEN RAISE EXCEPTION 'BR14: maximum three open loans'; END IF;
  UPDATE equipment SET current_status='In Use' WHERE equipment_id=NEW.equipment_id;
 END IF;
 IF TG_OP='UPDATE' AND OLD.actual_return_date IS NULL AND NEW.actual_return_date IS NOT NULL THEN
  UPDATE equipment SET current_status='Available' WHERE equipment_id=NEW.equipment_id AND current_status='In Use';
 END IF;
 RETURN NEW;
END $$;

CREATE OR REPLACE FUNCTION enforce_asset_and_lab() RETURNS trigger LANGUAGE plpgsql SET search_path=lab_tracker,pg_catalog,pg_temp AS $$
DECLARE v_level text;
BEGIN
 IF TG_TABLE_NAME='chemical' THEN
  SELECT safety_level INTO v_level FROM laboratory WHERE lab_id=NEW.lab_id FOR SHARE;
  IF NEW.hazard_level='Extreme' AND v_level IS DISTINCT FROM 'Hazardous' THEN RAISE EXCEPTION 'BR20: Extreme requires Hazardous lab'; END IF;
  IF TG_OP='INSERT' AND NEW.quantity_in_stock<>0 THEN RAISE EXCEPTION 'BR19: initial stock must use receive_chemical'; END IF;
  IF TG_OP='UPDATE' AND NEW.lab_id<>OLD.lab_id AND EXISTS(SELECT 1 FROM allocated_chem WHERE chemical_id=NEW.chemical_id) THEN
   RAISE EXCEPTION 'BR11: remove chemical allocations before lab relocation';
  END IF;
 ELSIF TG_TABLE_NAME='equipment' THEN
  IF TG_OP='UPDATE' AND NEW.lab_id<>OLD.lab_id AND EXISTS(SELECT 1 FROM allocated_equip WHERE equipment_id=NEW.equipment_id) THEN
   RAISE EXCEPTION 'BR11: remove equipment allocations before lab relocation';
  END IF;
  IF TG_OP='UPDATE' AND OLD.current_status='In Use' AND NEW.current_status IN ('Under Maintenance','Retired') AND EXISTS(SELECT 1 FROM borrow_transaction WHERE equipment_id=NEW.equipment_id AND actual_return_date IS NULL) THEN
   RAISE EXCEPTION 'BR13: cannot retire or maintain borrowed equipment';
  END IF;
 ELSIF NEW.safety_level<>'Hazardous' AND EXISTS(SELECT 1 FROM chemical WHERE lab_id=NEW.lab_id AND hazard_level='Extreme') THEN
  RAISE EXCEPTION 'BR20: lab contains Extreme chemical';
 END IF;
 RETURN NEW;
END $$;

CREATE OR REPLACE FUNCTION enforce_allocation() RETURNS trigger LANGUAGE plpgsql SET search_path=lab_tracker,pg_catalog,pg_temp AS $$
DECLARE v_grant bigint; v_lab bigint; v_status text;
BEGIN
 SELECT p.grant_id,g.status INTO v_grant,v_status FROM research_point p JOIN research_grant g USING(grant_id) WHERE p.rearch_point_id=NEW.rearch_point_id FOR SHARE OF g,p;
 IF NOT FOUND OR v_status<>'Active' THEN RAISE EXCEPTION 'BR12: allocation requires Active grant'; END IF;
 IF TG_TABLE_NAME='allocated_equip' THEN SELECT lab_id INTO v_lab FROM equipment WHERE equipment_id=NEW.equipment_id FOR SHARE;
 ELSE SELECT lab_id INTO v_lab FROM chemical WHERE chemical_id=NEW.chemical_id FOR SHARE; END IF;
 PERFORM 1 FROM grant_laboratory WHERE grant_id=v_grant AND lab_id=v_lab FOR SHARE;
 IF NOT FOUND THEN RAISE EXCEPTION 'BR11: asset lab is not assigned to grant'; END IF;
 RETURN NEW;
END $$;

CREATE OR REPLACE FUNCTION protect_grant_lab() RETURNS trigger LANGUAGE plpgsql SET search_path=lab_tracker,pg_catalog,pg_temp AS $$
BEGIN
 PERFORM 1 FROM research_grant WHERE grant_id=OLD.grant_id FOR UPDATE;
 IF EXISTS(SELECT 1 FROM allocated_equip a JOIN research_point p USING(rearch_point_id) JOIN equipment e USING(equipment_id) WHERE p.grant_id=OLD.grant_id AND e.lab_id=OLD.lab_id)
 OR EXISTS(SELECT 1 FROM allocated_chem a JOIN research_point p USING(rearch_point_id) JOIN chemical c USING(chemical_id) WHERE p.grant_id=OLD.grant_id AND c.lab_id=OLD.lab_id) THEN
  RAISE EXCEPTION 'BR11: remove allocations before grant lab membership';
 END IF;
 IF TG_OP='UPDATE' THEN RETURN NEW; ELSE RETURN OLD; END IF;
END $$;

CREATE OR REPLACE FUNCTION protect_point_grant() RETURNS trigger LANGUAGE plpgsql SET search_path=lab_tracker,pg_catalog,pg_temp AS $$
BEGIN
 IF NEW.grant_id<>OLD.grant_id AND (EXISTS(SELECT 1 FROM allocated_equip WHERE rearch_point_id=OLD.rearch_point_id) OR EXISTS(SELECT 1 FROM allocated_chem WHERE rearch_point_id=OLD.rearch_point_id)) THEN
  RAISE EXCEPTION 'BR11: allocated research point cannot change grant';
 END IF;
 RETURN NEW;
END $$;

CREATE OR REPLACE FUNCTION enforce_maintenance() RETURNS trigger LANGUAGE plpgsql SET search_path=lab_tracker,pg_catalog,pg_temp AS $$
DECLARE v_state text;
BEGIN
 IF TG_OP='UPDATE' AND (NEW.technician_id,NEW.equipment_id,NEW.start_date) IS DISTINCT FROM (OLD.technician_id,OLD.equipment_id,OLD.start_date) THEN RAISE EXCEPTION 'BR03: maintenance identity is immutable'; END IF;
 SELECT current_status INTO v_state FROM equipment WHERE equipment_id=NEW.equipment_id FOR UPDATE;
 IF NEW.end_date IS NULL THEN
  IF EXISTS(SELECT 1 FROM borrow_transaction WHERE equipment_id=NEW.equipment_id AND actual_return_date IS NULL) OR v_state='Retired' THEN RAISE EXCEPTION 'BR13: equipment cannot enter maintenance'; END IF;
  UPDATE equipment SET current_status='Under Maintenance' WHERE equipment_id=NEW.equipment_id;
 ELSIF TG_OP='UPDATE' AND OLD.end_date IS NULL THEN
  UPDATE equipment SET current_status='Available' WHERE equipment_id=NEW.equipment_id;
 END IF;
 RETURN NEW;
END $$;

CREATE OR REPLACE FUNCTION protect_history() RETURNS trigger LANGUAGE plpgsql SET search_path=lab_tracker,pg_catalog,pg_temp AS $$
BEGIN RAISE EXCEPTION 'BR19/21: history is append-only; use controlled workflow'; END $$;

CREATE OR REPLACE FUNCTION receive_chemical(p_chemical bigint,p_actor bigint,p_quantity numeric,p_reason text) RETURNS bigint
 LANGUAGE plpgsql SECURITY DEFINER SET search_path=lab_tracker,pg_catalog,pg_temp AS $$
DECLARE v_balance numeric; v_id bigint;
BEGIN
 IF p_quantity IS NULL OR p_quantity<=0 OR p_quantity<>round(p_quantity,3) THEN RAISE EXCEPTION 'BR19: positive quantity with at most 3 decimals required'; END IF;
 PERFORM 1 FROM person p JOIN technician t ON t.technician_id=p.person_id WHERE p.person_id=p_actor AND p.status='Active' FOR SHARE OF p;
 IF NOT FOUND THEN RAISE EXCEPTION 'BR19: active technician required'; END IF;
 UPDATE chemical SET quantity_in_stock=quantity_in_stock+p_quantity WHERE chemical_id=p_chemical RETURNING quantity_in_stock INTO v_balance;
 IF NOT FOUND THEN RAISE EXCEPTION 'BR25: chemical not found'; END IF;
 INSERT INTO chemical_movement(chemical_id,person_id,quantity,reason,balance_after)
 VALUES(p_chemical,p_actor,p_quantity,p_reason,v_balance) RETURNING movement_id INTO v_id;
 RETURN v_id;
END $$;

CREATE OR REPLACE FUNCTION issue_chemical(p_chemical bigint,p_actor bigint,p_point bigint,p_quantity numeric,p_reason text) RETURNS bigint
 LANGUAGE plpgsql SECURITY DEFINER SET search_path=lab_tracker,pg_catalog,pg_temp AS $$
DECLARE v_chemical chemical%ROWTYPE; v_id bigint; v_grant bigint; v_status text;
BEGIN
 IF p_quantity IS NULL OR p_quantity<=0 OR p_quantity<>round(p_quantity,3) THEN RAISE EXCEPTION 'BR19: positive quantity with at most 3 decimals required'; END IF;
 PERFORM 1 FROM person WHERE person_id=p_actor AND status='Active' FOR SHARE;
 IF NOT FOUND THEN RAISE EXCEPTION 'BR06: active person required'; END IF;
 SELECT p.grant_id,g.status INTO v_grant,v_status FROM research_point p JOIN research_grant g USING(grant_id) WHERE p.rearch_point_id=p_point FOR SHARE OF p,g;
 IF NOT FOUND OR v_status<>'Active' THEN RAISE EXCEPTION 'BR12: issue requires Active grant'; END IF;
 SELECT * INTO v_chemical FROM chemical WHERE chemical_id=p_chemical FOR UPDATE;
 IF NOT FOUND THEN RAISE EXCEPTION 'BR25: chemical not found'; END IF;
 IF v_chemical.expiry_date<CURRENT_DATE THEN RAISE EXCEPTION 'BR18: expired chemical cannot be issued'; END IF;
 PERFORM 1 FROM allocated_chem WHERE rearch_point_id=p_point AND chemical_id=p_chemical FOR SHARE;
 IF NOT FOUND THEN RAISE EXCEPTION 'BR11: chemical must be allocated to research point'; END IF;
 PERFORM 1 FROM grant_laboratory WHERE grant_id=v_grant AND lab_id=v_chemical.lab_id FOR SHARE;
 IF NOT FOUND THEN RAISE EXCEPTION 'BR11: chemical lab is not assigned to grant'; END IF;
 IF v_chemical.hazard_level IN ('High','Extreme') THEN
  PERFORM 1 FROM chemical_certification WHERE chemical_id=p_chemical FOR SHARE;
  IF NOT FOUND THEN RAISE EXCEPTION 'BR06: matching certificate policy missing'; END IF;
  PERFORM 1 FROM has_certification h JOIN chemical_certification r USING(cert_id) WHERE r.chemical_id=p_chemical AND h.person_id=p_actor FOR SHARE OF h;
  IF EXISTS(SELECT 1 FROM chemical_certification r WHERE r.chemical_id=p_chemical AND NOT EXISTS(
   SELECT 1 FROM has_certification h WHERE h.person_id=p_actor AND h.cert_id=r.cert_id AND h.issue_date<=CURRENT_DATE AND h.expiry_date>=CURRENT_DATE
  )) THEN RAISE EXCEPTION 'BR06: all matching valid certificates required'; END IF;
 END IF;
 UPDATE chemical SET quantity_in_stock=quantity_in_stock-p_quantity WHERE chemical_id=p_chemical AND quantity_in_stock>=p_quantity RETURNING quantity_in_stock INTO v_chemical.quantity_in_stock;
 IF NOT FOUND THEN RAISE EXCEPTION 'BR17: insufficient chemical stock'; END IF;
 INSERT INTO chemical_movement(chemical_id,person_id,rearch_point_id,quantity,reason,balance_after)
 VALUES(p_chemical,p_actor,p_point,p_quantity,p_reason,v_chemical.quantity_in_stock) RETURNING movement_id INTO v_id;
 RETURN v_id;
END $$;

CREATE OR REPLACE FUNCTION checkout_equipment(p_actor bigint,p_equipment bigint,p_due date) RETURNS bigint
 LANGUAGE plpgsql SECURITY DEFINER SET search_path=lab_tracker,pg_catalog,pg_temp AS $$
DECLARE v_id bigint;
BEGIN
 INSERT INTO borrow_transaction(person_id,equipment_id,borrow_date,expected_return_date)
 VALUES(p_actor,p_equipment,CURRENT_DATE,p_due) RETURNING borrow_id INTO v_id;
 RETURN v_id;
END $$;

CREATE OR REPLACE FUNCTION return_equipment(p_actor bigint,p_borrow bigint) RETURNS void
 LANGUAGE plpgsql SECURITY DEFINER SET search_path=lab_tracker,pg_catalog,pg_temp AS $$
BEGIN
 UPDATE borrow_transaction SET actual_return_date=CURRENT_DATE WHERE borrow_id=p_borrow AND person_id=p_actor AND actual_return_date IS NULL;
 IF NOT FOUND THEN RAISE EXCEPTION 'Loan not found or already returned'; END IF;
END $$;

CREATE OR REPLACE FUNCTION record_access(p_actor bigint,p_lab bigint,p_purpose text,p_approver bigint DEFAULT NULL) RETURNS bigint
 LANGUAGE plpgsql SECURITY DEFINER SET search_path=lab_tracker,pg_catalog,pg_temp AS $$
DECLARE v_id bigint;
BEGIN
 INSERT INTO access_log(person_id,lab_id,entry_time,purpose,approved_by)
 VALUES(p_actor,p_lab,clock_timestamp() AT TIME ZONE 'Asia/Ho_Chi_Minh',p_purpose,p_approver) RETURNING log_id INTO v_id;
 RETURN v_id;
END $$;

CREATE OR REPLACE FUNCTION close_access(p_actor bigint,p_log bigint) RETURNS void
 LANGUAGE plpgsql SECURITY DEFINER SET search_path=lab_tracker,pg_catalog,pg_temp AS $$
BEGIN
 UPDATE access_log SET exit_time=clock_timestamp() AT TIME ZONE 'Asia/Ho_Chi_Minh' WHERE log_id=p_log AND person_id=p_actor AND exit_time IS NULL;
 IF NOT FOUND THEN RAISE EXCEPTION 'Open access log not found'; END IF;
END $$;

CREATE OR REPLACE FUNCTION start_maintenance(p_actor bigint,p_equipment bigint,p_description text,p_cost numeric) RETURNS bigint
 LANGUAGE plpgsql SECURITY DEFINER SET search_path=lab_tracker,pg_catalog,pg_temp AS $$
DECLARE v_id bigint;
BEGIN
 PERFORM 1 FROM person p JOIN technician t ON t.technician_id=p.person_id WHERE p.person_id=p_actor AND p.status='Active' FOR SHARE OF p;
 IF NOT FOUND THEN RAISE EXCEPTION 'BR03: active technician required'; END IF;
 INSERT INTO maintenance_log(technician_id,equipment_id,start_date,description,cost) VALUES(p_actor,p_equipment,CURRENT_DATE,p_description,p_cost) RETURNING maintenance_id INTO v_id;
 RETURN v_id;
END $$;

CREATE OR REPLACE FUNCTION finish_maintenance(p_actor bigint,p_maintenance bigint,p_description text,p_cost numeric) RETURNS void
 LANGUAGE plpgsql SECURITY DEFINER SET search_path=lab_tracker,pg_catalog,pg_temp AS $$
BEGIN
 PERFORM 1 FROM person p JOIN technician t ON t.technician_id=p.person_id WHERE p.person_id=p_actor AND p.status='Active' FOR SHARE OF p;
 IF NOT FOUND THEN RAISE EXCEPTION 'BR03: active technician required'; END IF;
 UPDATE maintenance_log SET end_date=CURRENT_DATE,description=p_description,cost=p_cost WHERE maintenance_id=p_maintenance AND technician_id=p_actor AND end_date IS NULL;
 IF NOT FOUND THEN RAISE EXCEPTION 'Open maintenance not found for technician'; END IF;
END $$;

CREATE OR REPLACE VIEW v_person_role AS
 SELECT p.person_id,p.full_name,p.email,p.status,
 CASE WHEN f.faculty_id IS NOT NULL THEN 'Faculty' WHEN s.student_id IS NOT NULL THEN 'Student' ELSE 'Technician' END AS person_role
 FROM person p LEFT JOIN faculty f ON f.faculty_id=p.person_id LEFT JOIN student s ON s.student_id=p.person_id;

CREATE OR REPLACE VIEW v_grant_asset_summary AS
 SELECT g.grant_id,g.grant_title,g.status,g.total_budget,g.remaining_budget,
 (SELECT count(DISTINCT a.equipment_id) FROM research_point p JOIN allocated_equip a USING(rearch_point_id) WHERE p.grant_id=g.grant_id) AS equipment_count,
 (SELECT count(DISTINCT a.chemical_id) FROM research_point p JOIN allocated_chem a USING(rearch_point_id) WHERE p.grant_id=g.grant_id) AS chemical_count
 FROM research_grant g;

CREATE OR REPLACE VIEW v_certification_current AS
SELECT h.person_id, p.full_name, h.cert_id, c.cert_name, h.issue_date, h.expiry_date,
       CASE WHEN h.expiry_date < CURRENT_DATE THEN 'Expired' ELSE 'Valid' END AS effective_status,
       CASE WHEN h.expiry_date < CURRENT_DATE THEN 'Expired' ELSE 'Valid' END AS status
FROM has_certification h
JOIN person p USING (person_id)
JOIN certification c USING (cert_id);

CREATE OR REPLACE VIEW v_borrow_current AS
SELECT b.*,
       CASE WHEN b.actual_return_date > b.expected_return_date
                   OR (b.actual_return_date IS NULL AND b.expected_return_date < CURRENT_DATE)
            THEN 'Overdue'
            WHEN b.actual_return_date IS NULL THEN 'Borrowed'
            ELSE 'Returned' END AS status,
       CASE WHEN b.actual_return_date > b.expected_return_date
                   OR (b.actual_return_date IS NULL AND b.expected_return_date < CURRENT_DATE)
            THEN 'Overdue'
            WHEN b.actual_return_date IS NULL THEN 'Borrowed'
            ELSE 'Returned' END AS effective_status
FROM borrow_transaction b;

CREATE OR REPLACE VIEW v_chemical_movement AS
SELECT m.*, CASE WHEN m.rearch_point_id IS NULL THEN 'Receipt' ELSE 'Issue' END AS movement_type
FROM chemical_movement m;

CREATE OR REPLACE VIEW v_open_loans AS
SELECT b.borrow_id, b.person_id, p.full_name, b.equipment_id, e.equipment_name,
       e.lab_id, b.borrow_date, b.expected_return_date,
       GREATEST(CURRENT_DATE - b.expected_return_date, 0) AS days_overdue,
       b.status AS effective_status
FROM v_borrow_current b
JOIN person p USING (person_id)
JOIN equipment e USING (equipment_id)
WHERE b.actual_return_date IS NULL;

CREATE OR REPLACE VIEW v_chemical_stock_audit AS
SELECT c.chemical_id, c.chemical_name, c.quantity_in_stock,
       COALESCE(SUM(CASE WHEN m.rearch_point_id IS NULL THEN m.quantity ELSE -m.quantity END), 0)::numeric(14,3) AS ledger_balance,
       c.quantity_in_stock = COALESCE(SUM(CASE WHEN m.rearch_point_id IS NULL THEN m.quantity ELSE -m.quantity END), 0) AS reconciled
FROM chemical c
LEFT JOIN chemical_movement m USING (chemical_id)
GROUP BY c.chemical_id;

REVOKE EXECUTE ON ALL FUNCTIONS IN SCHEMA lab_tracker FROM PUBLIC;
DO $$
DECLARE r text;
BEGIN
 FOREACH r IN ARRAY ARRAY['lab_reader','lab_app','lab_manager'] LOOP
  IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname=r) THEN
   EXECUTE format('GRANT SELECT ON lab_tracker.v_person_role, lab_tracker.v_grant_asset_summary, lab_tracker.v_certification_current, lab_tracker.v_borrow_current, lab_tracker.v_chemical_movement, lab_tracker.v_open_loans, lab_tracker.v_chemical_stock_audit TO %I',r);
  END IF;
 END LOOP;
END $$;
