import '../models/models.dart';

DateTime d(int y, int m, int day, [int h = 10, int min = 0]) => DateTime(y, m, day, h, min);

List<ClinicUser> seedUsers() => [
      ClinicUser(id: 'u-p1', email: 'patient@medical.iq', fullName: 'علي جاسم محمد', role: 'patient', phone: '07720001122', password: 'Patient123'),
      ClinicUser(id: 'u-p2', email: 'zainab.a@example.com', fullName: 'زينب عبد الأمير', role: 'patient', phone: '07830004455', password: 'Patient123'),
      ClinicUser(id: 'u-d1', email: 'doctor@medical.iq', fullName: 'أحمد الكعبي', role: 'doctor', phone: '07701234567', password: 'Doctor123'),
      ClinicUser(id: 'u-d2', email: 'sara.pedia@medical.iq', fullName: 'سارة الموسوي', role: 'doctor', phone: '07812345678', password: 'Doctor123'),
      ClinicUser(id: 'u-d3', email: 'hussein.ortho@medical.iq', fullName: 'حسين الجبوري', role: 'doctor', phone: '07505551212', password: 'Doctor123'),
      ClinicUser(id: 'u-d6', email: 'nora.obgyn@medical.iq', fullName: 'نورا قادر', role: 'doctor', phone: '07507778899', password: 'Doctor123'),
    ];

List<Doctor> seedDoctors() => [
      Doctor(
        id: 'd1', userId: 'u-d1', fullName: 'أحمد الكعبي', gender: 'Male', dateOfBirth: '1982-03-11',
        specialty: 'أمراض القلب', clinicName: 'عيادة القلب التخصصية', city: 'بغداد',
        phone: '07701234567', email: 'doctor@medical.iq', licenseNumber: 'IQ-DOC-10021',
        status: 'approved', subscriptionStatus: 'active', subscriptionStart: d(2026, 7, 1),
        subscriptionEnd: d(2026, 12, 26), yearsOfExperience: 12, qualifications: 'بورد القلب التداخلي',
        biography: 'استشاري أمراض القلب في مدينة الطب. خبرة في القسطرة والعناية المركزة القلبية.',
        workingHours: '9 صباحاً - 3 مساءً', featured: true, certificates: ['شهادة البورد العراقي.pdf'],
        profilePhoto: 'assets/doctors/doctor_ahmed.jpg',
        latitude: 33.3128, longitude: 44.3615,
        createdDate: d(2025, 11, 4),
      ),
      Doctor(
        id: 'd2', userId: 'u-d2', fullName: 'سارة الموسوي', gender: 'Female', dateOfBirth: '1991-06-20',
        specialty: 'الأطفال', clinicName: 'عيادة الأطفال الذكية', city: 'بغداد',
        phone: '07812345678', email: 'sara.pedia@medical.iq', licenseNumber: 'IQ-DOC-10045',
        status: 'pending', subscriptionStatus: 'inactive', yearsOfExperience: 7,
        biography: 'طبيبة أطفال، بانتظار موافقة الإدارة.',
        profilePhoto: 'assets/doctors/doctor_sara.jpg',
        latitude: 33.3402, longitude: 44.4001,
        createdDate: d(2026, 8, 12),
      ),
      Doctor(
        id: 'd3', userId: 'u-d3', fullName: 'حسين الجبوري', gender: 'Male',
        specialty: 'العظام', clinicName: 'مركز العظام والمفاصل', city: 'بغداد',
        phone: '07505551212', email: 'hussein.ortho@medical.iq', licenseNumber: 'IQ-DOC-10088',
        status: 'approved', subscriptionStatus: 'active', subscriptionStart: d(2026, 2, 20),
        subscriptionEnd: d(2027, 2, 20), yearsOfExperience: 15, workingHours: '10 صباحاً - 4 مساءً',
        biography: 'استشاري جراحة العظام والمفاصل.', featured: true,
        profilePhoto: 'assets/doctors/doctor_hussein.jpg',
        latitude: 33.2985, longitude: 44.3420,
        createdDate: d(2025, 9, 18),
      ),
      Doctor(
        id: 'd6', userId: 'u-d6', fullName: 'نورا قادر', gender: 'Female',
        specialty: 'النساء والولادة', clinicName: 'عيادة الأمومة', city: 'بغداد',
        phone: '07507778899', email: 'nora.obgyn@medical.iq', licenseNumber: 'IQ-DOC-10170',
        status: 'approved', subscriptionStatus: 'active', subscriptionStart: d(2026, 6, 1),
        subscriptionEnd: d(2026, 12, 1), yearsOfExperience: 11, featured: true,
        profilePhoto: 'assets/doctors/doctor_nora.jpg',
        latitude: 33.3255, longitude: 44.3855,
        createdDate: d(2026, 3, 2),
      ),
    ];

