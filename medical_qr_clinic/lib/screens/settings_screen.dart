import 'package:flutter/material.dart';

import '../state/clinic_store.dart';
import '../widgets/mobile_kit.dart';
import '../widgets/ui.dart';
import 'doctor_profile_screen.dart';
import 'patient_profile_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = ClinicScope.of(context);
    final user = store.currentUser;
    final name = store.currentDoctor?.fullName ?? store.currentPatient?.fullName ?? user?.fullName ?? 'مستخدم';

    return ListView(
      padding: clinicPadding(context),
      children: [
        const PageHeader(
          title: 'الإعدادات',
          subtitle: 'المظهر والإشعارات وإدارة الحساب',
          icon: Icons.settings_rounded,
        ),
        SoftCard(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              PhotoAvatar(name: name, size: 52, photo: user?.profilePhoto),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      store.isDoctor ? 'د. $name' : name,
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: ClinicColors.primaryDeep),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      user?.phone.isNotEmpty == true ? user!.phone : (user?.email ?? ''),
                      style: const TextStyle(color: ClinicColors.muted, fontSize: 12),
                    ),
                  ],
                ),
              ),
              StatusChip(label: roleAr(store.role), color: ClinicColors.primary),
            ],
          ),
        ),
        const _SectionLabel('المظهر'),
        SoftCard(
          padding: EdgeInsets.zero,
          child: SwitchListTile(
            value: store.darkMode,
            onChanged: (_) => store.toggleDark(),
            secondary: const _Glyph(Icons.dark_mode_rounded),
            title: const Text('الوضع الليلي', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
            subtitle: const Text('ألوان داكنة مريحة للعين', style: TextStyle(color: ClinicColors.muted, fontSize: 12)),
          ),
        ),
        const _SectionLabel('الإشعارات'),
        SoftCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              SwitchListTile(
                value: user?.notifyPush ?? true,
                onChanged: (value) => store.setNotificationPrefs(push: value),
                secondary: const _Glyph(Icons.notifications_active_rounded),
                title: const Text('إشعارات الجهاز', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                subtitle: const Text('تنبيه فوري حتى لو التطبيق مغلق', style: TextStyle(color: ClinicColors.muted, fontSize: 12)),
              ),
              const Divider(height: 1, indent: 16, endIndent: 16),
              SwitchListTile(
                value: user?.notifySms ?? true,
                onChanged: (value) => store.setNotificationPrefs(sms: value),
                secondary: const _Glyph(Icons.sms_rounded),
                title: const Text('رسائل واتساب', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                subtitle: const Text('رمز الدخول وتنبيهات مهمة', style: TextStyle(color: ClinicColors.muted, fontSize: 12)),
              ),
              const Divider(height: 1, indent: 16, endIndent: 16),
              SwitchListTile(
                value: user?.notifyEmail ?? true,
                onChanged: (value) => store.setNotificationPrefs(email: value),
                secondary: const _Glyph(Icons.mail_rounded),
                title: const Text('البريد الإلكتروني', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                subtitle: const Text('ملخص دوري لنشاط حسابك', style: TextStyle(color: ClinicColors.muted, fontSize: 12)),
              ),
            ],
          ),
        ),
        const _SectionLabel('الحساب'),
        _Tile(
          icon: Icons.manage_accounts_rounded,
          title: 'تعديل الملف الشخصي',
          subtitle: 'الاسم والصورة والبيانات الطبية',
          onTap: () => Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => store.isDoctor ? const DoctorProfileScreen() : const PatientProfileScreen(),
          )),
        ),
        _Tile(
          icon: Icons.logout_rounded,
          title: 'تسجيل الخروج',
          subtitle: 'إنهاء الجلسة على هذا الجهاز',
          onTap: store.logout,
        ),
        const _SectionLabel('منطقة الخطر'),
        const _DeleteAccountCard(),
        const SizedBox(height: 8),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 18, 4, 10),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 16,
            decoration: BoxDecoration(color: ClinicColors.primary, borderRadius: BorderRadius.circular(4)),
          ),
          const SizedBox(width: 8),
          Text(text, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: ClinicColors.primaryDeep)),
        ],
      ),
    );
  }
}

