import 'package:flutter/material.dart';

import '../api/api_client.dart';
import '../api/mappers.dart';
import '../data/doctor_locations.dart';
import '../data/doctor_photos.dart';
import '../data/labels.dart';
import '../models/models.dart';
import '../services/push_service.dart';

class ClinicStore extends ChangeNotifier {
  ClinicStore() {
    users = [];
    doctors = [];
    patients = [];
    posts = [];
    comments = [];
    visits = [];
    files = [];
    sessions = [];
    availability = [];
    appointments = [];
    notifications = [];
    messages = [];
    reviews = [];
    achievements = [];
    follows = [];
    cards = [];
    regions = [];
  }

  final api = ApiClient();
  Branding branding = Branding();
  bool darkMode = false;
  bool busy = false;
  String? authError;
  String? lastMessage;
  OtpChallenge? otp;
  String? resetEmail;
  String? pendingProfilePhotoPath;

  ClinicUser? currentUser;
  ClinicPage page = ClinicPage.home;
  String? selectedPatientId;
  String? selectedDoctorId;
  String appointmentView = 'list';
  DateTime calendarDate = DateTime.now();

  late List<ClinicUser> users;
  late List<Doctor> doctors;
  late List<Patient> patients;
  late List<Post> posts;
  late List<PostComment> comments;
  late List<Visit> visits;
  late List<MedicalFile> files;
  late List<AccessSession> sessions;
  late List<Availability> availability;
  late List<Appointment> appointments;
  late List<AppNotification> notifications;
  late List<ChatMessage> messages;
  late List<DoctorReview> reviews;
  late List<Achievement> achievements;
  late List<({String patientId, String doctorId})> follows;
  late List<PaymentCard> cards;
  late List<MapRegion> regions;
  final likedPostIds = <String>{};
  String? selectedRegionId;

  String get role => currentUser?.role ?? '';
  bool get isPatient => role == 'patient';
  bool get isDoctor => role == 'doctor';
  bool get isAdmin => role == 'admin' || role == 'owner';
  bool get canManageRegions => isDoctor || isAdmin;
  bool get loggedIn => currentUser != null;

  Patient? get currentPatient {
    final user = currentUser;
    if (user == null || user.role != 'patient') return null;
    return patients.where((p) => p.userId == user.id).firstOrNull;
  }

  Doctor? get currentDoctor {
    final user = currentUser;
    if (user == null || user.role != 'doctor') return null;
    return doctors.where((d) => d.userId == user.id).firstOrNull;
  }

  bool get doctorLocked {
    final doctor = currentDoctor;
    if (doctor == null) return false;
    return doctor.status == 'pending' || doctor.subscriptionStatus != 'active';
  }

  bool get doctorPending => currentDoctor?.status == 'pending';

  int get unreadCount => notifications.where((n) => n.userId == currentUser?.id && !n.read).length;

  List<Doctor> get featuredDoctors {
    final featured = doctors.where((d) => d.isActive && d.featured).toList();
    if (featured.isNotEmpty) return featured;
    return doctors.where((d) => d.isActive).take(4).toList();
  }

  List<Post> get publishedPosts {
    final list = posts.where((p) => p.status == 'published').toList()
      ..sort((a, b) => b.createdDate.compareTo(a.createdDate));
    return list;
  }

  List<AppNotification> get myNotifications {
    final id = currentUser?.id;
    final list = notifications.where((n) => n.userId == id).toList()
      ..sort((a, b) => b.createdDate.compareTo(a.createdDate));
    return list;
  }

  List<Appointment> get myAppointments {
    if (isDoctor) {
      final id = currentDoctor?.id;
      return appointments.where((a) => a.doctorId == id).toList()
        ..sort((a, b) => b.dateTime.compareTo(a.dateTime));
    }
    final id = currentPatient?.id;
    return appointments.where((a) => a.patientId == id).toList()
      ..sort((a, b) => b.dateTime.compareTo(a.dateTime));
  }

  List<(String, String, String, int)> get conversationSummaries {
    final map = <String, List<ChatMessage>>{};
    for (final m in messages) {
      if (isDoctor && m.doctorId != currentDoctor?.id) continue;
      if (isPatient && m.patientId != currentPatient?.id) continue;
      map.putIfAbsent(m.conversationId, () => []).add(m);
    }
    final items = <(String, String, String, int)>[];
    for (final entry in map.entries) {
      final thread = [...entry.value]..sort((a, b) => b.createdDate.compareTo(a.createdDate));
      final last = thread.first;
      final title = isDoctor
          ? (patientById(last.patientId)?.fullName ?? last.senderName)
          : 'د. ${doctorById(last.doctorId)?.fullName ?? last.senderName}';
      final unread = thread.where((m) => !m.read && m.senderUserId != currentUser?.id).length;
      items.add((entry.key, title, last.content, unread));
    }
    items.sort((a, b) {
      final am = messages.where((m) => m.conversationId == a.$1).map((m) => m.createdDate).fold<DateTime?>(null, (p, n) => p == null || n.isAfter(p) ? n : p);
      final bm = messages.where((m) => m.conversationId == b.$1).map((m) => m.createdDate).fold<DateTime?>(null, (p, n) => p == null || n.isAfter(p) ? n : p);
      return (bm ?? DateTime(0)).compareTo(am ?? DateTime(0));
    });
    return items;
  }

  /// أطباء يمكن للمريض مراسلتهم (زيارات/مواعيد/متابعة/محادثات سابقة).
  List<Doctor> get chatableDoctors {
    final pid = currentPatient?.id;
    if (pid == null) return [];
    final ids = <String>{
      ...appointments.where((a) => a.patientId == pid).map((a) => a.doctorId),
      ...visits.where((v) => v.patientId == pid).map((v) => v.doctorId),
      ...messages.where((m) => m.patientId == pid).map((m) => m.doctorId),
      ...follows.where((f) => f.patientId == pid).map((f) => f.doctorId),
    };
    return doctors.where((d) => ids.contains(d.id)).toList()
      ..sort((a, b) => a.fullName.compareTo(b.fullName));
  }

