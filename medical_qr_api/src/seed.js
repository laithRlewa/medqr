const bcrypt = require('bcryptjs');
const { query } = require('./db');

function id() {
  return `id-${Date.now()}-${Math.floor(Math.random() * 1000)}`;
}

async function seedIfEmpty() {
  const { rows } = await query('SELECT COUNT(*)::int AS c FROM users');
  if (rows[0].c > 0) return;

  const hash = (password) => bcrypt.hashSync(password, 10);
  const adminHash = hash('Admin123');
  const doctorHash = hash('Doctor123');
  const patientHash = hash('Patient123');

  await query(
    `INSERT INTO users (id, email, password_hash, full_name, role, phone) VALUES
      ('local-admin', 'admin@medical.iq', $1, 'مدير النظام', 'admin', '07700000000'),
      ('u-p1', 'patient@medical.iq', $2, 'علي جاسم محمد', 'patient', '07720001122'),
      ('u-p2', 'zainab.a@example.com', $2, 'زينب عبد الأمير', 'patient', '07830004455'),
      ('u-d1', 'doctor@medical.iq', $3, 'أحمد الكعبي', 'doctor', '07701234567'),
      ('u-d2', 'sara.pedia@medical.iq', $3, 'سارة الموسوي', 'doctor', '07812345678'),
      ('u-d3', 'hussein.ortho@medical.iq', $3, 'حسين الجبوري', 'doctor', '07505551212'),
      ('u-d6', 'nora.obgyn@medical.iq', $3, 'نورا قادر', 'doctor', '07507778899')`,
    [adminHash, patientHash, doctorHash],
  );

  await query(`INSERT INTO doctors
    (id, user_id, full_name, gender, date_of_birth, specialty, clinic_name, city, phone, email, license_number, status, subscription_status, subscription_start, subscription_end, subscription_duration, payment_amount, years_of_experience, qualifications, biography, working_hours, certificates, featured, rating, reviews, created_at)
    VALUES
    ('d1','u-d1','أحمد الكعبي','Male','1982-03-11','أمراض القلب','عيادة القلب التخصصية','بغداد','07701234567','doctor@medical.iq','IQ-DOC-10021','approved','active','2026-07-01','2026-12-26','1_month',75000,12,'بورد القلب التداخلي','استشاري أمراض القلب في مدينة الطب.','09:00-15:00',ARRAY['شهادة البورد العراقي.pdf'],TRUE,4.8,128,'2025-11-04'),
    ('d2','u-d2','سارة الموسوي','Female','1991-06-20','الأطفال','عيادة الأطفال الذكية','بغداد','07812345678','sara.pedia@medical.iq','IQ-DOC-10045','pending','inactive',NULL,NULL,NULL,0,7,'','طبيبة أطفال، بانتظار موافقة الإدارة.','',ARRAY[]::TEXT[],FALSE,4.4,19,'2026-08-12'),
    ('d3','u-d3','حسين الجبوري','Male','','العظام','مركز العظام والمفاصل','بغداد','07505551212','hussein.ortho@medical.iq','IQ-DOC-10088','approved','active','2026-02-20','2027-02-20','1_year',600000,15,'','استشاري جراحة العظام والمفاصل.','10:00-16:00',ARRAY[]::TEXT[],TRUE,4.6,86,'2025-09-18'),
    ('d6','u-d6','نورا قادر','Female','','النساء والولادة','عيادة الأمومة','بغداد','07507778899','nora.obgyn@medical.iq','IQ-DOC-10170','approved','active','2026-06-01','2026-12-01','6_months',320000,11,'','','',ARRAY[]::TEXT[],TRUE,4.9,64,'2026-03-02')`);

  await query(`INSERT INTO patients
    (id, user_id, full_name, patient_id, qr_code_data, phone, email, city, gender, blood_type, status, national_id, date_of_birth, allergies, chronic_diseases, current_medications, emergency_contact_name, emergency_contact_relationship, emergency_contact_phone, medical_history, vaccination_records, surgery_records, created_at)
    VALUES
    ('p1','u-p1','علي جاسم محمد','IQ-P-24081','IQ-P-24081','07720001122','patient@medical.iq','بغداد','Male','O+','active','19901234567','1990-04-12','البنسلين','ارتفاع ضغط الدم','أملوديبين 5 ملغ','فاطمة جاسم','زوجة','07721112233','ارتفاع ضغط منذ 2019','كوفيد-19 جرعتان','لا توجد','2026-02-11'),
    ('p2','u-p2','زينب عبد الأمير','IQ-P-24102','IQ-P-24102','07830004455','zainab.a@example.com','كربلاء','Female','A+','active','','1988-09-03','لا توجد','','','','','','','','','2026-04-07'),
    ('p3',NULL,'حسن كريم','IQ-P-24155','IQ-P-24155','07506667788','hasan.k@example.com','كركوك','Male','B-','active','','1979-01-22','','السكري النوع الثاني','','','','','','','','2026-05-21'),
    ('p5',NULL,'يوسف نوري','IQ-P-24220','IQ-P-24220','07815556677','yousef.n@example.com','البصرة','Male','O-','active','','2001-07-15','','','','','','','','','','2026-07-02'),
    ('p6',NULL,'هدى صالح','IQ-P-24248','IQ-P-24248','07512223344','huda.s@example.com','أربيل','Female','A-','active','','1993-02-28','','','','','','','','','','2026-07-28')`);

  await query(`INSERT INTO posts (id, doctor_id, doctor_name, content, category, likes_count, comments_count, created_at) VALUES
    ('po1','d1','أحمد الكعبي','نصائح للوقاية من أمراض القلب في فصل الصيف.','educational',24,2,'2026-08-10 14:00'),
    ('po2','d6','نورا قادر','أهمية الفحوصات الدورية أثناء الحمل.','news',18,1,'2026-08-14 11:00'),
    ('po3','d3','حسين الجبوري','تمارين منزلية بعد عمليات الركبة.','workshop',11,1,'2026-08-19 16:00')`);

  await query(`INSERT INTO post_comments (id, post_id, author_name, content, created_at) VALUES
    ('c1','po1','علي جاسم محمد','نصائح مفيدة، شكراً دكتور.','2026-08-10 16:00'),
    ('c2','po1','زينب عبد الأمير','هل ينطبق هذا على مرضى الضغط أيضاً؟','2026-08-11 09:00'),
    ('c3','po2','هدى صالح','موعد فحوصات الثلث الثاني مهم جداً.','2026-08-14 15:00'),
    ('c4','po3','حسن كريم','سأبدأ التمارين بعد مراجعة الطبيب.','2026-08-19 18:00')`);

  await query(`INSERT INTO visits (id, doctor_id, doctor_name, doctor_specialty, patient_id, patient_name, visit_date, visit_time, symptoms, diagnosis, treatment_plan, prescribed_medications, follow_up_notes, created_at) VALUES
    ('v1','d1','أحمد الكعبي','أمراض القلب','p1','علي جاسم محمد','2026-03-12','10:00','ألم صدر','ذبحة مستقرة','أدوية ومراجعة','أسبرين','مراجعة بعد شهر','2026-03-12 10:00'),
    ('v2','d1','أحمد الكعبي','أمراض القلب','p2','زينب عبد الأمير','2026-04-03','11:00','','خفقان','','','','2026-04-03 11:00'),
    ('v3','d3','حسين الجبوري','العظام','p3','حسن كريم','2026-05-19','10:00','','خشونة ركبة','','','','2026-05-19 10:00'),
    ('v6','d1','أحمد الكعبي','أمراض القلب','p5','يوسف نوري','2026-08-02','09:00','','','','','','2026-08-02 09:00'),
    ('v7','d3','حسين الجبوري','العظام','p1','علي جاسم محمد','2026-08-11','12:00','','التهاب أوتار','','','','2026-08-11 12:00'),
    ('v8','d1','أحمد الكعبي','أمراض القلب','p3','حسن كريم','2026-08-16','10:00','','','','','','2026-08-16 10:00')`);

  await query(`INSERT INTO medical_files (id, doctor_id, doctor_name, patient_id, file_type, file_name, description, created_at) VALUES
    ('f1','d1','أحمد الكعبي','p1','prescription','وصفة-1.pdf','وصفة أسبرين','2026-03-12'),
    ('f2','d1','أحمد الكعبي','p2','lab_result','تحليل-دم.pdf','','2026-04-03'),
    ('f3','d3','حسين الجبوري','p3','radiology','أشعة-ركبة.jpg','','2026-05-19'),
    ('f6','d3','حسين الجبوري','p1','xray','سينية-صدر.jpg','','2026-08-02')`);

  await query(`INSERT INTO access_sessions (id, patient_id, patient_user_id, doctor_id, patient_name, doctor_name, status, granted_at, expires_at, access_method) VALUES
    ('s1','p1','u-p1','d1','علي جاسم محمد','أحمد الكعبي','active',NOW(), NOW() + INTERVAL '24 hours','qr_scan'),
    ('s2','p5',NULL,'d1','يوسف نوري','أحمد الكعبي','active',NOW(), NOW() + INTERVAL '36 hours','search')`);

  await query(`INSERT INTO availability (id, doctor_id, doctor_name, day_of_week, start_time, end_time) VALUES
    ('av1','d1','أحمد الكعبي',0,'09:00','13:00'),
    ('av2','d1','أحمد الكعبي',1,'09:00','15:00'),
    ('av3','d1','أحمد الكعبي',2,'09:00','15:00'),
    ('av4','d1','أحمد الكعبي',3,'09:00','13:00'),
    ('av5','d3','حسين الجبوري',1,'10:00','16:00'),
    ('av6','d6','نورا قادر',0,'09:00','14:00')`);

  await query(`INSERT INTO appointments (id, doctor_id, doctor_user_id, doctor_name, doctor_specialty, patient_id, patient_user_id, patient_name, patient_phone, appointment_date, appointment_time, reason, status) VALUES
    ('ap1','d1','u-d1','أحمد الكعبي','أمراض القلب','p1','u-p1','علي جاسم محمد','07720001122','2026-08-24','10:00','مراجعة ضغط الدم','pending'),
    ('ap2','d1','u-d1','أحمد الكعبي','أمراض القلب','p2','u-p2','زينب عبد الأمير','07830004455','2026-08-25','11:30','خفقان','confirmed'),
    ('ap3','d3','u-d3','حسين الجبوري','العظام','p1','u-p1','علي جاسم محمد','07720001122','2026-08-18','12:00','ألم كتف','completed')`);

  await query(`INSERT INTO notifications (id, user_id, title, message, type, is_read, created_at) VALUES
    ('n1','u-p1','تم منح الوصول','تم منح د. أحمد الكعبي صلاحية الوصول إلى سجلاتك الطبية','access_granted',FALSE,'2026-08-22 08:00'),
    ('n2','u-d1','طلب موعد جديد','علي جاسم محمد طلب موعداً في 2026-08-24 الساعة 10:00.','system',FALSE,'2026-08-22 07:00'),
    ('n3','local-admin','طبيب جديد بانتظار المراجعة','سارة الموسوي قدّمت طلباً للانضمام كطبيبة أطفال.','system',FALSE,'2026-08-12 10:00')`);

  await query(`INSERT INTO audit_logs (id, user_id, user_name, user_role, action_type, description, target_type, target_id, ip_address, device_info, created_at) VALUES
    ('a1','local-admin','مدير النظام','admin','admin_action','تمت الموافقة على الطبيب: حسين الجبوري','Doctor','d3','178.104.255.180','API Server','2026-08-20 09:00'),
    ('a2','u-d1','د. أحمد الكعبي','doctor','qr_scan','مسح رمز مريض علي جاسم محمد','Patient','p1','178.104.255.180','API Server','2026-08-21 11:00'),
    ('a3','u-p1','علي جاسم محمد','patient','login','تسجيل دخول المريض',NULL,NULL,'178.104.255.180','API Server','2026-08-21 08:00')`);

  await query(`INSERT INTO activations (id, doctor_id, doctor_name, admin_name, payment_amount, duration, start_date, end_date, action, created_at) VALUES
    ('al1','d1','أحمد الكعبي','مدير النظام',75000,'1_month','2026-07-01','2026-08-26','activate','2026-07-01 12:00'),
    ('al2','d3','حسين الجبوري','مدير النظام',600000,'1_year','2026-02-20','2027-02-20','activate','2026-02-20 11:00')`);

  await query(`INSERT INTO payment_cards (doctor_id, bank_name, card_number, card_holder_name, card_expiry, card_cvv) VALUES
    ('d1','مصرف الرافدين','4532 **** **** 1098','AHMAD ALKAABI','09/28','314'),
    ('d3','مصرف الرشيد','5210 **** **** 7741','HUSSEIN ALJUBOURI','03/27','882')`);

  await query(`INSERT INTO settings (key, value) VALUES
    ('app_name','الرمز الطبي العراقي'),
    ('app_logo',''),
    ('theme_primary_color','#FF6D00'),
    ('theme_secondary_color','#FFF7F0'),
    ('app_font','Tajawal'),
    ('default_theme','light'),
    ('access_duration_hours','24'),
    ('diagnosis_edit_hours','24'),
    ('default_language','ar')`);

  console.log('تم إدخال البيانات التجريبية');
}

