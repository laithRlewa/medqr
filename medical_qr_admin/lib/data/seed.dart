import '../models/models.dart';

DateTime d(int y, int m, int day, [int h = 10, int min = 0]) => DateTime(y, m, day, h, min);

List<Doctor> seedDoctors() => [
      Doctor(
        id: 'd1', userId: 'u-d1', fullName: 'أحمد الكعبي', gender: 'Male', dateOfBirth: '1982-03-11',
        specialty: 'أمراض القلب', clinicName: 'عيادة القلب التخصصية', city: 'بغداد',
        phone: '07701234567', email: 'ahmad.cardio@medical.iq', licenseNumber: 'IQ-DOC-10021',
        status: 'approved', subscriptionStatus: 'active', subscriptionStart: d(2026, 7, 1),
        subscriptionEnd: d(2026, 8, 26), subscriptionDuration: '1_month', paymentAmount: 75000,
        yearsOfExperience: 12, qualifications: 'بورد القلب التداخلي',
        biography: 'استشاري أمراض القلب في مدينة الطب.', workingHours: '9 صباحاً - 3 مساءً',
        certificates: ['شهادة البورد العراقي.pdf'], createdDate: d(2025, 11, 4),
      ),
      Doctor(
        id: 'd2', userId: 'u-d2', fullName: 'سارة الموسوي', gender: 'Female', dateOfBirth: '1991-06-20',
        specialty: 'الأطفال', clinicName: 'عيادة الأطفال الذكية', city: 'النجف',
        phone: '07812345678', email: 'sara.pedia@medical.iq', licenseNumber: 'IQ-DOC-10045',
        status: 'pending', subscriptionStatus: 'inactive', yearsOfExperience: 7, createdDate: d(2026, 8, 12),
      ),
      Doctor(
        id: 'd3', userId: 'u-d3', fullName: 'حسين الجبوري', gender: 'Male',
        specialty: 'العظام', clinicName: 'مركز العظام والمفاصل', city: 'الموصل',
        phone: '07505551212', email: 'hussein.ortho@medical.iq', licenseNumber: 'IQ-DOC-10088',
        status: 'approved', subscriptionStatus: 'active', subscriptionStart: d(2026, 2, 20),
        subscriptionEnd: d(2027, 2, 20), subscriptionDuration: '1_year', paymentAmount: 600000,
        yearsOfExperience: 15, workingHours: '10 صباحاً - 4 مساءً', createdDate: d(2025, 9, 18),
      ),
      Doctor(
        id: 'd4', userId: 'u-d4', fullName: 'ليلى حسن', gender: 'Female',
        specialty: 'الجلدية', clinicName: 'عيادة الجلد والتجميل', city: 'أربيل',
        phone: '07501112233', email: 'layla.derma@medical.iq', licenseNumber: 'IQ-DOC-10102',
        status: 'suspended', subscriptionStatus: 'inactive', yearsOfExperience: 9, createdDate: d(2026, 1, 9),
      ),
      Doctor(
        id: 'd5', userId: 'u-d5', fullName: 'محمد العبيدي', gender: 'Male',
        specialty: 'طب عام', clinicName: 'العيادة العامة', city: 'البصرة',
        phone: '07719998877', email: 'mohammed.gp@medical.iq', licenseNumber: 'IQ-DOC-10133',
        status: 'pending', subscriptionStatus: 'inactive', yearsOfExperience: 4, createdDate: d(2026, 8, 18),
      ),
      Doctor(
        id: 'd6', userId: 'u-d6', fullName: 'نورا قادر', gender: 'Female',
        specialty: 'النساء والولادة', clinicName: 'عيادة الأمومة', city: 'السليمانية',
        phone: '07507778899', email: 'nora.obgyn@medical.iq', licenseNumber: 'IQ-DOC-10170',
        status: 'approved', subscriptionStatus: 'active', subscriptionStart: d(2026, 6, 1),
        subscriptionEnd: d(2026, 12, 1), subscriptionDuration: '6_months', paymentAmount: 320000,
        yearsOfExperience: 11, createdDate: d(2026, 3, 2),
      ),
    ];