List<Patient> seedPatients() => [
      Patient(
        id: 'p1', userId: 'u-p1', fullName: 'علي جاسم محمد', patientId: 'IQ-P-24081',
        qrCodeData: 'IQ-P-24081', phone: '07720001122', email: 'patient@medical.iq', city: 'بغداد',
        gender: 'Male', bloodType: 'O+', status: 'active', nationalId: '19901234567',
        dateOfBirth: '1990-04-12', allergies: 'البنسلين', chronicDiseases: 'ارتفاع ضغط الدم',
        currentMedications: 'أملوديبين 5 ملغ', emergencyContactName: 'فاطمة جاسم',
        emergencyContactRelationship: 'زوجة', emergencyContactPhone: '07721112233',
        medicalHistory: 'ارتفاع ضغط منذ 2019', vaccinationRecords: 'كوفيد-19 جرعتان',
        surgeryRecords: 'لا توجد', createdDate: d(2026, 2, 11),
      ),
      Patient(
        id: 'p2', userId: 'u-p2', fullName: 'زينب عبد الأمير', patientId: 'IQ-P-24102',
        qrCodeData: 'IQ-P-24102', phone: '07830004455', email: 'zainab.a@example.com',
        city: 'كربلاء', gender: 'Female', bloodType: 'A+', status: 'active',
        dateOfBirth: '1988-09-03', allergies: 'لا توجد', createdDate: d(2026, 4, 7),
      ),
      Patient(
        id: 'p3', userId: 'u-p3', fullName: 'حسن كريم', patientId: 'IQ-P-24155',
        qrCodeData: 'IQ-P-24155', phone: '07506667788', email: 'hasan.k@example.com',
        city: 'كركوك', gender: 'Male', bloodType: 'B-', status: 'active',
        dateOfBirth: '1979-01-22', chronicDiseases: 'السكري النوع الثاني', createdDate: d(2026, 5, 21),
      ),
      Patient(
        id: 'p5', userId: 'u-p5', fullName: 'يوسف نوري', patientId: 'IQ-P-24220',
        qrCodeData: 'IQ-P-24220', phone: '07815556677', email: 'yousef.n@example.com',
        city: 'البصرة', gender: 'Male', bloodType: 'O-', status: 'active',
        dateOfBirth: '2001-07-15', createdDate: d(2026, 7, 2),
      ),
      Patient(
        id: 'p6', userId: 'u-p6', fullName: 'هدى صالح', patientId: 'IQ-P-24248',
        qrCodeData: 'IQ-P-24248', phone: '07512223344', email: 'huda.s@example.com',
        city: 'أربيل', gender: 'Female', bloodType: 'A-', status: 'active',
        dateOfBirth: '1993-02-28', createdDate: d(2026, 7, 28),
      ),
    ];