async function seedRegionsIfEmpty() {
  const { rows } = await query('SELECT COUNT(*)::int AS c FROM map_regions');
  if (rows[0].c > 0) return;

  await query(`INSERT INTO map_regions (id, name, city, center_lat, center_lng, zoom, sort_order) VALUES
    ('reg-karada','الكرادة','بغداد',33.3128,44.3615,13.5,1),
    ('reg-mansour','المنصور','بغداد',33.2985,44.3420,13.5,2),
    ('reg-adhamiya','الأعظمية','بغداد',33.3402,44.4001,13.5,3),
    ('reg-jadriya','الجادرية','بغداد',33.3255,44.3855,13.5,4),
    ('reg-kadhimiya','الكاظمية','بغداد',33.3790,44.3410,13.5,5),
    ('reg-dora','الدورة','بغداد',33.2620,44.3680,13.5,6)`);

  await query(`UPDATE doctors SET region_id='reg-karada', latitude=33.3128, longitude=44.3615 WHERE id='d1'`);
  await query(`UPDATE doctors SET region_id='reg-adhamiya', latitude=33.3402, longitude=44.4001 WHERE id='d2'`);
  await query(`UPDATE doctors SET region_id='reg-mansour', latitude=33.2985, longitude=44.3420 WHERE id='d3'`);
  await query(`UPDATE doctors SET region_id='reg-jadriya', latitude=33.3255, longitude=44.3855 WHERE id='d6'`);
}

module.exports = { seedIfEmpty, seedRegionsIfEmpty, id };