List<Patient> seedPatients() => [
      Patient(
        id: 'p1', userId: 'u-p1', fullName: 'علي جاسم محمد', patientId: 'IQ-P-24081',
        phone: '07720001122', email: 'ali.j@example.com', city: 'بغداد', gender: 'Male',
        bloodType: 'O+', status: 'active', nationalId: '19901234567', dateOfBirth: '1990-04-12',
        allergies: 'البنسلين', chronicDiseases: 'ارتفاع ضغط الدم', currentMedications: 'أملوديبين 5 ملغ',
        emergencyContactName: 'فاطمة جاسم', emergencyContactRelationship: 'زوجة',
        emergencyContactPhone: '07721112233', medicalHistory: 'ارتفاع ضغط منذ 2019',
        vaccinationRecords: 'كوفيد-19 جرعتان', surgeryRecords: 'لا توجد', createdDate: d(2026, 2, 11),
      ),
      Patient(
        id: 'p2', userId: 'u-p2', fullName: 'زينب عبد الأمير', patientId: 'IQ-P-24102',
        phone: '07830004455', email: 'zainab.a@example.com', city: 'كربلاء', gender: 'Female',
        bloodType: 'A+', status: 'active', dateOfBirth: '1988-09-03', allergies: 'لا توجد', createdDate: d(2026, 4, 7),
      ),
      Patient(
        id: 'p3', userId: 'u-p3', fullName: 'حسن كريم', patientId: 'IQ-P-24155',
        phone: '07506667788', email: 'hasan.k@example.com', city: 'كركوك', gender: 'Male',
        bloodType: 'B-', status: 'active', dateOfBirth: '1979-01-22', chronicDiseases: 'السكري النوع الثاني',
        createdDate: d(2026, 5, 21),
      ),
      Patient(
        id: 'p4', userId: 'u-p4', fullName: 'مريم أحمد', patientId: 'IQ-P-24190',
        phone: '07704445566', email: 'maryam.a@example.com', city: 'بغداد', gender: 'Female',
        bloodType: 'AB+', status: 'suspended', dateOfBirth: '1995-11-08', createdDate: d(2026, 6, 14),
      ),
      Patient(
        id: 'p5', userId: 'u-p5', fullName: 'يوسف نوري', patientId: 'IQ-P-24220',
        phone: '07815556677', email: 'yousef.n@example.com', city: 'البصرة', gender: 'Male',
        bloodType: 'O-', status: 'active', dateOfBirth: '2001-07-15', createdDate: d(2026, 7, 2),
      ),
      Patient(
        id: 'p6', userId: 'u-p6', fullName: 'هدى صالح', patientId: 'IQ-P-24248',
        phone: '07512223344', email: 'huda.s@example.com', city: 'أربيل', gender: 'Female',
        bloodType: 'A-', status: 'active', dateOfBirth: '1993-02-28', createdDate: d(2026, 7, 28),
      ),
    ];

List<Post> seedPosts() => [
      Post(id: 'po1', doctorName: 'أحمد الكعبي', content: 'نصائح للوقاية من أمراض القلب في فصل الصيف.', category: 'educational', likesCount: 24, commentsCount: 6, createdDate: d(2026, 8, 10, 14)),
      Post(id: 'po2', doctorName: 'نورا قادر', content: 'أهمية الفحوصات الدورية أثناء الحمل.', category: 'news', likesCount: 18, commentsCount: 3, createdDate: d(2026, 8, 14, 11)),
      Post(id: 'po3', doctorName: 'حسين الجبوري', content: 'تمارين منزلية بعد عمليات الركبة.', category: 'workshop', likesCount: 11, commentsCount: 2, createdDate: d(2026, 8, 19, 16)),
    ];

