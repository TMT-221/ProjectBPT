CREATE TABLE IF NOT EXISTS app_auth.demo_migration (
 version integer PRIMARY KEY
);

DO $$
BEGIN
 INSERT INTO app_auth.demo_migration(version) VALUES (1) ON CONFLICT DO NOTHING;
 IF NOT FOUND THEN RETURN; END IF;

 IF NOT EXISTS (SELECT 1 FROM app_auth.user_account WHERE person_id=7 AND email='student@lab.local')
    OR NOT EXISTS (SELECT 1 FROM app_auth.user_account WHERE person_id=10 AND email='technician@lab.local') THEN
  RETURN;
 END IF;

 INSERT INTO lab_tracker.has_certification(person_id,cert_id,issue_date,expiry_date)
 SELECT 7,cert_id,CURRENT_DATE-340,CURRENT_DATE+25
 FROM lab_tracker.certification WHERE cert_id=1
 ON CONFLICT (person_id,cert_id) DO NOTHING;

 INSERT INTO lab_tracker.chemical(lab_id,chemical_name,cas_number,unit,expiry_date,hazard_level,storage_condition)
 SELECT lab_id,'Mẫu đối chiếu kho','144-55-8','g',CURRENT_DATE+365,'Low','Lọ kín, nơi khô ráo'
 FROM lab_tracker.laboratory WHERE lab_id=1
  AND NOT EXISTS (SELECT 1 FROM lab_tracker.chemical WHERE chemical_name='Mẫu đối chiếu kho');

 PERFORM 1 FROM lab_tracker.equipment WHERE equipment_id=12 AND current_status='Available' FOR UPDATE;
 IF FOUND AND EXISTS (SELECT 1 FROM lab_tracker.person p JOIN lab_tracker.technician t ON t.technician_id=p.person_id
     WHERE p.person_id=10 AND p.status='Active') THEN
  PERFORM lab_tracker.start_maintenance(10,12,'Kiểm tra thiết bị trước khi bàn giao',0);
 END IF;
END $$;
