CREATE SCHEMA app_auth;
CREATE TABLE app_auth.user_account (
 person_id bigint PRIMARY KEY REFERENCES lab_tracker.person ON DELETE RESTRICT,
 email varchar(254) UNIQUE NOT NULL CHECK (email=lower(email)),
 password_hash text NOT NULL,
 enabled boolean NOT NULL DEFAULT true
);
CREATE TABLE app_auth.account_role (
 person_id bigint NOT NULL REFERENCES app_auth.user_account ON DELETE CASCADE,
 role text NOT NULL CHECK (role IN ('member','research_admin','lab_operator','auditor')),
 PRIMARY KEY(person_id,role)
);
CREATE TABLE app_auth.session (
 token_hash text PRIMARY KEY,
 person_id bigint NOT NULL REFERENCES app_auth.user_account ON DELETE CASCADE,
 csrf_token text NOT NULL,
 last_seen timestamptz NOT NULL DEFAULT now(),
 expires_at timestamptz NOT NULL DEFAULT now()+interval '8 hours'
);
CREATE INDEX ix_web_session_expiry ON app_auth.session(expires_at);
CREATE VIEW app_auth.v_person_identity AS
 SELECT p.person_id,p.full_name,p.status,
   CASE WHEN s.student_id IS NOT NULL THEN 'student'
        WHEN f.faculty_id IS NOT NULL THEN 'faculty'
        WHEN t.technician_id IS NOT NULL THEN 'technician' END AS role
 FROM lab_tracker.person p
 LEFT JOIN lab_tracker.student s ON s.student_id=p.person_id
 LEFT JOIN lab_tracker.faculty f ON f.faculty_id=p.person_id
 LEFT JOIN lab_tracker.technician t ON t.technician_id=p.person_id;
REVOKE ALL ON SCHEMA app_auth FROM PUBLIC;
CREATE ROLE lab_web_auth NOLOGIN;
CREATE ROLE lab_web_demo NOLOGIN;
GRANT USAGE ON SCHEMA app_auth TO lab_web_auth;
GRANT SELECT ON app_auth.user_account,app_auth.account_role,app_auth.v_person_identity TO lab_web_auth;
GRANT SELECT,INSERT,UPDATE,DELETE ON app_auth.session TO lab_web_auth;
GRANT USAGE ON SCHEMA lab_tracker TO lab_web_demo;
GRANT SELECT ON lab_tracker.laboratory,lab_tracker.equipment,lab_tracker.research_grant,lab_tracker.research_point,
 lab_tracker.chemical,lab_tracker.certification,lab_tracker.has_certification,lab_tracker.allocated_equip,
 lab_tracker.allocated_chem,lab_tracker.access_log,lab_tracker.borrow_transaction,lab_tracker.maintenance_log,
 lab_tracker.grant_laboratory,lab_tracker.chemical_certification,lab_tracker.chemical_movement TO lab_web_demo;
GRANT SELECT (person_id,full_name,status) ON lab_tracker.person TO lab_web_demo;
GRANT SELECT (student_id,student_code) ON lab_tracker.student TO lab_web_demo;
GRANT EXECUTE ON FUNCTION lab_tracker.checkout_equipment(bigint,bigint,date),lab_tracker.return_equipment(bigint,bigint),
 lab_tracker.record_access(bigint,bigint,text,bigint),lab_tracker.close_access(bigint,bigint),
 lab_tracker.issue_chemical(bigint,bigint,bigint,numeric,text),lab_tracker.receive_chemical(bigint,bigint,numeric,text),
 lab_tracker.start_maintenance(bigint,bigint,text,numeric),lab_tracker.finish_maintenance(bigint,bigint,text,numeric)
 TO lab_web_demo;
