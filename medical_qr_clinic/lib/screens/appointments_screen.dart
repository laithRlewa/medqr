import 'package:flutter/material.dart';

import '../models/models.dart';
import '../state/clinic_store.dart';
import '../theme/clinic_style.dart';
import '../widgets/mobile_kit.dart';
import '../widgets/ui.dart';

class AppointmentsScreen extends StatelessWidget {
  const AppointmentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = ClinicScope.of(context);
    final all = store.myAppointments;
    final pending = all.where((a) => a.status == 'pending').toList();
    final upcoming = all.where((a) => a.status == 'confirmed').toList();
    final past = all.where((a) => ['declined', 'cancelled', 'completed'].contains(a.status)).toList();
    final mobile = isMobileLayout(context);

    return ListView(
      padding: clinicPadding(context),
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('المواعيد', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: ClinicColors.primaryDeep)),
                  const SizedBox(height: 2),
                  Text(
                    store.isDoctor ? 'إدارة طلبات مواعيد المرضى' : 'طلباتك وجدولك',
                    style: const TextStyle(color: ClinicColors.muted, fontSize: 12),
                  ),
                ],
              ),
            ),
            if (store.isDoctor)
              CircleIconBtn(
                icon: Icons.schedule_outlined,
                size: 38,
                color: ClinicColors.tint,
                iconColor: ClinicColors.primary,
                onTap: () => store.goTo(ClinicPage.availability),
              ),
          ],
        ),
        const SizedBox(height: 10),
        SoftCard(
          radius: ClinicRadii.pill,
          padding: const EdgeInsets.all(4),
          color: ClinicColors.tint,
          child: Row(
            children: [
              for (final opt in const [('list', 'قائمة'), ('week', 'أسبوعي'), ('day', 'يومي')])
                Expanded(
                  child: _ViewTab(
                    label: opt.$2,
                    selected: store.appointmentView == opt.$1,
                    onTap: () {
                      store.appointmentView = opt.$1;
                      store.refreshUi();
                    },
                  ),
                ),
            ],
          ),
        ),
        if (store.isPatient) ...[
          const SizedBox(height: 10),
          OrangeButton(
            label: 'حجز موعد جديد',
            icon: Icons.add_rounded,
            onTap: () => store.goTo(ClinicPage.bookAppointment),
          ),
        ],
        if (store.isDoctor && !mobile) ...[
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              onPressed: () => store.goTo(ClinicPage.availability),
              icon: const Icon(Icons.schedule_outlined, size: 18),
              label: const Text('أوقات توافري'),
            ),
          ),
        ],
        const SizedBox(height: 12),
        if (all.isEmpty)
          SoftCard(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
              child: Column(
                children: [
                  const ClinicIllustration(ClinicArt.clipboardMeds, height: 120),
                  const SizedBox(height: 12),
                  const Text('لا توجد مواعيد بعد', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                  const SizedBox(height: 6),
                  Text(
                    store.isPatient ? 'احجز موعدك الأول مع طبيب متخصص' : 'ستظهر طلبات المرضى هنا',
                    style: const TextStyle(color: ClinicColors.muted),
                    textAlign: TextAlign.center,
                  ),
                  if (store.isPatient) ...[
                    const SizedBox(height: 16),
                    SizedBox(
                      width: 180,
                      child: OrangeButton(label: 'ابدأ الحجز', onTap: () => store.goTo(ClinicPage.bookAppointment)),
                    ),
                  ],
                ],
              ),
            ),
          )
        else if (store.appointmentView != 'list')
          _CalendarStrip(store: store)
        else ...[
          _Section(
            title: 'قيد المراجعة',
            count: pending.length,
            accent: const Color(0xFFE0A100),
            emptyLabel: 'لا توجد طلبات قيد المراجعة',
            children: [for (final a in pending) _AppointmentCard(appointment: a)],
          ),
          const SizedBox(height: 14),
          _Section(
            title: 'القادمة',
            count: upcoming.length,
            accent: ClinicColors.available,
            emptyLabel: 'لا توجد مواعيد قادمة',
            children: [for (final a in upcoming) _AppointmentCard(appointment: a)],
          ),
          const SizedBox(height: 14),
          _Section(
            title: 'السابقة',
            count: past.length,
            accent: ClinicColors.muted,
            emptyLabel: 'لا توجد مواعيد سابقة',
            children: [for (final a in past) _AppointmentCard(appointment: a)],
          ),
        ],
      ],
    );
  }
}

