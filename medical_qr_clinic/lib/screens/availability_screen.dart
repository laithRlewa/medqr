import 'package:flutter/material.dart';

import '../state/clinic_store.dart';
import '../widgets/ui.dart';

class AvailabilityScreen extends StatefulWidget {
  const AvailabilityScreen({super.key});

  @override
  State<AvailabilityScreen> createState() => _AvailabilityScreenState();
}

class _AvailabilityScreenState extends State<AvailabilityScreen> {
  int day = 1;
  TimeOfDay start = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay end = const TimeOfDay(hour: 17, minute: 0);

  String _fmt(TimeOfDay t) => '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final store = ClinicScope.of(context);
    final doctor = store.currentDoctor;
    if (doctor == null) return const EmptyHint('لا يوجد ملف طبيب');
    final slots = store.availabilityFor(doctor.id);

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const PageHeader(title: 'أوقات توافري', subtitle: 'حدد الأيام والساعات المتاحة للحجز', icon: Icons.schedule),
        SectionCard(
          title: 'إضافة فترة',
          child: Wrap(
            spacing: 12,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SizedBox(
                width: 180,
                child: DropdownButtonFormField<int>(
                  initialValue: day,
                  decoration: const InputDecoration(labelText: 'اليوم'),
                  items: [for (var i = 0; i < weekDays.length; i++) DropdownMenuItem(value: i, child: Text(weekDays[i]))],
                  onChanged: (v) => setState(() => day = v ?? day),
                ),
              ),
              OutlinedButton(onPressed: () async {
                final t = await showTimePicker(context: context, initialTime: start);
                if (t != null) setState(() => start = t);
              }, child: Text('من ${_fmt(start)}')),
              OutlinedButton(onPressed: () async {
                final t = await showTimePicker(context: context, initialTime: end);
                if (t != null) setState(() => end = t);
              }, child: Text('إلى ${_fmt(end)}')),
              FilledButton(
                onPressed: () {
                  store.addAvailability(dayOfWeek: day, start: _fmt(start), end: _fmt(end));
                  toast(context, store.lastMessage ?? '');
                },
                child: const Text('إضافة'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        if (slots.isEmpty) const EmptyHint('لا توجد أوقات مسجلة'),
        for (final slot in slots)
          Card(
            child: ListTile(
              title: Text(weekDays[slot.dayOfWeek]),
              subtitle: Text('${slot.startTime} — ${slot.endTime}'),
              trailing: Wrap(children: [
                Switch(value: slot.isAvailable, onChanged: (_) => store.toggleAvailability(slot)),
                IconButton(onPressed: () => store.deleteAvailability(slot), icon: const Icon(Icons.delete_outline)),
              ]),
            ),
          ),
      ],
    );
  }
}
