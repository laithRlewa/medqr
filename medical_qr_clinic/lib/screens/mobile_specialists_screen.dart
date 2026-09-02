import 'package:flutter/material.dart';

import '../state/clinic_store.dart';
import '../theme/clinic_style.dart';
import '../widgets/mobile_kit.dart';

class MobileSpecialistsScreen extends StatefulWidget {
  const MobileSpecialistsScreen({super.key});

  @override
  State<MobileSpecialistsScreen> createState() => _MobileSpecialistsScreenState();
}

class _MobileSpecialistsScreenState extends State<MobileSpecialistsScreen> {
  String search = '';
  String? highlightedId;

  @override
  Widget build(BuildContext context) {
    final store = ClinicScope.of(context);
    final doctors = store.doctors.where((d) => d.isActive).where((d) {
      if (store.selectedRegionId != null && d.regionId != store.selectedRegionId) return false;
      if (search.isEmpty) return true;
      final q = search.toLowerCase();
      final regionName = store.regionById(d.regionId)?.name ?? '';
      return d.fullName.toLowerCase().contains(q) || d.specialty.contains(search) || d.city.contains(search) || regionName.contains(search);
    }).toList();

    return ListView(
      padding: clinicPadding(context),
      children: [
        const Text('ابحث عن متخصص', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: ClinicColors.primaryDeep)),
        const SizedBox(height: 6),
        Text('${doctors.length} طبيب متاح', style: const TextStyle(color: ClinicColors.muted)),
        if (store.regions.isNotEmpty) ...[
          const SizedBox(height: 14),
          SizedBox(
            height: 38,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                PillFilter(
                  label: 'كل المناطق',
                  selected: store.selectedRegionId == null,
                  onTap: () => store.selectRegion(null),
                ),
                const SizedBox(width: 8),
                for (final region in store.regions) ...[
                  PillFilter(
                    label: region.name,
                    selected: store.selectedRegionId == region.id,
                    onTap: () => store.selectRegion(region.id),
                  ),
                  const SizedBox(width: 8),
                ],
              ],
            ),
          ),
        ],
        const SizedBox(height: 16),
        SoftCard(
          radius: ClinicRadii.pill,
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          child: Row(
            children: [
              const Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Icon(Icons.search, color: ClinicColors.muted)),
              Expanded(
                child: TextField(
                  onChanged: (v) => setState(() => search = v),
                  decoration: const InputDecoration(
                    hintText: 'اسم الطبيب أو التخصص أو المنطقة',
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    filled: false,
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        if (doctors.isEmpty)
          SoftCard(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 36),
              child: Column(
                children: [
                  Icon(Icons.search_off_rounded, size: 40, color: ClinicColors.muted.withValues(alpha: 0.7)),
                  const SizedBox(height: 10),
                  const Text('لا يوجد أطباء مطابقون', style: TextStyle(color: ClinicColors.muted)),
                ],
              ),
            ),
          )
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: doctors.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.72,
            ),
            itemBuilder: (context, i) {
              final doc = doctors[i];
              return SpecialistCard(
                doctor: doc,
                highlighted: highlightedId == doc.id || (highlightedId == null && i == 0),
                onTap: () {
                  setState(() => highlightedId = doc.id);
                  store.openDoctor(doc.id);
                },
              );
            },
          ),
      ],
    );
  }
}
