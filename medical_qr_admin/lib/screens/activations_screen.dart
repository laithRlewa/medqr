import 'package:flutter/material.dart';

import '../models/models.dart';
import '../state/admin_store.dart';
import '../widgets/ui.dart';

class ActivationsScreen extends StatefulWidget {
  const ActivationsScreen({super.key});

  @override
  State<ActivationsScreen> createState() => _ActivationsScreenState();
}

class _ActivationsScreenState extends State<ActivationsScreen> {
  String search = '';
  String filter = 'all';

  @override
  Widget build(BuildContext context) {
    final store = AdminScope.of(context);
    final today = DateTime(store.now.year, store.now.month, store.now.day);
    final filtered = store.doctors.where((d) {
      if (filter == 'active' && d.subscriptionStatus != 'active') return false;
      if (filter == 'inactive' && d.subscriptionStatus == 'active') return false;
      if (filter == 'expiring') {
        if (d.subscriptionStatus != 'active' || d.subscriptionEnd == null) return false;
        final days = d.subscriptionEnd!.difference(today).inDays;
        if (days < 0 || days > 7) return false;
      }
      final q = search.trim().toLowerCase();
      if (q.isNotEmpty && !d.fullName.toLowerCase().contains(q) && !d.specialty.toLowerCase().contains(q)) return false;
      return true;
    }).toList();

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const PageHeader(title: 'تفعيل اشتراكات الأطباء', subtitle: 'إدارة اشتراكات الأطباء وتواريخ انتهائها', icon: Icons.credit_card),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 4,
          childAspectRatio: 2.4,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          children: [
            StatCard(title: 'إجمالي الأطباء', value: '${store.doctors.length}', icon: Icons.medical_services, color: Colors.cyan),
            StatCard(title: 'اشتراكات نشطة', value: '${store.activeSubscriptions}', icon: Icons.check_circle, color: Colors.green),
            StatCard(title: 'غير نشطة', value: '${store.doctors.length - store.activeSubscriptions}', icon: Icons.cancel, color: Colors.grey),
            StatCard(title: 'تنتهي قريباً (7 أيام)', value: '${store.expiringSoon}', icon: Icons.warning_amber, color: Colors.orange),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            SearchField(hint: 'ابحث بالاسم أو التخصص...', onChanged: (v) => setState(() => search = v)),
            const SizedBox(width: 12),
            PeriodChips(value: filter, options: const [('all', 'الكل'), ('active', 'نشط'), ('inactive', 'غير نشط'), ('expiring', 'تنتهي قريباً')], onChanged: (v) => setState(() => filter = v)),
          ],
        ),
        const SizedBox(height: 16),
        if (filtered.isEmpty) const EmptyHint('لا يوجد أطباء مطابقون'),
        ...filtered.map((doc) {
          final days = doc.subscriptionEnd?.difference(today).inDays;
          return Card(
            child: ListTile(
              leading: AvatarCircle(name: doc.fullName, photo: doc.profilePhoto),
              title: Text('د. ${doc.fullName}'),
              subtitle: Text([
                '${doc.specialty} · ${doc.city}',
                if (doc.subscriptionStatus == 'active' && doc.subscriptionEnd != null) 'ينتهي: ${dateFmt.format(doc.subscriptionEnd!)}',
                if (doc.paymentAmount > 0) 'آخر دفعة: ${doc.paymentAmount.toStringAsFixed(0)} دينار',
              ].join('\n')),
              isThreeLine: true,
              trailing: Wrap(
                spacing: 8,
                children: [
                  StatusChip(
                    label: doc.subscriptionStatus == 'active' ? (days != null && days <= 7 ? 'ينتهي خلال $days يوم' : 'نشط') : 'غير نشط',
                    color: doc.subscriptionStatus == 'active' ? (days != null && days <= 7 ? Colors.orange : Colors.green) : Colors.grey,
                  ),
                  OutlinedButton(onPressed: () => _showCard(store, doc), child: const Text('البطاقة')),
                  OutlinedButton(onPressed: () => _showHistory(store, doc), child: const Text('السجل')),
                  FilledButton(onPressed: () => _activate(store, doc), child: Text(doc.subscriptionStatus == 'active' ? 'تجديد' : 'تفعيل')),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Future<void> _activate(AdminStore store, Doctor doctor) async {
    final amount = TextEditingController();
    var duration = durations.first;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) {
          final start = DateTime.now();
          final end = DateTime(start.year, start.month + duration.$3, start.day);
          final card = store.cardFor(doctor.id);
          return AlertDialog(
            title: const Text('تفعيل اشتراك الطبيب'),
            content: SizedBox(
              width: 440,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('د. ${doctor.fullName} · ${doctor.specialty}'),
                  if (doctor.subscriptionStatus == 'active' && doctor.subscriptionEnd != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: StatusChip(label: 'اشتراك حالي نشط حتى ${dateFmt.format(doctor.subscriptionEnd!)}', color: Colors.cyan),
                    ),
                  if (card != null) ...[
                    const SizedBox(height: 12),
                    Text('بطاقة الدفع المسجلة: ${card.cardHolderName} · ${card.bankName} · •••• ${card.cardNumber.substring(card.cardNumber.length - 4)}'),
                  ],
                  const SizedBox(height: 16),
                  TextField(controller: amount, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'مبلغ الدفع (دينار)')),
                  const SizedBox(height: 12),
                  DropdownButtonFormField(
                    initialValue: duration,
                    items: [for (final item in durations) DropdownMenuItem(value: item, child: Text(item.$2))],
                    onChanged: (value) => setLocal(() => duration = value ?? duration),
                    decoration: const InputDecoration(labelText: 'مدة الاشتراك'),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: Text('تاريخ البدء\n${dateFmt.format(start)}')),
                      Expanded(child: Text('تاريخ الانتهاء\n${dateFmt.format(end)}')),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
              FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('تأكيد التفعيل')),
            ],
          );
        },
      ),
    );
    final parsed = double.tryParse(amount.text);
    WidgetsBinding.instance.addPostFrameCallback((_) => amount.dispose());
    if (ok == true) {
      final error = await store.activateDoctor(doctor: doctor, amount: parsed ?? 0, duration: duration.$1, months: duration.$3);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error ?? 'تم تفعيل الاشتراك بنجاح')));
    }
  }

  void _showCard(AdminStore store, Doctor doctor) {
    final card = store.cardFor(doctor.id);
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('بطاقة د. ${doctor.fullName}'),
        content: card == null
            ? const Text('لا توجد بطاقة مسجلة لهذا الطبيب')
            : Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 360,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), color: BrandPalette.primary),
                    child: DefaultTextStyle(
                      style: const TextStyle(color: Colors.white),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(card.bankName),
                          const SizedBox(height: 18),
                          Text(card.cardNumber, style: const TextStyle(fontSize: 18, letterSpacing: 1.4)),
                          const SizedBox(height: 18),
                          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(card.cardHolderName), Text(card.cardExpiry)]),
                        ],
                      ),
                    ),
                  ),
                  if (card.cardCvv.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text('رمز التحقق (CVV): ${card.cardCvv}'),
                  ],
                ],
              ),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إغلاق'))],
      ),
    );
  }

  void _showHistory(AdminStore store, Doctor doctor) {
    final logs = store.historyFor(doctor.id);
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('سجل تفعيل د. ${doctor.fullName}'),
        content: SizedBox(
          width: 460,
          child: logs.isEmpty
              ? const Text('لا يوجد سجل تفعيل')
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (final log in logs)
                      ListTile(
                        title: Text('${log.action == 'reactivate' ? 'تجديد' : log.action == 'expire' ? 'انتهاء تلقائي' : 'تفعيل'} · ${durationAr(log.duration)}'),
                        subtitle: Text('${log.paymentAmount.toStringAsFixed(0)} دينار · بواسطة ${log.adminName}'),
                        trailing: Text(dateFmt.format(log.createdDate)),
                      ),
                  ],
                ),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إغلاق'))],
      ),
    );
  }
}
