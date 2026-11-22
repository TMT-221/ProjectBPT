-- Additive integration migration. Run as the schema owner after auth.sql.
CREATE OR REPLACE FUNCTION lab_tracker.web_is_research_admin(p_actor bigint) RETURNS boolean
LANGUAGE sql STABLE SECURITY DEFINER SET search_path=pg_catalog,lab_tracker,pg_temp AS $$
 SELECT EXISTS (
  SELECT 1 FROM app_auth.account_role ar
  JOIN app_auth.user_account ua USING(person_id)
  JOIN lab_tracker.person p USING(person_id)
  WHERE ar.person_id=p_actor AND ar.role='research_admin' AND ua.enabled AND p.status='Active'
 );
$$;

CREATE OR REPLACE FUNCTION lab_tracker.web_writable_grant(p_actor bigint,p_grant bigint)
RETURNS lab_tracker.research_grant
LANGUAGE plpgsql SECURITY DEFINER SET search_path=pg_catalog,lab_tracker,pg_temp AS $$
DECLARE g lab_tracker.research_grant%ROWTYPE;
BEGIN
 SELECT * INTO g FROM lab_tracker.research_grant WHERE grant_id=p_grant FOR SHARE;
 IF NOT FOUND THEN RAISE EXCEPTION 'WEB_GRANT_MISSING'; END IF;
 IF NOT EXISTS (
  SELECT 1 FROM app_auth.user_account ua JOIN lab_tracker.person p USING(person_id)
  WHERE p.person_id=p_actor AND p.status='Active' AND ua.enabled
 ) OR (g.principal_investigator_id IS DISTINCT FROM p_actor AND NOT lab_tracker.web_is_research_admin(p_actor)) THEN
  RAISE EXCEPTION 'WEB_GRANT_FORBIDDEN';
 END IF;
 IF g.status<>'Active' THEN RAISE EXCEPTION 'WEB_GRANT_NOT_ACTIVE'; END IF;
 RETURN g;
END;
$$;

CREATE OR REPLACE FUNCTION lab_tracker.web_add_point(p_actor bigint,p_grant bigint,p_name text,p_description text,p_start date,p_end date,p_status text)
RETURNS bigint
LANGUAGE plpgsql SECURITY DEFINER SET search_path=pg_catalog,lab_tracker,pg_temp AS $$
DECLARE g lab_tracker.research_grant%ROWTYPE; v_id bigint;
BEGIN
 g:=lab_tracker.web_writable_grant(p_actor,p_grant);
 IF p_start IS NULL OR p_end IS NULL OR p_start<g.start_date OR p_end>g.end_date OR p_end<=p_start THEN
  RAISE EXCEPTION 'WEB_POINT_DATE_RANGE';
 END IF;
 INSERT INTO lab_tracker.research_point(grant_id,point_name,description,start_date,end_date,status)
 VALUES(p_grant,p_name,p_description,p_start,p_end,p_status) RETURNING rearch_point_id INTO v_id;
 RETURN v_id;
END;
$$;

CREATE OR REPLACE FUNCTION lab_tracker.web_allocate(p_actor bigint,p_point bigint,p_asset bigint,p_kind text)
RETURNS void
LANGUAGE plpgsql SECURITY DEFINER SET search_path=pg_catalog,lab_tracker,pg_temp AS $$
DECLARE v_grant bigint;
BEGIN
 SELECT grant_id INTO v_grant FROM lab_tracker.research_point WHERE rearch_point_id=p_point FOR SHARE;
 IF NOT FOUND THEN RAISE EXCEPTION 'WEB_POINT_MISSING'; END IF;
 PERFORM lab_tracker.web_writable_grant(p_actor,v_grant);
 IF p_kind='equipment' THEN
  IF NOT EXISTS(SELECT 1 FROM lab_tracker.equipment WHERE equipment_id=p_asset) THEN RAISE EXCEPTION 'WEB_ASSET_MISSING'; END IF;
  INSERT INTO lab_tracker.allocated_equip(rearch_point_id,equipment_id) VALUES(p_point,p_asset);
 ELSIF p_kind='chemical' THEN
  IF NOT EXISTS(SELECT 1 FROM lab_tracker.chemical WHERE chemical_id=p_asset) THEN RAISE EXCEPTION 'WEB_ASSET_MISSING'; END IF;
  INSERT INTO lab_tracker.allocated_chem(rearch_point_id,chemical_id) VALUES(p_point,p_asset);
 ELSE RAISE EXCEPTION 'WEB_ASSET_KIND';
 END IF;