List<AuditLog> seedAudit() {
  final now = d(2026, 8, 22, 14);
  final logs = <AuditLog>[
    AuditLog(id: 'a1', userId: 'local-admin', userName: 'مدير النظام', userRole: 'admin', actionType: 'admin_action', description: 'تمت الموافقة على الطبيب: حسين الجبوري', targetType: 'Doctor', targetId: 'd3', ipAddress: '37.239.12.10', deviceInfo: 'Windows Desktop', createdDate: d(2026, 8, 20, 9)),
    AuditLog(id: 'a2', userId: 'u-d1', userName: 'د. أحمد الكعبي', userRole: 'doctor', actionType: 'qr_scan', description: 'مسح رمز مريض علي جاسم محمد', targetType: 'Patient', targetId: 'p1', ipAddress: '37.238.8.44', createdDate: d(2026, 8, 21, 11)),
    AuditLog(id: 'a3', userId: 'u-p1', userName: 'علي جاسم محمد', userRole: 'patient', actionType: 'login', description: 'تسجيل دخول المريض', ipAddress: '37.236.1.9', createdDate: d(2026, 8, 21, 8)),
    AuditLog(id: 'a4', userId: 'u-d6', userName: 'د. نورا قادر', userRole: 'doctor', actionType: 'visit_create', description: 'إنشاء زيارة للمريضة زينب عبد الأمير', targetType: 'Visit', createdDate: d(2026, 8, 18, 13)),
    AuditLog(id: 'a5', userId: 'u-d1', userName: 'د. أحمد الكعبي', userRole: 'doctor', actionType: 'diagnosis_create', description: 'إضافة تشخيص جديد', createdDate: d(2026, 8, 15, 15)),
    AuditLog(id: 'a6', userId: 'local-admin', userName: 'مدير النظام', userRole: 'admin', actionType: 'admin_action', description: 'تم تعليق الطبيب: ليلى حسن', targetType: 'Doctor', targetId: 'd4', ipAddress: '37.239.12.10', createdDate: d(2026, 8, 8, 12)),
    AuditLog(id: 'a7', userId: 'u-d3', userName: 'د. حسين الجبوري', userRole: 'doctor', actionType: 'file_upload', description: 'رفع ملف أشعة', createdDate: d(2026, 8, 11, 10)),
    AuditLog(id: 'a8', userId: 'u-p2', userName: 'زينب عبد الأمير', userRole: 'patient', actionType: 'profile_update', description: 'تحديث الملف الشخصي', createdDate: d(2026, 8, 9, 19)),
    AuditLog(id: 'a9', userId: 'u-d1', userName: 'د. أحمد الكعبي', userRole: 'doctor', actionType: 'post_create', description: 'إنشاء منشور توعوي', createdDate: d(2026, 8, 10, 14)),
    AuditLog(id: 'a10', userId: 'u-d3', userName: 'د. حسين الجبوري', userRole: 'doctor', actionType: 'access_create', description: 'منح وصول بعد مسح QR', createdDate: d(2026, 8, 11, 9)),
  ];
  for (var day = 0; day < 28; day++) {
    final date = now.subtract(Duration(days: day, hours: day % 5));
    logs.add(AuditLog(
      id: 'login-p-$day', userId: 'u-p${(day % 6) + 1}', userName: 'مريض',
      userRole: 'patient', actionType: 'login', description: 'تسجيل دخول المريض',
      createdDate: date,
    ));
    if (day % 2 == 0) {
      logs.add(AuditLog(
        id: 'login-d-$day', userId: 'u-d1', userName: 'د. أحمد الكعبي',
        userRole: 'doctor', actionType: 'login', description: 'تسجيل دخول الطبيب',
        createdDate: date.add(const Duration(hours: 1)),
      ));
    }
  }
  logs.sort((a, b) => b.createdDate.compareTo(a.createdDate));
  return logs;
}

