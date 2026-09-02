import 'package:flutter/material.dart';

import '../state/admin_store.dart';
import '../widgets/ui.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final TextEditingController appName;
  late final TextEditingController primary;
  late final TextEditingController access;
  late final TextEditingController diagnosis;
  late final TextEditingController language;
  bool ready = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (ready) return;
    final branding = AdminScope.of(context).branding;
    appName = TextEditingController(text: branding.appName);
    primary = TextEditingController(text: branding.primaryColor);
    access = TextEditingController(text: branding.accessDurationHours);
    diagnosis = TextEditingController(text: branding.diagnosisEditHours);
    language = TextEditingController(text: branding.defaultLanguage);
    ready = true;
  }

  @override
  void dispose() {
    if (ready) {
      appName.dispose();
      primary.dispose();
      access.dispose();
      diagnosis.dispose();
      language.dispose();
    }
    super.dispose();
  }

  void _save(AdminStore store, String key, String value) {
    store.saveSetting(key, value);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم حفظ الإعداد')));
  }

  @override
  Widget build(BuildContext context) {
    final store = AdminScope.of(context);
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const PageHeader(title: 'إعدادات النظام', subtitle: 'تهيئة إعدادات المنصة ومدد الوصول'),
        _card(Icons.settings, 'الإعدادات العامة', Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(controller: appName, decoration: const InputDecoration(labelText: 'اسم التطبيق')),
            const SizedBox(height: 8),
            FilledButton(onPressed: () => _save(store, 'app_name', appName.text), child: const Text('حفظ')),
            const SizedBox(height: 16),
            ColorField(value: primary.text, onChanged: (v) => setState(() => primary.text = v)),
            FilledButton(onPressed: () => _save(store, 'theme_primary_color', primary.text), child: const Text('حفظ اللون')),
          ],
        )),
        _card(Icons.schedule, 'إعدادات مدة الوصول', Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: access,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'مدة وصول الطبيب (ساعات)',
                helperText: 'مدة وصول الطبيب إلى سجلات المريض بعد مسح رمز QR',
              ),
            ),
            FilledButton(onPressed: () => _save(store, 'access_duration_hours', access.text), child: const Text('حفظ')),
            const SizedBox(height: 16),
            TextField(
              controller: diagnosis,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'مدة تعديل التشخيص (ساعات)',
                helperText: 'المدة التي يمكن للطبيب خلالها تعديل تشخيصه الأخير قبل قفله',
              ),
            ),
            FilledButton(onPressed: () => _save(store, 'diagnosis_edit_hours', diagnosis.text), child: const Text('حفظ')),
          ],
        )),
        _card(Icons.language, 'إعدادات اللغة', Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: language,
              decoration: const InputDecoration(
                labelText: 'اللغة الافتراضية',
                helperText: 'اللغات المدعومة: ar (العربية)، en (الإنجليزية)، ku (الكردية)',
              ),
            ),
            FilledButton(onPressed: () => _save(store, 'default_language', language.text), child: const Text('حفظ')),
          ],
        )),
        _card(Icons.shield_outlined, 'قوالب جاهزة لمدة الوصول', Wrap(
          spacing: 8,
          children: [
            for (final hours in [1, 6, 10, 24, 48])
              OutlinedButton(
                onPressed: () {
                  access.text = hours.toString();
                  _save(store, 'access_duration_hours', access.text);
                },
                child: Text('$hours ساعة'),
              ),
          ],
        )),
      ],
    );
  }

  Widget _card(IconData icon, String title, Widget child) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [Icon(icon), const SizedBox(width: 8), Text(title, style: const TextStyle(fontWeight: FontWeight.w800))]),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}
