import 'package:flutter/material.dart';

import '../state/admin_store.dart';
import '../widgets/ui.dart';

class AuditScreen extends StatefulWidget {
  const AuditScreen({super.key});

  @override
  State<AuditScreen> createState() => _AuditScreenState();
}

class _AuditScreenState extends State<AuditScreen> {
  String search = '';
  String type = 'all';

  @override
  Widget build(BuildContext context) {
    final store = AdminScope.of(context);
    final q = search.trim().toLowerCase();
    final filtered = store.auditLogs.take(store.auditLimit).where((l) {
      if (type != 'all' && l.actionType != type) return false;
      if (q.isEmpty) return true;
      return l.description.toLowerCase().contains(q) || l.userName.toLowerCase().contains(q);
    }).toList();

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const PageHeader(title: 'سجلات التدقيق', subtitle: 'سجل كامل لجميع الأنشطة في النظام', icon: Icons.fact_check),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 4,
          childAspectRatio: 2.6,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          children: [
            StatCard(title: 'إجمالي السجلات', value: '${filtered.length}', icon: Icons.list_alt, color: Colors.cyan),
            StatCard(title: 'عمليات دخول', value: '${filtered.where((l) => l.actionType == 'login').length}', icon: Icons.login, color: Colors.green),
            StatCard(title: 'عمليات طبية', value: '${filtered.where((l) => l.actionType.contains('file') || l.actionType.contains('diagnosis')).length}', icon: Icons.medical_information, color: Colors.purple),
            StatCard(title: 'مستخدمون نشطون', value: '${filtered.map((l) => l.userId).toSet().length}', icon: Icons.person, color: Colors.orange),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            SearchField(hint: 'بحث بالاسم أو الوصف...', onChanged: (v) => setState(() => search = v)),
            const SizedBox(width: 12),
            SizedBox(
              width: 260,
              child: DropdownButtonFormField<String>(
                initialValue: type,
                items: [
                  const DropdownMenuItem(value: 'all', child: Text('كل الإجراءات')),
                  for (final e in actionTypesAr.entries) DropdownMenuItem(value: e.key, child: Text(e.value)),
                ],
                onChanged: (v) => setState(() => type = v ?? 'all'),
                decoration: const InputDecoration(labelText: 'نوع الإجراء'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (filtered.isEmpty) const EmptyHint('لم يتم العثور على سجلات'),
        ...filtered.map((log) {
          return Card(
            child: ListTile(
              leading: AvatarCircle(name: log.userName),
              title: Text(log.userName),
              subtitle: Text([
                log.description,
                '${roleAr(log.userRole)} · ${actionAr(log.actionType)}',
                '${longDateFmt.format(log.createdDate)} · (${fromNow(log.createdDate, store.now)})',
                if (log.targetType != null) 'الهدف: ${log.targetType}',
                if (log.ipAddress != null) 'IP: ${log.ipAddress}',
              ].join('\n')),
              isThreeLine: true,
              trailing: StatusChip(label: actionAr(log.actionType), color: log.actionType == 'admin_action' ? Colors.red : Colors.cyan),
            ),
          );
        }),
        if (store.auditLogs.length > store.auditLimit)
          Center(
            child: OutlinedButton(onPressed: store.loadMoreAudit, child: const Text('تحميل المزيد')),
          ),
      ],
    );
  }
}
