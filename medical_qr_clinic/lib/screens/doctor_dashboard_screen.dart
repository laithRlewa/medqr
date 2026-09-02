import 'package:flutter/material.dart';

import '../models/models.dart';
import '../state/clinic_store.dart';
import '../theme/clinic_style.dart';
import '../widgets/clinic_icon.dart';
import '../widgets/mobile_kit.dart';
import '../widgets/ui.dart';

class DoctorDashboardScreen extends StatelessWidget {
  const DoctorDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = ClinicScope.of(context);
    final doctor = store.currentDoctor;
    if (doctor == null) {
      return const Center(child: Text('لم يتم العثور على ملف الطبيب'));
    }
    if (doctor.status == 'pending') {
      return const _Gate(
        icon: Icons.hourglass_top_rounded,
        color: Color(0xFFE0A100),
        title: 'الحساب قيد الموافقة',
        message: 'حسابك كطبيب بانتظار موافقة المدير. ستصلك إشعار عند التفعيل.',
      );
    }
    if (doctor.subscriptionStatus != 'active') {
      return _Gate(
        icon: Icons.lock_outline_rounded,
        color: const Color(0xFFC62828),
        title: 'انتهى اشتراكك',
        message: 'انتهت مدة اشتراكك ولا يمكنك الوصول إلى لوحة التحكم. يرجى التواصل مع الإدارة للتجديد.',
        extra: doctor.subscriptionEnd == null ? null : 'تاريخ انتهاء الاشتراك: ${longDateFmt.format(doctor.subscriptionEnd!)}',
        actionLabel: 'عرض ملفي الشخصي',
        onAction: () => store.goTo(ClinicPage.profile),
      );
    }

    final visits = store.visitsForDoctor(doctor.id);
    final files = store.files.where((f) => f.doctorId == doctor.id).toList();
    final sessions = store.activeSessionsForDoctor(doctor.id);
    final pending = store.myAppointments.where((a) => a.status == 'pending').toList();
    final today = store.myAppointments.where((a) {
      final d = a.appointmentDate;
      final n = DateTime.now();
      return d.year == n.year && d.month == n.month && d.day == n.day && (a.status == 'confirmed' || a.status == 'pending');
    }).toList();
    final myPosts = store.posts.where((p) => p.doctorId == doctor.id).toList();
    final uniquePatients = visits.map((v) => v.patientId).toSet().length;
    final mobile = isMobileLayout(context);

