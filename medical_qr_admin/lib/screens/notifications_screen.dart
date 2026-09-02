import 'package:flutter/material.dart';

import '../state/admin_store.dart';
import '../widgets/ui.dart';

IconData _iconFor(String type) => switch (type) {
      'diagnosis' => Icons.medical_services_outlined,
      'prescription' || 'report' => Icons.description_outlined,
      'post' || 'profile' => Icons.person_outline,
      'access_granted' => Icons.verified_user_outlined,
      'access_expired' => Icons.timer_off_outlined,
      _ => Icons.notifications_outlined,
    };

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = AdminScope.of(context);
    final items = store.notifications.where((n) => n.userId == (store.currentUser?.id ?? 'local-admin') || n.userId == 'local-admin').toList();
    final unread = items.where((n) => !n.read).length;
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Row(
          children: [
            Expanded(child: PageHeader(title: 'الإشعارات', subtitle: '$unread غير مقروء')),
            OutlinedButton.icon(
              onPressed: () => _openBroadcast(context, store),
              icon: const Icon(Icons.campaign_outlined),
              label: const Text('إرسال إشعار'),
            ),
            if (unread > 0) TextButton(onPressed: store.markAllNotificationsRead, child: const Text('تحديد الكل كمقروء')),
          ],
        ),
        if (items.isEmpty) const EmptyHint('لا توجد إشعارات بعد'),
        ...items.map(
          (item) => Card(
            color: item.read ? null : Theme.of(context).colorScheme.primary.withValues(alpha: 0.06),
            child: ListTile(
              leading: Icon(_iconFor(item.type), color: item.read ? null : Theme.of(context).colorScheme.primary),
              title: Text(item.title, style: TextStyle(fontWeight: item.read ? FontWeight.w500 : FontWeight.w800)),
              subtitle: Text('${item.message}\n${fromNow(item.createdDate, store.now)}'),
              isThreeLine: true,
              trailing: item.read
                  ? null
                  : IconButton(onPressed: () => store.markNotificationRead(item), icon: const Icon(Icons.check)),
              onTap: () => store.markNotificationRead(item),
            ),
          ),
        ),
      ],
    );
  }
}

Future<void> _openBroadcast(BuildContext context, AdminStore store) async {
  final title = TextEditingController();
  final message = TextEditingController();
  var role = 'all';
  await showDialog<bool>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: const Text('إرسال إشعار للمستخدمين'),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: title, decoration: const InputDecoration(labelText: 'العنوان')),
              const SizedBox(height: 12),
              TextField(controller: message, maxLines: 3, decoration: const InputDecoration(labelText: 'النص')),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: role,
                decoration: const InputDecoration(labelText: 'الجمهور'),
                items: const [
                  DropdownMenuItem(value: 'all', child: Text('كل المرضى والأطباء')),
                  DropdownMenuItem(value: 'patient', child: Text('المرضى فقط')),
                  DropdownMenuItem(value: 'doctor', child: Text('الأطباء فقط')),
                ],
                onChanged: (value) => setState(() => role = value ?? 'all'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء')),
          FilledButton(
            onPressed: () async {
              if (title.text.trim().isEmpty || message.text.trim().isEmpty) return;
              final error = await store.broadcastNotification(title: title.text, message: message.text, role: role);
              if (!context.mounted) return;
              Navigator.pop(context, error == null);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error ?? 'تم إرسال الإشعار')));
            },
            child: const Text('إرسال'),
          ),
        ],
      ),
    ),
  );
  title.dispose();
  message.dispose();
}
