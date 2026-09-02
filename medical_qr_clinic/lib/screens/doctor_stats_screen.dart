import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../state/clinic_store.dart';
import '../theme/clinic_style.dart';
import '../widgets/ui.dart';

class DoctorStatsScreen extends StatelessWidget {
  const DoctorStatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = ClinicScope.of(context);
    final doctor = store.currentDoctor;
    if (doctor == null) return const EmptyHint('لا يوجد ملف طبيب');
    final visits = store.visitsForDoctor(doctor.id);
    final files = store.files.where((f) => f.doctorId == doctor.id).toList();
    final appts = store.myAppointments;
    final unique = visits.map((v) => v.patientId).toSet().length;
    final now = DateTime.now();
    final thisMonth = visits.where((v) => v.visitDate.year == now.year && v.visitDate.month == now.month).length;
    final months = List.generate(6, (i) {
      final d = DateTime(now.year, now.month - 5 + i);
      final count = visits.where((v) => v.visitDate.year == d.year && v.visitDate.month == d.month).length;
      return (d, count);
    });
    final statuses = {
      'pending': appts.where((a) => a.status == 'pending').length,
      'confirmed': appts.where((a) => a.status == 'confirmed').length,
      'completed': appts.where((a) => a.status == 'completed').length,
      'cancelled': appts.where((a) => a.status == 'cancelled' || a.status == 'declined').length,
    };
    final upcoming = appts.where((a) => a.status == 'confirmed' && a.dateTime.isAfter(now)).take(6).toList();

    return ListView(
      padding: clinicPadding(context),
      children: [
        const PageHeader(title: 'إحصائيات العيادة', subtitle: 'ملخص نشاطك كطبيب', icon: Icons.bar_chart),
        Wrap(spacing: 12, runSpacing: 12, children: [
          SizedBox(width: 240, child: StatCard(title: 'مرضى فريدون', value: '$unique', icon: Icons.groups_outlined, color: Colors.blue)),
          SizedBox(width: 240, child: StatCard(title: 'زيارات هذا الشهر', value: '$thisMonth', icon: Icons.event, color: Colors.green)),
          SizedBox(width: 240, child: StatCard(title: 'كل الزيارات', value: '${visits.length}', icon: Icons.medical_services_outlined, color: Colors.teal)),
          SizedBox(width: 240, child: StatCard(title: 'ملفات مرفوعة', value: '${files.length}', icon: Icons.description_outlined, color: Colors.purple)),
          SizedBox(width: 240, child: StatCard(title: 'مواعيد قيد المراجعة', value: '${statuses['pending']}', icon: Icons.hourglass_top, color: Colors.amber.shade800)),
          SizedBox(width: 240, child: StatCard(title: 'مواعيد مؤكدة', value: '${statuses['confirmed']}', icon: Icons.check_circle_outline, color: Colors.indigo)),
        ]),
        const SizedBox(height: 16),
        SectionCard(
          title: 'الزيارات خلال 6 أشهر',
          child: SizedBox(
            height: 220,
            child: BarChart(BarChartData(
              titlesData: FlTitlesData(
                leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (v, _) {
                  final i = v.toInt();
                  if (i < 0 || i >= months.length) return const SizedBox.shrink();
                  return Text('${months[i].$1.month}', style: const TextStyle(fontSize: 11));
                })),
              ),
              barGroups: [
                for (var i = 0; i < months.length; i++)
                  BarChartGroupData(x: i, barRods: [BarChartRodData(toY: months[i].$2.toDouble(), color: ClinicColors.primary)]),
              ],
            )),
          ),
        ),
        const SizedBox(height: 12),
        SectionCard(
          title: 'حالة المواعيد',
          child: SizedBox(
            height: 200,
            child: PieChart(PieChartData(sections: [
              PieChartSectionData(value: statuses['pending']!.toDouble() + 0.01, color: Colors.amber, title: 'مراجعة'),
              PieChartSectionData(value: statuses['confirmed']!.toDouble() + 0.01, color: Colors.indigo, title: 'مؤكد'),
              PieChartSectionData(value: statuses['completed']!.toDouble() + 0.01, color: Colors.green, title: 'مكتمل'),
              PieChartSectionData(value: statuses['cancelled']!.toDouble() + 0.01, color: Colors.redAccent, title: 'ملغى'),
            ])),
          ),
        ),
        const SizedBox(height: 12),
        SectionCard(
          title: 'المواعيد القادمة',
          child: upcoming.isEmpty
              ? const Text('لا توجد مواعيد قادمة')
              : Column(children: [
                  for (final a in upcoming)
                    ListTile(
                      title: Text(a.patientName),
                      subtitle: Text('${dateFmt.format(a.appointmentDate)} · ${a.appointmentTime}'),
                      onTap: () => store.goTo(ClinicPage.doctorCalendar),
                    ),
                ]),
        ),
      ],
    );
  }
}