    return ListView(
      padding: clinicPadding(context),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(ClinicRadii.card),
            boxShadow: softShadow,
            gradient: const LinearGradient(
              colors: [ClinicColors.primaryDeep, ClinicColors.primary, ClinicColors.accent],
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  PhotoAvatar(name: doctor.fullName, size: 52, photo: store.currentUser?.profilePhoto),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('د. ${doctor.fullName}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 20)),
                        Text('${doctor.specialty} · ${doctor.clinicName}', style: const TextStyle(color: Color(0xFFD5EDF5), fontSize: 13)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _HeroAction(ClinicIcons.medicalCheckUp, 'مسح QR', () => store.goTo(ClinicPage.scanQr), filled: true),
                  _HeroAction(ClinicIcons.appointment, 'التقويم', () => store.goTo(ClinicPage.doctorCalendar)),
                  _HeroAction(ClinicIcons.medicalBill, 'إحصائيات', () => store.goTo(ClinicPage.doctorStats)),
                  _HeroAction(ClinicIcons.hospital, 'المناطق', () => store.goTo(ClinicPage.regionsManage)),
                  if (!mobile) _HeroAction(ClinicIcons.waitingRoom, 'التوفر', () => store.goTo(ClinicPage.availability)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SoftCard(
          onTap: () => store.goTo(ClinicPage.regionsManage),
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(color: ClinicColors.tint, borderRadius: BorderRadius.circular(14)),
                child: const Icon(Icons.map_outlined, color: ClinicColors.primary),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('مناطق الخريطة', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                    SizedBox(height: 2),
                    Text('حدد منطقة على الخريطة وأضف إليها الأطباء', style: TextStyle(color: ClinicColors.muted, fontSize: 12)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_left, color: ClinicColors.muted),
            ],
          ),
        ),
        const SizedBox(height: 16),
        LayoutBuilder(builder: (context, c) {
          final cols = c.maxWidth > 900 ? 4 : (c.maxWidth > 520 ? 2 : 2);
          final items = [
            _DashStat('المرضى', '$uniquePatients', ClinicIcons.patient, ClinicColors.primary, () => store.goTo(ClinicPage.myPatients)),
            _DashStat('الزيارات', '${visits.length}', ClinicIcons.medicalCheckUp, ClinicColors.available, null),
            _DashStat('اليوم', '${today.length}', ClinicIcons.appointment, ClinicColors.accent, () => store.goTo(ClinicPage.appointments)),
            _DashStat('جلسات نشطة', '${sessions.length}', ClinicIcons.onlineConsultation, const Color(0xFFC47A12), null),
          ];
          return GridView.count(
            crossAxisCount: cols,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: c.maxWidth > 900 ? 2.2 : 1.85,
            children: items,
          );
        }),
        if (pending.isNotEmpty) ...[
          const SizedBox(height: 20),
          _SectionTitle('طلبات بانتظار التأكيد', '${pending.length}', () => store.goTo(ClinicPage.appointments)),
          const SizedBox(height: 10),
          for (final a in pending.take(mobile ? 4 : 6)) ...[
            SoftCard(
              padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
              child: Row(
                children: [
                  PhotoAvatar(name: a.patientName, size: 46),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(a.patientName, style: const TextStyle(fontWeight: FontWeight.w800)),
                        Text(
                          '${dateFmt.format(a.appointmentDate)} · ${a.appointmentTime}',
                          style: const TextStyle(color: ClinicColors.muted, fontSize: 12),
                        ),
                        if (a.reason.isNotEmpty)
                          Text(a.reason, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, color: ClinicColors.ink)),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'تأكيد',
                    onPressed: () => store.confirmAppointment(a),
                    style: IconButton.styleFrom(backgroundColor: ClinicColors.available.withValues(alpha: 0.12)),
                    icon: const Icon(Icons.check_rounded, color: ClinicColors.available),
                  ),
                  IconButton(
                    tooltip: 'رفض',
                    onPressed: () => store.declineAppointment(a),
                    style: IconButton.styleFrom(backgroundColor: const Color(0xFFFFEBEE)),
                    icon: const Icon(Icons.close_rounded, color: Color(0xFFC62828)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
          ],
        ],
        const SizedBox(height: 12),
        LayoutBuilder(builder: (context, c) {
          final sessionsCard = SoftCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.schedule, size: 20, color: ClinicColors.primary),
                    SizedBox(width: 8),
                    Text('جلسات الوصول النشطة', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                  ],
                ),
                const SizedBox(height: 12),
                if (sessions.isEmpty)
                  const Text('لا توجد جلسات نشطة حالياً', style: TextStyle(color: ClinicColors.muted))
                else
                  for (final s in sessions)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: PhotoAvatar(name: s.patientName, size: 40),
                      title: Text(s.patientName, style: const TextStyle(fontWeight: FontWeight.w700)),
                      subtitle: Text('ينتهي: ${dateTimeFmt.format(s.expiresAt)}', style: const TextStyle(fontSize: 12)),
                      trailing: TextButton(onPressed: () => store.openPatient(s.patientId), child: const Text('عرض')),
                    ),
              ],
            ),
          );
          final visitsCard = SoftCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.history, size: 20, color: ClinicColors.primary),
                    const SizedBox(width: 8),
                    const Expanded(child: Text('الزيارات الأخيرة', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15))),
                    TextButton(onPressed: () => store.goTo(ClinicPage.myPatients), child: const Text('الكل')),
                  ],
                ),
                const SizedBox(height: 8),
                if (visits.isEmpty)
                  const Text('لا توجد زيارات بعد', style: TextStyle(color: ClinicColors.muted))
                else
                  for (final v in visits.take(5))
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: PhotoAvatar(name: v.patientName, size: 40),
                      title: Text(v.patientName, style: const TextStyle(fontWeight: FontWeight.w700)),
                      subtitle: Text(
                        '${dateFmt.format(v.visitDate)}${v.diagnosis.isEmpty ? '' : ' · ${v.diagnosis}'}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12),
                      ),
                      trailing: TextButton(
                        onPressed: () {
                          final p = store.patientById(v.patientId);
                          if (p != null) store.openPatientAfterAccess(p, method: 'search');
                        },
                        child: const Text('فتح'),
                      ),
                    ),
              ],
            ),
          );
          final postsCard = SoftCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.article_outlined, size: 20, color: ClinicColors.primary),
                    const SizedBox(width: 8),
                    const Expanded(child: Text('منشوراتي', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15))),
                    TextButton(onPressed: () => store.goTo(ClinicPage.social), child: const Text('المجتمع')),
                  ],
                ),
                const SizedBox(height: 8),
                if (myPosts.isEmpty)
                  const Text('لا توجد منشورات بعد', style: TextStyle(color: ClinicColors.muted))
                else
                  for (final p in myPosts.take(4))
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(p.content, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text('${postCategoryAr(p.category)} · ${p.likesCount} إعجاب', style: const TextStyle(fontSize: 12)),
                    ),
              ],
            ),
          );

          if (c.maxWidth < 900) {
            return Column(children: [
              sessionsCard,
              const SizedBox(height: 12),
              visitsCard,
              const SizedBox(height: 12),
              postsCard,
              const SizedBox(height: 8),
              SoftCard(
                child: Row(
                  children: [
                    const Icon(Icons.description_outlined, color: ClinicColors.primary),
                    const SizedBox(width: 10),
                    Text('${files.length} ملف طبي مرفوع', style: const TextStyle(fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
            ]);
          }
          return Column(
            children: [
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(child: sessionsCard),
                const SizedBox(width: 12),
                Expanded(child: visitsCard),
              ]),
              const SizedBox(height: 12),
              postsCard,
            ],
          );
        }),
      ],
    );
  }
}

