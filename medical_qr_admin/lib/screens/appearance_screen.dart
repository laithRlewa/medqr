import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../api/api_config.dart';
import '../state/admin_store.dart';
import '../widgets/ui.dart';

class AppearanceScreen extends StatefulWidget {
  const AppearanceScreen({super.key});

  @override
  State<AppearanceScreen> createState() => _AppearanceScreenState();
}

class _AppearanceScreenState extends State<AppearanceScreen> {
  late final TextEditingController name;
  late final TextEditingController primary;
  late final TextEditingController secondary;
  late final TextEditingController logo;
  bool ready = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (ready) return;
    final branding = AdminScope.of(context).branding;
    name = TextEditingController(text: branding.appName);
    primary = TextEditingController(text: branding.primaryColor);
    secondary = TextEditingController(text: branding.secondaryColor);
    logo = TextEditingController(text: branding.appLogo);
    ready = true;
  }

  @override
  void dispose() {
    if (ready) {
      name.dispose();
      primary.dispose();
      secondary.dispose();
      logo.dispose();
    }
    super.dispose();
  }

  void _preview(AdminStore store) {
    store.branding
      ..appName = name.text
      ..primaryColor = primary.text
      ..secondaryColor = secondary.text
      ..appLogo = logo.text;
    setState(() {});
  }

  void _save(AdminStore store, String key, String value) {
    _preview(store);
    store.saveSetting(key, value);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم حفظ الإعداد وتطبيقه')));
  }

  @override
  Widget build(BuildContext context) {
    final store = AdminScope.of(context);
    final branding = store.branding;
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const PageHeader(title: 'إعدادات المظهر', subtitle: 'تخصيص هوية التطبيق — التغييرات تُطبق فوراً (معاينة حية)', icon: Icons.palette),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('الهوية', style: TextStyle(fontWeight: FontWeight.w800)),
                const SizedBox(height: 12),
                TextField(
                  controller: name,
                  decoration: const InputDecoration(labelText: 'اسم التطبيق'),
                  onChanged: (_) => _preview(store),
                ),
                Align(alignment: Alignment.centerLeft, child: FilledButton(onPressed: () => _save(store, 'app_name', name.text), child: const Text('حفظ'))),
                const SizedBox(height: 12),
                TextField(
                  controller: logo,
                  decoration: const InputDecoration(labelText: 'رابط شعار التطبيق'),
                  onChanged: (_) => _preview(store),
                ),
                if (logo.text.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Image.network(ApiConfig.mediaUrl(logo.text), height: 64, errorBuilder: (_, __, ___) => const Icon(Icons.broken_image_outlined)),
                  ),
                Row(
                  children: [
                    OutlinedButton.icon(
                      onPressed: () async {
                        final result = await FilePicker.platform.pickFiles(type: FileType.image);
                        final path = result?.files.single.path;
                        if (path == null) return;
                        final url = await store.uploadPath(path);
                        if (url == null) return;
                        logo.text = url;
                        _save(store, 'app_logo', url);
                      },
                      icon: const Icon(Icons.upload_file),
                      label: const Text('رفع شعار'),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(onPressed: () => _save(store, 'app_logo', logo.text), child: const Text('حفظ الشعار')),
                    const SizedBox(width: 8),
                    OutlinedButton(
                      onPressed: () {
                        logo.clear();
                        _save(store, 'app_logo', '');
                      },
                      child: const Text('حذف الشعار'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('الألوان', style: TextStyle(fontWeight: FontWeight.w800)),
                const SizedBox(height: 12),
                ColorField(value: primary.text, onChanged: (v) {
                  primary.text = v;
                  _preview(store);
                }),
                FilledButton(onPressed: () => _save(store, 'theme_primary_color', primary.text), child: const Text('حفظ اللون الرئيسي')),
                const SizedBox(height: 16),
                ColorField(value: secondary.text, onChanged: (v) {
                  secondary.text = v;
                  _preview(store);
                }),
                FilledButton(onPressed: () => _save(store, 'theme_secondary_color', secondary.text), child: const Text('حفظ اللون الثانوي')),
              ],
            ),
          ),
        ),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                DropdownButtonFormField<String>(
                  initialValue: branding.fontFamily,
                  items: [for (final f in fonts) DropdownMenuItem(value: f.$1, child: Text(f.$2))],
                  onChanged: (v) {
                    branding.fontFamily = v ?? branding.fontFamily;
                    store.previewBranding();
                  },
                  decoration: const InputDecoration(labelText: 'الخط'),
                ),
                Align(alignment: Alignment.centerLeft, child: FilledButton(onPressed: () => _save(store, 'app_font', branding.fontFamily), child: const Text('حفظ الخط'))),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: branding.defaultTheme,
                  items: const [
                    DropdownMenuItem(value: 'light', child: Text('الوضع الفاتح')),
                    DropdownMenuItem(value: 'dark', child: Text('الوضع الداكن')),
                  ],
                  onChanged: (v) {
                    branding.defaultTheme = v ?? branding.defaultTheme;
                    store.previewBranding();
                  },
                  decoration: const InputDecoration(labelText: 'السمة الافتراضية'),
                ),
                Align(alignment: Alignment.centerLeft, child: FilledButton(onPressed: () => _save(store, 'default_theme', branding.defaultTheme), child: const Text('حفظ السمة'))),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
