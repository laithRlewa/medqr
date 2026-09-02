import 'package:flutter/material.dart';

import '../models/models.dart';
import '../state/clinic_store.dart';
import '../theme/clinic_style.dart';
import '../widgets/clinic_icon.dart';
import '../widgets/mobile_kit.dart';
import '../widgets/ui.dart';
import 'doctor_profile_screen.dart';
import 'patient_profile_screen.dart';

class MoreMenuScreen extends StatelessWidget {
  const MoreMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = ClinicScope.of(context);
    final name = store.currentDoctor?.fullName ?? store.currentPatient?.fullName ?? store.currentUser?.fullName ?? 'مستخدم';
    final subtitle = store.isDoctor
        ? '${store.currentDoctor?.specialty ?? 'طبيب'} · ${store.currentDoctor?.clinicName ?? ''}'
        : store.currentPatient?.patientId ?? 'مريض';

    return ListView(
      padding: clinicPadding(context),
      children: [
        SoftCard(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              PhotoAvatar(name: name, size: 52, photo: store.currentUser?.profilePhoto),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(store.isDoctor ? 'د. $name' : name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: ClinicColors.primaryDeep)),
                    const SizedBox(height: 2),
                    Text(subtitle, style: const TextStyle(color: ClinicColors.muted, fontSize: 12)),
                    const SizedBox(height: 6),
                    StatusChip(
                      label: store.isDoctor
                          ? (store.doctorPending ? 'بانتظار الموافقة' : (store.doctorLocked ? 'اشتراك غير نشط' : 'حساب نشط'))
                          : 'حساب مريض',
                      color: store.doctorLocked ? Colors.orange.shade800 : ClinicColors.primary,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        if (store.isPatient) ...[
          const _SectionLabel('رعايتي'),
          _item(context, ClinicIcons.medicalRecord, 'رمزي الطبي', 'عرض رمز QR وبيانات الطوارئ', () => store.goTo(ClinicPage.dashboard)),
          _item(context, ClinicIcons.prescription, 'سجلاتي الطبية', 'الزيارات والملفات والتشخيصات', () => store.goTo(ClinicPage.myRecords)),
          _item(context, ClinicIcons.appointment, 'مواعيدي', 'الطلبات والجدول', () => store.goTo(ClinicPage.appointments)),
          const _SectionLabel('البحث والحجز'),
          _item(context, ClinicIcons.hospital, 'خريطة الأطباء', 'اختر منطقتك وشاهد أطباءها', () => store.goTo(ClinicPage.doctorsMap)),
          _item(context, ClinicIcons.maleDoctor, 'البحث عن طبيب', 'احجز موعداً مع متخصص', () => store.goTo(ClinicPage.bookAppointment)),
        ],
        if (store.isDoctor) ...[
          const _SectionLabel('عملي اليومي'),
          _item(context, ClinicIcons.medicalCheckUp, 'مسح رمز المريض', 'افتح السجل عبر QR أو البحث', () => store.goTo(ClinicPage.scanQr)),
          _item(context, ClinicIcons.medicalApp, 'لوحة التحكم', 'إحصائيات العيادة والطلبات', () => store.goTo(ClinicPage.dashboard)),
          _item(context, ClinicIcons.patient, 'المرضى', 'الجلسات والسجلات المتاحة', () => store.goTo(ClinicPage.myPatients)),
          _item(context, ClinicIcons.appointment, 'المواعيد', 'تأكيد الطلبات وإدارة الجدول', () => store.goTo(ClinicPage.appointments)),
          const _SectionLabel('إدارة العيادة'),
          _item(context, ClinicIcons.hospital, 'مناطق الخريطة', 'حدد منطقة وأضف إليها الأطباء', () => store.goTo(ClinicPage.regionsManage)),
          _item(context, ClinicIcons.waitingRoom, 'أوقات التوفر', 'حدد ساعات عملك', () => store.goTo(ClinicPage.availability)),
          _item(context, ClinicIcons.insurance, 'التقويم', 'عرض أسبوعي لمواعيدك', () => store.goTo(ClinicPage.doctorCalendar)),
          _item(context, ClinicIcons.medicalBill, 'الإحصائيات', 'أداء العيادة والزيارات', () => store.goTo(ClinicPage.doctorStats)),
        ],
        const _SectionLabel('التواصل'),
        _item(context, ClinicIcons.onlineConsultation, 'الرسائل', 'محادثاتك مع ${store.isDoctor ? 'المرضى' : 'الأطباء'}', () => store.goTo(ClinicPage.messages)),
        _item(context, ClinicIcons.nurse, 'المجتمع الطبي', 'المنشورات والتوعية', () => store.goTo(ClinicPage.social)),
        _item(context, ClinicIcons.emergencyCall, 'الإشعارات', store.unreadCount > 0 ? '${store.unreadCount} غير مقروء' : 'لا توجد رسائل جديدة', () => store.goTo(ClinicPage.notifications)),
        const _SectionLabel('الحساب'),
        _item(context, store.isDoctor ? ClinicIcons.maleDoctor : ClinicIcons.patient, 'تعديل الملف الشخصي', 'بياناتك الطبية والمهنية', () {
          Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => store.isDoctor ? const DoctorProfileScreen() : const PatientProfileScreen(),
          ));
        }),
        const SizedBox(height: 4),
        SoftCard(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: ListTile(
            leading: const CircleAvatar(backgroundColor: ClinicColors.bgDeep, child: Icon(Icons.settings_rounded, color: ClinicColors.primary)),
            title: const Text('الإعدادات', style: TextStyle(fontWeight: FontWeight.w800)),
            subtitle: const Text('المظهر والإشعارات وحذف الحساب'),
            trailing: const Icon(Icons.chevron_left, color: ClinicColors.muted, size: 18),
            onTap: () => store.goTo(ClinicPage.settings),
          ),
        ),
        const SizedBox(height: 8),
        SoftCard(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: ListTile(
            leading: const CircleAvatar(backgroundColor: ClinicColors.bgDeep, child: Icon(Icons.logout, color: ClinicColors.primary)),
            title: const Text('تسجيل الخروج', style: TextStyle(fontWeight: FontWeight.w800)),
            subtitle: const Text('إنهاء الجلسة الحالية'),
            onTap: store.logout,
          ),
        ),
      ],
    );
  }

  static Widget _item(BuildContext context, String asset, String title, String subtitle, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: SoftCard(
        padding: EdgeInsets.zero,
        onTap: onTap,
        child: ListTile(
          dense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
          leading: ClinicIconBadge(asset, size: 36, iconSize: 22, radius: 10),
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
          subtitle: Text(subtitle, style: const TextStyle(color: ClinicColors.muted, fontSize: 11)),
          trailing: const Icon(Icons.chevron_left, color: ClinicColors.muted, size: 18),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 6, 4, 10),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 16,
            decoration: BoxDecoration(color: ClinicColors.primary, borderRadius: BorderRadius.circular(4)),
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: ClinicColors.primaryDeep),
          ),
        ],
      ),
    );
  }
}
