import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../state/admin_store.dart';
import '../widgets/ui.dart';

const chartColors = BrandPalette.chart;

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  int weeksBack = 8;

  @override
  Widget build(BuildContext context) {
    final store = AdminScope.of(context);
    final monthFmt = DateFormat('MMM yyyy', 'ar');
    final visitsByMonth = <String, int>{};
    for (final v in store.visits) {
      final key = monthFmt.format(v.visitDate);
      visitsByMonth[key] = (visitsByMonth[key] ?? 0) + 1;
    }
    final visitEntries = visitsByMonth.entries.toList();
    final specialtyMap = <String, int>{};
    for (final d in store.doctors) {
      specialtyMap[d.specialty] = (specialtyMap[d.specialty] ?? 0) + 1;
    }
    final specialtyEntries = specialtyMap.entries.toList();
    final fileMap = <String, int>{};
    for (final f in store.files) {
      fileMap[fileTypeAr(f.fileType)] = (fileMap[fileTypeAr(f.fileType)] ?? 0) + 1;
    }
    final fileEntries = fileMap.entries.toList();
    final doctorVisits = <String, int>{};
    for (final v in store.visits) {
      doctorVisits[v.doctorName] = (doctorVisits[v.doctorName] ?? 0) + 1;
    }
    final topDoctors = doctorVisits.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

    final weeks = <({String label, int visits, int files})>[];
    for (var i = weeksBack - 1; i >= 0; i--) {
      final start = store.now.subtract(Duration(days: i * 7));
      final weekStart = start.subtract(Duration(days: start.weekday - 1));
      final weekEnd = weekStart.add(const Duration(days: 6));
      weeks.add((
        label: DateFormat('d MMM', 'ar').format(weekStart),
        visits: store.visits.where((v) => !v.visitDate.isBefore(weekStart) && !v.visitDate.isAfter(weekEnd)).length,
        files: store.files.where((f) => !f.createdDate.isBefore(weekStart) && !f.createdDate.isAfter(weekEnd)).length,
      ));
    }
    final periodStart = store.now.subtract(Duration(days: (weeksBack - 1) * 7));
    final activity = <String, ({String name, String specialty, int visits, int files, DateTime? last})>{};
    for (final d in store.doctors) {
      activity[d.id] = (name: d.fullName, specialty: d.specialty, visits: 0, files: 0, last: null);
    }
    for (final v in store.visits.where((v) => !v.visitDate.isBefore(periodStart))) {
      final row = activity[v.doctorId];
      if (row == null) continue;
      activity[v.doctorId] = (name: row.name, specialty: row.specialty, visits: row.visits + 1, files: row.files, last: v.visitDate);
    }
    for (final f in store.files.where((f) => !f.createdDate.isBefore(periodStart))) {
      final row = activity[f.doctorId];
      if (row == null) continue;
      activity[f.doctorId] = (name: row.name, specialty: row.specialty, visits: row.visits, files: row.files + 1, last: f.createdDate);
    }
    final activeDoctors = activity.values.where((d) => d.visits > 0 || d.files > 0).toList()
      ..sort((a, b) => (b.visits + b.files).compareTo(a.visits + a.files));
    final totalWeekVisits = weeks.fold<int>(0, (s, w) => s + w.visits);
    final totalWeekFiles = weeks.fold<int>(0, (s, w) => s + w.files);
    final avg = activeDoctors.isEmpty ? 0 : totalWeekVisits / activeDoctors.length;

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const PageHeader(title: 'التحليلات', subtitle: 'إحصائيات ورؤى استخدام المنصة'),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 4,
          childAspectRatio: 2.4,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          children: [
            StatCard(title: 'المرضى', value: '${store.patients.length}', icon: Icons.groups, color: Colors.blue),
            StatCard(title: 'الأطباء', value: '${store.doctors.length}', icon: Icons.medical_services, color: Colors.green),
            StatCard(title: 'الزيارات', value: '${store.visits.length}', icon: Icons.event, color: Colors.purple),
            StatCard(title: 'الملفات', value: '${store.files.length}', icon: Icons.folder_copy, color: Colors.amber.shade800),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _chartCard(context, 'الزيارات حسب الشهر', visitEntries.isEmpty ? const EmptyHint('لا توجد بيانات زيارات بعد') : _bar(visitEntries))),
            const SizedBox(width: 12),
            Expanded(child: _chartCard(context, 'الأطباء حسب التخصص', specialtyEntries.isEmpty ? const EmptyHint('لا توجد بيانات أطباء بعد') : _pie(specialtyEntries))),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _chartCard(
                context,
                'توزيع أنواع الملفات',
                fileEntries.isEmpty
                    ? const EmptyHint('لا توجد بيانات ملفات بعد')
                    : SizedBox(
                        height: 220,
                        child: BarChart(
                          BarChartData(
                            alignment: BarChartAlignment.spaceAround,
                            gridData: const FlGridData(show: false),
                            borderData: FlBorderData(show: false),
                            titlesData: FlTitlesData(
                              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  getTitlesWidget: (value, _) {
                                    final i = value.toInt();
                                    if (i < 0 || i >= fileEntries.length) return const SizedBox.shrink();
                                    return Text(fileEntries[i].key, style: const TextStyle(fontSize: 10));
                                  },
                                ),
                              ),
                            ),
                            barGroups: [
                              for (var i = 0; i < fileEntries.length; i++)
                                BarChartGroupData(x: i, barRods: [BarChartRodData(toY: fileEntries[i].value.toDouble(), color: BrandPalette.accent, width: 16, borderRadius: BorderRadius.circular(4))]),
                            ],
                          ),
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('الأطباء الأكثر نشاطاً', style: Theme.of(context).textTheme.titleMedium),
                      if (topDoctors.isEmpty) const EmptyHint('لا يوجد نشاط بعد'),
                      for (var i = 0; i < topDoctors.take(5).length; i++)
                        ListTile(
                          leading: Text('${i + 1}'),
                          title: Text('د. ${topDoctors[i].key}'),
                          trailing: StatusChip(label: '${topDoctors[i].value} زيارة', color: Colors.cyan),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(child: Text('تقارير نشاط الأطباء الأسبوعية', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800))),
            PeriodChips(value: weeksBack, options: const [(4, '4 أسابيع'), (8, '8 أسابيع'), (12, '12 أسبوع')], onChanged: (v) => setState(() => weeksBack = v)),
          ],
        ),
        const SizedBox(height: 12),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 4,
          childAspectRatio: 2.4,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          children: [
            StatCard(title: 'مرضى تمت معاينتهم', value: '$totalWeekVisits', icon: Icons.groups, color: Colors.cyan),
            StatCard(title: 'تقارير مرفوعة', value: '$totalWeekFiles', icon: Icons.folder_copy, color: Colors.purple),
            StatCard(title: 'أطباء نشطون', value: '${activeDoctors.length}', icon: Icons.emoji_events, color: Colors.green),
            StatCard(title: 'متوسط المعاينات/طبيب', value: avg.toStringAsFixed(1), icon: Icons.trending_up, color: Colors.orange),
          ],
        ),
        const SizedBox(height: 12),
        _chartCard(
          context,
          'النشاط الأسبوعي — معاينات وتقارير',
          SizedBox(
            height: 260,
            child: BarChart(
              BarChartData(
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, _) {
                        final i = value.toInt();
                        if (i < 0 || i >= weeks.length) return const SizedBox.shrink();
                        return Text(weeks[i].label, style: const TextStyle(fontSize: 10));
                      },
                    ),
                  ),
                ),
                barGroups: [
                  for (var i = 0; i < weeks.length; i++)
                    BarChartGroupData(
                      x: i,
                      barRods: [
                        BarChartRodData(toY: weeks[i].visits.toDouble(), color: BrandPalette.accent, width: 8, borderRadius: BorderRadius.circular(4)),
                        BarChartRodData(toY: weeks[i].files.toDouble(), color: BrandPalette.primaryDeep, width: 8, borderRadius: BorderRadius.circular(4)),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('نشاط الأطباء التفصيلي', style: Theme.of(context).textTheme.titleMedium),
                if (activeDoctors.isEmpty) const EmptyHint('لا يوجد نشاط في هذه الفترة'),
                DataTable(
                  columns: const [
                    DataColumn(label: Text('#')),
                    DataColumn(label: Text('الطبيب')),
                    DataColumn(label: Text('التخصص')),
                    DataColumn(label: Text('معاينات')),
                    DataColumn(label: Text('تقارير')),
                    DataColumn(label: Text('الإجمالي')),
                    DataColumn(label: Text('آخر نشاط')),
                  ],
                  rows: [
                    for (var i = 0; i < activeDoctors.length; i++)
                      DataRow(cells: [
                        DataCell(Text('${i + 1}')),
                        DataCell(Text('د. ${activeDoctors[i].name}')),
                        DataCell(Text(activeDoctors[i].specialty)),
                        DataCell(Text('${activeDoctors[i].visits}')),
                        DataCell(Text('${activeDoctors[i].files}')),
                        DataCell(Text('${activeDoctors[i].visits + activeDoctors[i].files}')),
                        DataCell(Text(activeDoctors[i].last == null ? '—' : dateFmt.format(activeDoctors[i].last!))),
                      ]),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _chartCard(BuildContext context, String title, Widget child) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }

  Widget _bar(List<MapEntry<String, int>> entries) {
    return SizedBox(
      height: 220,
      child: BarChart(
        BarChartData(
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, _) {
                  final i = value.toInt();
                  if (i < 0 || i >= entries.length) return const SizedBox.shrink();
                  return Text(entries[i].key, style: const TextStyle(fontSize: 10));
                },
              ),
            ),
          ),
          barGroups: [
            for (var i = 0; i < entries.length; i++)
              BarChartGroupData(x: i, barRods: [BarChartRodData(toY: entries[i].value.toDouble(), color: BrandPalette.primary, width: 18, borderRadius: BorderRadius.circular(6))]),
          ],
        ),
      ),
    );
  }

  Widget _pie(List<MapEntry<String, int>> entries) {
    return SizedBox(
      height: 220,
      child: PieChart(
        PieChartData(
          sections: [
            for (var i = 0; i < entries.length; i++)
              PieChartSectionData(
                value: entries[i].value.toDouble(),
                title: '${entries[i].key} (${entries[i].value})',
                color: chartColors[i % chartColors.length],
                radius: 70,
                titleStyle: const TextStyle(fontSize: 10, color: Colors.white),
              ),
          ],
        ),
      ),
    );
  }
}
