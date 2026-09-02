import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../state/clinic_store.dart';
import '../widgets/clinic_icon.dart';
import '../widgets/mobile_kit.dart';
import '../widgets/ui.dart';

class DoctorProfileScreen extends StatefulWidget {
  const DoctorProfileScreen({super.key});

  @override
  State<DoctorProfileScreen> createState() => _DoctorProfileScreenState();
}

class _DoctorProfileScreenState extends State<DoctorProfileScreen> {
  bool editing = false;
  bool ready = false;
  bool saving = false;
  int section = 0;

  late final TextEditingController name;
  late final TextEditingController phone;
  late final TextEditingController email;
  late final TextEditingController clinic;
  late final TextEditingController license;
  late final TextEditingController bio;
  late final TextEditingController hours;
  late final TextEditingController quals;
  late final TextEditingController years;
  late final TextEditingController cert;
  late final TextEditingController currentPass;
  late final TextEditingController newPass;
  String city = 'بغداد';
  String specialty = 'طب عام';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (ready) return;
    final d = ClinicScope.of(context).currentDoctor;
    name = TextEditingController(text: d?.fullName ?? '');
    phone = TextEditingController(text: d?.phone ?? '');
    email = TextEditingController(text: d?.email ?? '');
    clinic = TextEditingController(text: d?.clinicName ?? '');
    license = TextEditingController(text: d?.licenseNumber ?? '');
    bio = TextEditingController(text: d?.biography ?? '');
    hours = TextEditingController(text: d?.workingHours ?? '');
    quals = TextEditingController(text: d?.qualifications ?? '');
    years = TextEditingController(text: '${d?.yearsOfExperience ?? 0}');
    cert = TextEditingController();
    currentPass = TextEditingController();
    newPass = TextEditingController();
    city = d?.city ?? 'بغداد';
    specialty = d?.specialty ?? 'طب عام';
    ready = true;
  }

  @override
  void dispose() {
    if (ready) {
      name.dispose();
      phone.dispose();
      email.dispose();
      clinic.dispose();
      license.dispose();
      bio.dispose();
      hours.dispose();
      quals.dispose();
      years.dispose();
      cert.dispose();
      currentPass.dispose();
      newPass.dispose();
    }
    super.dispose();
  }

  String _status(dynamic d) {
    if (d.status == 'pending') return 'بانتظار الموافقة';
    if (d.subscriptionStatus != 'active') return 'اشتراك غير نشط';
    return 'حساب نشط';
  }

  Color _statusColor(dynamic d) {
    if (d.status == 'pending') return const Color(0xFFE0A100);
    if (d.subscriptionStatus != 'active') return const Color(0xFFC62828);
    return ClinicColors.available;
  }

  Future<void> _save() async {
    final store = ClinicScope.of(context);
    final d = store.currentDoctor;
    if (d == null) return;
    if (!validPhone(phone.text)) {
      toast(context, 'رقم هاتف غير صالح');
      return;
    }
    if (email.text.trim().isNotEmpty && !validEmail(email.text)) {
      toast(context, 'بريد إلكتروني غير صالح');
      return;
    }
    if (license.text.trim().isEmpty) {
      toast(context, 'رقم الترخيص مطلوب');
      return;
    }
    setState(() => saving = true);
    d
      ..fullName = name.text.trim()
      ..phone = phone.text.trim()
      ..email = email.text.trim()
      ..clinicName = clinic.text.trim()
      ..licenseNumber = license.text.trim()
      ..biography = bio.text.trim()
      ..workingHours = hours.text.trim()
      ..qualifications = quals.text.trim()
      ..yearsOfExperience = int.tryParse(years.text) ?? d.yearsOfExperience
      ..city = city
      ..specialty = specialty;
    await store.updateDoctorProfile(d);
    if (!mounted) return;
    setState(() {
      saving = false;
      editing = false;
    });
    toast(context, store.lastMessage ?? 'تم حفظ الملف الشخصي');
  }

  Future<void> _pickPhoto(ClinicStore store) async {
    final file = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 85, maxWidth: 1200);
    if (file == null) return;
    final url = await store.uploadPath(file.path);
    if (url == null || url.isEmpty) {
      if (mounted) toast(context, 'تعذر رفع الصورة');
      return;
    }
    await store.updateProfilePhoto(url);
    if (mounted) toast(context, 'تم تحديث الصورة');
  }

  @override
  Widget build(BuildContext context) {
    final store = ClinicScope.of(context);
    final d = store.currentDoctor;
    if (d == null) return const Center(child: Text('لم يتم العثور على ملف الطبيب'));
    final mobile = isMobileLayout(context);

    return Scaffold(
      backgroundColor: ClinicColors.bg,
      body: ListView(
      padding: clinicPadding(context),
      children: [
        SoftCard(
          color: ClinicColors.primaryDeep,
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
          child: Column(
            children: [
              Row(
                children: [
                  Stack(
                    children: [
                      PhotoAvatar(
                        name: d.fullName,
                        size: 72,
                        photo: store.currentUser?.profilePhoto.isNotEmpty == true
                            ? store.currentUser!.profilePhoto
                            : d.profilePhoto,
                      ),
                      if (editing)
                        Positioned(
                          left: 0,
                          bottom: 0,
                          child: Material(
                            color: Colors.white,
                            shape: const CircleBorder(),
                            child: InkWell(
                              customBorder: const CircleBorder(),
                              onTap: () => _pickPhoto(store),
                              child: const Padding(
                                padding: EdgeInsets.all(6),
                                child: Icon(Icons.camera_alt_outlined, size: 16, color: ClinicColors.primaryDeep),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'د. ${d.fullName}',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${d.specialty} · ${d.clinicName}',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 12),
                        ),
                        const SizedBox(height: 8),
                        StatusChip(label: _status(d), color: _statusColor(d)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (!editing)
                    FilledButton.tonalIcon(
                      style: FilledButton.styleFrom(backgroundColor: Colors.white, foregroundColor: ClinicColors.primaryDeep),
                      onPressed: () => setState(() => editing = true),
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      label: const Text('تعديل'),
                    )
                  else ...[
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(foregroundColor: Colors.white, side: const BorderSide(color: Colors.white70)),
                      onPressed: saving ? null : () => setState(() => editing = false),
                      child: const Text('إلغاء'),
                    ),
                    FilledButton(
                      style: FilledButton.styleFrom(backgroundColor: Colors.white, foregroundColor: ClinicColors.primaryDeep),
                      onPressed: saving ? null : _save,
                      child: saving
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Text('حفظ'),
                    ),
                  ],
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(foregroundColor: Colors.white, side: const BorderSide(color: Colors.white70)),
                    onPressed: () => store.goTo(ClinicPage.availability),
                    icon: const Icon(Icons.schedule_outlined, size: 18),
                    label: const Text('التوفر'),
                  ),
                  if (!mobile)
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(foregroundColor: Colors.white, side: const BorderSide(color: Colors.white70)),
                      onPressed: () => store.openDoctor(d.id),
                      icon: const Icon(Icons.public_outlined, size: 18),
                      label: const Text('صفحتي العامة'),
                    ),
                ],
              ),
            ],
          ),
        ),
        if (d.status == 'pending') ...[
          const SizedBox(height: 10),
          SoftCard(
            color: const Color(0xFFFFF8E1),
            child: Row(
              children: [
                const ClinicIcon(ClinicIcons.waitingRoom, size: 36),
                const SizedBox(width: 10),
                const Expanded(child: Text('حسابك بانتظار موافقة الإدارة', style: TextStyle(fontWeight: FontWeight.w700))),
              ],
            ),
          ),
        ],
        if (d.subscriptionStatus != 'active') ...[
          const SizedBox(height: 10),
          SoftCard(
            color: const Color(0xFFFFEBEE),
            child: Row(
              children: [
                const Icon(Icons.lock_outline, color: Color(0xFFC62828)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    d.subscriptionEnd == null
                        ? 'الاشتراك غير نشط — تواصل مع الإدارة'
                        : 'انتهى الاشتراك في ${longDateFmt.format(d.subscriptionEnd!)}',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _SegChip('المهني', 0, section, (v) => setState(() => section = v)),
              _SegChip('الشهادات', 1, section, (v) => setState(() => section = v)),
              _SegChip('الأمان', 2, section, (v) => setState(() => section = v)),
            ],
          ),
        ),
        const SizedBox(height: 12),
        if (section == 0) _professional(store),
        if (section == 1) _certificates(store, d),
        if (section == 2) _security(store),
        const SizedBox(height: 20),
        const Center(child: ClinicIllustration(ClinicArt.nurseLab, height: 96, opacity: 0.9)),
        const SizedBox(height: 8),
      ],
      ),
    );
  }

  Widget _professional(ClinicStore store) {
    return SoftCard(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _SectionTitle('البيانات المهنية'),
          _field('الاسم الكامل', name),
          _field('الهاتف', phone, type: TextInputType.phone),
          _field('البريد الإلكتروني', email, type: TextInputType.emailAddress),
          _field('اسم العيادة', clinic),
          _field('رقم الترخيص', license),
          _dropdown('المدينة', city, cities, (v) => setState(() => city = v)),
          _dropdown('التخصص', specialty, specialties, (v) => setState(() => specialty = v)),
          _field('سنوات الخبرة', years, type: TextInputType.number),
          _field('ساعات العمل', hours, hint: 'مثال: 09:00 - 17:00'),
          _field('المؤهلات', quals, lines: 2),
          _field('نبذة مختصرة', bio, lines: 4),
        ],
      ),
    );
  }

  Widget _certificates(ClinicStore store, Doctor d) {
    final list = d.certificates;
    return SoftCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _SectionTitle('الشهادات والإنجازات'),
          if (editing) ...[
            Row(
              children: [
                Expanded(child: _field('اسم الشهادة', cert, padBottom: false)),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: () {
                    if (cert.text.trim().isEmpty) return;
                    store.addCertificate(cert.text.trim());
                    cert.clear();
                    setState(() {});
                  },
                  child: const Text('إضافة'),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],
          if (list.isEmpty)
            const EmptyHint('لا توجد شهادات بعد', art: ClinicArt.clipboardMeds, artHeight: 90)
          else
            for (final c in list)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: SoftCard(
                  color: ClinicColors.tint,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const ClinicIcon(ClinicIcons.medicalBill, size: 28),
                    title: Text(c, style: const TextStyle(fontWeight: FontWeight.w700)),
                    trailing: editing
                        ? IconButton(
                            onPressed: () {
                              store.removeCertificate(c);
                              setState(() {});
                            },
                            icon: const Icon(Icons.delete_outline, color: Color(0xFFC62828)),
                          )
                        : null,
                  ),
                ),
              ),
        ],
      ),
    );
  }

  Widget _security(ClinicStore store) {
    return SoftCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _SectionTitle('الأمان'),
          const Text(
            'لتغيير كلمة المرور أدخل الحالية ثم الجديدة.',
            style: TextStyle(color: ClinicColors.muted, fontSize: 12),
          ),
          const SizedBox(height: 10),
          _field('كلمة المرور الحالية', currentPass, obscure: true),
          _field('كلمة المرور الجديدة', newPass, obscure: true),
          FilledButton.icon(
            onPressed: () async {
              if (currentPass.text.isEmpty || newPass.text.length < 6) {
                toast(context, 'أدخل كلمة مرور صحيحة (6 أحرف على الأقل)');
                return;
              }
              await store.changePassword(currentPass.text, newPass.text);
              if (!mounted) return;
              toast(context, store.lastMessage ?? 'تم التحديث');
              currentPass.clear();
              newPass.clear();
            },
            icon: const Icon(Icons.lock_reset),
            label: const Text('تغيير كلمة المرور'),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: store.logout,
            icon: const Icon(Icons.logout),
            label: const Text('تسجيل الخروج'),
          ),
        ],
      ),
    );
  }

  Widget _field(
    String label,
    TextEditingController c, {
    int lines = 1,
    TextInputType? type,
    String? hint,
    bool obscure = false,
    bool padBottom = true,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: padBottom ? 10 : 0),
      child: TextField(
        controller: c,
        enabled: editing || obscure,
        maxLines: obscure ? 1 : lines,
        obscureText: obscure,
        keyboardType: type,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          isDense: true,
        ),
      ),
    );
  }

  Widget _dropdown(String label, String value, List<String> items, ValueChanged<String> onChanged) {
    final safe = items.contains(value) ? value : items.first;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: DropdownButtonFormField<String>(
        key: ValueKey('$label-$safe'),
        initialValue: safe,
        isExpanded: true,
        decoration: InputDecoration(labelText: label, isDense: true),
        items: [
          for (final i in items)
            DropdownMenuItem(
              value: i,
              child: Text(i, maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
        ],
        selectedItemBuilder: (context) => [
          for (final i in items)
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: Text(i, maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
        ],
        onChanged: editing ? (v) { if (v != null) onChanged(v); } : null,
      ),
    );
  }
}

class _SegChip extends StatelessWidget {
  const _SegChip(this.label, this.value, this.selected, this.onSelect);
  final String label;
  final int value;
  final int selected;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(end: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected == value,
        onSelected: (_) => onSelect(value),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: ClinicColors.primaryDeep)),
    );
  }
}