class _Glyph extends StatelessWidget {
  const _Glyph(this.icon, {this.color = ClinicColors.primary});
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
      child: Icon(icon, color: color, size: 21),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({required this.icon, required this.title, required this.subtitle, required this.onTap});

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: SoftCard(
        padding: EdgeInsets.zero,
        onTap: onTap,
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          leading: _Glyph(icon),
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
          subtitle: Text(subtitle, style: const TextStyle(color: ClinicColors.muted, fontSize: 12)),
          trailing: const Icon(Icons.chevron_left, color: ClinicColors.muted, size: 18),
        ),
      ),
    );
  }
}

const _danger = Color(0xFFC62828);

class _DeleteAccountCard extends StatefulWidget {
  const _DeleteAccountCard();

  @override
  State<_DeleteAccountCard> createState() => _DeleteAccountCardState();
}

class _DeleteAccountCardState extends State<_DeleteAccountCard> {
  bool _working = false;

  @override
  Widget build(BuildContext context) {
    final store = ClinicScope.of(context);
    return SoftCard(
      color: const Color(0xFFFFF5F5),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const _Glyph(Icons.delete_forever_rounded, color: _danger),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'حذف الحساب نهائياً',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: _danger),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            store.isDoctor
                ? 'سيُحذف حسابك وملفك المهني وكل الزيارات والملفات الطبية والمواعيد والرسائل والمنشورات التي أنشأتها.'
                : 'سيُحذف حسابك وسجلك الطبي وكل الزيارات والملفات والمواعيد والرسائل ورمز QR الخاص بك.',
            style: const TextStyle(color: ClinicColors.muted, fontSize: 12.5, height: 1.6),
          ),
          const SizedBox(height: 6),
          const Text(
            'لا يمكن التراجع عن هذا الإجراء.',
            style: TextStyle(color: _danger, fontSize: 12.5, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _working ? null : () => _confirm(store),
              style: OutlinedButton.styleFrom(
                foregroundColor: _danger,
                side: const BorderSide(color: _danger),
                minimumSize: const Size(0, 48),
              ),
              icon: _working
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: _danger),
                    )
                  : const Icon(Icons.delete_forever_rounded, size: 20),
              label: Text(_working ? 'جارٍ الحذف…' : 'حذف حسابي وكل بياناتي'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirm(ClinicStore store) async {
    final approved = await showDialog<bool>(
      context: context,
      builder: (_) => const _ConfirmDeleteDialog(),
    );
    if (approved != true || !mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    setState(() => _working = true);
    final error = await store.deleteAccount();
    // نجاح الحذف يسجّل الخروج فيُزال هذا الودجت من الشجرة.
    if (mounted) setState(() => _working = false);
    messenger.showSnackBar(
      SnackBar(
        content: Text(error ?? 'تم حذف حسابك وكل بياناته نهائياً'),
        backgroundColor: error == null ? null : _danger,
      ),
    );
  }
}

/// يطلب كتابة كلمة التأكيد حتى لا يقع الحذف بضغطة عابرة.
class _ConfirmDeleteDialog extends StatefulWidget {
  const _ConfirmDeleteDialog();

  static const keyword = 'حذف';

  @override
  State<_ConfirmDeleteDialog> createState() => _ConfirmDeleteDialogState();
}

class _ConfirmDeleteDialogState extends State<_ConfirmDeleteDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _matches => _controller.text.trim() == _ConfirmDeleteDialog.keyword;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      icon: const Icon(Icons.warning_amber_rounded, color: _danger, size: 34),
      title: const Text('تأكيد حذف الحساب', textAlign: TextAlign.center),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'ستفقد كل سجلاتك ومستنداتك فوراً ولا يمكن استرجاعها لاحقاً.',
            style: TextStyle(height: 1.6, fontSize: 13),
          ),
          const SizedBox(height: 16),
          const Text(
            'اكتب «حذف» للمتابعة',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: ClinicColors.primaryDeep),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _controller,
            autofocus: true,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(hintText: 'حذف'),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('إلغاء'),
        ),
        FilledButton(
          onPressed: _matches ? () => Navigator.of(context).pop(true) : null,
          style: FilledButton.styleFrom(backgroundColor: _danger),
          child: const Text('حذف نهائي'),
        ),
      ],
    );
  }
}
