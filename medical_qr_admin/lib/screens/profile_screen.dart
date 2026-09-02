import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../api/api_config.dart';
import '../state/admin_store.dart';
import '../widgets/ui.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late final TextEditingController phone;
  late final TextEditingController photo;
  bool editing = false;
  bool ready = false;
  String? phoneError;

  @override
  void initState() {
    super.initState();
    phone = TextEditingController();
    photo = TextEditingController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (ready) return;
    final user = AdminScope.of(context).currentUser;
    phone.text = user?.phone ?? '';
    photo.text = user?.profilePhoto ?? '';
    ready = true;
  }

  @override
  void dispose() {
    phone.dispose();
    photo.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = AdminScope.of(context);
    final user = store.currentUser!;
    final myLogs = store.auditLogs.where((l) => l.userId == user.id).take(20).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('ملف المدير')),
      body: DefaultTabController(
        length: 3,
        child: Column(
          children: [
            const TabBar(tabs: [
              Tab(text: 'شخصي'),
              Tab(text: 'الأمان'),
              Tab(text: 'النشاط'),
            ]),
            Expanded(
              child: TabBarView(
                children: [
                  ListView(
                    padding: const EdgeInsets.all(24),
                    children: [
                      const PageHeader(title: 'المعلومات الشخصية', subtitle: 'إدارة حسابك الشخصي وإعدادات الأمان'),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: editing
                            ? Row(children: [
                                OutlinedButton(onPressed: () => setState(() => editing = false), child: const Text('إلغاء')),
                                const SizedBox(width: 8),
                                FilledButton(
                                  onPressed: () async {
                                    final error = await store.updateProfilePhone(phone.text);
                                    if (!mounted) return;
                                    if (error != null) {
                                      setState(() => phoneError = error);
                                      return;
                                    }
                                    await store.updateProfilePhoto(photo.text);
                                    if (!mounted) return;
                                    setState(() {
                                      editing = false;
                                      phoneError = null;
                                    });
                                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم حفظ التغييرات')));
                                  },
                                  child: const Text('حفظ'),
                                ),
                              ])
                            : OutlinedButton(onPressed: () => setState(() => editing = true), child: const Text('تعديل')),
                      ),
                      const SizedBox(height: 16),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            children: [
                              CircleAvatar(
                                radius: 36,
                                backgroundColor: Theme.of(context).colorScheme.primary,
                                backgroundImage: user.profilePhoto.isEmpty ? null : NetworkImage(ApiConfig.mediaUrl(user.profilePhoto)),
                                child: user.profilePhoto.isEmpty ? Text(user.fullName.characters.first, style: const TextStyle(color: Colors.white, fontSize: 28)) : null,
                              ),
                              const SizedBox(height: 16),
                              if (editing) ...[
                                TextField(controller: photo, decoration: const InputDecoration(labelText: 'رابط الصورة')),
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: OutlinedButton.icon(
                                    onPressed: () async {
                                      final result = await FilePicker.platform.pickFiles(type: FileType.image);
                                      final path = result?.files.single.path;
                                      if (path == null) return;
                                      final url = await store.uploadPath(path);
                                      if (url == null) return;
                                      photo.text = url;
                                      await store.updateProfilePhoto(url);
                                      setState(() {});
                                    },
                                    icon: const Icon(Icons.upload_file),
                                    label: const Text('رفع صورة'),
                                  ),
                                ),
                              ],
                              const SizedBox(height: 12),
                              TextField(enabled: false, decoration: InputDecoration(labelText: 'الاسم الكامل', hintText: user.fullName, helperText: 'الاسم مرتبط بحساب الدخول')),
                              const SizedBox(height: 12),
                              TextField(enabled: false, decoration: InputDecoration(labelText: 'البريد الإلكتروني', hintText: user.email, helperText: 'البريد مرتبط بحساب الدخول')),
                              const SizedBox(height: 12),
                              if (editing)
                                TextField(
                                  controller: phone,
                                  decoration: InputDecoration(labelText: 'رقم الهاتف', errorText: phoneError, hintText: '07XXXXXXXXX'),
                                )
                              else
                                ListTile(title: const Text('رقم الهاتف'), subtitle: Text(user.phone.isEmpty ? '—' : user.phone)),
                              const ListTile(title: Text('الدور'), subtitle: Text('مدير النظام')),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  ListView(
                    padding: const EdgeInsets.all(24),
                    children: [
                      Card(
                        child: ListTile(
                          title: const Text('كلمة المرور'),
                          subtitle: Text(store.passwordResetSent ? 'تم إرسال الرابط. تحقق من بريدك الإلكتروني.' : 'لتغيير كلمة المرور، سيتم إرسال رابط آمن إلى بريدك الإلكتروني'),
                          trailing: OutlinedButton(onPressed: store.requestPasswordReset, child: const Text('إرسال رابط تغيير كلمة المرور')),
                        ),
                      ),
                      Card(
                        child: ListTile(
                          title: const Text('البريد الإلكتروني'),
                          subtitle: Text(user.email),
                          trailing: const StatusChip(label: 'مؤكد', color: Colors.green),
                        ),
                      ),
                      Card(
                        child: SwitchListTile(
                          title: const Text('إشعارات البريد الإلكتروني'),
                          subtitle: const Text('تلقي التحديثات عبر البريد'),
                          value: user.notifyEmail,
                          onChanged: (v) => store.updateAccount(notifyEmail: v),
                        ),
                      ),
                      Card(
                        child: SwitchListTile(
                          title: const Text('إشعارات الرسائل النصية'),
                          subtitle: const Text('تلقي التحديثات عبر SMS'),
                          value: user.notifySms,
                          onChanged: (v) => store.updateAccount(notifySms: v),
                        ),
                      ),
                      Card(
                        child: ListTile(
                          title: const Text('تفضيل اللغة'),
                          trailing: DropdownButton<String>(
                            value: user.languagePreference,
                            items: const [
                              DropdownMenuItem(value: 'ar', child: Text('العربية')),
                              DropdownMenuItem(value: 'en', child: Text('English')),
                              DropdownMenuItem(value: 'ku', child: Text('كوردی')),
                            ],
                            onChanged: (v) => store.updateAccount(language: v),
                          ),
                        ),
                      ),
                      const Card(
                        child: ListTile(
                          title: Text('المصادقة الثنائية (2FA)'),
                          subtitle: Text('طبقة حماية إضافية لحسابك'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Switch(value: false, onChanged: null),
                              StatusChip(label: 'غير مدعوم حالياً', color: Colors.grey),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  ListView(
                    padding: const EdgeInsets.all(24),
                    children: [
                      const PageHeader(title: 'سجل النشاط', subtitle: 'آخر إجراءات هذا الحساب'),
                      if (myLogs.isEmpty) const EmptyHint('لا يوجد نشاط مسجل'),
                      for (final log in myLogs)
                        Card(
                          child: ListTile(
                            title: Text(log.description),
                            subtitle: Text('${actionAr(log.actionType)} · ${dateTimeFmt.format(log.createdDate)}'),
                            trailing: log.ipAddress == null ? null : Text(log.ipAddress!),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
