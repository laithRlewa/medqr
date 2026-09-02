import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../state/clinic_store.dart';
import '../widgets/media.dart';
import '../widgets/mobile_kit.dart';
import '../widgets/ui.dart';

enum _FileSort { newest, oldest, type, name }

String _basename(String path) {
  final norm = path.replaceAll('\\', '/');
  final i = norm.lastIndexOf('/');
  return i < 0 ? norm : norm.substring(i + 1);
}

String _ext(String name) {
  final i = name.lastIndexOf('.');
  return i < 0 ? '' : name.substring(i).toLowerCase();
}

String _fmtRemain(Duration d) {
  final m = d.inMinutes.clamp(0, 99);
  final s = d.inSeconds.remainder(60).clamp(0, 59);
  return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
}

class PatientRecordScreen extends StatefulWidget {
  const PatientRecordScreen({super.key, required this.patientId});
  final String patientId;

  @override
  State<PatientRecordScreen> createState() => _PatientRecordScreenState();
}

class _PatientRecordScreenState extends State<PatientRecordScreen> {
  _FileSort _fileSort = _FileSort.newest;
  Timer? _tick;

  @override
  void initState() {
    super.initState();
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = ClinicScope.of(context);
    final patient = store.patientById(widget.patientId);
    if (patient == null) {
      return const Center(child: Text('المريض غير موجود'));
    }
    if (!store.hasAccess(patient.id)) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.lock_outline, size: 48),
            const SizedBox(height: 12),
            Text('لا توجد جلسة وصول نشطة لـ ${patient.fullName}'),
            const SizedBox(height: 8),
            FilledButton(onPressed: () => store.goTo(ClinicPage.scanQr), child: const Text('مسح QR أو بحث')),
          ],
        ),
      );
    }

    final canWrite = store.canWritePatient(patient.id);
    final remain = store.writeRemainingFor(patient.id);
    final visits = store.visitsForPatient(patient.id);
    final files = _sortedFiles(store.filesForPatient(patient.id));

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        PageHeader(
          title: patient.fullName,
          subtitle: '${patient.patientId} · ${patient.city}',
          actions: [
            if (canWrite) ...[
              OutlinedButton.icon(
                onPressed: () => _visitDialog(context, store, patient),
                icon: const Icon(Icons.add),
                label: const Text('زيارة جديدة'),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: () => _fileDialog(context, store, patient),
                icon: const Icon(Icons.upload_file),
                label: const Text('ملف طبي'),
              ),
            ] else
              FilledButton.tonalIcon(
                onPressed: () => store.goTo(ClinicPage.scanQr),
                icon: const Icon(Icons.qr_code_scanner),
                label: const Text('مسح QR للتعديل'),
              ),
            const SizedBox(width: 8),
            OutlinedButton.icon(
              onPressed: () => store.openMessages(patientId: patient.id, doctorId: store.currentDoctor?.id),
              icon: const Icon(Icons.chat_bubble_outline),
              label: const Text('مراسلة'),
            ),
          ],
        ),
        SoftCard(
          color: canWrite ? const Color(0xFFE8F5E9) : const Color(0xFFFFF3E0),
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Icon(
                canWrite ? Icons.timer_outlined : Icons.lock_clock,
                color: canWrite ? const Color(0xFF2E7D32) : const Color(0xFFE65100),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  canWrite
                      ? 'يمكنك التعديل ورفع المستندات لمدة ${_fmtRemain(remain)} بعد مسح QR'
                      : 'انتهت مهلة التعديل/الرفع (10 دقائق). يمكنك العرض فقط — امسح QR مجدداً للتعديل.',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: canWrite ? const Color(0xFF1B5E20) : const Color(0xFFE65100),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Card(
          color: Colors.red.shade50,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Wrap(spacing: 24, runSpacing: 8, children: [
              InfoRow('الاسم', patient.fullName),
              InfoRow('العمر', patient.ageYears == null ? '—' : '${patient.ageYears} سنة (${genderAr(patient.gender)})'),
              InfoRow('فصيلة الدم', patient.bloodType),
              InfoRow('الطوارئ', '${patient.emergencyContactName} — ${patient.emergencyContactPhone}'),
              if (patient.allergies.isNotEmpty) InfoRow('الحساسية', patient.allergies),
              if (patient.chronicDiseases.isNotEmpty) InfoRow('الأمراض المزمنة', patient.chronicDiseases),
              if (patient.currentMedications.isNotEmpty) InfoRow('الأدوية', patient.currentMedications),
            ]),
          ),
        ),
        const SizedBox(height: 16),
        DefaultTabController(
          length: 3,
          child: Material(
            color: Colors.transparent,
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
                          ? const EmptyHint('لا توجد زيارات', art: ClinicArt.ecgReview)
                          : ListView(children: [
                              for (final v in visits)
                                Card(
                                  child: ListTile(
                                    title: Text('د. ${v.doctorName}'),
                                    subtitle: Text([
                                      if (v.diagnosis.isNotEmpty) 'التشخيص: ${v.diagnosis}',
                                      if (v.symptoms.isNotEmpty) 'الأعراض: ${v.symptoms}',
                                      if (v.prescribedMedications.isNotEmpty) 'الأدوية: ${v.prescribedMedications}',
                                      if (v.treatmentPlan.isNotEmpty) 'العلاج: ${v.treatmentPlan}',
                                    ].join('\n')),
                                    trailing: Wrap(children: [
                                      Text(dateFmt.format(v.visitDate)),
                                      if (canWrite && store.currentDoctor?.id == v.doctorId)
                                        IconButton(
                                          icon: const Icon(Icons.edit_outlined),
                                          onPressed: () => _visitDialog(context, store, patient, visit: v),
                                        ),
                                    ]),
                                    isThreeLine: true,
                                  ),
                                ),
                            ]),
                      _filesTab(context, store, patient, files, canWrite: canWrite),
                      ListView(
                        padding: const EdgeInsets.only(top: 8),
                        children: [
                          InfoRow('الهاتف', patient.phone),
                          InfoRow('البريد', patient.email),
                          InfoRow('الهوية', patient.nationalId),
                          InfoRow('التاريخ المرضي', patient.medicalHistory),
                          InfoRow('اللقاحات', patient.vaccinationRecords),
                          InfoRow('العمليات', patient.surgeryRecords),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  List<MedicalFile> _sortedFiles(List<MedicalFile> files) {
    final list = [...files];
    switch (_fileSort) {
      case _FileSort.newest:
        list.sort((a, b) => b.createdDate.compareTo(a.createdDate));
      case _FileSort.oldest:
        list.sort((a, b) => a.createdDate.compareTo(b.createdDate));
      case _FileSort.type:
        list.sort((a, b) {
          final t = fileTypeAr(a.fileType).compareTo(fileTypeAr(b.fileType));
          return t != 0 ? t : b.createdDate.compareTo(a.createdDate);
        });
      case _FileSort.name:
        list.sort((a, b) {
          final an = a.fileName.isEmpty ? fileTypeAr(a.fileType) : a.fileName;
          final bn = b.fileName.isEmpty ? fileTypeAr(b.fileType) : b.fileName;
          final t = an.compareTo(bn);
          return t != 0 ? t : b.createdDate.compareTo(a.createdDate);
        });
    }
    return list;
  }

  Widget _filesTab(BuildContext context, ClinicStore store, Patient patient, List<MedicalFile> files, {required bool canWrite}) {
    return Column(
      children: [
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _sortChip('الأحدث', _FileSort.newest),
              _sortChip('الأقدم', _FileSort.oldest),
              _sortChip('حسب النوع', _FileSort.type),
              _sortChip('حسب الاسم', _FileSort.name),
              if (canWrite) ...[
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: () => _fileDialog(context, store, patient),
                  icon: const Icon(Icons.attach_file, size: 18),
                  label: const Text('إرفاق'),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 4),
        Expanded(
          child: files.isEmpty
              ? EmptyHint(
                  canWrite ? 'لا توجد ملفات — أرفق صورة أو PDF' : 'لا توجد ملفات',
                  art: ClinicArt.dnaClipboard,
                )
              : ListView.builder(
                  itemCount: files.length,
                  itemBuilder: (_, i) {
                    final f = files[i];
                    final title = f.fileName.isEmpty ? fileTypeAr(f.fileType) : f.fileName;
                    return FileTile(
                      name: title,
                      type: fileTypeAr(f.fileType),
                      subtitle: 'د. ${f.doctorName} · ${dateFmt.format(f.createdDate)}',
                      url: f.fileUrl,
                      description: f.description,
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _sortChip(String label, _FileSort sort) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(end: 6),
      child: ChoiceChip(
        label: Text(label),
        selected: _fileSort == sort,
        onSelected: (_) => setState(() => _fileSort = sort),
        visualDensity: VisualDensity.compact,
      ),
    );
  }

  void _visitDialog(BuildContext context, ClinicStore store, Patient patient, {Visit? visit}) {
    if (!store.canWritePatient(patient.id)) {
      toast(context, 'انتهت مهلة التعديل. امسح QR مجدداً.');
      return;
    }
    final symptoms = TextEditingController(text: visit?.symptoms ?? '');
    final diagnosis = TextEditingController(text: visit?.diagnosis ?? '');
    final plan = TextEditingController(text: visit?.treatmentPlan ?? '');
    final meds = TextEditingController(text: visit?.prescribedMedications ?? '');
    final follow = TextEditingController(text: visit?.followUpNotes ?? '');
    final time = TextEditingController(text: visit?.visitTime ?? '10:00');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(visit == null ? 'زيارة جديدة' : 'تعديل الزيارة'),
        content: SizedBox(
          width: 460,
          child: SingleChildScrollView(
            child: Column(
              children: [
                TextField(controller: time, decoration: const InputDecoration(labelText: 'وقت الزيارة')),
                const SizedBox(height: 8),
                TextField(controller: symptoms, decoration: const InputDecoration(labelText: 'الأعراض'), maxLines: 2),
                const SizedBox(height: 8),
                TextField(controller: diagnosis, decoration: const InputDecoration(labelText: 'التشخيص'), maxLines: 2),
                const SizedBox(height: 8),
                TextField(controller: plan, decoration: const InputDecoration(labelText: 'خطة العلاج'), maxLines: 2),
                const SizedBox(height: 8),
                TextField(controller: meds, decoration: const InputDecoration(labelText: 'الأدوية'), maxLines: 2),
                const SizedBox(height: 8),
                TextField(controller: follow, decoration: const InputDecoration(labelText: 'ملاحظات المتابعة'), maxLines: 2),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          FilledButton(
            onPressed: () async {
              if (visit == null) {
                await store.addVisit(
                  patient: patient,
                  symptoms: symptoms.text,
                  diagnosis: diagnosis.text,
                  treatmentPlan: plan.text,
                  medications: meds.text,
                  followUp: follow.text,
                  visitTime: time.text,
                );
              } else {
                final err = await store.editVisit(
                  visit,
                  symptoms: symptoms.text,
                  diagnosis: diagnosis.text,
                  treatmentPlan: plan.text,
                  medications: meds.text,
                  followUp: follow.text,
                );
                if (err != null) {
                  if (ctx.mounted) toast(ctx, err);
                  return;
                }
              }
              if (ctx.mounted) {
                Navigator.pop(ctx);
                toast(ctx, store.lastMessage ?? 'تم الحفظ');
              }
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    ).whenComplete(() {
      disposeLater(symptoms);
      disposeLater(diagnosis);
      disposeLater(plan);
      disposeLater(meds);
      disposeLater(follow);
      disposeLater(time);
    });
  }

  void _fileDialog(BuildContext context, ClinicStore store, Patient patient) {
    if (!store.canWritePatient(patient.id)) {
      toast(context, 'انتهت مهلة الرفع. امسح QR مجدداً.');
      return;
    }
    final name = TextEditingController();
    final desc = TextEditingController();
    var type = 'document';
    String? fileUrl;
    String? localLabel;
    var uploading = false;
    var saving = false;

    String guessType(String fileName) {
      final ext = _ext(fileName);
      if (ext == '.pdf') return 'document';
      if (['.jpg', '.jpeg', '.png', '.webp', '.heic'].contains(ext)) return 'image';
      return type;
    }

    Future<void> attachPath(String path, void Function(void Function()) setLocal) async {
      setLocal(() => uploading = true);
      final url = await store.uploadPath(path);
      final base = _basename(path);
      setLocal(() {
        uploading = false;
        if (url == null || url.isEmpty) return;
        fileUrl = url;
        localLabel = base;
        if (name.text.trim().isEmpty) name.text = base;
        type = guessType(base);
      });
      if (url == null || url.isEmpty) {
        if (context.mounted) toast(context, 'تعذر رفع الملف. تحقق من الاتصال.');
      }
    }

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: const Text('إرفاق ملف طبي'),
          content: SizedBox(
            width: 440,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  DropdownButtonFormField<String>(
                    key: ValueKey(type),
                    initialValue: type,
                    decoration: const InputDecoration(labelText: 'نوع الملف'),
                    items: [for (final e in fileTypesAr.entries) DropdownMenuItem(value: e.key, child: Text(e.value))],
                    onChanged: uploading ? null : (v) => setLocal(() => type = v ?? type),
                  ),
                  const SizedBox(height: 8),
                  TextField(controller: name, decoration: const InputDecoration(labelText: 'اسم الملف')),
                  const SizedBox(height: 8),
                  TextField(controller: desc, decoration: const InputDecoration(labelText: 'الوصف')),
                  const SizedBox(height: 12),
                  Text('إرفاق', style: Theme.of(ctx).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      OutlinedButton.icon(
                        onPressed: uploading
                            ? null
                            : () async {
                                final picked = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 88);
                                if (picked != null) await attachPath(picked.path, setLocal);
                              },
                        icon: const Icon(Icons.photo_library_outlined),
                        label: const Text('صورة'),
                      ),
                      OutlinedButton.icon(
                        onPressed: uploading
                            ? null
                            : () async {
                                final picked = await ImagePicker().pickImage(source: ImageSource.camera, imageQuality: 88);
                                if (picked != null) await attachPath(picked.path, setLocal);
                              },
                        icon: const Icon(Icons.photo_camera_outlined),
                        label: const Text('كاميرا'),
                      ),
                      OutlinedButton.icon(
                        onPressed: uploading
                            ? null
                            : () async {
                                final result = await FilePicker.platform.pickFiles(
                                  type: FileType.custom,
                                  allowedExtensions: const ['pdf'],
                                );
                                final path = result?.files.single.path;
                                if (path != null) await attachPath(path, setLocal);
                              },
                        icon: const Icon(Icons.picture_as_pdf_outlined),
                        label: const Text('PDF'),
                      ),
                      OutlinedButton.icon(
                        onPressed: uploading
                            ? null
                            : () async {
                                final result = await FilePicker.platform.pickFiles(
                                  type: FileType.custom,
                                  allowedExtensions: const ['jpg', 'jpeg', 'png', 'webp', 'pdf'],
                                );
                                final path = result?.files.single.path;
                                if (path != null) await attachPath(path, setLocal);
                              },
                        icon: const Icon(Icons.attach_file),
                        label: const Text('ملف'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (uploading)
                    const LinearProgressIndicator()
                  else if (fileUrl != null && fileUrl!.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: ClinicColors.primaryDeep.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            (localLabel ?? '').toLowerCase().endsWith('.pdf')
                                ? Icons.picture_as_pdf
                                : Icons.image_outlined,
                            color: ClinicColors.primaryDeep,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              localLabel ?? 'تم الرفع',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ),
                          IconButton(
                            tooltip: 'إزالة',
                            onPressed: () => setLocal(() {
                              fileUrl = null;
                              localLabel = null;
                            }),
                            icon: const Icon(Icons.close),
                          ),
                        ],
                      ),
                    )
                  else
                    Text(
                      'اختر صورة أو PDF لإرفاقه مع السجل.',
                      style: TextStyle(color: Theme.of(ctx).colorScheme.onSurfaceVariant),
                    ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: saving || uploading ? null : () => Navigator.pop(ctx), child: const Text('إلغاء')),
            FilledButton(
              onPressed: saving || uploading
                  ? null
                  : () async {
                      if (fileUrl == null || fileUrl!.isEmpty) {
                        toast(ctx, 'أرفق صورة أو PDF أولاً');
                        return;
                      }
                      setLocal(() => saving = true);
                      await store.addFile(
                        patient: patient,
                        fileType: type,
                        fileName: name.text.trim().isEmpty ? (localLabel ?? 'ملف-$type') : name.text.trim(),
                        description: desc.text.trim(),
                        fileUrl: fileUrl!,
                      );
                      if (ctx.mounted) {
                        Navigator.pop(ctx);
                        toast(context, store.lastMessage ?? 'تم إضافة الملف الطبي');
                      }
                    },
              child: saving ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('حفظ'),
            ),
          ],
        ),
      ),
    ).whenComplete(() {
      disposeLater(name);
      disposeLater(desc);
    });
  }
}
