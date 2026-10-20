import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../api/api_client.dart';
import '../api/mappers.dart';
import '../data/labels.dart';
import '../models/models.dart';

class AdminStore extends ChangeNotifier {
  AdminStore() {
    doctors = [];
    patients = [];
    posts = [];
    auditLogs = [];
    notifications = [];
    activationLogs = [];
    cards = [];
    visits = [];
    files = [];
    sessions = [];
    users = [];
  }

  static const _tokenKey = 'auth_token';

  final api = ApiClient();
  bool busy = false;

  AdminUser? currentUser;
  String? authError;
  bool passwordResetSent = false;
  bool darkMode = false;
  AdminPage page = AdminPage.dashboard;
  int auditLimit = 50;
  Branding branding = Branding();

  late List<Doctor> doctors;
  late List<Patient> patients;
  late List<Post> posts;
  late List<AuditLog> auditLogs;
  late List<AppNotification> notifications;
  late List<ActivationLog> activationLogs;
  late List<PaymentCard> cards;
  late List<Visit> visits;
  late List<MedicalFile> files;
  late List<AccessSession> sessions;
  late List<PlatformUser> users;
  List<MapRegion> regions = [];

  MapRegion? regionById(String? id) {
    if (id == null || id.isEmpty) return null;
    for (final r in regions) {
      if (r.id == id) return r;
    }
    return null;
  }

  DateTime get now => DateTime.now();

  int get unreadCount => notifications.where((n) => !n.read && n.userId == (currentUser?.id ?? 'local-admin')).length;
  int get pendingDoctors => doctors.where((d) => d.status == 'pending').length;
  int get activeSubscriptions => doctors.where((d) => d.subscriptionStatus == 'active').length;
  int get activeSessions => sessions.where((s) => s.status == 'active' && s.expiresAt.isAfter(now)).length;
  int get expiringSoon => doctors.where((d) {
        if (d.subscriptionStatus != 'active' || d.subscriptionEnd == null) return false;
        final days = d.subscriptionEnd!.difference(DateTime(now.year, now.month, now.day)).inDays;
        return days >= 0 && days <= 7;
      }).length;

  bool get isAdmin {
    final role = currentUser?.role;
    return role == 'admin' || role == 'owner';
  }

  void goTo(AdminPage next) {
    page = next;
    notifyListeners();
  }