  /// مرضى يمكن للطبيب مراسلتهم (وصول/زيارات/محادثات سابقة).
  List<Patient> get chatablePatients {
    final did = currentDoctor?.id;
    if (did == null) return [];
    final ids = <String>{
      ...sessions.where((s) => s.doctorId == did && s.isActive()).map((s) => s.patientId),
      ...visits.where((v) => v.doctorId == did).map((v) => v.patientId),
      ...messages.where((m) => m.doctorId == did).map((m) => m.patientId),
      ...appointments.where((a) => a.doctorId == did).map((a) => a.patientId),
    };
    return patients.where((p) => ids.contains(p.id)).toList()
      ..sort((a, b) => a.fullName.compareTo(b.fullName));
  }

  Patient? patientById(String id) => patients.where((p) => p.id == id).firstOrNull;
  Doctor? doctorById(String id) => doctors.where((d) => d.id == id).firstOrNull;

  List<Visit> visitsForPatient(String patientId) =>
      visits.where((v) => v.patientId == patientId).toList()..sort((a, b) => b.visitDate.compareTo(a.visitDate));

  List<Visit> visitsForDoctor(String doctorId) =>
      visits.where((v) => v.doctorId == doctorId).toList()..sort((a, b) => b.visitDate.compareTo(a.visitDate));

  List<MedicalFile> filesForPatient(String patientId) =>
      files.where((f) => f.patientId == patientId && f.status == 'active').toList()
        ..sort((a, b) => b.createdDate.compareTo(a.createdDate));

  List<AccessSession> activeSessionsForDoctor(String doctorId) =>
      sessions.where((s) => s.doctorId == doctorId && s.isActive(calendarDate)).toList();

  bool hasAccess(String patientId) {
    final doctor = currentDoctor;
    if (doctor == null) return false;
    return sessions.any((s) => s.doctorId == doctor.id && s.patientId == patientId && s.isActive());
  }

  AccessSession? accessSessionFor(String patientId) {
    final doctor = currentDoctor;
    if (doctor == null) return null;
    final list = sessions.where((s) => s.doctorId == doctor.id && s.patientId == patientId && s.isActive()).toList()
      ..sort((a, b) => b.grantedAt.compareTo(a.grantedAt));
    return list.firstOrNull;
  }

  /// التعديل والرفع فقط خلال 10 دقائق بعد مسح QR.
  bool canWritePatient(String patientId) => accessSessionFor(patientId)?.canWrite() ?? false;

  Duration writeRemainingFor(String patientId) => accessSessionFor(patientId)?.writeRemaining() ?? Duration.zero;

  void _renewLocalWriteWindow(Patient patient, {required String method}) {
    final doctor = currentDoctor;
    if (doctor == null) return;
    final now = DateTime.now();
    final hours = branding.accessDurationHours <= 0 ? 24 : branding.accessDurationHours;
    final idx = sessions.indexWhere((s) => s.doctorId == doctor.id && s.patientId == patient.id && s.isActive());
    final existing = idx >= 0 ? sessions[idx] : null;
    final renewed = AccessSession(
      id: existing?.id ?? 'pending_${patient.id}',
      patientId: patient.id,
      patientUserId: patient.userId,
      doctorId: doctor.id,
      patientName: patient.fullName,
      doctorName: doctor.fullName,
      status: 'active',
      grantedAt: now,
      expiresAt: existing?.expiresAt.isAfter(now.add(Duration(hours: hours))) == true
          ? existing!.expiresAt
          : now.add(Duration(hours: hours)),
      durationHours: existing?.durationHours ?? hours,
      accessMethod: method,
    );
    if (idx >= 0) {
      sessions = [...sessions]..[idx] = renewed;
    } else {
      sessions = [renewed, ...sessions];
    }
  }

  Future<void> reportPatientProfileView(Patient patient) async {
    try {
      await api.post('/api/access/view', {'patientId': patient.id});
    } catch (_) {}
  }

  List<Availability> availabilityFor(String doctorId) =>
      availability.where((a) => a.doctorId == doctorId).toList()..sort((a, b) => a.dayOfWeek.compareTo(b.dayOfWeek));

  List<String> openSlots(String doctorId, DateTime date) {
    final day = date.weekday % 7;
    final dayAvail = availability.where((a) => a.doctorId == doctorId && a.dayOfWeek == day && a.isAvailable);
    final booked = appointments
        .where((a) =>
            a.doctorId == doctorId &&
            a.appointmentDate.year == date.year &&
            a.appointmentDate.month == date.month &&
            a.appointmentDate.day == date.day &&
            (a.status == 'pending' || a.status == 'confirmed'))
        .map((a) => a.appointmentTime)
        .toSet();
    return dayAvail.expand((a) => generateSlots(a.startTime, a.endTime)).where((s) => !booked.contains(s)).toList();
  }

  List<PostComment> commentsFor(String postId) =>
      comments.where((c) => c.postId == postId).toList()..sort((a, b) => a.createdDate.compareTo(b.createdDate));

  List<DoctorReview> reviewsForDoctor(String doctorId) =>
      reviews.where((r) => r.doctorId == doctorId).toList()..sort((a, b) => b.createdDate.compareTo(a.createdDate));

  DoctorReview? reviewForVisit(String visitId) => reviews.where((r) => r.visitId == visitId).firstOrNull;

  List<Achievement> achievementsFor(String doctorId) =>
      achievements.where((a) => a.doctorId == doctorId).toList()..sort((a, b) => b.createdDate.compareTo(a.createdDate));

  bool isFollowing(String doctorId) {
    final patientId = currentPatient?.id;
    if (patientId == null) return false;
    return follows.any((f) => f.patientId == patientId && f.doctorId == doctorId);
  }

  String conversationId(String patientId, String doctorId) => '${patientId}__$doctorId';

  List<ChatMessage> messagesFor({required String patientId, required String doctorId}) =>
      messages.where((m) => m.patientId == patientId && m.doctorId == doctorId).toList()
        ..sort((a, b) => a.createdDate.compareTo(b.createdDate));

  void toggleDark() {
    darkMode = !darkMode;
    notifyListeners();
  }

  void refreshUi() => notifyListeners();

  void goTo(ClinicPage next) {
    if (doctorLocked && !_allowedWhenLocked(next)) {
      lastMessage = doctorPending ? 'الحساب قيد الموافقة' : 'انتهى اشتراكك. تواصل مع الإدارة للتجديد.';
      page = ClinicPage.profile;
      notifyListeners();
      return;
    }
    page = next;
    if (next != ClinicPage.patientRecord && next != ClinicPage.messages) selectedPatientId = null;
    if (next != ClinicPage.doctorPublic && next != ClinicPage.messages) selectedDoctorId = null;
    notifyListeners();
  }