List<AppNotification> seedNotifications() => [
      AppNotification(id: 'n1', userId: 'local-admin', title: 'طبيب جديد بانتظار المراجعة', message: 'سارة الموسوي قدّمت طلباً للانضمام كطبيبة أطفال.', type: 'system', createdDate: d(2026, 8, 12, 10)),
      AppNotification(id: 'n2', userId: 'local-admin', title: 'اشتراك ينتهي قريباً', message: 'اشتراك د. أحمد الكعبي ينتهي خلال أيام.', type: 'access_granted', createdDate: d(2026, 8, 20, 9)),
      AppNotification(id: 'n3', userId: 'local-admin', title: 'منشور جديد', message: 'تم نشر محتوى توعوي من د. حسين الجبوري.', type: 'post', read: true, createdDate: d(2026, 8, 19, 16)),
    ];

List<ActivationLog> seedActivations() => [
      ActivationLog(id: 'al1', doctorId: 'd1', doctorName: 'أحمد الكعبي', adminName: 'مدير النظام', paymentAmount: 75000, duration: '1_month', startDate: d(2026, 7, 1), endDate: d(2026, 8, 26), action: 'activate', createdDate: d(2026, 7, 1, 12)),
      ActivationLog(id: 'al2', doctorId: 'd3', doctorName: 'حسين الجبوري', adminName: 'مدير النظام', paymentAmount: 600000, duration: '1_year', startDate: d(2026, 2, 20), endDate: d(2027, 2, 20), action: 'activate', createdDate: d(2026, 2, 20, 11)),
    ];

List<PaymentCard> seedCards() => [
      PaymentCard(doctorId: 'd1', bankName: 'مصرف الرافدين', cardNumber: '4532 **** **** 1098', cardHolderName: 'AHMAD ALKAABI', cardExpiry: '09/28', cardCvv: '314'),
      PaymentCard(doctorId: 'd3', bankName: 'مصرف الرشيد', cardNumber: '5210 **** **** 7741', cardHolderName: 'HUSSEIN ALJUBOURI', cardExpiry: '03/27', cardCvv: '882'),
    ];

List<Visit> seedVisits() => [
      Visit(id: 'v1', doctorId: 'd1', doctorName: 'أحمد الكعبي', doctorSpecialty: 'أمراض القلب', patientId: 'p1', patientName: 'علي جاسم محمد', visitDate: d(2026, 3, 12), symptoms: 'ألم صدر', diagnosis: 'ذبحة مستقرة', treatmentPlan: 'أدوية ومراجعة', prescribedMedications: 'أسبرين'),
      Visit(id: 'v2', doctorId: 'd1', doctorName: 'أحمد الكعبي', doctorSpecialty: 'أمراض القلب', patientId: 'p2', patientName: 'زينب عبد الأمير', visitDate: d(2026, 4, 3), diagnosis: 'خفقان'),
      Visit(id: 'v3', doctorId: 'd3', doctorName: 'حسين الجبوري', doctorSpecialty: 'العظام', patientId: 'p3', patientName: 'حسن كريم', visitDate: d(2026, 5, 19), diagnosis: 'خشونة ركبة'),
      Visit(id: 'v4', doctorId: 'd6', doctorName: 'نورا قادر', doctorSpecialty: 'النساء والولادة', patientId: 'p2', patientName: 'زينب عبد الأمير', visitDate: d(2026, 6, 8)),
      Visit(id: 'v5', doctorId: 'd6', doctorName: 'نورا قادر', doctorSpecialty: 'النساء والولادة', patientId: 'p6', patientName: 'هدى صالح', visitDate: d(2026, 7, 14)),
      Visit(id: 'v6', doctorId: 'd1', doctorName: 'أحمد الكعبي', doctorSpecialty: 'أمراض القلب', patientId: 'p5', patientName: 'يوسف نوري', visitDate: d(2026, 8, 2)),
      Visit(id: 'v7', doctorId: 'd3', doctorName: 'حسين الجبوري', doctorSpecialty: 'العظام', patientId: 'p1', patientName: 'علي جاسم محمد', visitDate: d(2026, 8, 11), diagnosis: 'التهاب أوتار'),
      Visit(id: 'v8', doctorId: 'd1', doctorName: 'أحمد الكعبي', doctorSpecialty: 'أمراض القلب', patientId: 'p3', patientName: 'حسن كريم', visitDate: d(2026, 8, 16)),
      Visit(id: 'v9', doctorId: 'd6', doctorName: 'نورا قادر', doctorSpecialty: 'النساء والولادة', patientId: 'p4', patientName: 'مريم أحمد', visitDate: d(2026, 6, 22)),
      Visit(id: 'v10', doctorId: 'd3', doctorName: 'حسين الجبوري', doctorSpecialty: 'العظام', patientId: 'p5', patientName: 'يوسف نوري', visitDate: d(2026, 7, 30)),
    ];