class _ViewTab extends StatelessWidget {
  const _ViewTab({required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? ClinicColors.primary : Colors.transparent,
      borderRadius: BorderRadius.circular(ClinicRadii.pill),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(ClinicRadii.pill),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 11),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 13,
              color: selected ? Colors.white : ClinicColors.ink,
            ),
          ),
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.count,
    required this.accent,
    required this.emptyLabel,
    required this.children,
  });

  final String title;
  final int count;
  final Color accent;
  final String emptyLabel;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text('$count', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: accent)),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (children.isEmpty)
          SoftCard(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            child: Center(child: Text(emptyLabel, style: const TextStyle(color: ClinicColors.muted))),
          )
        else
          for (final child in children) ...[
            child,
            const SizedBox(height: 10),
          ],
      ],
    );
  }
}

class _CalendarStrip extends StatelessWidget {
  const _CalendarStrip({required this.store});
  final ClinicStore store;

  @override
  Widget build(BuildContext context) {
    final start = store.appointmentView == 'week'
        ? store.calendarDate.subtract(Duration(days: store.calendarDate.weekday % 7))
        : store.calendarDate;
    final days = store.appointmentView == 'week' ? 7 : 1;

    return Column(
      children: [
        SoftCard(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Row(
            children: [
              IconButton(
                onPressed: () {
                  store.calendarDate = store.calendarDate.subtract(Duration(days: days));
                  store.refreshUi();
                },
                icon: const Icon(Icons.chevron_right),
              ),
              Expanded(
                child: Column(
                  children: [
                    Text(dateFmt.format(store.calendarDate), style: const TextStyle(fontWeight: FontWeight.w800)),
                    TextButton(
                      onPressed: () {
                        store.calendarDate = DateTime.now();
                        store.refreshUi();
                      },
                      child: const Text('اليوم', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () {
                  store.calendarDate = store.calendarDate.add(Duration(days: days));
                  store.refreshUi();
                },
                icon: const Icon(Icons.chevron_left),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        for (var i = 0; i < days; i++) ...[
          _DayBlock(store: store, day: start.add(Duration(days: i))),
          const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _DayBlock extends StatelessWidget {
  const _DayBlock({required this.store, required this.day});
  final ClinicStore store;
  final DateTime day;

  @override
  Widget build(BuildContext context) {
    final items = store.myAppointments
        .where((a) => a.appointmentDate.year == day.year && a.appointmentDate.month == day.month && a.appointmentDate.day == day.day)
        .toList()
      ..sort((a, b) => a.appointmentTime.compareTo(b.appointmentTime));

    return SoftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${weekDays[day.weekday % 7]} · ${dateFmt.format(day)}',
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
          ),
          const SizedBox(height: 10),
          if (items.isEmpty)
            const Text('لا مواعيد في هذا اليوم', style: TextStyle(color: ClinicColors.muted))
          else
            for (final a in items) ...[
              _AppointmentCard(appointment: a),
              if (a != items.last) const SizedBox(height: 10),
            ],
        ],
      ),
    );
  }
}

class _AppointmentCard extends StatelessWidget {
  const _AppointmentCard({required this.appointment});
  final Appointment appointment;

  @override
  Widget build(BuildContext context) {
    final store = ClinicScope.of(context);
    final a = appointment;
    final statusColor = appointmentColor(a.status);
    final person = store.isDoctor ? a.patientName : 'د. ${a.doctorName}';
    final detail = store.isDoctor
        ? (a.reason.isNotEmpty ? a.reason : a.patientPhone)
        : a.doctorSpecialty;

    return SoftCard(
      onTap: () => _details(context, store, a),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PhotoAvatar(name: store.isDoctor ? a.patientName : a.doctorName, size: 48),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(person, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                    if (detail.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(detail, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: ClinicColors.muted, fontSize: 12)),
                    ],
                  ],
                ),
              ),
              StatusChip(label: appointmentStatusLabel(a.status), color: statusColor),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: ClinicColors.tint,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today_outlined, size: 15, color: ClinicColors.primary),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    dateFmt.format(a.appointmentDate),
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 10),
                const Icon(Icons.schedule, size: 15, color: ClinicColors.primary),
                const SizedBox(width: 6),
                Text(a.appointmentTime, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
              ],
            ),
          ),
          if (_hasActions(store, a)) ...[
            const SizedBox(height: 12),
            _Actions(appointment: a),
          ],
        ],
      ),
    );
  }