  bool _allowedWhenLocked(ClinicPage next) =>
      next == ClinicPage.home || next == ClinicPage.profile || next == ClinicPage.notifications;

  void openPatient(String patientId) {
    if (!isDoctor || doctorLocked) return;
    selectedPatientId = patientId;
    page = ClinicPage.patientRecord;
    notifyListeners();
    final patient = patientById(patientId);
    if (patient != null) {
      Future<void>.microtask(() => reportPatientProfileView(patient));
    }
  }

  void openDoctor(String doctorId) {
    selectedDoctorId = doctorId;
    page = ClinicPage.doctorPublic;
    notifyListeners();
  }

  void openMessages({String? patientId, String? doctorId}) {
    selectedPatientId = patientId;
    selectedDoctorId = doctorId;
    page = ClinicPage.messages;
    notifyListeners();
  }

  void selectRegion(String? regionId) {
    selectedRegionId = regionId;
    notifyListeners();
  }

  MapRegion? regionById(String? id) {
    if (id == null || id.isEmpty) return null;
    return regions.where((r) => r.id == id).firstOrNull;
  }

  List<Doctor> doctorsInRegion(String? regionId, {bool activeOnly = true}) {
    return doctors.where((d) {
      if (activeOnly && !d.isActive) return false;
      if (!activeOnly && d.status != 'approved') return false;
      if (regionId == null || regionId.isEmpty) return true;
      return d.regionId == regionId;
    }).toList();
  }

  Future<String?> createMapRegion({
    required String name,
    required double centerLat,
    required double centerLng,
    double zoom = 13.5,
  }) async {
    try {
      final data = await api.post('/api/regions', {
        'name': name.trim(),
        'city': serviceCity,
        'centerLat': centerLat,
        'centerLng': centerLng,
        'zoom': zoom,
      });
      await refresh();
      lastMessage = 'تم إنشاء المنطقة';
      notifyListeners();
      final region = asMap(data['region']);
      return asString(region['id']).isEmpty ? null : asString(region['id']);
    } catch (e) {
      lastMessage = _err(e);
      notifyListeners();
      return null;
    }
  }

  Future<void> updateMapRegion(String id, Map<String, dynamic> body) async {
    await _safe(() async {
      await api.patch('/api/regions/$id', body);
    }, 'تم تحديث المنطقة');
  }

  Future<void> deleteMapRegion(String id) async {
    await _safe(() async {
      await api.delete('/api/regions/$id');
    }, 'تم حذف المنطقة');
  }

  Future<void> assignDoctorsToRegion(String regionId, List<String> doctorIds, {bool replace = true}) async {
    await _safe(() async {
      await api.post('/api/regions/$regionId/doctors', {
        'doctorIds': doctorIds,
        'replace': replace,
      });
    }, 'تم تحديث أطباء المنطقة');
  }

  String _err(Object error) {
    if (error is ApiException) return error.message;
    return 'تعذر الاتصال بالخادم. تحقق من الشبكة.';
  }

  OtpPurpose _purposeFromApi(String value) => switch (value) {
        'register' => OtpPurpose.register,
        'reset' || 'resetPassword' => OtpPurpose.resetPassword,
        _ => OtpPurpose.login,
      };

  String _purposeApi(OtpPurpose purpose) => switch (purpose) {
        OtpPurpose.register => 'register',
        OtpPurpose.resetPassword => 'reset',
        OtpPurpose.login => 'login',
      };

  void _setOtpFromApi(Map<String, dynamic> data) {
    final now = DateTime.now();
    final phone = asString(data['phone'], asString(data['email']));
    otp = OtpChallenge(
      email: phone,
      code: asString(data['demoCode']),
      purpose: _purposeFromApi(asString(data['purpose'], 'login')),
      expiresAt: now.add(const Duration(minutes: 5)),
      sentAt: now,
    );
    authError = null;
  }

