enum ClinicPage {
  home,
  dashboard,
  bookAppointment,
  appointments,
  myPatients,
  scanQr,
  notifications,
  profile,
  availability,
  myRecords,
  patientRecord,
  doctorPublic,
  doctorStats,
  doctorCalendar,
  social,
  messages,
  doctorsMap,
  regionsManage,
  settings,
}

enum OtpPurpose { login, register, resetPassword }

class OtpChallenge {
  OtpChallenge({
    required this.email,
    required this.code,
    required this.purpose,
    required this.expiresAt,
    required this.sentAt,
  });

  final String email;
  final String code;
  final OtpPurpose purpose;
  final DateTime expiresAt;
  final DateTime sentAt;

  Duration get remaining => expiresAt.difference(DateTime.now());
}

class ClinicUser {
  ClinicUser({
    required this.id,
    required this.email,
    required this.fullName,
    required this.role,
    this.phone = '',
    this.profilePhoto = '',
    this.password = '',
    this.notifyEmail = true,
    this.notifySms = true,
    this.notifyPush = true,
  });

  final String id;
  String email;
  String fullName;
  final String role;
  String phone;
  String profilePhoto;
  String password;
  bool notifyEmail;
  bool notifySms;
  bool notifyPush;
}

class Branding {
  Branding({
    this.appName = 'الرمز الطبي العراقي',
    this.appLogo = '',
    this.primaryColor = '#1A7A99',
    this.secondaryColor = '#E4F1F5',
    this.fontFamily = 'Cairo',
    this.accessDurationHours = 24,
    this.diagnosisEditHours = 24,
  });

  String appName;
  String appLogo;
  String primaryColor;
  String secondaryColor;
  String fontFamily;
  int accessDurationHours;
  int diagnosisEditHours;
}

class Doctor {
  Doctor({
    required this.id,
    required this.fullName,
    required this.specialty,
    required this.clinicName,
    required this.city,
    required this.phone,
    required this.email,
    required this.licenseNumber,
    required this.status,
    required this.subscriptionStatus,
    required this.createdDate,
    this.userId,
    this.gender = 'Male',
    this.dateOfBirth = '',
    this.subscriptionStart,
    this.subscriptionEnd,
    this.yearsOfExperience = 0,
    this.qualifications = '',
    this.biography = '',
    this.workingHours = '',
    this.profilePhoto = '',
    this.featured = false,
    this.rating = 4.5,
    this.reviews = 0,
    this.latitude,
    this.longitude,
    this.regionId,
    List<String>? certificates,
  }) : certificates = certificates ?? [];

  final String id;
  String? userId;
  String fullName;
  String gender;
  String dateOfBirth;
  String specialty;
  String clinicName;
  String city;
  String phone;
  String email;
  String licenseNumber;
  String status;
  String subscriptionStatus;
  DateTime? subscriptionStart;
  DateTime? subscriptionEnd;
  int yearsOfExperience;
  String qualifications;
  String biography;
  String workingHours;
  String profilePhoto;
  List<String> certificates;
  bool featured;
  double rating;
  int reviews;
  double? latitude;
  double? longitude;
  String? regionId;
  final DateTime createdDate;

  bool get isApproved => status == 'approved';
  bool get isActive => isApproved && subscriptionStatus == 'active';
}

class Patient {
  Patient({
    required this.id,
    required this.fullName,
    required this.patientId,
    required this.phone,
    required this.email,
    required this.city,
    required this.gender,
    required this.bloodType,
    required this.status,
    required this.createdDate,
    this.userId,
    this.qrCodeData = '',
    this.nationalId = '',
    this.dateOfBirth = '',
    this.allergies = '',
    this.chronicDiseases = '',
    this.currentMedications = '',
    this.emergencyContactName = '',
    this.emergencyContactRelationship = '',
    this.emergencyContactPhone = '',
    this.medicalHistory = '',
    this.vaccinationRecords = '',
    this.surgeryRecords = '',
    this.profilePhoto = '',
  });

