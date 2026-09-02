import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../api/api_config.dart';
import '../models/models.dart';
import '../state/admin_store.dart';
import '../widgets/ui.dart';

class PatientRecordScreen extends StatelessWidget {
  const PatientRecordScreen({super.key, required this.patient});

  final Patient patient;

  @override
  Widget build(BuildContext context) {
    final store = AdminScope.of(context);
    final visits = store.visitsFor(patient.id);
    final files = store.filesFor(patient.id);
    final age = patient.dateOfBirth.isEmpty ? null : DateTime.now().difference(DateTime.tryParse(patient.dateOfBirth) ?? DateTime.now()).inDays ~/ 365;

    return Scaffold(
      appBar: AppBar(title: Text(patient.fullName)),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Card(
            color: Colors.red.shade50,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('معلومات الطوارئ', style: TextStyle(color: Colors.red, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 8),
                  Wrap(spacing: 24, runSpacing: 8, children: [
                    Text('الاسم: ${patient.fullName}'),
                    Text('العمر: ${age ?? '—'} سنة (${patient.gender == 'Male' ? 'ذكر' : 'أنثى'})'),
                    Text('فصيلة الدم: ${patient.bloodType}'),
                    Text('الطوارئ: ${patient.emergencyContactName} — ${patient.emergencyContactPhone}'),
                    if (patient.allergies.isNotEmpty) Text('الحساسية: ${patient.allergies}'),
                    if (patient.chronicDiseases.isNotEmpty) Text('الأمراض المزمنة: ${patient.chronicDiseases}'),
                    if (patient.currentMedications.isNotEmpty) Text('الأدوية: ${patient.currentMedications}'),
                  ]),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          DefaultTabController(
            length: 3,
            child: Column(
              children: [
                TabBar(tabs: [
                  Tab(text: 'الزيارات (${visits.length})'),
                  Tab(text: 'الملفات (${files.length})'),
                  const Tab(text: 'المعلومات الطبية'),
                ]),
                SizedBox(
                  height: 520,
                  child: TabBarView(
                    children: [
                      visits.isEmpty
                          ? const EmptyHint('لا توجد زيارات مسجلة')
                          : ListView(
                              children: [
                                for (final v in visits)
                                  Card(
                                    child: ListTile(
                                      title: Text('د. ${v.doctorName}'),
                                      subtitle: Text([
                                        v.doctorSpecialty,
                                        if (v.symptoms.isNotEmpty) 'الأعراض: ${v.symptoms}',
                                        if (v.diagnosis.isNotEmpty) 'التشخيص: ${v.diagnosis}',
                                        if (v.treatmentPlan.isNotEmpty) 'العلاج: ${v.treatmentPlan}',
                                        if (v.prescribedMedications.isNotEmpty) 'الأدوية: ${v.prescribedMedications}',
                                        if (v.followUpNotes.isNotEmpty) 'المتابعة: ${v.followUpNotes}',
                                      ].join('\n')),
                                      trailing: Text(dateFmt.format(v.visitDate)),
                                      isThreeLine: true,
                                    ),
                                  ),
                              ],
                            ),
                      files.isEmpty
                          ? const EmptyHint('لا توجد ملفات')
                          : ListView(
                              children: [
                                for (final f in files)
                                  Card(
                                    child: ListTile(
                                      leading: const Icon(Icons.insert_drive_file_outlined),
                                      title: Text(f.fileName.isEmpty ? fileTypeAr(f.fileType) : f.fileName),
                                      subtitle: Text('${fileTypeAr(f.fileType)} · د. ${f.doctorName}\n${f.description}'),
                                      trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                                        Text(dateFmt.format(f.createdDate)),
                                        if (f.fileUrl.isNotEmpty)
                                          IconButton(
                                            onPressed: () => launchUrl(Uri.parse(ApiConfig.mediaUrl(f.fileUrl)), mode: LaunchMode.externalApplication),
                                            icon: const Icon(Icons.open_in_new),
                                          ),
                                      ]),
                                    ),
                                  ),
                              ],
                            ),
                      ListView(
                        children: [
                          _infoCard('التاريخ الطبي', patient.medicalHistory.isEmpty ? 'لا يوجد تاريخ طبي مسجل' : patient.medicalHistory),
                          _infoCard('سجلات التطعيم', patient.vaccinationRecords.isEmpty ? 'لا توجد سجلات تطعيم' : patient.vaccinationRecords),
                          _infoCard('سجلات العمليات الجراحية', patient.surgeryRecords.isEmpty ? 'لا توجد سجلات عمليات' : patient.surgeryRecords),
                          _infoCard('التفاصيل الشخصية', 'رقم المريض: ${patient.patientId}\nالهاتف: ${patient.phone}\nالمدينة: ${patient.city}${patient.nationalId.isEmpty ? '' : '\nالبطاقة الوطنية: ${patient.nationalId}'}'),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoCard(String title, String body) {
    return Card(
      child: ListTile(title: Text(title), subtitle: Text(body)),
    );
  }
}