  Future<bool> login(String phone) async {
    authError = null;
    if (!validPhone(phone)) {
      authError = 'رقم هاتف غير صالح (07XXXXXXXXX)';
      notifyListeners();
      return false;
    }
    busy = true;
    notifyListeners();
    try {
      final data = await api.post('/api/auth/otp/request', {'phone': phone.trim()});
      _setOtpFromApi(data);
      lastMessage = 'أدخل رمز التحقق المرسل إلى واتساب';
      return true;
    } catch (e) {
      authError = _err(e);
      return false;
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  Future<String?> register({
    required String role,
    required String fullName,
    required String phone,
    String email = '',
    String city = 'بغداد',
    String specialty = 'طب عام',
    String clinicName = '',
    String licenseNumber = '',
    String gender = 'Male',
    String dateOfBirth = '',
    String bloodType = 'O+',
    int yearsOfExperience = 0,
    String biography = '',
    String qualifications = '',
    String workingHours = '',
    String? profilePhotoPath,
  }) async {
    if (!validPhone(phone)) return 'رقم هاتف غير صالح (07XXXXXXXXX)';
    if (fullName.trim().isEmpty) return 'الاسم مطلوب';
    if (email.trim().isNotEmpty && !validEmail(email)) return 'بريد إلكتروني غير صالح';
    if (role == 'doctor' && licenseNumber.trim().isEmpty) return 'رقم الترخيص مطلوب';
    if (role == 'doctor' && clinicName.trim().isEmpty) return 'اسم العيادة مطلوب';
    pendingProfilePhotoPath = profilePhotoPath;
    authError = null;
    busy = true;
    notifyListeners();
    try {
      final data = await api.post('/api/auth/register', {
        'role': role,
        'fullName': fullName.trim(),
        'email': email.trim(),
        'phone': phone.trim(),
        'city': city,
        'specialty': specialty,
        'clinicName': clinicName,
        'licenseNumber': licenseNumber,
        'gender': gender,
        'dateOfBirth': dateOfBirth,
        'bloodType': bloodType,
        'yearsOfExperience': yearsOfExperience,
        'biography': biography.trim(),
        'qualifications': qualifications.trim(),
        'workingHours': workingHours.trim(),
      });
      _setOtpFromApi(data);
      lastMessage = 'أدخل رمز التحقق المرسل إلى واتساب';
      return null;
    } catch (e) {
      return _err(e);
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  Future<String?> requestPasswordReset(String email) async {
    authError = null;
    if (!validEmail(email)) return 'بريد إلكتروني غير صالح';
    try {
      final data = await api.post('/api/auth/password/reset-request', {'email': email.trim()});
      _setOtpFromApi(data);
      lastMessage = 'أدخل رمز التحقق لإعادة تعيين كلمة المرور';
      notifyListeners();
      return null;
    } catch (e) {
      return _err(e);
    }
  }

  Future<String?> verifyOtp(String code) async {
    final challenge = otp;
    if (challenge == null) return 'لا توجد عملية تحقق نشطة';
    busy = true;
    notifyListeners();
    try {
      final data = await api.post('/api/auth/otp/verify', {
        'phone': challenge.email,
        'email': challenge.email,
        'code': code.trim(),
      });
      authError = null;
      otp = null;
      if (data['resetReady'] == true) {
        resetEmail = asString(data['email'], challenge.email);
        lastMessage = 'تم التحقق. عيّن كلمة مرور جديدة';
        return null;
      }
      await _applyAuth(data);
      return null;
    } catch (e) {
      authError = _err(e);
      return authError;
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  Future<String?> resendOtp() async {
    final challenge = otp;
    if (challenge == null) return 'لا توجد عملية تحقق نشطة';
    if (DateTime.now().difference(challenge.sentAt).inSeconds < 30) {
      return 'انتظر قليلاً قبل إعادة الإرسال';
    }
    try {
      final data = await api.post('/api/auth/otp/resend', {
        'phone': challenge.email,
        'email': challenge.email,
        'purpose': _purposeApi(challenge.purpose),
      });
      _setOtpFromApi(data);
      lastMessage = 'تم إرسال رمز جديد';
      notifyListeners();
      return null;
    } catch (e) {
      return _err(e);
    }
  }

  void cancelOtp() {
    otp = null;
    resetEmail = null;
    authError = null;
    pendingProfilePhotoPath = null;
    notifyListeners();
  }

  Future<String?> completePasswordReset(String password, String confirm) async {
    final email = resetEmail;
    if (email == null) return 'لا توجد عملية استعادة نشطة';
    if (password.length < 6) return 'كلمة المرور قصيرة';
    if (password != confirm) return 'كلمتا المرور غير متطابقتين';
    try {
      await api.post('/api/auth/password/reset', {'email': email, 'password': password});
      resetEmail = null;
      lastMessage = 'تم تعيين كلمة المرور. سجّل الدخول';
      notifyListeners();
      return null;
    } catch (e) {
      return _err(e);
    }
  }

  void logout() {
    PushService.instance.onLoggedOut();
    currentUser = null;
    api.token = null;
    otp = null;
    resetEmail = null;
    pendingProfilePhotoPath = null;
    page = ClinicPage.home;
    selectedPatientId = null;
    selectedDoctorId = null;
    authError = null;
    likedPostIds.clear();
    notifyListeners();
  }

  Future<void> refresh() async {
    final data = await api.get('/api/bootstrap');
    applyBootstrap(data);
  }

  Future<void> _applyAuth(Map<String, dynamic> data) async {
    api.token = asString(data['token']);
    if (api.token == null || api.token!.isEmpty) {
      throw ApiException('تعذر إكمال تسجيل الدخول');
    }
    await refresh();
    final photoPath = pendingProfilePhotoPath;
    pendingProfilePhotoPath = null;
    if (photoPath != null && photoPath.isNotEmpty) {
      final url = await uploadPath(photoPath);
      if (url != null && url.isNotEmpty) await updateProfilePhoto(url);
    }
    page = ClinicPage.home;
    lastMessage = 'مرحباً ${currentUser?.fullName.split(' ').first ?? ''}';
    await PushService.instance.onLoggedIn();
  }

  void openFromNotification({required String type, required String link}) {
    goTo(pageFromNotification(type: type, link: link));
  }

  Future<void> registerDeviceToken(String token, {String platform = 'android'}) async {
    try {
      await api.put('/api/me/device-token', {
        'token': token,
        'platform': platform,
        'deviceInfo': platform,
      });
    } catch (_) {}
  }

  Future<void> unregisterDeviceToken(String token) async {
    try {
      await api.delete('/api/me/device-token', {'token': token});
    } catch (_) {}
  }

  Future<String?> uploadPath(String path) async {
    try {
      final data = await api.upload(path);
      return asString(data['url'], asString(data['fileUrl']));
    } catch (_) {
      return null;
    }
  }

  Future<void> updateProfilePhoto(String url) async {
    try {
      await api.patch('/api/me', {'profilePhoto': url});
      if (isDoctor && currentDoctor != null) {
        await api.patch('/api/doctors/${currentDoctor!.id}', {'profilePhoto': url});
      } else if (isPatient && currentPatient != null) {
        await api.patch('/api/patients/${currentPatient!.id}', {'profilePhoto': url});
      }
      await refresh();
    } catch (e) {
      lastMessage = _err(e);
    }
    notifyListeners();
  }

  Future<void> _safe(Future<void> Function() action, String ok) async {
    try {
      await action();
      await refresh();
      lastMessage = ok;
    } catch (e) {
      lastMessage = _err(e);
    }
    notifyListeners();
  }

  Future<void> updatePatientProfile(Patient updated) async {
    try {
      await api.patch('/api/patients/${updated.id}', {
        'fullName': updated.fullName,
        'phone': updated.phone,
        'email': updated.email,
        'city': updated.city,
        'gender': updated.gender,
        'bloodType': updated.bloodType,
        'dateOfBirth': updated.dateOfBirth,
        'allergies': updated.allergies,
        'chronicDiseases': updated.chronicDiseases,
        'currentMedications': updated.currentMedications,
        'emergencyContactName': updated.emergencyContactName,
        'emergencyContactRelationship': updated.emergencyContactRelationship,
        'emergencyContactPhone': updated.emergencyContactPhone,
        'medicalHistory': updated.medicalHistory,
        'vaccinationRecords': updated.vaccinationRecords,
        'surgeryRecords': updated.surgeryRecords,
        'profilePhoto': updated.profilePhoto,
      });
      await api.patch('/api/me', {'fullName': updated.fullName, 'phone': updated.phone});
      await refresh();
      lastMessage = 'تم حفظ الملف الشخصي';
    } catch (e) {
      lastMessage = _err(e);
    }
    notifyListeners();
  }

  Future<void> updateDoctorProfile(Doctor updated) async {
    try {
      await api.patch('/api/doctors/${updated.id}', {
        'fullName': updated.fullName,
        'phone': updated.phone,
        'email': updated.email,
        'specialty': updated.specialty,
        'clinicName': updated.clinicName,
        'city': updated.city,
        'licenseNumber': updated.licenseNumber,
        'biography': updated.biography,
        'workingHours': updated.workingHours,
        'qualifications': updated.qualifications,
        'yearsOfExperience': updated.yearsOfExperience,
        'certificates': updated.certificates,
        'gender': updated.gender,
        'dateOfBirth': updated.dateOfBirth,
        'profilePhoto': updated.profilePhoto,
      });
      await api.patch('/api/me', {'fullName': updated.fullName, 'phone': updated.phone});
      await refresh();
      lastMessage = 'تم حفظ الملف الشخصي';
    } catch (e) {
      lastMessage = _err(e);
    }
    notifyListeners();
  }

  Future<void> addCertificate(String name) async {
    final doctor = currentDoctor;
    if (doctor == null || name.trim().isEmpty) return;
    doctor.certificates = [...doctor.certificates, name.trim()];
    await updateDoctorProfile(doctor);
    lastMessage = 'تمت إضافة الشهادة';
    notifyListeners();
  }

  Future<void> removeCertificate(String name) async {
    final doctor = currentDoctor;
    if (doctor == null) return;
    doctor.certificates = doctor.certificates.where((c) => c != name).toList();
    await updateDoctorProfile(doctor);
  }

  Future<void> changePassword(String current, String next) async {
    try {
      await api.patch('/api/me', {'currentPassword': current, 'nextPassword': next});
      lastMessage = 'تم تغيير كلمة المرور';
    } catch (e) {
      lastMessage = _err(e);
    }
    notifyListeners();
  }

  Future<void> bookAppointment({
    required Doctor doctor,
    required DateTime date,
    required String time,
    required String reason,
  }) async {
    final patient = currentPatient;
    final user = currentUser;
    if (patient == null || user == null) {
      lastMessage = 'يرجى إكمال تسجيل بياناتك كمريض أولاً';
      notifyListeners();
      return;
    }
    await _safe(() async {
      await api.post('/api/appointments', {
        'doctorId': doctor.id,
        'doctorUserId': doctor.userId,
        'doctorName': doctor.fullName,
        'doctorSpecialty': doctor.specialty,
        'patientId': patient.id,
        'patientUserId': user.id,
        'patientName': patient.fullName,
        'patientPhone': patient.phone,
        'appointmentDate': isoDate(date),
        'appointmentTime': time,
        'reason': reason,
      });
    }, 'تم إرسال طلب الموعد');
    page = ClinicPage.appointments;
    notifyListeners();
  }

  Future<void> _setAppointmentStatus(Appointment appt, String status, String ok) async {
    await _safe(() async {
      await api.patch('/api/appointments/${appt.id}', {'status': status});
    }, ok);
  }

  Future<void> confirmAppointment(Appointment appt) => _setAppointmentStatus(appt, 'confirmed', 'تم تأكيد الموعد');
  Future<void> declineAppointment(Appointment appt) => _setAppointmentStatus(appt, 'declined', 'تم رفض الموعد');
  Future<void> cancelAppointment(Appointment appt) => _setAppointmentStatus(appt, 'cancelled', 'تم إلغاء الموعد');
  Future<void> completeAppointment(Appointment appt) => _setAppointmentStatus(appt, 'completed', 'تم تعليم الموعد كمكتمل');

  Future<void> updateAppointmentDetails(Appointment appt, {DateTime? date, String? time, String? notes, String? status}) async {
    await _safe(() async {
      await api.patch('/api/appointments/${appt.id}', {
        if (date != null) 'appointmentDate': isoDate(date),
        if (time != null) 'appointmentTime': time,
        if (notes != null) 'notes': notes,
        if (status != null) 'status': status,
      });
    }, 'تم تحديث الموعد');
  }

  Future<void> addAvailability({required int dayOfWeek, required String start, required String end}) async {
    if (start.compareTo(end) >= 0) {
      lastMessage = 'يجب أن يكون وقت البدء قبل وقت الانتهاء';
      notifyListeners();
      return;
    }
    await _safe(() async {
      await api.post('/api/availability', {'dayOfWeek': dayOfWeek, 'startTime': start, 'endTime': end});
    }, 'تمت إضافة وقت التوفر');
  }

  Future<void> toggleAvailability(Availability slot) async {
    await _safe(() async {
      await api.patch('/api/availability/${slot.id}', {'isAvailable': !slot.isAvailable});
    }, 'تم تحديث التوفر');
  }

  Future<void> deleteAvailability(Availability slot) async {
    await _safe(() async {
      await api.delete('/api/availability/${slot.id}');
    }, 'تم حذف وقت التوفر');
  }

  Future<AccessSession?> grantAccess(Patient patient, {String method = 'qr_scan'}) async {
    final doctor = currentDoctor;
    if (doctor == null || doctorLocked) return null;
    try {
      await api.post('/api/access', {'patientId': patient.id, 'method': method});
      await refresh();
      lastMessage = 'تم إنشاء جلسة وصول لـ ${patient.fullName}';
      notifyListeners();
      return sessions.where((s) => s.doctorId == doctor.id && s.patientId == patient.id && s.isActive()).firstOrNull;
    } catch (e) {
      lastMessage = _err(e);
      notifyListeners();
      return null;
    }
  }

  void _grantLocalAccess(Patient patient, {required String method}) {
    _renewLocalWriteWindow(patient, method: method);
  }

  /// يفتح السجل فوراً ثم يزامن جلسة الوصول مع الخادم في الخلفية.
  Future<void> openPatientAfterAccess(Patient patient, {String method = 'qr_scan'}) async {
    final doctor = currentDoctor;
    if (doctor == null || doctorLocked) return;

    if (method == 'qr_scan') {
      _renewLocalWriteWindow(patient, method: method);
    } else if (!hasAccess(patient.id)) {
      _grantLocalAccess(patient, method: method);
    }

    openPatient(patient.id);

    // مزامنة غير حاجبة — فتح السجل لا ينتظر الشبكة.
    Future<void>.microtask(() async {
      try {
        await api.post('/api/access', {'patientId': patient.id, 'method': method});
        await refresh();
        lastMessage = method == 'qr_scan'
            ? 'جلسة QR نشطة — يمكنك التعديل والرفع لمدة 10 دقائق'
            : 'تم فتح سجل ${patient.fullName}';
        notifyListeners();
      } catch (e) {
        if (!hasAccess(patient.id)) {
          sessions = sessions.where((s) => s.id != 'pending_${patient.id}').toList();
        }
        lastMessage = _err(e);
        notifyListeners();
      }
    });
  }

  Future<void> addVisit({
    required Patient patient,
    required String symptoms,
    required String diagnosis,
    required String treatmentPlan,
    required String medications,
    required String followUp,
    required String visitTime,
  }) async {
    if (!hasAccess(patient.id)) return;
    if (!canWritePatient(patient.id)) {
      lastMessage = 'انتهت مهلة التعديل (10 دقائق بعد مسح QR). امسح الرمز مجدداً.';
      notifyListeners();
      return;
    }
    await _safe(() async {
      await api.post('/api/visits', {
        'patientId': patient.id,
        'patientName': patient.fullName,
        'patientUserId': patient.userId,
        'visitTime': visitTime,
        'symptoms': symptoms,
        'diagnosis': diagnosis,
        'treatmentPlan': treatmentPlan,
        'medications': medications,
        'followUp': followUp,
      });
    }, 'تم حفظ الزيارة');
  }

  Future<String?> editVisit(
    Visit visit, {
    required String symptoms,
    required String diagnosis,
    required String treatmentPlan,
    required String medications,
    required String followUp,
  }) async {
    if (!canWritePatient(visit.patientId)) {
      return 'انتهت مهلة التعديل (10 دقائق بعد مسح QR). امسح الرمز مجدداً.';
    }
    try {
      await api.patch('/api/visits/${visit.id}', {
        'symptoms': symptoms,
        'diagnosis': diagnosis,
        'treatmentPlan': treatmentPlan,
        'medications': medications,
        'followUp': followUp,
      });
      await refresh();
      lastMessage = 'تم تعديل الزيارة';
      notifyListeners();
      return null;
    } catch (e) {
      return _err(e);
    }
  }

  Future<void> addFile({
    required Patient patient,
    required String fileType,
    required String fileName,
    required String description,
    String fileUrl = '',
  }) async {
    if (!hasAccess(patient.id)) return;
    if (!canWritePatient(patient.id)) {
      lastMessage = 'انتهت مهلة الرفع (10 دقائق بعد مسح QR). امسح الرمز مجدداً.';
      notifyListeners();
      return;
    }
    await _safe(() async {
      await api.post('/api/files', {
        'patientId': patient.id,
        'fileType': fileType,
        'fileName': fileName.isEmpty ? 'ملف-$fileType' : fileName,
        'description': description,
        'fileUrl': fileUrl,
      });
    }, 'تم إضافة الملف الطبي');
  }

  Future<void> markRead(AppNotification notif) async {
    try {
      await api.post('/api/notifications/${notif.id}/read');
      notif.read = true;
    } catch (_) {
      notif.read = true;
    }
    notifyListeners();
  }

  Future<void> markAllRead() async {
    try {
      await api.post('/api/notifications/read-all');
    } catch (_) {}
    for (final n in myNotifications) {
      n.read = true;
    }
    notifyListeners();
  }

  Future<void> toggleLike(Post post) async {
    try {
      await api.post('/api/posts/${post.id}/like');
      await refresh();
    } catch (e) {
      lastMessage = _err(e);
    }
    notifyListeners();
  }

  Future<void> addComment(Post post, String content) async {
    if (content.trim().isEmpty) return;
    await _safe(() async {
      await api.post('/api/posts/${post.id}/comments', {'content': content.trim()});
    }, 'تم إضافة التعليق');
  }

  Future<void> createPost(String content, String category) async {
    if (content.trim().isEmpty) return;
    await _safe(() async {
      await api.post('/api/posts', {'content': content.trim(), 'category': category});
    }, 'تم نشر المنشور');
  }

  Future<void> sendMessage({
    required String patientId,
    required String doctorId,
    required String content,
    String messageType = 'text',
    Map<String, dynamic>? questionnaire,
  }) async {
    final trimmed = content.trim();
    if (trimmed.isEmpty && messageType == 'text') {
      lastMessage = 'اكتب رسالة أولاً';
      notifyListeners();
      return;
    }
    try {
      await api.post('/api/messages', {
        'patientId': patientId,
        'doctorId': doctorId,
        'conversationId': conversationId(patientId, doctorId),
        'content': trimmed.isEmpty ? (questionnaire != null ? 'استبيان متابعة' : '') : trimmed,
        'messageType': messageType,
        if (questionnaire != null) 'questionnaire': questionnaire,
      });
      await refresh();
      lastMessage = null;
    } catch (e) {
      lastMessage = _err(e);
    }
    notifyListeners();
  }

  Future<void> markConversationRead(String id) async {
    try {
      await api.post('/api/messages/read', {'conversationId': id});
    } catch (_) {}
  }

  Future<void> submitReview({
    required Doctor doctor,
    required Patient patient,
    required int rating,
    required String comment,
    Visit? visit,
  }) async {
    await _safe(() async {
      await api.post('/api/reviews', {
        'doctorId': doctor.id,
        'doctorName': doctor.fullName,
        'patientId': patient.id,
        'patientName': patient.fullName,
        'visitId': visit?.id,
        'rating': rating,
        'comment': comment,
      });
    }, 'تم حفظ التقييم');
  }

  Future<void> addAchievement({
    required String title,
    required String description,
    required String achievedAt,
    String imageUrl = '',
  }) async {
    await _safe(() async {
      await api.post('/api/achievements', {
        'title': title,
        'description': description,
        'achievedAt': achievedAt,
        'imageUrl': imageUrl,
      });
    }, 'تمت إضافة الإنجاز');
  }

  Future<void> deleteAchievement(Achievement item) async {
    await _safe(() async {
      await api.delete('/api/achievements/${item.id}');
    }, 'تم حذف الإنجاز');
  }

  Future<void> toggleFollow(Doctor doctor) async {
    try {
      if (isFollowing(doctor.id)) {
        await api.delete('/api/doctors/${doctor.id}/follow');
      } else {
        await api.post('/api/doctors/${doctor.id}/follow');
      }
      await refresh();
    } catch (e) {
      lastMessage = _err(e);
    }
    notifyListeners();
  }

  Future<void> deactivateAccount() async {
    await _safe(() async {
      await api.post('/api/me/deactivate');
    }, 'تم إيقاف الحساب');
    logout();
  }

  Future<void> setNotificationPrefs({bool? email, bool? sms, bool? push}) async {
    final user = currentUser;
    if (user == null) return;
    final previousEmail = user.notifyEmail;
    final previousSms = user.notifySms;
    final previousPush = user.notifyPush;
    if (email != null) user.notifyEmail = email;
    if (sms != null) user.notifySms = sms;
    if (push != null) user.notifyPush = push;
    notifyListeners();
    try {
      await api.patch('/api/me', {
        if (email != null) 'notifyEmail': email,
        if (sms != null) 'notifySms': sms,
        if (push != null) 'notifyPush': push,
      });
    } catch (e) {
      user.notifyEmail = previousEmail;
      user.notifySms = previousSms;
      user.notifyPush = previousPush;
      lastMessage = _err(e);
      notifyListeners();
    }
  }

  /// حذف نهائي للحساب وكل سجلاته ومستنداته. يعيد رسالة الخطأ عند الفشل.
  Future<String?> deleteAccount() async {
    try {
      await api.delete('/api/me');
    } catch (e) {
      return _err(e);
    }
    logout();
    return null;
  }

  List<Patient> searchPatients({String qr = '', String name = '', String phone = '', String id = ''}) {
    var found = patients;
    if (qr.trim().isNotEmpty) {
      final q = qr.trim().toLowerCase();
      found = found
          .where((p) =>
              p.qrCodeData.toLowerCase() == q ||
              p.patientId.toLowerCase() == q ||
              p.qrCodeData.toLowerCase().contains(q) ||
              p.patientId.toLowerCase().contains(q))
          .toList();
    }
    if (name.trim().isNotEmpty) {
      final q = name.trim().toLowerCase();
      found = found.where((p) => p.fullName.toLowerCase().contains(q)).toList();
    }
    if (phone.trim().isNotEmpty) {
      found = found.where((p) => p.phone.contains(phone.trim())).toList();
    }
    if (id.trim().isNotEmpty) {
      final q = id.trim().toLowerCase();
      found = found.where((p) => p.patientId.toLowerCase().contains(q) || p.nationalId.contains(id.trim())).toList();
    }
    return found;
  }

  String isoDate(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  void applyBootstrap(Map<String, dynamic> data) {
    final user = asMap(data['user']);
    if (user.isNotEmpty) {
      currentUser = ClinicUser(
        id: asString(user['id']),
        email: asString(user['email']),
        fullName: asString(user['fullName']),
        role: asString(user['role']),
        phone: asString(user['phone']),
        profilePhoto: asString(user['profilePhoto']),
        notifyEmail: asBool(user['notifyEmail'], true),
        notifySms: asBool(user['notifySms'], true),
        notifyPush: asBool(user['notifyPush'], true),
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
        ..accessDurationHours = asInt(settings['access_duration_hours'], branding.accessDurationHours)
        ..diagnosisEditHours = asInt(settings['diagnosis_edit_hours'], branding.diagnosisEditHours);
    }
    doctors = asMapList(data['doctors']).map(_doctor).toList();
    patients = asMapList(data['patients']).map(_patient).toList();
    if (currentUser != null && currentUser!.role == 'doctor' && currentUser!.profilePhoto.isEmpty) {
      final mine = doctors.where((d) => d.userId == currentUser!.id).firstOrNull;
      if (mine != null && mine.profilePhoto.isNotEmpty) {
        currentUser!.profilePhoto = mine.profilePhoto;
      } else {
        currentUser!.profilePhoto = resolveDoctorPhoto(name: currentUser!.fullName);
      }
    }
    posts = asMapList(data['posts']).map(_post).toList();
    comments = asMapList(data['comments']).map(_comment).toList();
    visits = asMapList(data['visits']).map(_visit).toList();
    files = asMapList(data['files']).map(_file).toList();
    sessions = asMapList(data['sessions']).map(_session).toList();
    availability = asMapList(data['availability']).map(_availability).toList();
    appointments = asMapList(data['appointments']).map(_appointment).toList();
    notifications = asMapList(data['notifications']).map(_notification).toList();
    messages = asMapList(data['messages']).map(_message).toList();
    reviews = asMapList(data['reviews']).map(_review).toList();
    achievements = asMapList(data['achievements']).map(_achievement).toList();
    follows = asMapList(data['follows'])
        .map((f) => (patientId: asString(f['patientId']), doctorId: asString(f['doctorId'])))
        .toList();
    cards = asMapList(data['cards']).map(_card).toList();
    regions = asMapList(data['regions']).map(_region).toList();
    likedPostIds
      ..clear()
      ..addAll((data['likedPostIds'] as List? ?? []).map((e) => e.toString()));
  }

  MapRegion _region(Map<String, dynamic> r) => MapRegion(
        id: asString(r['id']),
        name: asString(r['name']),
        city: asString(r['city'], serviceCity),
        centerLat: asDouble(r['centerLat']),
        centerLng: asDouble(r['centerLng']),
        zoom: asDouble(r['zoom'], 13.5),
        sortOrder: asInt(r['sortOrder']),
        isActive: asBool(r['isActive'], true),
      );

  Doctor _doctor(Map<String, dynamic> d) => Doctor(
        id: asString(d['id']),
        userId: d['userId']?.toString(),
        fullName: asString(d['fullName']),
        specialty: asString(d['specialty']),
        clinicName: asString(d['clinicName']),
        city: serviceCity, // الخدمة مغلقة على بغداد فقط
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
        yearsOfExperience: asInt(d['yearsOfExperience']),
        qualifications: asString(d['qualifications']),
        biography: asString(d['biography']),
        workingHours: asString(d['workingHours']),
        profilePhoto: resolveDoctorPhoto(id: asString(d['id']), name: asString(d['fullName']), existing: asString(d['profilePhoto'])),
        featured: asBool(d['featured']),
        rating: asDouble(d['rating'], 4.5),
        reviews: asInt(d['reviews']),
        certificates: asStrings(d['certificates']),
        latitude: d['latitude'] == null ? null : asDouble(d['latitude']),
        longitude: d['longitude'] == null ? null : asDouble(d['longitude']),
        regionId: d['regionId']?.toString(),
      );

  Patient _patient(Map<String, dynamic> p) => Patient(
        id: asString(p['id']),
        userId: p['userId']?.toString(),
        fullName: asString(p['fullName']),
        patientId: asString(p['patientId']),
        qrCodeData: asString(p['qrCodeData'], asString(p['patientId'])),
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
      );

  Post _post(Map<String, dynamic> p) => Post(
        id: asString(p['id']),
        doctorId: asString(p['doctorId']),
        doctorName: asString(p['doctorName']),
        content: asString(p['content']),
        category: asString(p['category']),
        createdDate: asDate(p['createdDate']),
        status: asString(p['status'], 'published'),
        likesCount: asInt(p['likesCount']),
        commentsCount: asInt(p['commentsCount']),
        imageUrl: asString(p['imageUrl'], asStrings(p['images']).firstOrNull ?? ''),
        images: asStrings(p['images']),
      );

  PostComment _comment(Map<String, dynamic> c) => PostComment(
        id: asString(c['id']),
        postId: asString(c['postId']),
        authorName: asString(c['authorName']),
        content: asString(c['content']),
        createdDate: asDate(c['createdDate']),
      );

  Visit _visit(Map<String, dynamic> v) => Visit(
        id: asString(v['id']),
        doctorId: asString(v['doctorId']),
        doctorName: asString(v['doctorName']),
        doctorSpecialty: asString(v['doctorSpecialty']),
        patientId: asString(v['patientId']),
        patientName: asString(v['patientName']),
        visitDate: asDate(v['visitDate']),
        createdDate: asDate(v['createdDate'] ?? v['visitDate']),
        visitTime: asString(v['visitTime']),
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
        status: asString(f['status'], 'active'),
      );

  AccessSession _session(Map<String, dynamic> s) => AccessSession(
        id: asString(s['id']),
        patientId: asString(s['patientId']),
        patientUserId: s['patientUserId']?.toString(),
        doctorId: asString(s['doctorId']),
        patientName: asString(s['patientName']),
        doctorName: asString(s['doctorName']),
        status: asString(s['status'], 'active'),
        grantedAt: asDate(s['grantedAt']),
        expiresAt: asDate(s['expiresAt']),
        durationHours: asInt(s['durationHours'], 24),
        accessMethod: asString(s['accessMethod'], 'qr_scan'),
      );

  Availability _availability(Map<String, dynamic> a) => Availability(
        id: asString(a['id']),
        doctorId: asString(a['doctorId']),
        doctorName: asString(a['doctorName']),
        dayOfWeek: asInt(a['dayOfWeek']),
        startTime: asString(a['startTime']),
        endTime: asString(a['endTime']),
        isAvailable: asBool(a['isAvailable'], true),
      );

  Appointment _appointment(Map<String, dynamic> a) => Appointment(
        id: asString(a['id']),
        doctorId: asString(a['doctorId']),
        doctorUserId: a['doctorUserId']?.toString(),
        doctorName: asString(a['doctorName']),
        doctorSpecialty: asString(a['doctorSpecialty']),
        patientId: asString(a['patientId']),
        patientUserId: a['patientUserId']?.toString(),
        patientName: asString(a['patientName']),
        patientPhone: asString(a['patientPhone']),
        appointmentDate: asDate(a['appointmentDate']),
        appointmentTime: asString(a['appointmentTime']),
        reason: asString(a['reason']),
        status: asString(a['status'], 'pending'),
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

  ChatMessage _message(Map<String, dynamic> m) => ChatMessage(
        id: asString(m['id']),
        conversationId: asString(m['conversationId'], '${asString(m['patientId'])}__${asString(m['doctorId'])}'),
        patientId: asString(m['patientId']),
        doctorId: asString(m['doctorId']),
        senderUserId: asString(m['senderUserId']),
        senderName: asString(m['senderName']),
        senderRole: asString(m['senderRole']),
        content: asString(m['content']),
        messageType: asString(m['messageType'], 'text'),
        questionnaire: m['questionnaire'] is Map ? asMap(m['questionnaire']) : null,
        read: asBool(m['read']),
        createdDate: asDate(m['createdDate']),
      );

  DoctorReview _review(Map<String, dynamic> r) => DoctorReview(
        id: asString(r['id']),
        doctorId: asString(r['doctorId']),
        doctorName: asString(r['doctorName']),
        patientId: asString(r['patientId']),
        patientName: asString(r['patientName']),
        visitId: asString(r['visitId']),
        rating: asInt(r['rating']),
        comment: asString(r['comment']),
        createdDate: asDate(r['createdDate']),
      );

  Achievement _achievement(Map<String, dynamic> a) => Achievement(
        id: asString(a['id']),
        doctorId: asString(a['doctorId']),
        title: asString(a['title']),
        description: asString(a['description']),
        achievedAt: asString(a['achievedAt']),
        imageUrl: asString(a['imageUrl']),
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
}

class ClinicScope extends InheritedNotifier<ClinicStore> {
  const ClinicScope({super.key, required ClinicStore store, required super.child}) : super(notifier: store);

  /// للاستخدام داخل build — يشترك في التحديثات فيُعاد بناء الودجت عند تغيّر الحالة.
  static ClinicStore of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<ClinicScope>();
    assert(scope != null, 'ClinicScope not found');
    return scope!.notifier!;
  }

  /// قراءة بلا اشتراك — آمنة داخل initState والمؤقّتات ومعالجات الأحداث.
  static ClinicStore read(BuildContext context) {
    final scope = context.getInheritedWidgetOfExactType<ClinicScope>();
    assert(scope != null, 'ClinicScope not found');
    return scope!.notifier!;
  }
}
