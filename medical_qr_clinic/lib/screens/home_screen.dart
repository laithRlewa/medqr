import 'package:flutter/material.dart';

import '../state/clinic_store.dart';
import '../widgets/brand_logo.dart';
import '../widgets/clinic_icon.dart';
import '../widgets/mobile_kit.dart';
import '../widgets/ui.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = ClinicScope.of(context);
    final first = (store.currentDoctor?.fullName ?? store.currentPatient?.fullName ?? '').split(' ').first;
    final posts = store.publishedPosts.take(3).toList();
    final doctors = store.featuredDoctors;
    final upcoming = store.myAppointments.where((a) => a.status == 'confirmed' || a.status == 'pending').firstOrNull;

    return ListView(
      padding: clinicPadding(context),
      children: [
        Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(ClinicRadii.card),
            boxShadow: softShadow,
            gradient: const LinearGradient(
              colors: [ClinicColors.primaryDeep, ClinicColors.primary, ClinicColors.accent],
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(20)),
                      child: const Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(Icons.verified_user_outlined, color: Colors.white, size: 16),
                        SizedBox(width: 6),
                        Text('منصة طبية آمنة', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                      ]),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      first.isEmpty ? 'مرحباً بك' : 'مرحباً، $first',
                      style: const TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      store.isDoctor
                          ? 'إدارة عيادتك، مسح رموز المرضى، ومتابعة المواعيد من مكان واحد.'
                          : 'سجلاتك الطبية، مواعيدك، ورمز QR الصحي — كل شيء في متناول يدك.',
                      style: const TextStyle(color: Color(0xFFD5EDF5), height: 1.5),
                    ),
                    const SizedBox(height: 18),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        if (store.isPatient) ...[
                          _HeroBtn(Icons.qr_code_2, 'رمزي الطبي', () => store.goTo(ClinicPage.dashboard), filled: true),
                          _HeroBtn(Icons.map_rounded, 'خريطة الأطباء', () => store.goTo(ClinicPage.doctorsMap)),
                          _HeroBtn(Icons.event_available_outlined, 'حجز موعد', () => store.goTo(ClinicPage.bookAppointment)),
                        ],
                        if (store.isDoctor) ...[
                          _HeroBtn(Icons.qr_code_scanner, 'مسح QR', () => store.goTo(ClinicPage.scanQr), filled: true),
                          _HeroBtn(Icons.space_dashboard_rounded, 'لوحة التحكم', () => store.goTo(ClinicPage.dashboard)),
                          _HeroBtn(Icons.pin_drop_rounded, 'مناطق الخريطة', () => store.goTo(ClinicPage.regionsManage)),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              if (MediaQuery.sizeOf(context).width > 1000) ...[
                const SizedBox(width: 24),
                const BrandLogoTile(size: 96, padding: 16, radius: 26),
              ],
            ],
          ),
        ),
        if (upcoming != null) ...[
          const SizedBox(height: 18),
          Row(
            children: [
              const Expanded(child: Text('الموعد القادم', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800))),
              TextButton(onPressed: () => store.goTo(ClinicPage.appointments), child: const Text('المواعيد')),
            ],
          ),
          SoftCard(
            child: Row(
              children: [
                PhotoAvatar(name: store.isDoctor ? upcoming.patientName : upcoming.doctorName, size: 52),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        store.isDoctor ? upcoming.patientName : 'د. ${upcoming.doctorName}',
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                      ),
                      Text(
                        '${dateFmt.format(upcoming.appointmentDate)} · ${upcoming.appointmentTime}',
                        style: const TextStyle(color: ClinicColors.muted, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                StatusChip(
                  label: upcoming.status == 'confirmed' ? 'مؤكد' : 'قيد الانتظار',
                  color: upcoming.status == 'confirmed' ? ClinicColors.available : const Color(0xFFE0A100),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 20),
        const Text('إجراءات سريعة', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
        const SizedBox(height: 10),
        LayoutBuilder(builder: (context, c) {
          final actions = store.isPatient
              ? [
                  _QuickTile(ClinicIcons.maleDoctor, 'حجز موعد', 'ابحث عن متخصص', ClinicColors.primary, () => store.goTo(ClinicPage.bookAppointment)),
                  _QuickTile(ClinicIcons.hospital, 'خريطة الأطباء', 'العيادات القريبة', ClinicColors.accent, () => store.goTo(ClinicPage.doctorsMap)),
                  _QuickTile(ClinicIcons.medicalRecord, 'رمزي الطبي', 'QR للطوارئ', ClinicColors.primaryDeep, () => store.goTo(ClinicPage.dashboard)),
                  _QuickTile(ClinicIcons.prescription, 'سجلاتي', 'زيارات وملفات', ClinicColors.available, () => store.goTo(ClinicPage.myRecords)),
                  _QuickTile(ClinicIcons.appointment, 'مواعيدي', 'الطلبات والجدول', ClinicColors.primary, () => store.goTo(ClinicPage.appointments)),
                  _QuickTile(ClinicIcons.onlineConsultation, 'الرسائل', 'تواصل مع طبيبك', ClinicColors.accent, () => store.goTo(ClinicPage.messages)),
                  _QuickTile(ClinicIcons.nurse, 'المجتمع الطبي', 'منشورات وتوعية', ClinicColors.primaryDeep, () => store.goTo(ClinicPage.social)),
                  _QuickTile(ClinicIcons.emergencyCall, 'الإشعارات', 'آخر التحديثات', ClinicColors.available, () => store.goTo(ClinicPage.notifications)),
                ]
              : [
                  _QuickTile(ClinicIcons.medicalCheckUp, 'مسح QR', 'افتح سجل مريض', ClinicColors.primary, () => store.goTo(ClinicPage.scanQr)),
                  _QuickTile(ClinicIcons.patient, 'المرضى', 'قائمة مرضاك', ClinicColors.accent, () => store.goTo(ClinicPage.myPatients)),
                  _QuickTile(ClinicIcons.appointment, 'المواعيد', 'تأكيد الطلبات', ClinicColors.primaryDeep, () => store.goTo(ClinicPage.appointments)),
                  _QuickTile(ClinicIcons.medicalBill, 'إحصائيات', 'أداء العيادة', ClinicColors.available, () => store.goTo(ClinicPage.doctorStats)),
                  _QuickTile(ClinicIcons.hospital, 'مناطق الخريطة', 'وزّع الأطباء', ClinicColors.primary, () => store.goTo(ClinicPage.regionsManage)),
                  _QuickTile(ClinicIcons.waitingRoom, 'أوقات التوفر', 'ساعات العمل', ClinicColors.accent, () => store.goTo(ClinicPage.availability)),
                  _QuickTile(ClinicIcons.onlineConsultation, 'الرسائل', 'محادثات المرضى', ClinicColors.primaryDeep, () => store.goTo(ClinicPage.messages)),
                  _QuickTile(ClinicIcons.nurse, 'المجتمع الطبي', 'انشر وتفاعل', ClinicColors.available, () => store.goTo(ClinicPage.social)),
                ];
          final cols = c.maxWidth > 900 ? 4 : 2;
          return GridView.count(
            crossAxisCount: cols,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: cols == 4 ? 2.4 : 1.9,
            children: actions,
          );
        }),
        if (doctors.isNotEmpty) ...[
          const SizedBox(height: 24),
          Row(
            children: [
              const Expanded(child: Text('أطباء مميزون', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800))),
              TextButton(
                onPressed: () => store.goTo(store.isPatient ? ClinicPage.bookAppointment : ClinicPage.social),
                child: const Text('عرض الكل', style: TextStyle(fontWeight: FontWeight.w800)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 188,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: doctors.length,
              separatorBuilder: (_, _) => const SizedBox(width: 12),
              itemBuilder: (context, i) {
                final doc = doctors[i];
                return FeaturedDoctorCard(doctor: doc, onTap: () => store.openDoctor(doc.id));
              },
            ),
          ),
        ],
        if (posts.isNotEmpty) ...[
          const SizedBox(height: 24),
          Row(
            children: [
              const Expanded(child: Text('من المجتمع الطبي', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800))),
              TextButton(onPressed: () => store.goTo(ClinicPage.social), child: const Text('الكل', style: TextStyle(fontWeight: FontWeight.w800))),
            ],
          ),
          const SizedBox(height: 8),
          for (final post in posts) ...[
            SoftCard(
              onTap: () => store.goTo(ClinicPage.social),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  PhotoAvatar(name: post.doctorName, size: 44),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('د. ${post.doctorName}', style: const TextStyle(fontWeight: FontWeight.w800)),
                        const SizedBox(height: 4),
                        Text(post.content, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(height: 1.4)),
                        const SizedBox(height: 6),
                        Text(
                          '${fromNow(post.createdDate)} · ${post.likesCount} إعجاب',
                          style: const TextStyle(color: ClinicColors.muted, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
          ],
        ],
      ],
    );
  }
}

class _HeroBtn extends StatelessWidget {
  const _HeroBtn(this.icon, this.label, this.onTap, {this.filled = false});
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: filled ? Colors.white : Colors.white24,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: filled ? ClinicColors.primaryDeep : Colors.white),
              const SizedBox(width: 6),
              Text(label, style: TextStyle(fontWeight: FontWeight.w800, color: filled ? ClinicColors.primaryDeep : Colors.white)),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickTile extends StatelessWidget {
  const _QuickTile(this.asset, this.title, this.subtitle, this.color, this.onTap);
  final String asset;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      onTap: onTap,
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          ClinicIconBadge(asset, size: 44, iconSize: 26, color: color.withValues(alpha: 0.12), radius: 14),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800)),
                Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: ClinicColors.muted, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
