import 'package:flutter/material.dart';

import '../data/labels.dart';
import '../models/models.dart';
import '../state/clinic_store.dart';
import '../theme/clinic_style.dart';
import '../widgets/mobile_kit.dart';
import '../widgets/ui.dart';

class MobileConsultantScreen extends StatefulWidget {
  const MobileConsultantScreen({super.key, required this.doctorId});
  final String doctorId;

  @override
  State<MobileConsultantScreen> createState() => _MobileConsultantScreenState();
}

class _MobileConsultantScreenState extends State<MobileConsultantScreen> {
  DateTime? selectedDate;
  String? selectedTime;

  @override
  Widget build(BuildContext context) {
    final store = ClinicScope.of(context);
    final doctor = store.doctorById(widget.doctorId);
    if (doctor == null) return const Center(child: Text('الطبيب غير موجود'));

    final days = List.generate(8, (i) => DateTime.now().add(Duration(days: i)));
    final slots = selectedDate == null ? <String>[] : store.openSlots(doctor.id, selectedDate!);
    final hours = doctor.workingHours.isEmpty ? '09:00-19:00' : doctor.workingHours;

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            children: [
              MobilePageHeader(
                title: 'ملف الاستشاري',
                onBack: () => store.goTo(store.isPatient ? ClinicPage.bookAppointment : ClinicPage.home),
                trailing: CircleIconBtn(icon: Icons.ios_share_outlined, onTap: () => toast(context, 'مشاركة ملف د. ${doctor.fullName}')),
              ),
              SoftCard(
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TealTag(doctor.specialty),
                          const SizedBox(height: 10),
                          Text('د. ${doctor.fullName}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                          const SizedBox(height: 4),
                          Text(doctor.clinicName, style: const TextStyle(color: ClinicColors.muted)),
                          Text(doctor.city, style: const TextStyle(color: ClinicColors.muted, fontSize: 13)),
                        ],
                      ),
                    ),
                    PhotoAvatar(name: doctor.fullName, size: 92, photo: doctor.profilePhoto),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  InfoTile(icon: Icons.schedule, label: hours),
                  const SizedBox(width: 8),
                  InfoTile(icon: Icons.star_rounded, label: doctor.rating.toStringAsFixed(1)),
                  const SizedBox(width: 8),
                  InfoTile(icon: Icons.work_outline, label: '${doctor.yearsOfExperience} سنة'),
                ],
              ),
              if (store.isPatient) ...[
                const SizedBox(height: 22),
                const Text('اختر التاريخ', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                const SizedBox(height: 12),
                SizedBox(
                  height: 86,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: days.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 8),
                    itemBuilder: (context, i) {
                      final day = days[i];
                      return DateChip(
                        day: weekDaysShort[day.weekday % 7],
                        date: '${day.day}',
                        selected: selectedDate != null && selectedDate!.year == day.year && selectedDate!.month == day.month && selectedDate!.day == day.day,
                        onTap: () => setState(() { selectedDate = day; selectedTime = null; }),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 18),
                const Text('اختر الوقت', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                const SizedBox(height: 12),
                if (selectedDate == null)
                  const Text('اختر يوماً أولاً', style: TextStyle(color: ClinicColors.muted))
                else if (slots.isEmpty)
                  const Text('لا توجد أوقات متاحة في هذا اليوم', style: TextStyle(color: ClinicColors.muted))
                else
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        for (final slot in slots) ...[
                          TimeChip(time: slot, selected: selectedTime == slot, onTap: () => setState(() => selectedTime = slot)),
                          const SizedBox(width: 8),
                        ],
                      ],
                    ),
                  ),
              ] else ...[
                const SizedBox(height: 18),
                Text(doctor.biography.isEmpty ? 'لا توجد نبذة بعد' : doctor.biography),
              ],
            ],
          ),
        ),
        if (store.isPatient)
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: Row(
                children: [
                  CircleIconBtn(
                    icon: Icons.chat_bubble_outline,
                    color: ClinicColors.tint,
                    iconColor: ClinicColors.primary,
                    size: 54,
                    onTap: () => store.openMessages(patientId: store.currentPatient?.id, doctorId: doctor.id),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OrangeButton(
                      label: 'احجز الآن',
                      onTap: selectedDate == null || selectedTime == null
                          ? null
                          : () {
                              store.bookAppointment(doctor: doctor, date: selectedDate!, time: selectedTime!, reason: 'حجز من الملف');
                              toast(context, store.lastMessage ?? 'تم إرسال طلب الموعد');
                            },
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