List<MedicalFile> seedFiles() => [
      MedicalFile(id: 'f1', fileType: 'prescription', doctorId: 'd1', doctorName: 'أحمد الكعبي', patientId: 'p1', fileName: 'وصفة-1.pdf', createdDate: d(2026, 3, 12)),
      MedicalFile(id: 'f2', fileType: 'lab_result', doctorId: 'd1', doctorName: 'أحمد الكعبي', patientId: 'p2', fileName: 'تحليل-دم.pdf', createdDate: d(2026, 4, 3)),
      MedicalFile(id: 'f3', fileType: 'radiology', doctorId: 'd3', doctorName: 'حسين الجبوري', patientId: 'p3', fileName: 'أشعة-ركبة.jpg', createdDate: d(2026, 5, 19)),
      MedicalFile(id: 'f4', fileType: 'blood_test', doctorId: 'd6', doctorName: 'نورا قادر', patientId: 'p2', fileName: 'سكر-تراكمي.pdf', createdDate: d(2026, 6, 8)),
      MedicalFile(id: 'f5', fileType: 'document', doctorId: 'd6', doctorName: 'نورا قادر', patientId: 'p6', fileName: 'تقرير-حمل.pdf', createdDate: d(2026, 7, 14)),
      MedicalFile(id: 'f6', fileType: 'xray', doctorId: 'd3', doctorName: 'حسين الجبوري', patientId: 'p1', fileName: 'سينية-صدر.jpg', createdDate: d(2026, 8, 2)),
      MedicalFile(id: 'f7', fileType: 'prescription', doctorId: 'd1', doctorName: 'أحمد الكعبي', patientId: 'p5', createdDate: d(2026, 8, 16)),
    ];

List<AccessSession> seedSessions() => [
      AccessSession(id: 's1', patientName: 'علي جاسم محمد', doctorName: 'أحمد الكعبي', status: 'active', expiresAt: d(2026, 8, 23, 18)),
      AccessSession(id: 's2', patientName: 'يوسف نوري', doctorName: 'حسين الجبوري', status: 'active', expiresAt: d(2026, 8, 24, 9)),
      AccessSession(id: 's3', patientName: 'زينب عبد الأمير', doctorName: 'نورا قادر', status: 'expired', expiresAt: d(2026, 8, 10, 12)),
    ];

List<PlatformUser> seedUsers() => [
      PlatformUser(id: 'local-admin', email: 'admin@medical.iq', role: 'admin', createdDate: d(2025, 8, 1)),
      PlatformUser(id: 'u-d1', email: 'ahmad.cardio@medical.iq', role: 'user', createdDate: d(2025, 11, 4)),
      PlatformUser(id: 'u-d2', email: 'sara.pedia@medical.iq', role: 'user', createdDate: d(2026, 8, 12)),
      PlatformUser(id: 'u-d3', email: 'hussein.ortho@medical.iq', role: 'user', createdDate: d(2025, 9, 18)),
      PlatformUser(id: 'u-p1', email: 'ali.j@example.com', role: 'user', createdDate: d(2026, 2, 11)),
      PlatformUser(id: 'u-p2', email: 'zainab.a@example.com', role: 'user', createdDate: d(2026, 4, 7)),
      PlatformUser(id: 'u-p3', email: 'hasan.k@example.com', role: 'user', createdDate: d(2026, 5, 21)),
    ];
