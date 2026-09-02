import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lottie/lottie.dart';

import '../data/labels.dart';
import '../state/clinic_store.dart';
import '../theme/clinic_style.dart';
import '../widgets/mobile_kit.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  String? role;
  int doctorStep = 0;
  final name = TextEditingController();
  final email = TextEditingController();
  final phone = TextEditingController();
  final license = TextEditingController();
  final clinic = TextEditingController();
  final years = TextEditingController();
  final bio = TextEditingController();
  final quals = TextEditingController();
  final hours = TextEditingController();
  final dob = TextEditingController();
  String city = 'بغداد';
  String specialty = 'طب عام';
  String gender = 'Male';
  String bloodType = 'O+';
  String? photoPath;
  String? error;

  @override
  void dispose() {
    name.dispose();
    email.dispose();
    phone.dispose();
    license.dispose();
    clinic.dispose();
    years.dispose();
    bio.dispose();
    quals.dispose();
    hours.dispose();
    dob.dispose();
    super.dispose();
  }

  bool get _isDoctor => role == 'doctor';
  bool get _wide => MediaQuery.sizeOf(context).width >= 760;

  void _back() {
    setState(() {
      error = null;
      if (_isDoctor && doctorStep > 0) {
        doctorStep = 0;
        return;
      }
      role = null;
      doctorStep = 0;
    });
  }

  Future<void> _pickPhoto() async {
    final file = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (file != null) setState(() => photoPath = file.path);
  }

  Future<void> _pickDob() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(now.year - 30),
      firstDate: DateTime(1940),
      lastDate: DateTime(now.year - 18),
    );
    if (picked != null) {
      setState(() => dob.text =
          '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}');
    }
  }

  bool _validateDetails() {
    if (name.text.trim().isEmpty) {
      setState(() => error = 'الاسم مطلوب');
      return false;
    }
    if (!validPhone(phone.text)) {
      setState(() => error = 'رقم هاتف غير صالح (07XXXXXXXXX)');
      return false;
    }
    if (email.text.trim().isNotEmpty && !validEmail(email.text)) {
      setState(() => error = 'بريد إلكتروني غير صالح');
      return false;
    }
    if (_isDoctor && clinic.text.trim().isEmpty) {
      setState(() => error = 'اسم العيادة مطلوب');
      return false;
    }
    if (_isDoctor && license.text.trim().isEmpty) {
      setState(() => error = 'رقم الترخيص مطلوب');
      return false;
    }
    setState(() => error = null);
    return true;
  }

  void _goToDetail() {
    FocusManager.instance.primaryFocus?.unfocus();
    if (!_validateDetails()) return;
    setState(() => doctorStep = 1);
  }

  Future<void> _submit() async {
    FocusManager.instance.primaryFocus?.unfocus();
    if (_isDoctor && !_validateDetails()) {
      setState(() => doctorStep = 0);
      return;
    }
    final message = await ClinicScope.of(context).register(
      role: role!,
      fullName: name.text,
      email: email.text,
      phone: phone.text,
      city: city,
      specialty: specialty,
      clinicName: clinic.text,
      licenseNumber: license.text,
      gender: gender,
      dateOfBirth: dob.text,
      bloodType: bloodType,
      yearsOfExperience: int.tryParse(years.text) ?? 0,
      biography: bio.text,
      qualifications: quals.text,
      workingHours: hours.text,
      profilePhotoPath: photoPath,
    );
    if (!mounted) return;
    if (message != null) {
      setState(() => error = message);
      return;
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final store = ClinicScope.of(context);
    return Scaffold(
      backgroundColor: ClinicColors.bg,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: role == null ? 820 : 920),
            child: Padding(
              padding: EdgeInsets.fromLTRB(20, 8, 20, isMobileLayout(context) ? 16 : 24),
              child: Column(
                children: [
                  _topBar(),
                  const SizedBox(height: 12),
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 280),
                      switchInCurve: Curves.easeOut,
                      switchOutCurve: Curves.easeIn,
                      child: SingleChildScrollView(
                        key: ValueKey('reg-${role ?? 'pick'}-$doctorStep'),
                        padding: const EdgeInsets.only(bottom: 12),
                        child: role == null ? _rolePick() : _form(),
                      ),
                    ),
                  ),
                  if (role != null) _actions(store.busy),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _topBar() {
    return Row(
      children: [
        CircleIconBtn(
          icon: Icons.arrow_forward_ios,
          size: 44,
          onTap: role == null ? () => Navigator.maybePop(context) : _back,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                role == null
                    ? 'إنشاء حساب'
                    : _isDoctor
                        ? (doctorStep == 0 ? 'تفاصيل الطبيب' : 'التفصيل المهني')
                        : 'تسجيل مريض',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
              ),
              Text(
                role == null
                    ? 'اختر دورك ثم أكمل البيانات بترتيب واضح'
                    : _isDoctor
                        ? (doctorStep == 0 ? 'الخطوة 1 من 2 — البيانات الأساسية والعيادة' : 'الخطوة 2 من 2 — الخبرة والسيرة والصورة')
                        : 'رمز التحقق يصل إلى واتساب بعد إرسال النموذج',
                style: const TextStyle(color: ClinicColors.muted, fontSize: 13),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _rolePick() {
    final cards = [
      _roleCard(
        value: 'patient',
        title: 'مريض',
        subtitle: 'سجل طبي، رمز QR، وحجز مواعيد بسهولة.',
        points: const ['رمز طبي شخصي', 'ملفات وتحاليل', 'متابعة المواعيد'],
        icon: Icons.favorite_outline,
        color: ClinicColors.primary,
      ),
      _roleCard(
        value: 'doctor',
        title: 'طبيب',
        subtitle: 'ملف مهني مرتب، ثم تفصيل العيادة والترخيص.',
        points: const ['التخصص والعيادة', 'ترخيص وخبرة', 'موافقة الإدارة'],
        icon: Icons.medical_services_outlined,
        color: ClinicColors.primaryDeep,
        lottie: true,
      ),
    ];
    return Column(
      children: [
        const SizedBox(height: 8),
        Text('كيف تريد استخدام المنصة؟', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 6),
        const Text('واجهة واحدة… بمسار واضح لكل دور', style: TextStyle(color: ClinicColors.muted)),
        const SizedBox(height: 24),
        if (_wide)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: cards[0]),
              const SizedBox(width: 16),
              Expanded(child: cards[1]),
            ],
          )
        else ...[
          cards[0],
          const SizedBox(height: 14),
          cards[1],
        ],
      ],
    );
  }

  Widget _roleCard({
    required String value,
    required String title,
    required String subtitle,
    required List<String> points,
    required IconData icon,
    required Color color,
    bool lottie = false,
  }) {
    return SoftCard(
      onTap: () => setState(() {
        role = value;
        doctorStep = 0;
        error = null;
      }),
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(16)),
                child: Icon(icon, color: color, size: 26),
              ),
              const Spacer(),
              if (lottie)
                SizedBox(width: 88, height: 64, child: Lottie.asset('assets/lottie/doctores-freepik.json', repeat: true, fit: BoxFit.contain)),
            ],
          ),
          const SizedBox(height: 16),
          Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          Text(subtitle, style: const TextStyle(color: ClinicColors.muted, height: 1.45)),
          const SizedBox(height: 16),
          for (final point in points)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Icon(Icons.check_circle, size: 18, color: color),
                  const SizedBox(width: 8),
                  Expanded(child: Text(point, style: const TextStyle(fontWeight: FontWeight.w600))),
                ],
              ),
            ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: Text('ابدأ من هنا', style: TextStyle(color: color, fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }

  Widget _form() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_isDoctor) ...[
          _doctorHero(),
          const SizedBox(height: 16),
          _progress(),
          const SizedBox(height: 16),
        ],
        if (error != null) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF1F0),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: [
                const Icon(Icons.error_outline, color: Color(0xFFD32F2F)),
                const SizedBox(width: 10),
                Expanded(child: Text(error!, style: const TextStyle(color: Color(0xFFD32F2F), fontWeight: FontWeight.w700))),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
        if (!_isDoctor || doctorStep == 0) ..._detailsSections(),
        if (_isDoctor && doctorStep == 1) ..._professionalSections(),
      ],
    );
  }

  Widget _doctorHero() {
    return SoftCard(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      color: ClinicColors.tint,
      child: _wide
          ? Row(
              children: [
                SizedBox(width: 168, height: 128, child: Lottie.asset('assets/lottie/doctores-freepik.json', repeat: true, fit: BoxFit.contain)),
                const SizedBox(width: 16),
                Expanded(child: _heroCopy()),
              ],
            )
          : Column(
              children: [
                SizedBox(height: 140, child: Lottie.asset('assets/lottie/doctores-freepik.json', repeat: true, fit: BoxFit.contain)),
                _heroCopy(),
              ],
            ),
    );
  }

  Widget _heroCopy() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('ملف مهني مرتب', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
        const SizedBox(height: 6),
        Text(
          doctorStep == 0
              ? 'نبدأ بالبيانات الأساسية وتفاصيل العيادة، ثم ننتقل إلى التفصيل المهني.'
              : 'أكمل الخبرة والسيرة والصورة. يُراجع الحساب من الإدارة قبل التفعيل.',
          style: const TextStyle(color: ClinicColors.muted, height: 1.45),
        ),
      ],
    );
  }

  Widget _progress() {
    return SoftCard(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
      child: Column(
        children: [
          Row(
            children: [
              _stepDot(1, 'التفاصيل', doctorStep >= 0, doctorStep == 0),
              Expanded(
                child: Container(
                  height: 3,
                  margin: const EdgeInsets.only(bottom: 18),
                  decoration: BoxDecoration(
                    color: doctorStep > 0 ? ClinicColors.primary : ClinicColors.bgDeep,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
              _stepDot(2, 'التفصيل', doctorStep >= 1, doctorStep == 1),
            ],
          ),
        ],
      ),
    );
  }

  Widget _stepDot(int number, String label, bool reached, bool active) {
    return Column(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 34,
          height: 34,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: reached ? ClinicColors.primary : ClinicColors.bgDeep,
            shape: BoxShape.circle,
            boxShadow: active ? [BoxShadow(color: ClinicColors.primary.withValues(alpha: 0.28), blurRadius: 12, offset: const Offset(0, 4))] : null,
          ),
          child: Text('$number', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
        ),
        const SizedBox(height: 6),
        Text(label, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: active ? ClinicColors.primaryDeep : ClinicColors.muted)),
      ],
    );
  }

  List<Widget> _detailsSections() {
    return [
      _section(
        icon: Icons.person_outline,
        title: 'البيانات الشخصية',
        subtitle: 'تظهر في الملف بعد تفعيل الحساب',
        children: [
          _row(
            _field(controller: name, label: 'الاسم الكامل *', icon: Icons.badge_outlined),
            _field(
              controller: phone,
              label: 'الهاتف *',
              icon: Icons.phone_iphone,
              type: TextInputType.phone,
              formatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9+]'))],
            ),
          ),
          const SizedBox(height: 12),
          _row(
            _field(controller: email, label: _isDoctor ? 'البريد الإلكتروني' : 'البريد الإلكتروني (اختياري)', icon: Icons.mail_outline, type: TextInputType.emailAddress),
            _dropdown(
              value: city,
              label: 'المدينة *',
              icon: Icons.location_city_outlined,
              items: cities,
              onChanged: (v) => setState(() => city = v ?? city),
            ),
          ),
          const SizedBox(height: 12),
          if (_isDoctor)
            _dropdown(
              value: gender,
              label: 'الجنس',
              icon: Icons.wc_outlined,
              items: const ['Male', 'Female'],
              labels: const {'Male': 'ذكر', 'Female': 'أنثى'},
              onChanged: (v) => setState(() => gender = v ?? gender),
            )
          else
            _row(
              _dropdown(
                value: gender,
                label: 'الجنس',
                icon: Icons.wc_outlined,
                items: const ['Male', 'Female'],
                labels: const {'Male': 'ذكر', 'Female': 'أنثى'},
                onChanged: (v) => setState(() => gender = v ?? gender),
              ),
              _dropdown(
                value: bloodType,
                label: 'فصيلة الدم',
                icon: Icons.water_drop_outlined,
                items: bloodTypes,
                onChanged: (v) => setState(() => bloodType = v ?? bloodType),
              ),
            ),
        ],
      ),
      if (_isDoctor) ...[
        const SizedBox(height: 14),
        _section(
          icon: Icons.local_hospital_outlined,
          title: 'تفاصيل العيادة',
          subtitle: 'التخصص والاسم ورقم الترخيص',
          children: [
            _row(
              _dropdown(
                value: specialties.contains(specialty) ? specialty : specialties.first,
                label: 'التخصص *',
                icon: Icons.medical_information_outlined,
                items: specialties,
                onChanged: (v) => setState(() => specialty = v ?? specialty),
              ),
              _field(controller: clinic, label: 'اسم العيادة *', icon: Icons.apartment_outlined),
            ),
            const SizedBox(height: 12),
            _field(controller: license, label: 'رقم الترخيص *', icon: Icons.verified_outlined),
          ],
        ),
      ],
    ];
  }

  List<Widget> _professionalSections() {
    return [
      _section(
        icon: Icons.workspace_premium_outlined,
        title: 'الخبرة والعمل',
        subtitle: 'تساعد المرضى على اختيار الطبيب المناسب',
        children: [
          _row(
            _field(controller: years, label: 'سنوات الخبرة', icon: Icons.timeline, type: TextInputType.number),
            _field(controller: hours, label: 'ساعات العمل', icon: Icons.schedule, hint: 'مثال: 09:00-17:00'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: dob,
            readOnly: true,
            onTap: _pickDob,
            decoration: _decoration('تاريخ الميلاد', Icons.calendar_month_outlined, hint: 'اختر التاريخ'),
          ),
        ],
      ),
      const SizedBox(height: 14),
      _section(
        icon: Icons.menu_book_outlined,
        title: 'السيرة والمؤهلات',
        subtitle: 'نبذة مهنية تظهر في صفحة الطبيب',
        children: [
          _area(controller: quals, label: 'المؤهلات', hint: 'البورد، الزمالة، الشهادات...'),
          const SizedBox(height: 12),
          _area(controller: bio, label: 'السيرة الذاتية', hint: 'أخبرنا عن خبرتك المهنية...', lines: 5),
        ],
      ),
      const SizedBox(height: 14),
      _section(
        icon: Icons.photo_camera_outlined,
        title: 'الصورة الشخصية',
        subtitle: 'اختيارية، ويمكن تغييرها لاحقاً',
        children: [_photoBox()],
      ),
    ];
  }

  Widget _section({
    required IconData icon,
    required String title,
    required String subtitle,
    required List<Widget> children,
  }) {
    return SoftCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(color: ClinicColors.tint, borderRadius: BorderRadius.circular(14)),
                child: Icon(icon, color: ClinicColors.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                    Text(subtitle, style: const TextStyle(color: ClinicColors.muted, fontSize: 12.5)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          ...children,
        ],
      ),
    );
  }

  Widget _row(Widget a, Widget b) {
    if (!_wide) {
      return Column(children: [a, const SizedBox(height: 12), b]);
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: a),
        const SizedBox(width: 12),
        Expanded(child: b),
      ],
    );
  }

  InputDecoration _decoration(String label, IconData icon, {String? hint}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon, color: ClinicColors.muted),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hint,
    TextInputType? type,
    List<TextInputFormatter>? formatters,
  }) {
    return TextField(
      controller: controller,
      keyboardType: type,
      inputFormatters: formatters,
      decoration: _decoration(label, icon, hint: hint),
    );
  }

  Widget _area({required TextEditingController controller, required String label, String? hint, int lines = 3}) {
    final radius = BorderRadius.circular(22);
    return TextField(
      controller: controller,
      maxLines: lines,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        alignLabelWithHint: true,
        border: OutlineInputBorder(borderRadius: radius, borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: radius, borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: radius, borderSide: const BorderSide(color: ClinicColors.primary, width: 1.4)),
        contentPadding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      ),
    );
  }

  Widget _dropdown({
    required String value,
    required String label,
    required IconData icon,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    Map<String, String>? labels,
  }) {
    return DropdownButtonFormField<String>(
      initialValue: items.contains(value) ? value : items.first,
      decoration: _decoration(label, icon),
      items: [for (final item in items) DropdownMenuItem(value: item, child: Text(labels?[item] ?? item))],
      onChanged: onChanged,
    );
  }

  Widget _photoBox() {
    return InkWell(
      onTap: _pickPhoto,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: ClinicColors.bg,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: ClinicColors.border),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: photoPath == null
                  ? Container(
                      width: 76,
                      height: 76,
                      color: Colors.white,
                      child: const Icon(Icons.add_a_photo_outlined, color: ClinicColors.primary),
                    )
                  : Image.file(File(photoPath!), width: 76, height: 76, fit: BoxFit.cover),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(photoPath == null ? 'أضف صورة واضحة للملف' : 'تم اختيار الصورة', style: const TextStyle(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  Text(photoPath == null ? 'يفضّل صورة مربعة بخلفية هادئة' : 'اضغط لتغيير الصورة', style: const TextStyle(color: ClinicColors.muted, fontSize: 13)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _actions(bool busy) {
    final next = _isDoctor && doctorStep == 0;
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          Expanded(
            child: GhostButton(
              label: _isDoctor && doctorStep > 0 ? 'رجوع' : 'تغيير الدور',
              onTap: _back,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: OrangeButton(
              label: busy
                  ? 'جارٍ الإرسال...'
                  : next
                      ? 'التالي: التفصيل المهني'
                      : _isDoctor
                          ? 'تقديم للموافقة'
                          : 'إرسال رمز واتساب',
              onTap: busy ? null : (next ? _goToDetail : _submit),
            ),
          ),
        ],
      ),
    );
  }
}
