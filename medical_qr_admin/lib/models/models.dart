enum AdminPage {
  dashboard,
  doctors,
  doctorsMap,
  activations,
  patients,
  posts,
  users,
  appearance,
  audit,
  analytics,
  settings,
  notifications,
}

class AdminUser {
  AdminUser({
    required this.id,
    required this.email,
    required this.fullName,
    this.phone = '',
    this.role = 'admin',
    this.profilePhoto = '',
    this.languagePreference = 'ar',
    this.notifyEmail = true,
    this.notifySms = true,
  });

  final String id;
  final String email;
  String fullName;
  String phone;
  final String role;
  String profilePhoto;
  String languagePreference;
  bool notifyEmail;
  bool notifySms;
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
    this.subscriptionDuration,
    this.paymentAmount = 0,
    this.yearsOfExperience = 0,
    this.qualifications = '',
    this.biography = '',
    this.workingHours = '',
    this.profilePhoto = '',
    this.lastModifiedBy,
    this.lastModifiedAt,
    this.featured = false,
    this.regionId,
    this.latitude,
    this.longitude,
    List<String>? certificates,
  }) : certificates = certificates ?? [];

  final String id;
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
  String? subscriptionDuration;
  double paymentAmount;
  String? userId;
  int yearsOfExperience;
  String qualifications;
  String biography;
  String workingHours;
  String profilePhoto;
  List<String> certificates;
  bool featured;
  String? lastModifiedBy;
  DateTime? lastModifiedAt;
  String? regionId;
  double? latitude;
  double? longitude;
  final DateTime createdDate;
}

class MapRegion {
  MapRegion({
    required this.id,
    required this.name,
    required this.centerLat,
    required this.centerLng,
    this.city = 'بغداد',
    this.zoom = 13,
    this.isActive = true,
  });

  final String id;
  final String name;
  final String city;
  final double centerLat;
  final double centerLng;
  final double zoom;
  final bool isActive;
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
    this.lastModifiedBy,
    this.lastModifiedAt,
  });

  final String id;
  String fullName;
  String patientId;
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
  String? lastModifiedBy;
  DateTime? lastModifiedAt;
  final DateTime createdDate;
}

class Post {
  Post({
    required this.id,
    required this.doctorName,
    required this.content,
    required this.category,
    required this.createdDate,
    this.status = 'published',
    this.likesCount = 0,
    this.commentsCount = 0,
  });

  final String id;
  final String doctorName;
  final String content;
  final String category;
  String status;
  int likesCount;
  int commentsCount;
  final DateTime createdDate;
}

class AuditLog {
  AuditLog({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userRole,
    required this.actionType,
    required this.description,
    required this.createdDate,
    this.targetType,
    this.targetId,
    this.ipAddress,
    this.deviceInfo,
  });

  final String id;
  final String userId;
  final String userName;
  final String userRole;
  final String actionType;
  final String description;
  final String? targetType;
  final String? targetId;
  final String? ipAddress;
  final String? deviceInfo;
  final DateTime createdDate;
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

class ActivationLog {
  ActivationLog({
    required this.id,
    required this.doctorId,
    required this.doctorName,
    required this.adminName,
    required this.paymentAmount,
    required this.duration,
    required this.startDate,
    required this.endDate,
    required this.action,
    required this.createdDate,
  });

  final String id;
  final String doctorId;
  final String doctorName;
  final String adminName;
  final double paymentAmount;
  final String duration;
  final DateTime startDate;
  final DateTime endDate;
  final String action;
  final DateTime createdDate;
}

class PaymentCard {
  PaymentCard({
    required this.doctorId,
    required this.bankName,
    required this.cardNumber,
    required this.cardHolderName,
    required this.cardExpiry,
    this.cardCvv = '',
  });

  final String doctorId;
  final String bankName;
  final String cardNumber;
  final String cardHolderName;
  final String cardExpiry;
  final String cardCvv;
}

class Visit {
  Visit({
    required this.id,
    required this.doctorId,
    required this.doctorName,
    required this.patientId,
    required this.patientName,
    required this.visitDate,
    this.doctorSpecialty = '',
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
  final String symptoms;
  final String diagnosis;
  final String treatmentPlan;
  final String prescribedMedications;
  final String followUpNotes;
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
  });

  final String id;
  final String fileType;
  final String doctorId;
  final String doctorName;
  final String patientId;
  final String fileName;
  final String description;
  final String fileUrl;
  final DateTime createdDate;
}

class AccessSession {
  AccessSession({
    required this.id,
    required this.patientName,
    required this.doctorName,
    required this.status,
    required this.expiresAt,
  });

  final String id;
  final String patientName;
  final String doctorName;
  final String status;
  final DateTime expiresAt;
}

class PlatformUser {
  PlatformUser({required this.id, required this.email, required this.role, required this.createdDate});
  final String id;
  final String email;
  final String role;
  final DateTime createdDate;
}

class AppSetting {
  AppSetting({this.id, required this.key, required this.value, this.type = 'string', this.category = 'general'});
  String? id;
  final String key;
  String value;
  final String type;
  final String category;
}

class Branding {
  Branding({
    this.appName = 'الرمز الطبي العراقي',
    this.appLogo = '',
    this.primaryColor = '#1A7A99',
    this.secondaryColor = '#E4F1F5',
    this.fontFamily = 'Cairo',
    this.defaultTheme = 'light',
    this.accessDurationHours = '24',
    this.diagnosisEditHours = '24',
    this.defaultLanguage = 'ar',
  });

  String appName;
  String appLogo;
  String primaryColor;
  String secondaryColor;
  String fontFamily;
  String defaultTheme;
  String accessDurationHours;
  String diagnosisEditHours;
  String defaultLanguage;
}