END;
$$;

CREATE OR REPLACE FUNCTION lab_tracker.web_set_budget(p_actor bigint,p_grant bigint,p_remaining numeric)
RETURNS void
LANGUAGE plpgsql SECURITY DEFINER SET search_path=pg_catalog,lab_tracker,pg_temp AS $$
BEGIN
 IF NOT lab_tracker.web_is_research_admin(p_actor) THEN RAISE EXCEPTION 'WEB_ADMIN_ONLY'; END IF;
 IF p_remaining IS NULL OR p_remaining<0 OR p_remaining<>round(p_remaining,2) THEN RAISE EXCEPTION 'WEB_BUDGET_AMOUNT'; END IF;
 UPDATE lab_tracker.research_grant SET remaining_budget=p_remaining WHERE grant_id=p_grant;
 IF NOT FOUND THEN RAISE EXCEPTION 'WEB_GRANT_MISSING'; END IF;
END;
$$;

CREATE OR REPLACE FUNCTION lab_tracker.web_set_chemical_location(p_actor bigint,p_chemical bigint,p_lab bigint)
RETURNS void
LANGUAGE plpgsql SECURITY DEFINER SET search_path=pg_catalog,lab_tracker,pg_temp AS $$
BEGIN
 IF NOT lab_tracker.web_is_research_admin(p_actor) THEN RAISE EXCEPTION 'WEB_ADMIN_ONLY'; END IF;
 UPDATE lab_tracker.chemical SET lab_id=p_lab WHERE chemical_id=p_chemical;
 IF NOT FOUND THEN RAISE EXCEPTION 'WEB_ASSET_MISSING'; END IF;
END;
$$;

CREATE OR REPLACE FUNCTION lab_tracker.web_set_lab_safety(p_actor bigint,p_lab bigint,p_safety text)
RETURNS void
LANGUAGE plpgsql SECURITY DEFINER SET search_path=pg_catalog,lab_tracker,pg_temp AS $$
BEGIN
 IF NOT lab_tracker.web_is_research_admin(p_actor) THEN RAISE EXCEPTION 'WEB_ADMIN_ONLY'; END IF;
 UPDATE lab_tracker.laboratory SET safety_level=p_safety WHERE lab_id=p_lab;
 IF NOT FOUND THEN RAISE EXCEPTION 'WEB_LAB_MISSING'; END IF;
END;
$$;

REVOKE ALL ON FUNCTION lab_tracker.web_is_research_admin(bigint),
 lab_tracker.web_writable_grant(bigint,bigint),
 lab_tracker.web_add_point(bigint,bigint,text,text,date,date,text),
 lab_tracker.web_allocate(bigint,bigint,bigint,text),
 lab_tracker.web_set_budget(bigint,bigint,numeric),
 lab_tracker.web_set_chemical_location(bigint,bigint,bigint),
 lab_tracker.web_set_lab_safety(bigint,bigint,text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION
 lab_tracker.web_add_point(bigint,bigint,text,text,date,date,text),
 lab_tracker.web_allocate(bigint,bigint,bigint,text),
 lab_tracker.web_set_budget(bigint,bigint,numeric),
 lab_tracker.web_set_chemical_location(bigint,bigint,bigint),
 lab_tracker.web_set_lab_safety(bigint,bigint,text) TO lab_web_demo;
