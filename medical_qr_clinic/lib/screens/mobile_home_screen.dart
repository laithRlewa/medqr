import 'package:flutter/material.dart';

import '../models/models.dart';
import '../state/clinic_store.dart';
import '../theme/clinic_style.dart';
import '../widgets/brand_logo.dart';
import '../widgets/clinic_icon.dart';
import '../widgets/mobile_kit.dart';
import '../widgets/ui.dart';

class MobileHomeScreen extends StatefulWidget {
  const MobileHomeScreen({super.key});

  @override
  State<MobileHomeScreen> createState() => _MobileHomeScreenState();
}

class _MobileHomeScreenState extends State<MobileHomeScreen> {
  String search = '';

  @override
  Widget build(BuildContext context) {
    final store = ClinicScope.of(context);
    final name = store.currentDoctor?.fullName ?? store.currentPatient?.fullName ?? store.currentUser?.fullName ?? '';
    final first = name.split(' ').first;
    final upcoming = store.myAppointments.where((a) => a.status == 'confirmed' || a.status == 'pending').firstOrNull;
    final doctors = store.featuredDoctors.where((d) {
      if (search.isEmpty) return true;
      return d.fullName.contains(search) || d.specialty.contains(search);
    }).toList();
    final pendingCount = store.isDoctor ? store.myAppointments.where((a) => a.status == 'pending').length : 0;

    return ListView(
      padding: clinicPadding(context),
      children: [
        Row(
          children: [
            const BrandLogo(size: 38),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(greetingFor(DateTime.now()), style: const TextStyle(color: ClinicColors.muted, fontSize: 11)),
                  Text(
                    store.isDoctor ? 'د. $first' : first,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: ClinicColors.primaryDeep),
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: () => store.goTo(ClinicPage.profile),
              child: PhotoAvatar(name: name, size: 38, photo: store.currentUser?.profilePhoto),
            ),
            const SizedBox(width: 6),
            Stack(
              children: [
                CircleIconBtn(
                  icon: Icons.notifications_none_rounded,
                  size: 38,
                  color: ClinicColors.tint,
                  onTap: () => store.goTo(ClinicPage.notifications),
                ),
                if (store.unreadCount > 0)
                  Positioned(
                    left: 6,
                    top: 6,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(color: Color(0xFFE53935), shape: BoxShape.circle),
                    ),
                  ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),
        SoftCard(
          padding: const EdgeInsets.all(12),
          color: ClinicColors.primaryDeep,
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      store.isDoctor ? 'عيادتك اليوم' : 'صحتك أولاً',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      store.isDoctor
                          ? (pendingCount > 0 ? '$pendingCount طلب بانتظار التأكيد' : 'إدارة المواعيد والمرضى')
                          : 'احجز · امسح · تابع سجلاتك',
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.82), fontSize: 12),
                    ),
                  ],
                ),
              ),
              if (store.isPatient)
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: ClinicColors.primaryDeep,
                    minimumSize: const Size(0, 36),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                  onPressed: () => store.goTo(ClinicPage.doctorsMap),
                  child: const Text('الخريطة', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                )
              else
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: ClinicColors.primaryDeep,
                    minimumSize: const Size(0, 36),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                  onPressed: () => store.goTo(ClinicPage.scanQr),
                  child: const Text('مسح QR', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        SoftCard(
          radius: ClinicRadii.pill,
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          child: Row(
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 6),
                child: Icon(Icons.search, color: ClinicColors.muted, size: 20),
              ),
              Expanded(
                child: TextField(
                  onChanged: (v) => setState(() => search = v),
                  onSubmitted: (_) {
                    if (store.isPatient) store.goTo(ClinicPage.bookAppointment);
                  },
                  decoration: InputDecoration(
                    hintText: store.isDoctor ? 'ابحث عن مريض أو تخصص' : 'ابحث عن طبيب أو تخصص',
                    hintStyle: const TextStyle(fontSize: 13),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    filled: false,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        const _SectionTitle('كل الخدمات'),
        const SizedBox(height: 8),
        GridView.count(
          crossAxisCount: 4,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: 0.86,
          children: store.isDoctor
              ? [
                  _QuickAction(ClinicIcons.medicalCheckUp, 'مسح QR', ClinicColors.primary, () => store.goTo(ClinicPage.scanQr)),
                  _QuickAction(ClinicIcons.medicalApp, 'لوحتي', ClinicColors.accent, () => store.goTo(ClinicPage.dashboard)),
                  _QuickAction(ClinicIcons.patient, 'مرضاي', ClinicColors.primaryDeep, () => store.goTo(ClinicPage.myPatients)),
                  _QuickAction(ClinicIcons.appointment, 'المواعيد', ClinicColors.available, () => store.goTo(ClinicPage.appointments)),
                  _QuickAction(ClinicIcons.hospital, 'المناطق', ClinicColors.primary, () => store.goTo(ClinicPage.regionsManage)),
                  _QuickAction(ClinicIcons.waitingRoom, 'التوفر', ClinicColors.accent, () => store.goTo(ClinicPage.availability)),
                  _QuickAction(ClinicIcons.medicalBill, 'إحصائيات', ClinicColors.primaryDeep, () => store.goTo(ClinicPage.doctorStats)),
                  _QuickAction(ClinicIcons.nurse, 'المجتمع', ClinicColors.available, () => store.goTo(ClinicPage.social)),
                ]
              : [
                  _QuickAction(ClinicIcons.maleDoctor, 'بحث طبيب', ClinicColors.primary, () => store.goTo(ClinicPage.bookAppointment)),
                  _QuickAction(ClinicIcons.hospital, 'الخريطة', ClinicColors.accent, () => store.goTo(ClinicPage.doctorsMap)),
                  _QuickAction(ClinicIcons.medicalRecord, 'رمزي', ClinicColors.primaryDeep, () => store.goTo(ClinicPage.dashboard)),
                  _QuickAction(ClinicIcons.prescription, 'سجلاتي', ClinicColors.available, () => store.goTo(ClinicPage.myRecords)),
                  _QuickAction(ClinicIcons.appointment, 'مواعيدي', ClinicColors.primary, () => store.goTo(ClinicPage.appointments)),
                  _QuickAction(ClinicIcons.onlineConsultation, 'الرسائل', ClinicColors.accent, () => store.goTo(ClinicPage.messages)),
                  _QuickAction(ClinicIcons.nurse, 'المجتمع', ClinicColors.primaryDeep, () => store.goTo(ClinicPage.social)),
                  _QuickAction(ClinicIcons.emergencyCall, 'الإشعارات', ClinicColors.available, () => store.goTo(ClinicPage.notifications)),
                ],
        ),
        if (upcoming != null) ...[
          const SizedBox(height: 14),
          const _SectionTitle('الموعد القادم'),
          const SizedBox(height: 8),
          SoftCard(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                Row(
                  children: [
                    PhotoAvatar(name: store.isDoctor ? upcoming.patientName : upcoming.doctorName, size: 44),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            store.isDoctor ? upcoming.patientName : 'د. ${upcoming.doctorName}',
                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                          ),
                          Text(
                            store.isDoctor ? upcoming.reason : upcoming.doctorSpecialty,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: ClinicColors.muted, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    StatusChip(
                      label: upcoming.status == 'confirmed' ? 'مؤكد' : 'معلّق',
                      color: upcoming.status == 'confirmed' ? ClinicColors.available : const Color(0xFFE0A100),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(color: ClinicColors.tint, borderRadius: BorderRadius.circular(12)),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today_outlined, size: 14, color: ClinicColors.primary),
                      const SizedBox(width: 6),
                      Text(dateFmt.format(upcoming.appointmentDate), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                      const Spacer(),
                      const Icon(Icons.schedule, size: 14, color: ClinicColors.primary),
                      const SizedBox(width: 6),
                      Text(upcoming.appointmentTime, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(child: GhostButton(label: 'المواعيد', onTap: () => store.goTo(ClinicPage.appointments))),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OrangeButton(
                        label: store.isDoctor ? 'فتح' : 'الطبيب',
                        onTap: () {
                          if (store.isDoctor) {
                            final patient = store.patientById(upcoming.patientId);
                            if (patient != null) store.openPatientAfterAccess(patient, method: 'search');
                          } else {
                            store.openDoctor(upcoming.doctorId);
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
        if (store.isPatient || doctors.isNotEmpty) ...[
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(child: _SectionTitle(store.isDoctor ? 'أطباء الشبكة' : 'أطباء مميزون')),
              TextButton(
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                onPressed: () => store.goTo(store.isPatient ? ClinicPage.bookAppointment : ClinicPage.social),
                child: const Text('الكل', style: TextStyle(color: ClinicColors.primary, fontWeight: FontWeight.w800, fontSize: 13)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 188,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: doctors.length,
              separatorBuilder: (_, _) => const SizedBox(width: 10),
              itemBuilder: (context, i) {
                final doc = doctors[i];
                return FeaturedDoctorCard(doctor: doc, onTap: () => store.openDoctor(doc.id));
              },
            ),
          ),
        ],
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: ClinicColors.primaryDeep),
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction(this.asset, this.label, this.color, this.onTap);
  final String asset;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ClinicIconBadge(asset, size: 36, iconSize: 24, color: color.withValues(alpha: 0.14), radius: 12),
          const SizedBox(height: 6),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 10.5),
          ),
        ],
      ),
    );
  }
}
