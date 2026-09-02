import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../models/models.dart';
import '../state/admin_store.dart';
import '../widgets/ui.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int days = 7;

  @override
  Widget build(BuildContext context) {
    final store = AdminScope.of(context);
    final data = store.dailyLogins(days);
    final totalPatients = data.fold<int>(0, (s, e) => s + e.patients);
    final totalDoctors = data.fold<int>(0, (s, e) => s + e.doctors);
    final empty = data.every((e) => e.patients == 0 && e.doctors == 0);

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const PageHeader(title: 'لوحة الإدارة', subtitle: 'إدارة ومراقبة منصة الرمز الطبي العراقي'),
        LayoutBuilder(builder: (context, constraints) {
          final width = constraints.maxWidth < 520 ? constraints.maxWidth : (constraints.maxWidth < 980 ? (constraints.maxWidth - 12) / 2 : (constraints.maxWidth - 36) / 4);
          return Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              SizedBox(width: width, child: StatCard(title: 'إجمالي المرضى', value: '${store.patients.length}', icon: Icons.groups, color: Colors.blue, onTap: () => store.goTo(AdminPage.patients))),
              SizedBox(width: width, child: StatCard(title: 'إجمالي الأطباء', value: '${store.doctors.length}', icon: Icons.medical_services, color: Colors.green, onTap: () => store.goTo(AdminPage.doctors))),
              SizedBox(width: width, child: StatCard(title: 'إجمالي المستخدمين', value: '${store.users.length}', icon: Icons.people_alt, color: Colors.teal, onTap: () => store.goTo(AdminPage.users))),
              SizedBox(width: width, child: StatCard(title: 'إجمالي المنشورات', value: '${store.posts.length}', icon: Icons.article, color: Colors.indigo, onTap: () => store.goTo(AdminPage.posts))),
              SizedBox(width: width, child: StatCard(title: 'إجمالي الزيارات', value: '${store.visits.length}', icon: Icons.event, color: Colors.purple)),
              SizedBox(width: width, child: StatCard(title: 'الملفات الطبية', value: '${store.files.length}', icon: Icons.folder_copy, color: Colors.amber.shade800)),
              SizedBox(width: width, child: StatCard(title: 'أطباء قيد المراجعة', value: '${store.pendingDoctors}', icon: Icons.pending_actions, color: Colors.red, onTap: () => store.goTo(AdminPage.doctors))),
              SizedBox(width: width, child: StatCard(title: 'الجلسات النشطة', value: '${store.activeSessions}', icon: Icons.sensors, color: Colors.cyan)),
            ],
          );
        }),
        const SizedBox(height: 20),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.login, color: Theme.of(context).colorScheme.primary),
                    const SizedBox(width: 8),
                    Text('تسجيلات الدخول اليومية', style: Theme.of(context).textTheme.titleMedium),
                    const Spacer(),
                    PeriodChips(value: days, options: const [(7, '7 أيام'), (14, '14 يوم'), (30, '30 يوم')], onChanged: (v) => setState(() => days = v)),
                  ],
                ),
                const SizedBox(height: 12),
                Text('المرضى: $totalPatients    الأطباء: $totalDoctors'),
                const SizedBox(height: 12),
                SizedBox(
                  height: 280,
                  child: empty
                      ? const EmptyHint('لا توجد تسجيلات دخول في هذه الفترة')
                      : BarChart(
                          BarChartData(
                            gridData: const FlGridData(show: true),
                            borderData: FlBorderData(show: false),
                            titlesData: FlTitlesData(
                              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 28)),
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  getTitlesWidget: (value, _) {
                                    final i = value.toInt();
                                    if (i < 0 || i >= data.length) return const SizedBox.shrink();
                                    return Text(data[i].label, style: const TextStyle(fontSize: 10));
                                  },
                                ),
                              ),
                            ),
                            barGroups: [
                              for (var i = 0; i < data.length; i++)
                                BarChartGroupData(
                                  x: i,
                                  barRods: [
                                    BarChartRodData(toY: data[i].patients.toDouble(), color: BrandPalette.accent, width: 8, borderRadius: BorderRadius.circular(4)),
                                    BarChartRodData(toY: data[i].doctors.toDouble(), color: BrandPalette.primaryDeep, width: 8, borderRadius: BorderRadius.circular(4)),
                                  ],
                                ),
                            ],
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
