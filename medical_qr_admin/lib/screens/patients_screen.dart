import 'package:flutter/material.dart';

import '../state/admin_store.dart';
import '../widgets/ui.dart';
import 'patient_record_screen.dart';

class PatientsScreen extends StatefulWidget {
  const PatientsScreen({super.key});

  @override
  State<PatientsScreen> createState() => _PatientsScreenState();
}

class _PatientsScreenState extends State<PatientsScreen> {
  String search = '';

  @override
  Widget build(BuildContext context) {
    final store = AdminScope.of(context);
    final q = search.trim().toLowerCase();
    final filtered = store.patients.where((p) {
      if (q.isEmpty) return true;
      return p.fullName.toLowerCase().contains(q) || p.patientId.toLowerCase().contains(q) || p.phone.contains(q);
    }).toList();

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        PageHeader(title: 'إدارة المرضى', subtitle: '${store.patients.length} مريض مسجل'),
        SearchField(hint: 'بحث بالاسم أو الرقم أو الهاتف...', onChanged: (v) => setState(() => search = v)),
        const SizedBox(height: 16),
        if (filtered.isEmpty) const EmptyHint('لم يتم العثور على مرضى'),
        ...filtered.map((p) => Card(
              child: ListTile(
                leading: AvatarCircle(name: p.fullName, photo: p.profilePhoto),
                title: Text(p.fullName),
                subtitle: Text('${p.patientId} · ${p.phone} · ${p.city}\nفصيلة الدم: ${p.bloodType} · الجنس: ${p.gender == 'Male' ? 'ذكر' : 'أنثى'}'),
                isThreeLine: true,
                trailing: Wrap(
                  spacing: 8,
                  children: [
                    StatusChip(label: patientStatusAr(p.status), color: p.status == 'active' ? Colors.green : Colors.red),
                    OutlinedButton(
                      onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => PatientRecordScreen(patient: p))),
                      child: const Text('عرض'),
                    ),
                  ],
                ),
              ),
            )),
      ],
    );
  }
}
