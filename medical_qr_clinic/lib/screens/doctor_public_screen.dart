import 'package:flutter/material.dart';

import '../models/models.dart';
import '../state/clinic_store.dart';
import '../theme/clinic_style.dart';
import '../widgets/media.dart';
import '../widgets/mobile_kit.dart';
import '../widgets/ui.dart';
import 'mobile_consultant_screen.dart';

class DoctorPublicScreen extends StatelessWidget {
  const DoctorPublicScreen({super.key, required this.doctorId});
  final String doctorId;

  @override
  Widget build(BuildContext context) {
    if (isMobileLayout(context)) return MobileConsultantScreen(doctorId: doctorId);
    final store = ClinicScope.of(context);
    final doctor = store.doctorById(doctorId);
    if (doctor == null) return const Center(child: Text('الطبيب غير موجود'));
    final posts = store.posts.where((p) => p.doctorId == doctor.id && p.status == 'published').toList();
    final reviews = store.reviewsForDoctor(doctor.id);
    final achievements = store.achievementsFor(doctor.id);
    final owner = store.currentDoctor?.id == doctor.id;

    return ListView(
      padding: clinicPadding(context),
      children: [
        PageHeader(
          title: 'د. ${doctor.fullName}',
          subtitle: '${doctor.specialty} · ${doctor.clinicName} · ${doctor.city}',
          actions: [
            if (store.isPatient) ...[
              OutlinedButton.icon(
                onPressed: () => store.toggleFollow(doctor),
                icon: Icon(store.isFollowing(doctor.id) ? Icons.favorite : Icons.favorite_border),
                label: Text(store.isFollowing(doctor.id) ? 'إلغاء المتابعة' : 'متابعة'),
              ),
              const SizedBox(width: 8),
              OutlinedButton(onPressed: () => store.openMessages(patientId: store.currentPatient?.id, doctorId: doctor.id), child: const Text('مراسلة')),
              const SizedBox(width: 8),
              FilledButton(onPressed: () => store.goTo(ClinicPage.bookAppointment), child: const Text('حجز موعد')),
            ],
            if (owner) FilledButton(onPressed: () => store.goTo(ClinicPage.profile), child: const Text('تعديل ملفي')),
          ],
        ),
        SoftCard(
          child: Row(
            children: [
              PhotoAvatar(name: doctor.fullName, size: 96, photo: doctor.profilePhoto),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('د. ${doctor.fullName}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 20)),
                    const SizedBox(height: 4),
                    Text(doctor.specialty, style: const TextStyle(color: ClinicColors.primary, fontWeight: FontWeight.w700)),
                    Text('${doctor.clinicName} · ${doctor.city}', style: const TextStyle(color: ClinicColors.muted, fontSize: 13)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.star_rounded, color: ClinicColors.star, size: 18),
                        const SizedBox(width: 4),
                        Text('${doctor.rating.toStringAsFixed(1)} (${doctor.reviews})', style: const TextStyle(fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SectionCard(
          title: 'نبذة',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(spacing: 24, children: [
                InfoRow('الخبرة', '${doctor.yearsOfExperience} سنة'),
                InfoRow('ساعات العمل', doctor.workingHours),
                InfoRow('المؤهلات', doctor.qualifications),
                InfoRow('التقييم', '${doctor.rating.toStringAsFixed(1)} (${doctor.reviews} تقييم)'),
                InfoRow('الحالة', doctor.isActive ? 'متاح للحجز' : 'غير متاح حالياً'),
              ]),
              const SizedBox(height: 8),
              Text(doctor.biography.isEmpty ? 'لا توجد نبذة بعد' : doctor.biography),
              if (doctor.certificates.isNotEmpty) ...[
                const SizedBox(height: 8),
                const Text('الشهادات', style: TextStyle(fontWeight: FontWeight.w800)),
                for (final c in doctor.certificates)
                  ListTile(
                    dense: true,
                    leading: const Icon(Icons.workspace_premium_outlined),
                    title: Text(c.contains('/') ? 'شهادة' : c),
                    trailing: c.startsWith('/') || c.startsWith('http') ? IconButton(onPressed: () => openMedia(c), icon: const Icon(Icons.open_in_new)) : null,
                  ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 12),
        SectionCard(
          title: 'الإنجازات',
          child: Column(
            children: [
              if (owner)
                Align(
                  alignment: Alignment.centerLeft,
                  child: OutlinedButton.icon(
                    onPressed: () => _addAchievement(context, store),
                    icon: const Icon(Icons.add),
                    label: const Text('إضافة إنجاز'),
                  ),
                ),
              if (achievements.isEmpty) const Text('لا توجد إنجازات بعد'),
              for (final a in achievements)
                ListTile(
                  leading: a.imageUrl.isEmpty ? const Icon(Icons.emoji_events_outlined) : NetworkPhoto(a.imageUrl, width: 48, height: 48),
                  title: Text(a.title),
                  subtitle: Text([if (a.achievedAt.isNotEmpty) a.achievedAt, a.description].where((e) => e.isNotEmpty).join(' · ')),
                  trailing: owner ? IconButton(onPressed: () => store.deleteAchievement(a), icon: const Icon(Icons.delete_outline)) : null,
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SectionCard(
          title: 'تقييمات المرضى',
          child: reviews.isEmpty
              ? const Text('لا توجد تقييمات بعد')
              : Column(children: [
                  for (final r in reviews)
                    ListTile(
                      title: Text('${'★' * r.rating}  ${r.patientName}'),
                      subtitle: Text(r.comment.isEmpty ? 'بدون تعليق' : r.comment),
                    ),
                ]),
        ),
        const SizedBox(height: 12),
        SectionCard(
          title: 'المنشورات',
          child: posts.isEmpty
              ? const Text('لا توجد منشورات')
              : Column(children: [
                  for (final p in posts)
                    ListTile(
                      title: Text(p.content),
                      subtitle: Text('${postCategoryAr(p.category)} · ${fromNow(p.createdDate)} · ${p.likesCount} إعجاب'),
                      leading: p.photoList.isEmpty ? null : NetworkPhoto(p.photoList.first, width: 48, height: 48),
                    ),
                ]),
        ),
      ],
    );
  }

  Future<void> _addAchievement(BuildContext context, ClinicStore store) async {
    final title = TextEditingController();
    final desc = TextEditingController();
    final date = TextEditingController();
    var image = '';
    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: const Text('إنجاز جديد'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: title, decoration: const InputDecoration(labelText: 'العنوان')),
              TextField(controller: date, decoration: const InputDecoration(labelText: 'التاريخ')),
              TextField(controller: desc, decoration: const InputDecoration(labelText: 'الوصف')),
              TextButton(onPressed: () async {
                final url = await pickAndUpload(store, imagesOnly: true);
                if (url != null) setLocal(() => image = url);
              }, child: Text(image.isEmpty ? 'صورة اختيارية' : 'تم رفع الصورة')),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
            FilledButton(onPressed: () {
              store.addAchievement(title: title.text, description: desc.text, achievedAt: date.text, imageUrl: image);
              Navigator.pop(ctx);
            }, child: const Text('حفظ')),
          ],
        ),
      ),
    );
    title.dispose();
    desc.dispose();
    date.dispose();
  }
}