List<Post> seedPosts() => [
      Post(id: 'po1', doctorId: 'd1', doctorName: 'أحمد الكعبي', content: 'نصائح للوقاية من أمراض القلب في فصل الصيف: قلل الملح، اشرب الماء، وتجنب الإجهاد في الحر.', category: 'educational', likesCount: 24, commentsCount: 2, createdDate: d(2026, 8, 10, 14)),
      Post(id: 'po2', doctorId: 'd6', doctorName: 'نورا قادر', content: 'أهمية الفحوصات الدورية أثناء الحمل للحفاظ على صحة الأم والجنين.', category: 'news', likesCount: 18, commentsCount: 1, createdDate: d(2026, 8, 14, 11)),
      Post(id: 'po3', doctorId: 'd3', doctorName: 'حسين الجبوري', content: 'تمارين منزلية بعد عمليات الركبة تساعد على استعادة الحركة بأمان.', category: 'workshop', likesCount: 11, commentsCount: 1, createdDate: d(2026, 8, 19, 16)),
    ];

List<PostComment> seedComments() => [
      PostComment(id: 'c1', postId: 'po1', authorName: 'علي جاسم محمد', content: 'نصائح مفيدة، شكراً دكتور.', createdDate: d(2026, 8, 10, 16)),
      PostComment(id: 'c2', postId: 'po1', authorName: 'زينب عبد الأمير', content: 'هل ينطبق هذا على مرضى الضغط أيضاً؟', createdDate: d(2026, 8, 11, 9)),
      PostComment(id: 'c3', postId: 'po2', authorName: 'هدى صالح', content: 'موعد فحوصات الثلث الثاني مهم جداً.', createdDate: d(2026, 8, 14, 15)),
      PostComment(id: 'c4', postId: 'po3', authorName: 'حسن كريم', content: 'سأبدأ التمارين بعد مراجعة الطبيب.', createdDate: d(2026, 8, 19, 18)),
    ];

List<Visit> seedVisits() => [
      Visit(id: 'v1', doctorId: 'd1', doctorName: 'أحمد الكعبي', doctorSpecialty: 'أمراض القلب', patientId: 'p1', patientName: 'علي جاسم محمد', visitDate: d(2026, 3, 12), createdDate: d(2026, 3, 12, 10), visitTime: '10:00', symptoms: 'ألم صدر', diagnosis: 'ذبحة مستقرة', treatmentPlan: 'أدوية ومراجعة', prescribedMedications: 'أسبرين', followUpNotes: 'مراجعة بعد شهر'),
      Visit(id: 'v2', doctorId: 'd1', doctorName: 'أحمد الكعبي', doctorSpecialty: 'أمراض القلب', patientId: 'p2', patientName: 'زينب عبد الأمير', visitDate: d(2026, 4, 3), createdDate: d(2026, 4, 3, 11), diagnosis: 'خفقان'),
      Visit(id: 'v3', doctorId: 'd3', doctorName: 'حسين الجبوري', doctorSpecialty: 'العظام', patientId: 'p3', patientName: 'حسن كريم', visitDate: d(2026, 5, 19), createdDate: d(2026, 5, 19, 10), diagnosis: 'خشونة ركبة'),
      Visit(id: 'v6', doctorId: 'd1', doctorName: 'أحمد الكعبي', doctorSpecialty: 'أمراض القلب', patientId: 'p5', patientName: 'يوسف نوري', visitDate: d(2026, 8, 2), createdDate: d(2026, 8, 2, 9)),
      Visit(id: 'v7', doctorId: 'd3', doctorName: 'حسين الجبوري', doctorSpecialty: 'العظام', patientId: 'p1', patientName: 'علي جاسم محمد', visitDate: d(2026, 8, 11), createdDate: d(2026, 8, 11, 12), diagnosis: 'التهاب أوتار'),
      Visit(id: 'v8', doctorId: 'd1', doctorName: 'أحمد الكعبي', doctorSpecialty: 'أمراض القلب', patientId: 'p3', patientName: 'حسن كريم', visitDate: d(2026, 8, 16), createdDate: d(2026, 8, 16, 10)),
      Visit(id: 'v4', doctorId: 'd6', doctorName: 'نورا قادر', doctorSpecialty: 'النساء والولادة', patientId: 'p2', patientName: 'زينب عبد الأمير', visitDate: d(2026, 6, 8), createdDate: d(2026, 6, 8, 11)),
      Visit(id: 'v5', doctorId: 'd6', doctorName: 'نورا قادر', doctorSpecialty: 'النساء والولادة', patientId: 'p6', patientName: 'هدى صالح', visitDate: d(2026, 7, 14), createdDate: d(2026, 7, 14, 10)),
    ];

