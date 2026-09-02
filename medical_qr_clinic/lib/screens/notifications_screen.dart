import 'package:flutter/material.dart';

import '../state/clinic_store.dart';
import '../widgets/ui.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = ClinicScope.of(context);
    final items = store.myNotifications;
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        PageHeader(
          title: 'الإشعارات',
          subtitle: '${store.unreadCount} غير مقروء',
          icon: Icons.notifications_outlined,
          actions: [
            if (store.unreadCount > 0)
              OutlinedButton.icon(onPressed: store.markAllRead, icon: const Icon(Icons.done_all), label: const Text('تحديد الكل كمقروء')),
          ],
        ),
        if (items.isEmpty) const EmptyHint('لا توجد إشعارات بعد', art: ClinicArt.profileVisit),
        for (final n in items)
          Card(
            color: n.read ? null : ClinicColors.primary.withValues(alpha: 0.07),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: notifColor(n.type).withValues(alpha: 0.15),
                child: Icon(notifIcon(n.type), color: notifColor(n.type)),
              ),
              title: Text(n.title, style: TextStyle(fontWeight: n.read ? FontWeight.w500 : FontWeight.w800)),
              subtitle: Text('${n.message}\n${fromNow(n.createdDate)}'),
              isThreeLine: true,
              trailing: n.read
                  ? null
                  : IconButton(onPressed: () => store.markRead(n), icon: const Icon(Icons.check)),
              onTap: () {
                store.markRead(n);
                store.openFromNotification(type: n.type, link: n.link);
              },
            ),
          ),
      ],
    );
  }
}
