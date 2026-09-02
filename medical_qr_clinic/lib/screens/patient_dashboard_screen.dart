import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../models/models.dart';
import '../state/clinic_store.dart';
import '../theme/clinic_style.dart';
import '../widgets/mobile_kit.dart';
import '../widgets/ui.dart';

class PatientDashboardScreen extends StatelessWidget {
  const PatientDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = ClinicScope.of(context);
    final patient = store.currentPatient;
    if (patient == null) {
      return const Center(child: Text('لم يتم العثور على ملف المريض'));
    }
    final visits = store.visitsForPatient(patient.id);
    final files = store.filesForPatient(patient.id);
    final qrData = patient.qrCodeData.isEmpty ? patient.patientId : patient.qrCodeData;
    final mobile = isMobileLayout(context);

    return ListView(
      padding: clinicPadding(context),
      children: [
        PageHeader(
          title: 'رمزي الطبي',
          subtitle: 'رمز QR ومعلومات الطوارئ والسجلات',
          icon: Icons.qr_code_2,
          actions: [
            OutlinedButton.icon(
              onPressed: () => store.goTo(ClinicPage.myRecords),
              icon: const Icon(Icons.folder_shared_outlined, size: 18),
              label: const Text('سجلاتي'),
            ),
          ],
        ),
        SoftCard(
          color: const Color(0xFFFFF5F5),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFE3E3),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.emergency_outlined, color: Color(0xFFC62828)),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('معلومات الطوارئ', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: Color(0xFFB71C1C))),
                        Text('تظهر للطبيب عند مسح الرمز', style: TextStyle(color: ClinicColors.muted, fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 20,
                runSpacing: 10,
                children: [
                  _Meta('الاسم', patient.fullName),
                  _Meta('العمر', patient.ageYears == null ? '—' : '${patient.ageYears} سنة'),
                  _Meta('فصيلة الدم', patient.bloodType),
                  _Meta('جهة الاتصال', '${patient.emergencyContactName} — ${patient.emergencyContactPhone}'),
                  if (patient.allergies.isNotEmpty) _Meta('الحساسية', patient.allergies),
                  if (patient.chronicDiseases.isNotEmpty) _Meta('الأمراض المزمنة', patient.chronicDiseases),
                  if (patient.currentMedications.isNotEmpty) _Meta('الأدوية الحالية', patient.currentMedications),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        LayoutBuilder(builder: (context, c) {
          final wide = c.maxWidth > 820;
          final qrCard = SoftCard(
            child: Column(
              children: [
                const Text('رمز QR الخاص بك', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
                const SizedBox(height: 6),
                const Text(
                  'اعرضه لطبيبك للوصول الآمن إلى سجلاتك',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: ClinicColors.muted, fontSize: 13),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: ClinicColors.border),
                  ),
                  child: QrImageView(
                    data: qrData,
                    size: wide ? 200 : 180,
                    eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square, color: ClinicColors.primaryDeep),
                    dataModuleStyle: const QrDataModuleStyle(dataModuleShape: QrDataModuleShape.square, color: ClinicColors.primaryDeep),
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(color: ClinicColors.tint, borderRadius: BorderRadius.circular(14)),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.badge_outlined, size: 16, color: ClinicColors.primary),
                      const SizedBox(width: 6),
                      Text(patient.patientId, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                      const SizedBox(width: 8),
                      InkWell(
                        onTap: () async {
                          await Clipboard.setData(ClipboardData(text: patient.patientId));
                          if (context.mounted) toast(context, 'تم نسخ رقم المريض');
                        },
                        child: const Icon(Icons.copy_rounded, size: 16, color: ClinicColors.muted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );

          final side = Column(
            children: [
              Row(
                children: [
                  Expanded(child: _MiniStat(Icons.event_available_outlined, '${visits.length}', 'زيارة')),
                  const SizedBox(width: 10),
                  Expanded(child: _MiniStat(Icons.description_outlined, '${files.length}', 'ملف')),
                ],
              ),
              const SizedBox(height: 12),
              SoftCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.person_outline, size: 20, color: ClinicColors.primary),
                        SizedBox(width: 8),
                        Text('المعلومات الشخصية', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _Meta('الاسم الكامل', patient.fullName),
                    _Meta('الجنس', genderAr(patient.gender)),
                    _Meta('تاريخ الميلاد', patient.dateOfBirth),
                    _Meta('رقم الهاتف', patient.phone),
                    _Meta('المدينة', patient.city),
                  ],
                ),
              ),
            ],
          );

          if (!wide) return Column(children: [qrCard, const SizedBox(height: 12), side]);
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(width: 320, child: qrCard),
              const SizedBox(width: 16),
              Expanded(child: side),
            ],
          );
        }),
        const SizedBox(height: 22),
        Row(
          children: [
            const Expanded(child: Text('النشاط الأخير', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800))),
            TextButton(
              onPressed: () => store.goTo(ClinicPage.myRecords),
              child: const Text('عرض الكل', style: TextStyle(color: ClinicColors.primary, fontWeight: FontWeight.w800)),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (visits.isEmpty && files.isEmpty)
          SoftCard(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
              child: Column(
                children: [
                  const ClinicIllustration(ClinicArt.labMonitor, height: 110),
                  const SizedBox(height: 10),
                  const Text('لا توجد زيارات أو ملفات بعد', style: TextStyle(color: ClinicColors.muted)),
                  const SizedBox(height: 12),
                  GhostButton(label: 'ابحث عن طبيب', onTap: () => store.goTo(ClinicPage.bookAppointment)),
                ],
              ),
            ),
          )
        else ...[
          if (visits.isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: Text('الزيارات', style: TextStyle(fontWeight: FontWeight.w700, color: ClinicColors.muted, fontSize: 13)),
            ),
            for (final v in visits.take(mobile ? 3 : 5)) ...[
              _VisitTile(v),
              const SizedBox(height: 10),
            ],
          ],
          if (files.isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.only(top: 6, bottom: 8),
              child: Text('الملفات الطبية', style: TextStyle(fontWeight: FontWeight.w700, color: ClinicColors.muted, fontSize: 13)),
            ),
            for (final f in files.take(mobile ? 3 : 5)) ...[
              SoftCard(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                onTap: () => store.goTo(ClinicPage.myRecords),
                child: Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(color: ClinicColors.tint, borderRadius: BorderRadius.circular(14)),
                      child: const Icon(Icons.description_outlined, color: ClinicColors.primary),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(f.fileName.isEmpty ? fileTypeAr(f.fileType) : f.fileName, style: const TextStyle(fontWeight: FontWeight.w700)),
                          Text('د. ${f.doctorName} · ${dateFmt.format(f.createdDate)}', style: const TextStyle(color: ClinicColors.muted, fontSize: 12)),
                        ],
                      ),
                    ),
                    StatusChip(label: fileTypeAr(f.fileType), color: ClinicColors.primaryDeep),
                  ],
                ),
              ),
              const SizedBox(height: 10),
            ],
          ],
        ],
      ],
    );
  }
}