List<MedicalFile> seedFiles() => [
      MedicalFile(id: 'f1', fileType: 'prescription', doctorId: 'd1', doctorName: 'أحمد الكعبي', patientId: 'p1', fileName: 'وصفة-1.pdf', description: 'وصفة أسبرين', createdDate: d(2026, 3, 12)),
      MedicalFile(id: 'f2', fileType: 'lab_result', doctorId: 'd1', doctorName: 'أحمد الكعبي', patientId: 'p2', fileName: 'تحليل-دم.pdf', createdDate: d(2026, 4, 3)),
      MedicalFile(id: 'f3', fileType: 'radiology', doctorId: 'd3', doctorName: 'حسين الجبوري', patientId: 'p3', fileName: 'أشعة-ركبة.jpg', createdDate: d(2026, 5, 19)),
      MedicalFile(id: 'f6', fileType: 'xray', doctorId: 'd3', doctorName: 'حسين الجبوري', patientId: 'p1', fileName: 'سينية-صدر.jpg', createdDate: d(2026, 8, 2)),
      MedicalFile(id: 'f7', fileType: 'prescription', doctorId: 'd1', doctorName: 'أحمد الكعبي', patientId: 'p5', fileName: 'وصفة-يوسف.pdf', createdDate: d(2026, 8, 16)),
      MedicalFile(id: 'f4', fileType: 'blood_test', doctorId: 'd6', doctorName: 'نورا قادر', patientId: 'p2', fileName: 'سكر-تراكمي.pdf', createdDate: d(2026, 6, 8)),
    ];

List<AccessSession> seedSessions() => [
      AccessSession(id: 's1', patientId: 'p1', patientUserId: 'u-p1', doctorId: 'd1', patientName: 'علي جاسم محمد', doctorName: 'أحمد الكعبي', status: 'active', grantedAt: d(2026, 8, 22, 8), expiresAt: d(2026, 8, 23, 18), accessMethod: 'qr_scan'),
      AccessSession(id: 's2', patientId: 'p5', patientUserId: 'u-p5', doctorId: 'd1', patientName: 'يوسف نوري', doctorName: 'أحمد الكعبي', status: 'active', grantedAt: d(2026, 8, 22, 9), expiresAt: d(2026, 8, 24, 9), accessMethod: 'search'),
      AccessSession(id: 's3', patientId: 'p2', patientUserId: 'u-p2', doctorId: 'd6', patientName: 'زينب عبد الأمير', doctorName: 'نورا قادر', status: 'expired', grantedAt: d(2026, 8, 9, 10), expiresAt: d(2026, 8, 10, 12)),
    ];

List<Availability> seedAvailability() => [
      Availability(id: 'av1', doctorId: 'd1', doctorName: 'أحمد الكعبي', dayOfWeek: 0, startTime: '09:00', endTime: '13:00'),
      Availability(id: 'av2', doctorId: 'd1', doctorName: 'أحمد الكعبي', dayOfWeek: 1, startTime: '09:00', endTime: '15:00'),
      Availability(id: 'av3', doctorId: 'd1', doctorName: 'أحمد الكعبي', dayOfWeek: 2, startTime: '09:00', endTime: '15:00'),
      Availability(id: 'av4', doctorId: 'd1', doctorName: 'أحمد الكعبي', dayOfWeek: 3, startTime: '09:00', endTime: '13:00'),
      Availability(id: 'av5', doctorId: 'd3', doctorName: 'حسين الجبوري', dayOfWeek: 1, startTime: '10:00', endTime: '16:00'),
      Availability(id: 'av6', doctorId: 'd3', doctorName: 'حسين الجبوري', dayOfWeek: 3, startTime: '10:00', endTime: '16:00'),
      Availability(id: 'av7', doctorId: 'd6', doctorName: 'نورا قادر', dayOfWeek: 0, startTime: '09:00', endTime: '14:00'),
      Availability(id: 'av8', doctorId: 'd6', doctorName: 'نورا قادر', dayOfWeek: 2, startTime: '09:00', endTime: '14:00'),
    ];

