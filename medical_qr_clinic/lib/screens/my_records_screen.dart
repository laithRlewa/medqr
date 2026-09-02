import 'package:flutter/material.dart';

import '../state/clinic_store.dart';
import '../theme/clinic_style.dart';
import '../widgets/media.dart';
import '../widgets/ui.dart';

class MyRecordsScreen extends StatefulWidget {
  const MyRecordsScreen({super.key});

  @override
  State<MyRecordsScreen> createState() => _MyRecordsScreenState();
}

class _MyRecordsScreenState extends State<MyRecordsScreen> {
  String fileType = 'all';
  String period = 'all';

  @override
  Widget build(BuildContext context) {
    final store = ClinicScope.of(context);
    final patient = store.currentPatient;
    if (patient == null) return const EmptyHint('لا يوجد ملف مريض');
    final visits = store.visitsForPatient(patient.id);
    final diagnoses = visits.where((v) => v.diagnosis.isNotEmpty).toList();
    final prescriptions = visits.where((v) => v.prescribedMedications.isNotEmpty).toList();
    var files = store.filesForPatient(patient.id);
    if (fileType != 'all') files = files.where((f) => f.fileType == fileType).toList();
    if (period != 'all') {
      final now = DateTime.now();
      files = files.where((f) {
        final d = now.difference(f.createdDate);
        return switch (period) {
          'week' => d.inDays <= 7,
          'month' => d.inDays <= 31,
          'year' => d.inDays <= 366,
          _ => true,
        };
      }).toList();
    }

    return DefaultTabController(
      length: 5,
      child: ListView(
        padding: clinicPadding(context),
        children: [
          const PageHeader(title: 'سجلاتي الطبية', subtitle: 'الزيارات والتشخيصات والوصفات والملفات والمحادثات', icon: Icons.folder_shared_outlined),
          const Material(
            color: Colors.transparent,
            child: TabBar(isScrollable: true, tabs: [
              Tab(text: 'الزيارات'),
              Tab(text: 'التشخيصات'),
              Tab(text: 'الوصفات'),
              Tab(text: 'الملفات'),
              Tab(text: 'المحادثات'),
            ]),
          ),
          SizedBox(
            height: 640,
            child: TabBarView(
              children: [
                visits.isEmpty
                    ? const EmptyHint('لا توجد زيارات', art: ClinicArt.ecgReview)
                    : ListView(children: [
                        for (final v in visits)
                          Card(
                            child: ListTile(
                              title: Text('د. ${v.doctorName}'),
                              subtitle: Text([
                                if (v.diagnosis.isNotEmpty) 'التشخيص: ${v.diagnosis}',
                                if (v.prescribedMedications.isNotEmpty) 'الأدوية: ${v.prescribedMedications}',
                                if (v.followUpNotes.isNotEmpty) 'المتابعة: ${v.followUpNotes}',
                                dateFmt.format(v.visitDate),
                              ].join('\n')),
                              isThreeLine: true,
                              trailing: TextButton(
                                onPressed: () {
                                  final doctor = store.doctorById(v.doctorId);
                                  if (doctor == null) return;
                                  showReviewDialog(context, store, doctor: doctor, patient: patient, visit: v);
                                },
                                child: const Text('تقييم'),
                              ),
                            ),
                          ),
                      ]),
                diagnoses.isEmpty
                    ? const EmptyHint('لا توجد تشخيصات', art: ClinicArt.dnaReview)
                    : ListView(children: [
                        for (final v in diagnoses)
                          Card(child: ListTile(title: Text(v.diagnosis), subtitle: Text('د. ${v.doctorName} · ${dateFmt.format(v.visitDate)}'))),
                      ]),
                prescriptions.isEmpty
                    ? const EmptyHint('لا توجد وصفات', art: ClinicArt.clipboardMeds)
                    : ListView(children: [
                        for (final v in prescriptions)
                          Card(child: ListTile(title: Text(v.prescribedMedications), subtitle: Text('د. ${v.doctorName} · ${dateFmt.format(v.visitDate)}'))),
                      ]),
                Column(
                  children: [
                    Wrap(spacing: 6, children: [
                      ChoiceChip(label: const Text('الكل'), selected: fileType == 'all', onSelected: (_) => setState(() => fileType = 'all')),
                      for (final e in fileTypesAr.entries.take(6))
                        ChoiceChip(label: Text(e.value), selected: fileType == e.key, onSelected: (_) => setState(() => fileType = e.key)),
                    ]),
                    Wrap(spacing: 6, children: [
                      for (final e in const [('all', 'كل الفترات'), ('week', 'أسبوع'), ('month', 'شهر'), ('year', 'سنة')])
                        ChoiceChip(label: Text(e.$2), selected: period == e.$1, onSelected: (_) => setState(() => period = e.$1)),
                    ]),
                    Expanded(
                      child: files.isEmpty
                          ? const EmptyHint('لا توجد ملفات', art: ClinicArt.dnaClipboard)
                          : ListView(children: [
                              for (final f in files)
                                FileTile(
                                  name: f.fileName.isEmpty ? fileTypeAr(f.fileType) : f.fileName,
                                  type: fileTypeAr(f.fileType),
                                  subtitle: 'د. ${f.doctorName} · ${dateFmt.format(f.createdDate)}',
                                  url: f.fileUrl,
                                  description: f.description,
                                ),
                            ]),
                    ),
                  ],
                ),
                ListView(children: [
                  ListTile(
                    leading: const Icon(Icons.chat_bubble_outline),
                    title: const Text('فتح صندوق المحادثات'),
                    onTap: () => store.goTo(ClinicPage.messages),
                  ),
                  for (final item in store.conversationSummaries)
                    Card(
                      child: ListTile(
                        title: Text(item.$2),
                        subtitle: Text(item.$3),
                        onTap: () {
                          final parts = item.$1.split('__');
                          store.openMessages(patientId: parts.elementAtOrNull(0), doctorId: parts.elementAtOrNull(1));
                        },
                      ),
                    ),
                ]),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
