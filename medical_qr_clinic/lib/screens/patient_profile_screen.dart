import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../state/clinic_store.dart';
import '../widgets/mobile_kit.dart';
import '../widgets/ui.dart';

class PatientProfileScreen extends StatefulWidget {
  const PatientProfileScreen({super.key});

  @override
  State<PatientProfileScreen> createState() => _PatientProfileScreenState();
}

class _PatientProfileScreenState extends State<PatientProfileScreen> {
  bool editing = false;
  bool ready = false;
  bool saving = false;
  int section = 0;

  late final TextEditingController name;
  late final TextEditingController phone;
  late final TextEditingController email;
  late final TextEditingController dob;
  late final TextEditingController allergies;
  late final TextEditingController chronic;
  late final TextEditingController meds;
  late final TextEditingController emergencyName;
  late final TextEditingController emergencyPhone;
  late final TextEditingController emergencyRel;
  late final TextEditingController history;
  late final TextEditingController currentPass;
  late final TextEditingController newPass;
  String city = 'بغداد';
  String gender = 'Male';
  String blood = 'O+';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (ready) return;
    final p = ClinicScope.of(context).currentPatient;
    name = TextEditingController(text: p?.fullName ?? '');
    phone = TextEditingController(text: p?.phone ?? '');
    email = TextEditingController(text: p?.email ?? '');
    dob = TextEditingController(text: p?.dateOfBirth ?? '');
    allergies = TextEditingController(text: p?.allergies ?? '');
    chronic = TextEditingController(text: p?.chronicDiseases ?? '');
    meds = TextEditingController(text: p?.currentMedications ?? '');
    emergencyName = TextEditingController(text: p?.emergencyContactName ?? '');
    emergencyPhone = TextEditingController(text: p?.emergencyContactPhone ?? '');
    emergencyRel = TextEditingController(text: p?.emergencyContactRelationship ?? '');
    history = TextEditingController(text: p?.medicalHistory ?? '');
    currentPass = TextEditingController();
    newPass = TextEditingController();
    city = p?.city ?? 'بغداد';
    gender = p?.gender ?? 'Male';
    blood = p?.bloodType ?? 'O+';
    ready = true;
  }

  @override
  void dispose() {
    if (ready) {
      name.dispose();
      phone.dispose();
      email.dispose();
      dob.dispose();
      allergies.dispose();
      chronic.dispose();
      meds.dispose();
      emergencyName.dispose();
      emergencyPhone.dispose();
      emergencyRel.dispose();
      history.dispose();
      currentPass.dispose();
      newPass.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    final store = ClinicScope.of(context);
    final p = store.currentPatient;
    if (p == null) return;
    if (!validPhone(phone.text)) {
      toast(context, 'رقم هاتف غير صالح (07XXXXXXXXX)');
      return;
    }
    if (email.text.trim().isNotEmpty && !validEmail(email.text)) {
      toast(context, 'بريد إلكتروني غير صالح');
      return;
    }
    setState(() => saving = true);
    p
      ..fullName = name.text.trim()
      ..phone = phone.text.trim()
      ..email = email.text.trim()
      ..dateOfBirth = dob.text.trim()
      ..city = city
      ..gender = gender
      ..bloodType = blood
      ..allergies = allergies.text.trim()
      ..chronicDiseases = chronic.text.trim()
      ..currentMedications = meds.text.trim()
      ..emergencyContactName = emergencyName.text.trim()
      ..emergencyContactPhone = emergencyPhone.text.trim()
      ..emergencyContactRelationship = emergencyRel.text.trim()
      ..medicalHistory = history.text.trim();
    await store.updatePatientProfile(p);
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

  Future<void> _pickDob() async {
    if (!editing) return;
    final now = DateTime.now();
    final initial = DateTime.tryParse(dob.text) ?? DateTime(now.year - 25);
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1920),
      lastDate: now,
    );
    if (picked != null) {
      setState(() => dob.text = isoDate.format(picked));
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = ClinicScope.of(context);
    final p = store.currentPatient;
    if (p == null) return const Center(child: Text('لم يتم العثور على ملف المريض'));

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
                        name: p.fullName,
                        size: 72,
                        photo: store.currentUser?.profilePhoto.isNotEmpty == true
                            ? store.currentUser!.profilePhoto
                            : p.profilePhoto,
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
                        Text(p.fullName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18)),
                        const SizedBox(height: 4),
                        Text(p.patientId, style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 12)),
                        const SizedBox(height: 8),
                        StatusChip(label: '${p.city} · ${genderAr(p.gender)}', color: ClinicColors.accent),
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
                    onPressed: () => store.goTo(ClinicPage.dashboard),
                    icon: const Icon(Icons.qr_code_2, size: 18),
                    label: const Text('رمزي الطبي'),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _SegChip('شخصي', 0, section, (v) => setState(() => section = v)),
              _SegChip('طبي', 1, section, (v) => setState(() => section = v)),
              _SegChip('الأمان', 2, section, (v) => setState(() => section = v)),
            ],
          ),
        ),
        const SizedBox(height: 12),
        if (section == 0) _personal(),
        if (section == 1) _medical(),
        if (section == 2) _security(store),
        const SizedBox(height: 20),
        const Center(child: ClinicIllustration(ClinicArt.heartCheck, height: 96, opacity: 0.9)),
        const SizedBox(height: 8),
      ],
      ),
    );
  }

  Widget _personal() {
    return SoftCard(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _SectionTitle('البيانات الشخصية'),
          _field('الاسم الكامل', name),
          _field('الهاتف', phone, type: TextInputType.phone),
          _field('البريد الإلكتروني', email, type: TextInputType.emailAddress),
          InkWell(
            onTap: _pickDob,
            child: IgnorePointer(child: _field('تاريخ الميلاد', dob, hint: 'YYYY-MM-DD')),
          ),
          _dropdown('المدينة', city, cities, (v) => setState(() => city = v)),
          _dropdown('الجنس', gender, const ['Male', 'Female'], (v) => setState(() => gender = v), labelOf: genderAr),
        ],
      ),
    );
  }

  Widget _medical() {
    return SoftCard(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _SectionTitle('المعلومات الطبية'),
          _dropdown('فصيلة الدم', blood, bloodTypes, (v) => setState(() => blood = v)),
          _field('الحساسية', allergies, lines: 2),
          _field('الأمراض المزمنة', chronic, lines: 2),
          _field('الأدوية الحالية', meds, lines: 2),
          _field('اسم جهة الطوارئ', emergencyName),
          _field('هاتف الطوارئ', emergencyPhone, type: TextInputType.phone),
          _field('صلة القرابة', emergencyRel),
          _field('التاريخ المرضي', history, lines: 4),
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
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: c,
        enabled: editing || obscure,
        maxLines: obscure ? 1 : lines,
        obscureText: obscure,
        keyboardType: type,
        decoration: InputDecoration(labelText: label, hintText: hint, isDense: true),
      ),
    );
  }

  Widget _dropdown(
    String label,
    String value,
    List<String> items,
    ValueChanged<String> onChanged, {
    String Function(String)? labelOf,
  }) {
    final safe = items.contains(value) ? value : items.first;
    String textOf(String v) => labelOf?.call(v) ?? v;
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
              child: Text(textOf(i), maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
        ],
        selectedItemBuilder: (context) => [
          for (final i in items)
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: Text(textOf(i), maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
        ],
        onChanged: editing
            ? (v) {
                if (v != null) onChanged(v);
              }
            : null,
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