  Future<String?> login(String email, String password) async {
    authError = null;
    busy = true;
    notifyListeners();
    try {
      final data = await api.post('/api/auth/login', {
        'email': email.trim(),
        'password': password,
      });
      if (data['requiresOtp'] == true) {
        authError = 'هذا التطبيق مخصص للمديرين فقط';
        return authError;
      }
      api.token = asString(data['token']);
      if (api.token == null || api.token!.isEmpty) {
        authError = 'تعذر إكمال تسجيل الدخول';
        return authError;
      }
      await refresh();
      final role = currentUser?.role;
      if (role != 'admin' && role != 'owner') {
        currentUser = null;
        api.token = null;
        authError = 'هذا التطبيق مخصص للمديرين فقط';
        return authError;
      }
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_tokenKey, api.token!);
      return null;
    } catch (e) {
      authError = _err(e);
      return authError;
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  String? rejectNonAdmin(String role) {
    if (role != 'admin' && role != 'owner') {
      currentUser = null;
      authError = 'هذا التطبيق مخصص للمديرين فقط';
      notifyListeners();
      return authError;
    }
    return null;
  }

  void logout() {
    currentUser = null;
    api.token = null;
    page = AdminPage.dashboard;
    SharedPreferences.getInstance().then((p) => p.remove(_tokenKey));
    notifyListeners();
  }

  Future<void> restoreSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_tokenKey);
      if (saved == null || saved.isEmpty) return;
      api.token = saved;
      await refresh().timeout(const Duration(seconds: 15));
      final role = currentUser?.role;
      if (role != 'admin' && role != 'owner') {
        currentUser = null;
        api.token = null;
        await prefs.remove(_tokenKey);
      }
    } catch (e) {
      currentUser = null;
      api.token = null;
      if (e is ApiException) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove(_tokenKey);
      }
    }
    notifyListeners();
  }

  Future<void> refresh() async {
    final data = await api.get('/api/bootstrap');
    applyBootstrap(data);
  }

  String _err(Object error) {
    if (error is ApiException) return error.message;
    return 'تعذر الاتصال بالخادم. تحقق من الشبكة.';
  }

  void toggleDarkMode() {
    darkMode = !darkMode;
    notifyListeners();
  }

  Future<void> requestPasswordReset() async {
    try {
      await api.post('/api/auth/password/reset-request', {'email': currentUser?.email});
      passwordResetSent = true;
    } catch (e) {
      authError = _err(e);
    }
    notifyListeners();
  }

  Future<String?> uploadPath(String path) async {
    try {
      final data = await api.upload(path);
      return asString(data['url'], asString(data['fileUrl']));
    } catch (e) {
      return null;
    }
  }

  void addAudit(String actionType, String description, {String? targetType, String? targetId}) {
    auditLogs.insert(
      0,
      AuditLog(
        id: 'a-${DateTime.now().millisecondsSinceEpoch}',
        userId: currentUser?.id ?? 'unknown',
        userName: currentUser?.fullName ?? 'مدير',
        userRole: 'admin',
        actionType: actionType,
        description: description,
        targetType: targetType,
        targetId: targetId,
        ipAddress: 'client',
        deviceInfo: 'Windows Desktop',
        createdDate: DateTime.now(),
      ),
    );
  }

  Future<void> approveDoctor(Doctor doctor) async {
    try {
      await api.post('/api/doctors/${doctor.id}/approve');
      await refresh();
    } catch (e) {
      authError = _err(e);
    }
    notifyListeners();
  }

  Future<void> suspendDoctor(Doctor doctor) async {
    try {
      await api.post('/api/doctors/${doctor.id}/suspend');
      await refresh();
    } catch (e) {
      authError = _err(e);
    }
    notifyListeners();
  }

  Future<String?> activateDoctor({
    required Doctor doctor,
    required double amount,
    required String duration,
    required int months,
  }) async {
    if (amount <= 0) return 'يرجى إدخال مبلغ صحيح';
    try {
      await api.post('/api/doctors/${doctor.id}/activate', {
        'amount': amount,
        'duration': duration,
        'months': months,
      });
      await refresh();
      return null;
    } catch (e) {
      return _err(e);
    } finally {
      notifyListeners();
    }
  }

  PaymentCard? cardFor(String doctorId) {
    try {
      return cards.firstWhere((c) => c.doctorId == doctorId);
    } catch (_) {
      return null;
    }
  }

  List<ActivationLog> historyFor(String doctorId) =>
      activationLogs.where((l) => l.doctorId == doctorId).toList();

  Future<void> archivePost(Post post) async {
    try {
      await api.post('/api/posts/${post.id}/archive');
      await refresh();
    } catch (e) {
      authError = _err(e);
    }
    notifyListeners();
  }

  Future<String?> updateDoctor(Doctor doctor) async {
    if (doctor.fullName.trim().isEmpty) return 'الاسم مطلوب';
    if (!validPhone(doctor.phone)) return 'رقم هاتف غير صالح (07XXXXXXXXX)';
    if (!validEmail(doctor.email)) return 'بريد إلكتروني غير صالح';
    if (doctor.specialty.trim().isEmpty) return 'التخصص مطلوب';
    if (doctor.licenseNumber.trim().isEmpty) return 'رقم الترخيص مطلوب';
    try {
      await api.patch('/api/doctors/${doctor.id}', {
        'fullName': doctor.fullName,
        'phone': doctor.phone,
        'email': doctor.email,
        'specialty': doctor.specialty,
        'clinicName': doctor.clinicName,
        'city': doctor.city,
        'licenseNumber': doctor.licenseNumber,
        'biography': doctor.biography,
        'workingHours': doctor.workingHours,
        'qualifications': doctor.qualifications,
        'yearsOfExperience': doctor.yearsOfExperience,
        'certificates': doctor.certificates,
        'status': doctor.status,
        'profilePhoto': doctor.profilePhoto,
        'featured': doctor.featured,
        'gender': doctor.gender,
        'dateOfBirth': doctor.dateOfBirth,
      });
      await refresh();
      return null;
    } catch (e) {
      return _err(e);
    } finally {
      notifyListeners();
    }
  }

  Future<String?> updatePatient(Patient patient) async {
    if (patient.fullName.trim().isEmpty) return 'الاسم مطلوب';
    if (!validPhone(patient.phone)) return 'رقم هاتف غير صالح (07XXXXXXXXX)';
    if (!validEmail(patient.email)) return 'بريد إلكتروني غير صالح';
    try {
      await api.patch('/api/patients/${patient.id}', {
        'fullName': patient.fullName,
        'phone': patient.phone,
        'email': patient.email,
        'city': patient.city,
        'gender': patient.gender,
        'bloodType': patient.bloodType,
        'dateOfBirth': patient.dateOfBirth,
        'allergies': patient.allergies,
        'chronicDiseases': patient.chronicDiseases,
        'currentMedications': patient.currentMedications,
        'emergencyContactName': patient.emergencyContactName,
        'emergencyContactPhone': patient.emergencyContactPhone,
        'emergencyContactRelationship': patient.emergencyContactRelationship,
        'medicalHistory': patient.medicalHistory,
        'nationalId': patient.nationalId,
        'status': patient.status,
        'vaccinationRecords': patient.vaccinationRecords,
        'surgeryRecords': patient.surgeryRecords,
        'profilePhoto': patient.profilePhoto,
      });
      await refresh();
      return null;
    } catch (e) {
      return _err(e);
    } finally {
      notifyListeners();
    }
  }

  Future<void> saveSetting(String key, String value) async {
    switch (key) {
      case 'app_name':
        branding.appName = value;
      case 'app_logo':
        branding.appLogo = value;
      case 'theme_primary_color':
        branding.primaryColor = value;
      case 'theme_secondary_color':
        branding.secondaryColor = value;
      case 'app_font':
        branding.fontFamily = value;
      case 'default_theme':
        branding.defaultTheme = value;
        darkMode = value == 'dark';
      case 'access_duration_hours':
        branding.accessDurationHours = value;
      case 'diagnosis_edit_hours':
        branding.diagnosisEditHours = value;
      case 'default_language':
        branding.defaultLanguage = value;
    }
    notifyListeners();
    try {
      await api.patch('/api/settings/$key', {'value': value});
      await refresh();
    } catch (e) {
      authError = _err(e);
    }
    notifyListeners();
  }

  void previewBranding() => notifyListeners();

  Future<String?> updateProfilePhone(String phone) async {
    if (phone.isNotEmpty && !validPhone(phone)) return 'رقم هاتف غير صالح (07XXXXXXXXX)';
    currentUser?.phone = phone;
    notifyListeners();
    try {
      await api.patch('/api/me', {'phone': phone});
    } catch (e) {
      return _err(e);
    }
    return null;
  }

  Future<void> updateProfilePhoto(String path) async {
    currentUser?.profilePhoto = path;
    notifyListeners();
    try {
      await api.patch('/api/me', {'profilePhoto': path});
    } catch (_) {}
  }

  Future<void> updateAccount({bool? notifyEmail, bool? notifySms, String? language}) async {
    if (notifyEmail != null) currentUser?.notifyEmail = notifyEmail;
    if (notifySms != null) currentUser?.notifySms = notifySms;
    if (language != null) currentUser?.languagePreference = language;
    notifyListeners();
    try {
      await api.patch('/api/me', {
        'notifyEmail': currentUser?.notifyEmail,
        'notifySms': currentUser?.notifySms,
        'languagePreference': currentUser?.languagePreference,
      });
    } catch (_) {}
  }

  Future<void> markNotificationRead(AppNotification item) async {
    item.read = true;
    notifyListeners();
    try {
      await api.post('/api/notifications/${item.id}/read');
    } catch (_) {}
  }

  Future<String?> broadcastNotification({
    required String title,
    required String message,
    String role = 'all',
  }) async {
    try {
      await api.post('/api/notifications/broadcast', {
        'title': title.trim(),
        'message': message.trim(),
        'role': role,
        'type': 'admin',
        'link': '/notifications',
      });
      await refresh();
      notifyListeners();
      return null;
    } catch (e) {
      notifyListeners();
      return e.toString();
    }
  }

  Future<void> markAllNotificationsRead() async {
    for (final item in notifications) {
      if (item.userId == (currentUser?.id ?? 'local-admin')) item.read = true;
    }
    notifyListeners();
    try {
      await api.post('/api/notifications/read-all');
    } catch (_) {}
  }

  Future<void> loadMoreAudit() async {
    auditLimit += 50;
    try {
      final data = await api.get('/api/audit?limit=$auditLimit');
      auditLogs = asMapList(data['audit']).map(_audit).toList();
    } catch (e) {
      authError = _err(e);
    }
    notifyListeners();
  }

  void applyBootstrap(Map<String, dynamic> data) {
    final user = asMap(data['user']);
    if (user.isNotEmpty) {
      currentUser = AdminUser(
        id: asString(user['id']),
        email: asString(user['email']),
        fullName: asString(user['fullName']),
        phone: asString(user['phone']),
        role: asString(user['role'], 'admin'),
        profilePhoto: asString(user['profilePhoto']),
        languagePreference: asString(user['languagePreference'], 'ar'),
        notifyEmail: asBool(user['notifyEmail'], true),
        notifySms: asBool(user['notifySms'], true),
      );
    }
    final settings = asMap(data['branding']);
    if (settings.isNotEmpty) {
      branding
        ..appName = asString(settings['app_name'], branding.appName)
        ..appLogo = asString(settings['app_logo'], branding.appLogo)
        ..primaryColor = asString(settings['theme_primary_color'], branding.primaryColor)
        ..secondaryColor = asString(settings['theme_secondary_color'], branding.secondaryColor)
        ..fontFamily = asString(settings['app_font'], branding.fontFamily)
        ..defaultTheme = asString(settings['default_theme'], branding.defaultTheme)
        ..accessDurationHours = asString(settings['access_duration_hours'], branding.accessDurationHours)
        ..diagnosisEditHours = asString(settings['diagnosis_edit_hours'], branding.diagnosisEditHours)
        ..defaultLanguage = asString(settings['default_language'], branding.defaultLanguage);
      darkMode = branding.defaultTheme == 'dark';
    }
    doctors = asMapList(data['doctors']).map(_doctor).toList();
    patients = asMapList(data['patients']).map(_patient).toList();
    posts = asMapList(data['posts']).map(_post).toList();
    auditLogs = asMapList(data['audit']).map(_audit).toList();
    notifications = asMapList(data['notifications']).map(_notification).toList();
    activationLogs = asMapList(data['activations']).map(_activation).toList();
    cards = asMapList(data['cards']).map(_card).toList();
    visits = asMapList(data['visits']).map(_visit).toList();
    files = asMapList(data['files']).map(_file).toList();
    sessions = asMapList(data['sessions']).map(_session).toList();
    users = asMapList(data['users']).map(_platformUser).toList();
    regions = asMapList(data['regions']).map(_region).toList();
  }

  MapRegion _region(Map<String, dynamic> r) => MapRegion(
        id: asString(r['id']),
        name: asString(r['name']),
        city: asString(r['city'], 'بغداد'),
        centerLat: asDouble(r['centerLat']),
        centerLng: asDouble(r['centerLng']),
        zoom: asDouble(r['zoom'], 13),
        isActive: asBool(r['isActive'], true),
      );

  Doctor _doctor(Map<String, dynamic> d) => Doctor(
        id: asString(d['id']),
        userId: d['userId']?.toString(),
        fullName: asString(d['fullName']),
        specialty: asString(d['specialty']),
        clinicName: asString(d['clinicName']),
        city: asString(d['city']),
        phone: asString(d['phone']),
        email: asString(d['email']),
        licenseNumber: asString(d['licenseNumber']),
        status: asString(d['status']),
        subscriptionStatus: asString(d['subscriptionStatus']),
        createdDate: asDate(d['createdDate']),
        gender: asString(d['gender'], 'Male'),
        dateOfBirth: asString(d['dateOfBirth']),
        subscriptionStart: asDateOrNull(d['subscriptionStart']),
        subscriptionEnd: asDateOrNull(d['subscriptionEnd']),
        subscriptionDuration: d['subscriptionDuration']?.toString(),
        paymentAmount: asDouble(d['paymentAmount']),
        yearsOfExperience: asInt(d['yearsOfExperience']),
        qualifications: asString(d['qualifications']),
        biography: asString(d['biography']),
        workingHours: asString(d['workingHours']),
        profilePhoto: asString(d['profilePhoto']),
        lastModifiedBy: d['lastModifiedBy']?.toString(),
        lastModifiedAt: asDateOrNull(d['lastModifiedAt']),
        featured: asBool(d['featured']),
        certificates: asStrings(d['certificates']),
        regionId: d['regionId']?.toString(),
        latitude: asDoubleOrNull(d['latitude']),
        longitude: asDoubleOrNull(d['longitude']),
      );

  Patient _patient(Map<String, dynamic> p) => Patient(
        id: asString(p['id']),
        userId: p['userId']?.toString(),
        fullName: asString(p['fullName']),
        patientId: asString(p['patientId']),
        phone: asString(p['phone']),
        email: asString(p['email']),
        city: asString(p['city']),
        gender: asString(p['gender'], 'Male'),
        bloodType: asString(p['bloodType'], 'O+'),
        status: asString(p['status'], 'active'),
        createdDate: asDate(p['createdDate']),
        nationalId: asString(p['nationalId']),
        dateOfBirth: asString(p['dateOfBirth']),
        allergies: asString(p['allergies']),
        chronicDiseases: asString(p['chronicDiseases']),
        currentMedications: asString(p['currentMedications']),
        emergencyContactName: asString(p['emergencyContactName']),
        emergencyContactRelationship: asString(p['emergencyContactRelationship']),
        emergencyContactPhone: asString(p['emergencyContactPhone']),
        medicalHistory: asString(p['medicalHistory']),
        vaccinationRecords: asString(p['vaccinationRecords']),
        surgeryRecords: asString(p['surgeryRecords']),
        profilePhoto: asString(p['profilePhoto']),
        lastModifiedBy: p['lastModifiedBy']?.toString(),
        lastModifiedAt: asDateOrNull(p['lastModifiedAt']),
      );

  Post _post(Map<String, dynamic> p) => Post(
        id: asString(p['id']),
        doctorName: asString(p['doctorName']),
        content: asString(p['content']),
        category: asString(p['category']),
        createdDate: asDate(p['createdDate']),
        status: asString(p['status'], 'published'),
        likesCount: asInt(p['likesCount']),
        commentsCount: asInt(p['commentsCount']),
      );

  AuditLog _audit(Map<String, dynamic> a) => AuditLog(
        id: asString(a['id']),
        userId: asString(a['userId']),
        userName: asString(a['userName']),
        userRole: asString(a['userRole']),
        actionType: asString(a['actionType']),
        description: asString(a['description']),
        createdDate: asDate(a['createdDate']),
        targetType: a['targetType']?.toString(),
        targetId: a['targetId']?.toString(),
        ipAddress: a['ipAddress']?.toString(),
        deviceInfo: a['deviceInfo']?.toString(),
      );

  AppNotification _notification(Map<String, dynamic> n) => AppNotification(
        id: asString(n['id']),
        userId: asString(n['userId']),
        title: asString(n['title']),
        message: asString(n['message']),
        createdDate: asDate(n['createdDate']),
        read: asBool(n['read']),
        type: asString(n['type'], 'system'),
        link: asString(n['link']),
      );

  ActivationLog _activation(Map<String, dynamic> a) => ActivationLog(
        id: asString(a['id']),
        doctorId: asString(a['doctorId']),
        doctorName: asString(a['doctorName']),
        adminName: asString(a['adminName']),
        paymentAmount: asDouble(a['paymentAmount']),
        duration: asString(a['duration']),
        startDate: asDate(a['startDate']),
        endDate: asDate(a['endDate']),
        action: asString(a['action']),
        createdDate: asDate(a['createdDate']),
      );

  PaymentCard _card(Map<String, dynamic> c) => PaymentCard(
        doctorId: asString(c['doctorId']),
        bankName: asString(c['bankName']),
        cardNumber: asString(c['cardNumber']),
        cardHolderName: asString(c['cardHolderName']),
        cardExpiry: asString(c['cardExpiry']),
        cardCvv: asString(c['cardCvv']),
      );

  Visit _visit(Map<String, dynamic> v) => Visit(
        id: asString(v['id']),
        doctorId: asString(v['doctorId']),
        doctorName: asString(v['doctorName']),
        doctorSpecialty: asString(v['doctorSpecialty']),
        patientId: asString(v['patientId']),
        patientName: asString(v['patientName']),
        visitDate: asDate(v['visitDate']),
        symptoms: asString(v['symptoms']),
        diagnosis: asString(v['diagnosis']),
        treatmentPlan: asString(v['treatmentPlan']),
        prescribedMedications: asString(v['prescribedMedications']),
        followUpNotes: asString(v['followUpNotes']),
      );

  MedicalFile _file(Map<String, dynamic> f) => MedicalFile(
        id: asString(f['id']),
        fileType: asString(f['fileType']),
        createdDate: asDate(f['createdDate']),
        doctorId: asString(f['doctorId']),
        doctorName: asString(f['doctorName']),
        patientId: asString(f['patientId']),
        fileName: asString(f['fileName']),
        description: asString(f['description']),
        fileUrl: asString(f['fileUrl']),
      );

  AccessSession _session(Map<String, dynamic> s) => AccessSession(
        id: asString(s['id']),
        patientName: asString(s['patientName']),
        doctorName: asString(s['doctorName']),
        status: asString(s['status']),
        expiresAt: asDate(s['expiresAt']),
      );

  PlatformUser _platformUser(Map<String, dynamic> u) => PlatformUser(
        id: asString(u['id']),
        email: asString(u['email']),
        role: asString(u['role']),
        createdDate: asDate(u['createdDate']),
      );

  List<Visit> visitsFor(String patientId) => visits.where((v) => v.patientId == patientId).toList();
  List<MedicalFile> filesFor(String patientId) => files.where((f) => f.patientId == patientId).toList();

  List<({DateTime date, String label, int patients, int doctors})> dailyLogins(int days) {
    final start = DateTime(now.year, now.month, now.day).subtract(Duration(days: days - 1));
    final map = <String, ({DateTime date, int patients, int doctors})>{};
    for (var i = 0; i < days; i++) {
      final day = start.add(Duration(days: i));
      map[_dayKey(day)] = (date: day, patients: 0, doctors: 0);
    }
    for (final log in auditLogs.where((l) => l.actionType == 'login')) {
      final key = _dayKey(log.createdDate);
      final row = map[key];
      if (row == null) continue;
      if (log.userRole == 'doctor' || log.userRole == 'admin') {
        map[key] = (date: row.date, patients: row.patients, doctors: row.doctors + 1);
      } else {
        map[key] = (date: row.date, patients: row.patients + 1, doctors: row.doctors);
      }
    }
    const names = ['الاثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة', 'السبت', 'الأحد'];
    return map.values
        .map((e) => (date: e.date, label: names[e.date.weekday - 1], patients: e.patients, doctors: e.doctors))
        .toList();
  }

  String _dayKey(DateTime d) => '${d.year}-${d.month}-${d.day}';
}

class AdminScope extends InheritedNotifier<AdminStore> {
  const AdminScope({
    required AdminStore store,
    required super.child,
    super.key,
  }) : super(notifier: store);

  static AdminStore of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AdminScope>();
    assert(scope != null, 'AdminScope not found');
    return scope!.notifier!;
  }
}