  final String id;
  String fullName;
  String patientId;
  String qrCodeData;
  String? userId;
  String phone;
  String email;
  String city;
  String gender;
  String bloodType;
  String status;
  String nationalId;
  String dateOfBirth;
  String allergies;
  String chronicDiseases;
  String currentMedications;
  String emergencyContactName;
  String emergencyContactRelationship;
  String emergencyContactPhone;
  String medicalHistory;
  String vaccinationRecords;
  String surgeryRecords;
  String profilePhoto;
  final DateTime createdDate;

  int? get ageYears {
    final dob = DateTime.tryParse(dateOfBirth);
    if (dob == null) return null;
    final now = DateTime.now();
    var age = now.year - dob.year;
    if (now.month < dob.month || (now.month == dob.month && now.day < dob.day)) age--;
    return age;
  }
}

class Post {
  Post({
    required this.id,
    required this.doctorId,
    required this.doctorName,
    required this.content,
    required this.category,
    required this.createdDate,
    this.status = 'published',
    this.likesCount = 0,
    this.commentsCount = 0,
    this.imageUrl = '',
    List<String>? images,
  }) : images = images ?? [];

  final String id;
  final String doctorId;
  final String doctorName;
  String content;
  String category;
  String status;
  int likesCount;
  int commentsCount;
  String imageUrl;
  List<String> images;
  final DateTime createdDate;

  List<String> get photoList => images.isNotEmpty ? images : (imageUrl.isEmpty ? [] : [imageUrl]);
}

class PostComment {
  PostComment({
    required this.id,
    required this.postId,
    required this.authorName,
    required this.content,
    required this.createdDate,
  });

  final String id;
  final String postId;
  final String authorName;
  final String content;
  final DateTime createdDate;
}

class Appointment {
  Appointment({
    required this.id,
    required this.doctorId,
    required this.doctorName,
    required this.patientId,
    required this.patientName,
    required this.appointmentDate,
    required this.appointmentTime,
    required this.status,
    this.doctorUserId,
    this.patientUserId,
    this.doctorSpecialty = '',
    this.patientPhone = '',
    this.reason = '',
    this.durationMinutes = 30,
  });

  final String id;
  final String doctorId;
  final String? doctorUserId;
  final String doctorName;
  final String doctorSpecialty;
  final String patientId;
  final String? patientUserId;
  final String patientName;
  final String patientPhone;
  final DateTime appointmentDate;
  final String appointmentTime;
  final String reason;
  final int durationMinutes;
  String status;

  DateTime get dateTime {
    final parts = appointmentTime.split(':');
    final h = int.tryParse(parts.elementAtOrNull(0) ?? '') ?? 0;
    final m = int.tryParse(parts.elementAtOrNull(1) ?? '') ?? 0;
    return DateTime(appointmentDate.year, appointmentDate.month, appointmentDate.day, h, m);
  }
}

class Availability {
  Availability({
    required this.id,
    required this.doctorId,
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    this.doctorName = '',
    this.isAvailable = true,
  });

  final String id;
  final String doctorId;
  final String doctorName;
  final int dayOfWeek;
  final String startTime;
  final String endTime;
  bool isAvailable;
}

class Visit {
  Visit({
    required this.id,
    required this.doctorId,
    required this.doctorName,
    required this.patientId,
    required this.patientName,
    required this.visitDate,
    required this.createdDate,
    this.doctorSpecialty = '',
    this.visitTime = '',
    this.symptoms = '',
    this.diagnosis = '',
    this.treatmentPlan = '',
    this.prescribedMedications = '',
    this.followUpNotes = '',
  });

  final String id;
  final String doctorId;
  final String doctorName;
  final String doctorSpecialty;
  final String patientId;
  final String patientName;
  final DateTime visitDate;
  final DateTime createdDate;
  String visitTime;
  String symptoms;
  String diagnosis;
  String treatmentPlan;
  String prescribedMedications;
  String followUpNotes;
}

class MedicalFile {
  MedicalFile({
    required this.id,
    required this.fileType,
    required this.createdDate,
    this.doctorId = '',
    this.doctorName = '',
    this.patientId = '',
    this.fileName = '',
    this.description = '',
    this.fileUrl = '',
    this.status = 'active',
  });