class _Meta extends StatelessWidget {
  const _Meta(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: SizedBox(
        width: 220,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: ClinicColors.muted, fontSize: 12)),
            Text(value, style: const TextStyle(fontWeight: FontWeight.w700, height: 1.35)),
          ],
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat(this.icon, this.value, this.label);
  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(color: ClinicColors.tint, borderRadius: BorderRadius.circular(14)),
            child: Icon(icon, color: ClinicColors.primary),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 20, color: ClinicColors.primaryDeep)),
              Text(label, style: const TextStyle(color: ClinicColors.muted, fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }
}

class _VisitTile extends StatelessWidget {
  const _VisitTile(this.visit);
  final Visit visit;

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              PhotoAvatar(name: visit.doctorName, size: 42),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('د. ${visit.doctorName}', style: const TextStyle(fontWeight: FontWeight.w800)),
                    Text(
                      '${dateFmt.format(visit.visitDate)}${visit.visitTime.isEmpty ? '' : ' · ${visit.visitTime}'}',
                      style: const TextStyle(color: ClinicColors.muted, fontSize: 12),
                    ),
                  ],
                ),
              ),
              if (visit.doctorSpecialty.isNotEmpty) StatusChip(label: visit.doctorSpecialty, color: ClinicColors.primary),
            ],
          ),
          if (visit.symptoms.isNotEmpty || visit.diagnosis.isNotEmpty || visit.treatmentPlan.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: ClinicColors.tint, borderRadius: BorderRadius.circular(16)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (visit.symptoms.isNotEmpty) Text('الأعراض: ${visit.symptoms}', style: const TextStyle(fontSize: 13)),
                  if (visit.diagnosis.isNotEmpty) Text('التشخيص: ${visit.diagnosis}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                  if (visit.treatmentPlan.isNotEmpty) Text('خطة العلاج: ${visit.treatmentPlan}', style: const TextStyle(fontSize: 13)),
                  if (visit.prescribedMedications.isNotEmpty) Text('الأدوية: ${visit.prescribedMedications}', style: const TextStyle(fontSize: 13)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
