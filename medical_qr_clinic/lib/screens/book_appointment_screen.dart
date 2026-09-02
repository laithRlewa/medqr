import 'package:flutter/material.dart';

import '../models/models.dart';
import '../state/clinic_store.dart';
import '../widgets/ui.dart';

class BookAppointmentScreen extends StatefulWidget {
  const BookAppointmentScreen({super.key});

  @override
  State<BookAppointmentScreen> createState() => _BookAppointmentScreenState();
}

class _BookAppointmentScreenState extends State<BookAppointmentScreen> {
  String search = '';
  Doctor? selected;
  DateTime? date;
  String? time;
  final reason = TextEditingController();

  @override
  void dispose() {
    reason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = ClinicScope.of(context);
    if (selected != null) return _booking(store, selected!);

    final doctors = store.doctors.where((d) => d.isActive).where((d) {
      if (store.selectedRegionId != null && d.regionId != store.selectedRegionId) return false;
      if (search.isEmpty) return true;
      final q = search.toLowerCase();
      final regionName = store.regionById(d.regionId)?.name ?? '';
      return d.fullName.toLowerCase().contains(q) ||
          d.specialty.contains(search) ||
          d.city.contains(search) ||
          regionName.contains(search);
    }).toList();

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const PageHeader(title: 'بحث طبيب', subtitle: 'اختر منطقة ثم طبيباً معتمداً واحجز موعداً', icon: Icons.medical_services_outlined),
        if (store.regions.isNotEmpty) ...[
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                FilterChip(
                  label: const Text('كل المناطق'),
                  selected: store.selectedRegionId == null,
                  onSelected: (_) => store.selectRegion(null),
                ),
                const SizedBox(width: 8),
                for (final region in store.regions) ...[
                  FilterChip(
                    label: Text(region.name),
                    selected: store.selectedRegionId == region.id,
                    onSelected: (_) => store.selectRegion(region.id),
                  ),
                  const SizedBox(width: 8),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
        SearchField(hint: 'ابحث بالاسم أو التخصص أو المنطقة', onChanged: (v) => setState(() => search = v)),
        const SizedBox(height: 16),
        if (doctors.isEmpty) const EmptyHint('لا يوجد أطباء مطابقون', art: ClinicArt.nurseLab),
        for (final doc in doctors)
          Card(
            child: ListTile(
              leading: AvatarCircle(name: doc.fullName, photo: doc.profilePhoto),
              title: Text('د. ${doc.fullName}'),
              subtitle: Text('${doc.specialty} · ${doc.clinicName} · ${store.regionById(doc.regionId)?.name ?? doc.city}'),
              trailing: const Icon(Icons.chevron_left),
              onTap: () => setState(() {
                selected = doc;
                date = null;
                time = null;
              }),
            ),
          ),
      ],
    );
  }

  Widget _booking(ClinicStore store, Doctor doctor) {
    final patient = store.currentPatient;
    final slots = date == null ? <String>[] : store.openSlots(doctor.id, date!);
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: () => setState(() => selected = null),
            icon: const Icon(Icons.arrow_forward),
            label: const Text('العودة لقائمة الأطباء'),
          ),
        ),
        Card(
          child: ListTile(
            leading: AvatarCircle(name: doctor.fullName, radius: 28, photo: doctor.profilePhoto),
            title: Text('د. ${doctor.fullName}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
            subtitle: Text('${doctor.specialty}\n${doctor.clinicName} · ${doctor.city}'),
            isThreeLine: true,
          ),
        ),
        const SizedBox(height: 12),
        if (patient == null)
          const Card(child: Padding(padding: EdgeInsets.all(24), child: Text('يجب إكمال تسجيل بياناتك كمريض قبل حجز موعد.')))
        else ...[
          SectionCard(
            title: 'اختيار الموعد',
            icon: Icons.event,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                OutlinedButton.icon(
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 180)),
                      initialDate: date ?? DateTime.now(),
                    );
                    if (picked != null) setState(() { date = picked; time = null; });
                  },
                  icon: const Icon(Icons.calendar_today),
                  label: Text(date == null ? 'اختر التاريخ' : dateFmt.format(date!)),
                ),
                const SizedBox(height: 12),
                if (date != null && slots.isEmpty) const Text('لا توجد أوقات متاحة في هذا اليوم'),
                if (slots.isNotEmpty)
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final slot in slots)
                        ChoiceChip(
                          label: Text(slot),
                          selected: time == slot,
                          onSelected: (_) => setState(() => time = slot),
                        ),
                    ],
                  ),
                const SizedBox(height: 12),
                TextField(controller: reason, maxLines: 3, decoration: const InputDecoration(labelText: 'سبب الزيارة')),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: time == null || date == null
                      ? null
                      : () {
                          store.bookAppointment(doctor: doctor, date: date!, time: time!, reason: reason.text);
                          toast(context, store.lastMessage ?? 'تم إرسال طلب الموعد');
                        },
                  child: const Text('إرسال طلب الموعد'),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
