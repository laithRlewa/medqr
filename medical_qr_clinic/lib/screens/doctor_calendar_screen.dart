import 'package:flutter/material.dart';

import '../state/clinic_store.dart';
import '../widgets/ui.dart';

class DoctorCalendarScreen extends StatelessWidget {
  const DoctorCalendarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = ClinicScope.of(context);
    final start = DateTime.now();
    final days = List.generate(14, (i) => start.add(Duration(days: i)));

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        PageHeader(
          title: 'تقويم المواعيد',
          subtitle: 'الأسبوعان القادمان',
          icon: Icons.calendar_view_week,
          actions: [
            OutlinedButton(onPressed: () => store.goTo(ClinicPage.appointments), child: const Text('قائمة المواعيد')),
            const SizedBox(width: 8),
            OutlinedButton(onPressed: () => store.goTo(ClinicPage.availability), child: const Text('أوقات التوفر')),
          ],
        ),
        for (final day in days)
          Builder(builder: (context) {
            final items = store.myAppointments.where((a) =>
                a.appointmentDate.year == day.year &&
                a.appointmentDate.month == day.month &&
                a.appointmentDate.day == day.day).toList()
              ..sort((a, b) => a.appointmentTime.compareTo(b.appointmentTime));
            return Card(
              child: ExpansionTile(
                title: Text('${weekDays[day.weekday % 7]} · ${dateFmt.format(day)}'),
                subtitle: Text(items.isEmpty ? 'لا مواعيد' : '${items.length} موعد'),
                children: [
                  if (items.isEmpty) const ListTile(title: Text('يوم فارغ')),
                  for (final a in items)
                    ListTile(
                      title: Text('${a.appointmentTime} · ${a.patientName}'),
                      subtitle: Text(a.reason),
                      trailing: StatusChip(label: appointmentStatusLabel(a.status), color: appointmentColor(a.status)),
                    ),
                ],
              ),
            );
          }),
      ],
    );
  }
}
