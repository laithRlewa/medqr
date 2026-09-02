import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../models/models.dart';
import '../state/admin_store.dart';
import '../widgets/ui.dart';

class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> with SingleTickerProviderStateMixin {
  late final TabController tabs;
  String search = '';

  @override
  void initState() {
    super.initState();
    tabs = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = AdminScope.of(context);
    final q = search.trim().toLowerCase();
    final patients = store.patients.where((p) {
      if (q.isEmpty) return true;
      return p.fullName.toLowerCase().contains(q) || p.phone.contains(q) || p.email.toLowerCase().contains(q) || p.patientId.toLowerCase().contains(q);
    }).toList();
    final doctors = store.doctors.where((d) {
      if (q.isEmpty) return true;
      return d.fullName.toLowerCase().contains(q) || d.phone.contains(q) || d.specialty.toLowerCase().contains(q) || d.licenseNumber.toLowerCase().contains(q) || d.email.toLowerCase().contains(q);
    }).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const PageHeader(title: 'إدارة المستخدمين', subtitle: 'البحث وتعديل ملفات المرضى والأطباء'),
              SearchField(hint: 'بحث بالاسم، الهاتف، البريد، التخصص...', onChanged: (v) => setState(() => search = v), width: 420),
              const SizedBox(height: 12),
              TabBar(controller: tabs, tabs: [
                Tab(text: 'المرضى (${patients.length})'),
                Tab(text: 'الأطباء (${doctors.length})'),
              ]),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: tabs,
            children: [
              _list(patients, (p) => _patientTile(store, p)),
              _list(doctors, (d) => _doctorTile(store, d)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _list<T>(List<T> items, Widget Function(T) builder) {
    if (items.isEmpty) return const EmptyHint('لم يتم العثور على نتائج');
    return ListView(padding: const EdgeInsets.all(24), children: [for (final item in items) builder(item)]);
  }

  Widget _patientTile(AdminStore store, Patient p) {
    return Card(
      child: ListTile(
        leading: AvatarCircle(name: p.fullName, photo: p.profilePhoto),
        title: Text(p.fullName),
        subtitle: Text([
          '${p.patientId} · ${p.phone} · ${p.city}',
          if (p.lastModifiedBy != null) 'آخر تعديل: ${p.lastModifiedBy}${p.lastModifiedAt == null ? '' : ' · ${dateTimeFmt.format(p.lastModifiedAt!)}'}',
        ].join('\n')),
        trailing: Wrap(spacing: 8, children: [
          StatusChip(label: patientStatusAr(p.status), color: p.status == 'active' ? Colors.green : Colors.red),
          OutlinedButton(onPressed: () => _editPatient(store, p), child: const Text('تعديل')),
        ]),
      ),
    );
  }

  Widget _doctorTile(AdminStore store, Doctor d) {
    return Card(
      child: ListTile(
        leading: AvatarCircle(name: d.fullName, photo: d.profilePhoto, colors: const [BrandPalette.accent, BrandPalette.primaryDeep]),
        title: Text('د. ${d.fullName}'),
        subtitle: Text([
          '${d.specialty} · ${d.phone}',
          if (d.lastModifiedBy != null) 'آخر تعديل: ${d.lastModifiedBy}${d.lastModifiedAt == null ? '' : ' · ${dateTimeFmt.format(d.lastModifiedAt!)}'}',
        ].join('\n')),
        trailing: Wrap(spacing: 8, children: [
          StatusChip(label: doctorStatusAr(d.status), color: doctorStatusColor(d.status)),
          OutlinedButton(onPressed: () => _editDoctor(store, d), child: const Text('تعديل')),
        ]),
      ),
    );
  }

  Future<void> _editPatient(AdminStore store, Patient p) async {
    final name = TextEditingController(text: p.fullName);
    final phone = TextEditingController(text: p.phone);
    final email = TextEditingController(text: p.email);
    final nationalId = TextEditingController(text: p.nationalId);
    final dob = TextEditingController(text: p.dateOfBirth);
    final allergies = TextEditingController(text: p.allergies);
    final chronic = TextEditingController(text: p.chronicDiseases);
    final meds = TextEditingController(text: p.currentMedications);
    final emName = TextEditingController(text: p.emergencyContactName);
    final emRel = TextEditingController(text: p.emergencyContactRelationship);
    final emPhone = TextEditingController(text: p.emergencyContactPhone);
    var city = p.city;
    var blood = p.bloodType;
    var gender = p.gender;
    var status = p.status;
    String? error;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: const Text('تعديل ملف المريض'),
          content: SizedBox(
            width: 560,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  if (error != null) Text(error!, style: const TextStyle(color: Colors.red)),
                  TextField(controller: name, decoration: const InputDecoration(labelText: 'الاسم الكامل')),
                  TextField(controller: phone, decoration: const InputDecoration(labelText: 'الهاتف')),
                  TextField(controller: email, decoration: const InputDecoration(labelText: 'البريد')),
                  TextField(controller: nationalId, decoration: const InputDecoration(labelText: 'الرقم الوطني')),
                  TextField(controller: dob, decoration: const InputDecoration(labelText: 'تاريخ الميلاد')),
                  DropdownButtonFormField<String>(initialValue: cities.contains(city) ? city : cities.first, items: [for (final c in cities) DropdownMenuItem(value: c, child: Text(c))], onChanged: (v) => setLocal(() => city = v ?? city), decoration: const InputDecoration(labelText: 'المدينة')),
                  DropdownButtonFormField<String>(initialValue: gender, items: const [DropdownMenuItem(value: 'Male', child: Text('ذكر')), DropdownMenuItem(value: 'Female', child: Text('أنثى'))], onChanged: (v) => setLocal(() => gender = v ?? gender), decoration: const InputDecoration(labelText: 'الجنس')),
                  DropdownButtonFormField<String>(initialValue: bloodTypes.contains(blood) ? blood : bloodTypes.first, items: [for (final b in bloodTypes) DropdownMenuItem(value: b, child: Text(b))], onChanged: (v) => setLocal(() => blood = v ?? blood), decoration: const InputDecoration(labelText: 'فصيلة الدم')),
                  DropdownButtonFormField<String>(initialValue: status, items: const [DropdownMenuItem(value: 'active', child: Text('نشط')), DropdownMenuItem(value: 'suspended', child: Text('معلّق'))], onChanged: (v) => setLocal(() => status = v ?? status), decoration: const InputDecoration(labelText: 'الحالة')),
                  TextField(controller: allergies, decoration: const InputDecoration(labelText: 'الحساسية'), maxLines: 2),
                  TextField(controller: chronic, decoration: const InputDecoration(labelText: 'الأمراض المزمنة'), maxLines: 2),
                  TextField(controller: meds, decoration: const InputDecoration(labelText: 'الأدوية الحالية'), maxLines: 2),
                  TextField(controller: emName, decoration: const InputDecoration(labelText: 'اسم جهة اتصال الطوارئ')),
                  TextField(controller: emRel, decoration: const InputDecoration(labelText: 'صلة القرابة')),
                  TextField(controller: emPhone, decoration: const InputDecoration(labelText: 'هاتف الطوارئ')),
                  if (p.lastModifiedBy != null) Padding(padding: const EdgeInsets.only(top: 8), child: Text('آخر تعديل بواسطة: ${p.lastModifiedBy}')),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
            FilledButton(
              onPressed: () async {
                p
                  ..fullName = name.text
                  ..phone = phone.text
                  ..email = email.text
                  ..nationalId = nationalId.text
                  ..dateOfBirth = dob.text
                  ..city = city
                  ..gender = gender
                  ..bloodType = blood
                  ..status = status
                  ..allergies = allergies.text
                  ..chronicDiseases = chronic.text
                  ..currentMedications = meds.text
                  ..emergencyContactName = emName.text
                  ..emergencyContactRelationship = emRel.text
                  ..emergencyContactPhone = emPhone.text;
                final result = await store.updatePatient(p);
                if (result != null) {
                  setLocal(() => error = result);
                  return;
                }
                if (ctx.mounted) Navigator.pop(ctx, true);
              },
              child: const Text('حفظ التغييرات'),
            ),
          ],
        ),
      ),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      for (final c in [name, phone, email, nationalId, dob, allergies, chronic, meds, emName, emRel, emPhone]) {
        c.dispose();
      }
    });
    if (ok == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم حفظ التعديلات بنجاح')));
    }
  }

  Future<void> _editDoctor(AdminStore store, Doctor d) async {
    final name = TextEditingController(text: d.fullName);
    final phone = TextEditingController(text: d.phone);
    final email = TextEditingController(text: d.email);
    final license = TextEditingController(text: d.licenseNumber);
    final clinic = TextEditingController(text: d.clinicName);
    final hours = TextEditingController(text: d.workingHours);
    final years = TextEditingController(text: '${d.yearsOfExperience}');
    final quals = TextEditingController(text: d.qualifications);
    final bio = TextEditingController(text: d.biography);
    var specialty = d.specialty;
    var status = d.status;
    var city = d.city;
    var certs = [...d.certificates];
    var featured = d.featured;
    String? error;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: const Text('تعديل ملف الطبيب'),
          content: SizedBox(
            width: 560,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  if (error != null) Text(error!, style: const TextStyle(color: Colors.red)),
                  TextField(controller: name, decoration: const InputDecoration(labelText: 'الاسم الكامل')),
                  TextField(controller: phone, decoration: const InputDecoration(labelText: 'الهاتف')),
                  TextField(controller: email, decoration: const InputDecoration(labelText: 'البريد')),
                  DropdownButtonFormField<String>(initialValue: specialties.contains(specialty) ? specialty : specialties.first, items: [for (final s in specialties) DropdownMenuItem(value: s, child: Text(s))], onChanged: (v) => setLocal(() => specialty = v ?? specialty), decoration: const InputDecoration(labelText: 'التخصص')),
                  TextField(controller: license, decoration: const InputDecoration(labelText: 'رقم الترخيص')),
                  TextField(controller: clinic, decoration: const InputDecoration(labelText: 'اسم العيادة')),
                  TextField(controller: years, decoration: const InputDecoration(labelText: 'سنوات الخبرة'), keyboardType: TextInputType.number),
                  TextField(controller: hours, decoration: const InputDecoration(labelText: 'ساعات العمل')),
                  DropdownButtonFormField<String>(initialValue: cities.contains(city) ? city : cities.first, items: [for (final c in cities) DropdownMenuItem(value: c, child: Text(c))], onChanged: (v) => setLocal(() => city = v ?? city), decoration: const InputDecoration(labelText: 'المدينة')),
                  DropdownButtonFormField<String>(initialValue: status, items: const [
                    DropdownMenuItem(value: 'approved', child: Text('موافق عليه')),
                    DropdownMenuItem(value: 'pending', child: Text('قيد المراجعة')),
                    DropdownMenuItem(value: 'suspended', child: Text('معلّق')),
                  ], onChanged: (v) => setLocal(() => status = v ?? status), decoration: const InputDecoration(labelText: 'الحالة')),
                  TextField(controller: quals, decoration: const InputDecoration(labelText: 'المؤهلات'), maxLines: 2),
                  TextField(controller: bio, decoration: const InputDecoration(labelText: 'السيرة الذاتية'), maxLines: 3),
                  const SizedBox(height: 8),
                  SwitchListTile(
                    title: const Text('طبيب مميز في الصفحة الرئيسية'),
                    value: featured,
                    onChanged: (v) => setLocal(() => featured = v),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: OutlinedButton(
                      onPressed: () async {
                        final result = await FilePicker.platform.pickFiles();
                        final path = result?.files.single.path;
                        if (path == null) return;
                        final url = await store.uploadPath(path);
                        if (url != null) setLocal(() => certs.add(url));
                      },
                      child: const Text('رفع شهادة'),
                    ),
                  ),
                  for (var i = 0; i < certs.length; i++)
                    ListTile(
                      dense: true,
                      leading: const Icon(Icons.description_outlined),
                      title: Text(certs[i]),
                      trailing: IconButton(onPressed: () => setLocal(() => certs.removeAt(i)), icon: const Icon(Icons.delete_outline, color: Colors.red)),
                    ),
                  if (d.lastModifiedBy != null) Text('آخر تعديل بواسطة: ${d.lastModifiedBy}'),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
            FilledButton(
              onPressed: () async {
                d
                  ..fullName = name.text
                  ..phone = phone.text
                  ..email = email.text
                  ..licenseNumber = license.text
                  ..clinicName = clinic.text
                  ..workingHours = hours.text
                  ..yearsOfExperience = int.tryParse(years.text) ?? 0
                  ..qualifications = quals.text
                  ..biography = bio.text
                  ..specialty = specialty
                  ..status = status
                  ..city = city
                  ..certificates = certs
                  ..featured = featured;
                final result = await store.updateDoctor(d);
                if (result != null) {
                  setLocal(() => error = result);
                  return;
                }
                if (ctx.mounted) Navigator.pop(ctx, true);
              },
              child: const Text('حفظ التغييرات'),
            ),
          ],
        ),
      ),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      for (final c in [name, phone, email, license, clinic, hours, years, quals, bio]) {
        c.dispose();
      }
    });
    if (ok == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم حفظ التعديلات بنجاح')));
    }
  }
}
