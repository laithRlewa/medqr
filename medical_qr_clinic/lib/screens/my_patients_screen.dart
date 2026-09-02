import 'package:flutter/material.dart';

import '../state/clinic_store.dart';
import '../widgets/ui.dart';

class MyPatientsScreen extends StatefulWidget {
  const MyPatientsScreen({super.key});

  @override
  State<MyPatientsScreen> createState() => _MyPatientsScreenState();
}

class _MyPatientsScreenState extends State<MyPatientsScreen> {
  String search = '';

  @override
  Widget build(BuildContext context) {
    final store = ClinicScope.of(context);
    final doctor = store.currentDoctor;
    if (doctor == null) return const EmptyHint('لا يوجد ملف طبيب');
    final visits = store.visitsForDoctor(doctor.id);
    final map = <String, List<dynamic>>{};
    for (final v in visits) {
      map.putIfAbsent(v.patientId, () => []).add(v);
    }
    final entries = map.entries.where((e) {
      final name = visits.firstWhere((v) => v.patientId == e.key).patientName;
      return search.isEmpty || name.contains(search);
    }).toList();

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        PageHeader(title: 'مرضاي', subtitle: '${entries.length} مريض', icon: Icons.groups_outlined, actions: [
          FilledButton.icon(onPressed: () => store.goTo(ClinicPage.scanQr), icon: const Icon(Icons.qr_code_scanner), label: const Text('مسح / بحث')),
        ]),
        SearchField(hint: 'بحث عن المرضى...', onChanged: (v) => setState(() => search = v)),
        const SizedBox(height: 16),
        if (entries.isEmpty) const EmptyHint('لم يتم العثور على مرضى', art: ClinicArt.patientSearch),
        for (final e in entries)
          Builder(builder: (context) {
            final first = visits.firstWhere((v) => v.patientId == e.key);
            return Card(
              child: ListTile(
                leading: AvatarCircle(name: first.patientName),
                title: Text(first.patientName),
                subtitle: Text('${e.value.length} زيارة · آخر زيارة: ${dateFmt.format(e.value.first.visitDate)}'),
                trailing: Wrap(
                  spacing: 4,
                  children: [
                    IconButton(
                      tooltip: 'مراسلة',
                      onPressed: () => store.openMessages(patientId: e.key, doctorId: doctor.id),
                      icon: const Icon(Icons.chat_bubble_outline),
                    ),
                    OutlinedButton(
                      onPressed: () {
                        final patient = store.patientById(e.key);
                        if (patient != null) store.openPatientAfterAccess(patient, method: 'search');
                      },
                      child: const Text('عرض'),
                    ),
                  ],
                ),
              ),
            );
          }),
      ],
    );
  }
}