  final String id;
  final String fileType;
  final String doctorId;
  final String doctorName;
  final String patientId;
  final String fileName;
  final String description;
  final String fileUrl;
  final String status;
  final DateTime createdDate;
}

class AccessSession {
  AccessSession({
    required this.id,
    required this.patientId,
    required this.doctorId,
    required this.patientName,
    required this.doctorName,
    required this.status,
    required this.grantedAt,
    required this.expiresAt,
    this.patientUserId,
    this.durationHours = 24,
    this.accessMethod = 'qr_scan',
  });

  final String id;
  final String patientId;
  final String? patientUserId;
  final String doctorId;
  final String patientName;
  final String doctorName;
  String status;
  final DateTime grantedAt;
  final DateTime expiresAt;
  final int durationHours;
  final String accessMethod;

  bool isActive([DateTime? now]) => status == 'active' && expiresAt.isAfter(now ?? DateTime.now());

  /// نهاية مهلة التعديل/الرفع (10 دقائق من مسح QR).
  DateTime get writeDeadline => grantedAt.add(const Duration(minutes: 10));

  bool canWrite([DateTime? now]) {
    final n = now ?? DateTime.now();
    return isActive(n) && accessMethod == 'qr_scan' && n.isBefore(writeDeadline);
  }

  Duration writeRemaining([DateTime? now]) {
    final left = writeDeadline.difference(now ?? DateTime.now());
    return left.isNegative ? Duration.zero : left;
  }
}

class AppNotification {
  AppNotification({
    required this.id,
    required this.userId,
    required this.title,
    required this.message,
    required this.createdDate,
    this.read = false,
    this.type = 'system',
    this.link = '',
  });

  final String id;
  final String userId;
  final String title;
  final String message;
  final String type;
  final String link;
  bool read;
  final DateTime createdDate;
}

class ChatMessage {
  ChatMessage({
    required this.id,
    required this.conversationId,
    required this.patientId,
    required this.doctorId,
    required this.senderUserId,
    required this.senderName,
    required this.content,
    required this.createdDate,
    this.senderRole = '',
    this.messageType = 'text',
    this.questionnaire,
    this.read = false,
  });

  final String id;
  final String conversationId;
  final String patientId;
  final String doctorId;
  final String senderUserId;
  final String senderName;
  final String senderRole;
  final String content;
  final String messageType;
  final Map<String, dynamic>? questionnaire;
  bool read;
  final DateTime createdDate;
}

class DoctorReview {
  DoctorReview({
    required this.id,
    required this.doctorId,
    required this.patientId,
    required this.rating,
    required this.createdDate,
    this.doctorName = '',
    this.patientName = '',
    this.visitId = '',
    this.comment = '',
  });

  final String id;
  final String doctorId;
  final String doctorName;
  final String patientId;
  final String patientName;
  final String visitId;
  final int rating;
  final String comment;
  final DateTime createdDate;
}

class Achievement {
  Achievement({
    required this.id,
    required this.doctorId,
    required this.title,
    required this.createdDate,
    this.description = '',
    this.achievedAt = '',
    this.imageUrl = '',
  });

  final String id;
  final String doctorId;
  final String title;
  final String description;
  final String achievedAt;
  final String imageUrl;
  final DateTime createdDate;
}

class PaymentCard {
  PaymentCard({
    required this.doctorId,
    this.bankName = '',
    this.cardNumber = '',
    this.cardHolderName = '',
    this.cardExpiry = '',
    this.cardCvv = '',
  });

  final String doctorId;
  String bankName;
  String cardNumber;
  String cardHolderName;
  String cardExpiry;
  String cardCvv;
}

class MapRegion {
  MapRegion({
    required this.id,
    required this.name,
    required this.centerLat,
    required this.centerLng,
    this.city = 'بغداد',
    this.zoom = 13.5,
    this.sortOrder = 0,
    this.isActive = true,
  });

  final String id;
  String name;
  String city;
  double centerLat;
  double centerLng;
  double zoom;
  int sortOrder;
  bool isActive;
}