List<Appointment> seedAppointments() => [
      Appointment(
        id: 'ap1', doctorId: 'd1', doctorUserId: 'u-d1', doctorName: 'أحمد الكعبي', doctorSpecialty: 'أمراض القلب',
        patientId: 'p1', patientUserId: 'u-p1', patientName: 'علي جاسم محمد', patientPhone: '07720001122',
        appointmentDate: d(2026, 8, 24), appointmentTime: '10:00', reason: 'مراجعة ضغط الدم', status: 'pending',
      ),
      Appointment(
        id: 'ap2', doctorId: 'd1', doctorUserId: 'u-d1', doctorName: 'أحمد الكعبي', doctorSpecialty: 'أمراض القلب',
        patientId: 'p2', patientUserId: 'u-p2', patientName: 'زينب عبد الأمير', patientPhone: '07830004455',
        appointmentDate: d(2026, 8, 25), appointmentTime: '11:30', reason: 'خفقان', status: 'confirmed',
      ),
      Appointment(
        id: 'ap3', doctorId: 'd3', doctorUserId: 'u-d3', doctorName: 'حسين الجبوري', doctorSpecialty: 'العظام',
        patientId: 'p1', patientUserId: 'u-p1', patientName: 'علي جاسم محمد', patientPhone: '07720001122',
        appointmentDate: d(2026, 8, 18), appointmentTime: '12:00', reason: 'ألم كتف', status: 'completed',
      ),
      Appointment(
        id: 'ap4', doctorId: 'd6', doctorUserId: 'u-d6', doctorName: 'نورا قادر', doctorSpecialty: 'النساء والولادة',
        patientId: 'p2', patientUserId: 'u-p2', patientName: 'زينب عبد الأمير', patientPhone: '07830004455',
        appointmentDate: d(2026, 8, 12), appointmentTime: '09:30', reason: 'متابعة', status: 'cancelled',
      ),
    ];

List<AppNotification> seedNotifications() => [
      AppNotification(id: 'n1', userId: 'u-p1', title: 'تم منح الوصول', message: 'تم منح د. أحمد الكعبي (أمراض القلب) صلاحية الوصول إلى سجلاتك الطبية', type: 'access_granted', createdDate: d(2026, 8, 22, 8)),
      AppNotification(id: 'n2', userId: 'u-p1', title: 'تشخيص جديد', message: 'أضاف د. حسين الجبوري تشخيصاً جديداً: التهاب أوتار', type: 'diagnosis', createdDate: d(2026, 8, 11, 12)),
      AppNotification(id: 'n3', userId: 'u-d1', title: 'طلب موعد جديد', message: 'علي جاسم محمد طلب موعداً في 2026-08-24 الساعة 10:00.', type: 'system', link: 'appointments', createdDate: d(2026, 8, 22, 7)),
      AppNotification(id: 'n4', userId: 'u-d1', title: 'موعد مؤكد قادم', message: 'موعد زينب عبد الأمير في 25 آب الساعة 11:30.', type: 'system', read: true, createdDate: d(2026, 8, 21, 18)),
      AppNotification(id: 'n5', userId: 'u-p2', title: 'تم تأكيد الموعد', message: 'أكد د. أحمد الكعبي موعدك في 2026-08-25 الساعة 11:30.', type: 'system', createdDate: d(2026, 8, 21, 19)),
    ];