class _HeroAction extends StatelessWidget {
  const _HeroAction(this.asset, this.label, this.onTap, {this.filled = false});
  final String asset;
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
              ClinicIcon(asset, size: 20),
              const SizedBox(width: 6),
              Text(label, style: TextStyle(fontWeight: FontWeight.w800, color: filled ? ClinicColors.primaryDeep : Colors.white, fontSize: 13)),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashStat extends StatelessWidget {
  const _DashStat(this.title, this.value, this.asset, this.color, this.onTap);
  final String title;
  final String value;
  final String asset;
  final Color color;
  final VoidCallback? onTap;

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
                Text(value, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20, color: color)),
                Text(title, style: const TextStyle(color: ClinicColors.muted, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title, this.badge, this.onAll);
  final String title;
  final String badge;
  final VoidCallback onAll;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800))),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(color: ClinicColors.tint, borderRadius: BorderRadius.circular(20)),
          child: Text(badge, style: const TextStyle(fontWeight: FontWeight.w800, color: ClinicColors.primary, fontSize: 12)),
        ),
        TextButton(onPressed: onAll, child: const Text('الكل', style: TextStyle(fontWeight: FontWeight.w800))),
      ],
    );
  }
}

class _Gate extends StatelessWidget {
  const _Gate({
    required this.icon,
    required this.color,
    required this.title,
    required this.message,
    this.extra,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String message;
  final String? extra;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: SoftCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const ClinicIllustration(ClinicArt.nurseLab, height: 120),
              const SizedBox(height: 12),
              CircleAvatar(radius: 28, backgroundColor: color.withValues(alpha: 0.15), child: Icon(icon, color: color, size: 28)),
              const SizedBox(height: 14),
              Text(title, textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              Text(message, textAlign: TextAlign.center, style: const TextStyle(color: ClinicColors.muted, height: 1.45)),
              if (extra != null) ...[const SizedBox(height: 8), Text(extra!, style: Theme.of(context).textTheme.bodySmall)],
              if (actionLabel != null) ...[
                const SizedBox(height: 16),
                OrangeButton(label: actionLabel!, onTap: onAction),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