  bool _hasActions(ClinicStore store, Appointment a) {
    if (store.isDoctor && (a.status == 'pending' || a.status == 'confirmed')) return true;
    if ((a.status == 'pending' || a.status == 'confirmed') && (store.isPatient || store.isDoctor)) return true;
    return false;
  }

  void _details(BuildContext context, ClinicStore store, Appointment a) {
    if (store.isDoctor && a.status == 'pending') {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(a.patientName),
          content: Text('${dateFmt.format(a.appointmentDate)} الساعة ${a.appointmentTime}\n${a.reason}\n${a.patientPhone}'),
          actions: [
            TextButton(onPressed: () { store.declineAppointment(a); Navigator.pop(ctx); }, child: const Text('رفض')),
            FilledButton(onPressed: () { store.confirmAppointment(a); Navigator.pop(ctx); }, child: const Text('تأكيد')),
          ],
        ),
      );
      return;
    }
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تفاصيل الموعد'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('الطبيب: د. ${a.doctorName}'),
            Text('المريض: ${a.patientName}'),
            Text('التاريخ: ${dateFmt.format(a.appointmentDate)} ${a.appointmentTime}'),
            Text('الحالة: ${appointmentStatusLabel(a.status)}'),
            if (a.reason.isNotEmpty) Text('السبب: ${a.reason}'),
          ],
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إغلاق'))],
      ),
    );
  }
}

class _Actions extends StatelessWidget {
  const _Actions({required this.appointment});
  final Appointment appointment;

  @override
  Widget build(BuildContext context) {
    final store = ClinicScope.of(context);
    final a = appointment;

    if (store.isDoctor && a.status == 'pending') {
      return Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => store.declineAppointment(a),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFC62828),
                side: const BorderSide(color: Color(0xFFFFCDD2)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              icon: const Icon(Icons.close_rounded, size: 18),
              label: const Text('رفض'),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: FilledButton.icon(
              onPressed: () => store.confirmAppointment(a),
              style: FilledButton.styleFrom(
                backgroundColor: ClinicColors.available,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              icon: const Icon(Icons.check_rounded, size: 18),
              label: const Text('تأكيد'),
            ),
          ),
        ],
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        if ((a.status == 'pending' || a.status == 'confirmed') && (store.isPatient || store.isDoctor))
          OutlinedButton(
            onPressed: () => store.cancelAppointment(a),
            style: OutlinedButton.styleFrom(
              foregroundColor: ClinicColors.ink,
              side: const BorderSide(color: ClinicColors.border),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: const Text('إلغاء الموعد'),
          ),
        if (store.isDoctor && a.status == 'confirmed')
          FilledButton(
            onPressed: () => store.completeAppointment(a),
            style: FilledButton.styleFrom(
              backgroundColor: ClinicColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: const Text('إكمال'),
          ),
      ],
    );
  }
}
