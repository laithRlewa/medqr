import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';

import '../data/doctor_locations.dart';
import '../state/clinic_store.dart';
import '../widgets/mobile_kit.dart';
import '../widgets/ui.dart';

class DoctorsMapScreen extends StatefulWidget {
  const DoctorsMapScreen({super.key});

  @override
  State<DoctorsMapScreen> createState() => _DoctorsMapScreenState();
}

class _DoctorsMapScreenState extends State<DoctorsMapScreen> {
  final _mapController = MapController();
  final _search = TextEditingController();
  String? _specialty;
  String? _selectedId;
  bool _listOpen = false;

  @override
  void dispose() {
    _search.dispose();
    _mapController.dispose();
    super.dispose();
  }

  List<Doctor> _filtered(ClinicStore store) {
    final q = _search.text.trim().toLowerCase();
    final regionId = store.selectedRegionId;
    return store.doctors.where((d) {
      if (d.status != 'approved') return false;
      if (d.city.trim() != serviceCity) return false;
      if (regionId != null && regionId.isNotEmpty && d.regionId != regionId) return false;
      if (_specialty != null && d.specialty != _specialty) return false;
      if (q.isEmpty) return true;
      final regionName = store.regionById(d.regionId)?.name ?? '';
      return d.fullName.toLowerCase().contains(q) ||
          d.specialty.contains(_search.text.trim()) ||
          d.clinicName.contains(_search.text.trim()) ||
          regionName.contains(_search.text.trim());
    }).toList();
  }

  void _focusDoctor(Doctor doctor, ClinicStore store) {
    setState(() {
      _selectedId = doctor.id;
      _listOpen = false;
    });
    _mapController.move(doctorLatLng(doctor, regions: store.regions), 13);
  }

  void _focusRegion(ClinicStore store, String? regionId) {
    store.selectRegion(regionId);
    final region = store.regionById(regionId);
    if (region != null) {
      _mapController.move(regionCenter(region), region.zoom);
    } else {
      _mapController.move(baghdadCenter, 12.2);
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = ClinicScope.of(context);
    final doctors = _filtered(store);
    final specialties = store.doctors.map((d) => d.specialty).toSet().toList()..sort();
    final selected = doctors.where((d) => d.id == _selectedId).firstOrNull ??
        store.doctors.where((d) => d.id == _selectedId).firstOrNull;
    final bottomPad = isMobileLayout(context) ? 110.0 : 24.0;
    final regionName = store.regionById(store.selectedRegionId)?.name;
    final initialRegion = store.regionById(store.selectedRegionId);

    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: initialRegion != null ? regionCenter(initialRegion) : baghdadCenter,
            initialZoom: initialRegion?.zoom ?? 12.2,
            minZoom: 10.5,
            maxZoom: 17,
            interactionOptions: const InteractionOptions(flags: InteractiveFlag.all & ~InteractiveFlag.rotate),
            onTap: (_, _) => setState(() => _selectedId = null),
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'iq.medical.qr.clinic',
              maxNativeZoom: 19,
            ),
            MarkerLayer(
              markers: [
                for (final doc in doctors)
                  Marker(
                    point: doctorLatLng(doc, regions: store.regions),
                    width: 56,
                    height: 68,
                    alignment: Alignment.topCenter,
                    child: GestureDetector(
                      onTap: () => _focusDoctor(doc, store),
                      child: _DoctorPin(doctor: doc, selected: doc.id == _selectedId),
                    ),
                  ),
              ],
            ),
          ],
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Column(
              children: [
                SoftCard(
                  radius: ClinicRadii.pill,
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Row(
                    children: [
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8),
                        child: Icon(Icons.search, color: ClinicColors.muted),
                      ),
                      Expanded(
                        child: TextField(
                          controller: _search,
                          onChanged: (_) => setState(() {}),
                          decoration: const InputDecoration(
                            hintText: 'ابحث عن طبيب أو تخصص أو منطقة',
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            filled: false,
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      CircleIconBtn(
                        icon: _listOpen ? Icons.map_outlined : Icons.list_alt_rounded,
                        size: 40,
                        color: ClinicColors.tint,
                        iconColor: ClinicColors.primary,
                        onTap: () => setState(() => _listOpen = !_listOpen),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 38,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      PillFilter(
                        label: 'كل المناطق',
                        selected: store.selectedRegionId == null,
                        onTap: () => _focusRegion(store, null),
                      ),
                      const SizedBox(width: 8),
                      for (final region in store.regions) ...[
                        PillFilter(
                          label:
                              '${region.name} (${store.doctors.where((d) => d.status == 'approved' && d.regionId == region.id).length})',
                          selected: store.selectedRegionId == region.id,
                          onTap: () => _focusRegion(store, region.id),
                        ),
                        const SizedBox(width: 8),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 38,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      PillFilter(
                        label: 'كل التخصصات (${doctors.length})',
                        selected: _specialty == null,
                        onTap: () => setState(() => _specialty = null),
                      ),
                      const SizedBox(width: 8),
                      for (final s in specialties) ...[
                        PillFilter(
                          label: s,
                          selected: _specialty == s,
                          onTap: () => setState(() => _specialty = s),
                        ),
                        const SizedBox(width: 8),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        if (_listOpen)
          Positioned(
            left: 16,
            right: 16,
            top: MediaQuery.paddingOf(context).top + 148,
            bottom: bottomPad + (selected != null ? 170 : 0),
            child: SoftCard(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: doctors.isEmpty
                  ? const Center(child: Text('لا يوجد أطباء مطابقون', style: TextStyle(color: ClinicColors.muted)))
                  : ListView.separated(
                      itemCount: doctors.length,
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (context, i) {
                        final doc = doctors[i];
                        final area = store.regionById(doc.regionId)?.name ?? doc.city;
                        return ListTile(
                          leading: PhotoAvatar(name: doc.fullName, size: 44, photo: doc.profilePhoto, ring: false),
                          title: Text('د. ${doc.fullName}', style: const TextStyle(fontWeight: FontWeight.w800)),
                          subtitle: Text('${doc.specialty} · $area', style: const TextStyle(fontSize: 12, color: ClinicColors.muted)),
                          trailing: const Icon(Icons.place_outlined, color: ClinicColors.primary),
                          onTap: () => _focusDoctor(doc, store),
                        );
                      },
                    ),
            ),
          ),
        if (selected != null)
          Positioned(
            left: 16,
            right: 16,
            bottom: bottomPad,
            child: _DoctorMapCard(
              doctor: selected,
              regionLabel: store.regionById(selected.regionId)?.name,
              onClose: () => setState(() => _selectedId = null),
              onOpen: () => store.openDoctor(selected.id),
              onBook: () => store.openDoctor(selected.id),
            ),
          )
        else
          Positioned(
            left: 16,
            right: 16,
            bottom: bottomPad,
            child: SoftCard(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(color: ClinicColors.tint, borderRadius: BorderRadius.circular(14)),
                    child: const Icon(Icons.location_on, color: ClinicColors.primary),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      doctors.isEmpty
                          ? (regionName == null ? 'لا يوجد أطباء في بغداد' : 'لا يوجد أطباء في $regionName')
                          : '${doctors.length} طبيب${regionName == null ? ' في بغداد' : ' في $regionName'} — اضغط على علامة لعرض التفاصيل',
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ),
        Positioned(
          right: 16,
          bottom: bottomPad + (selected != null ? 190 : 78),
          child: Column(
            children: [
              _MapFab(icon: Icons.add, onTap: () => _mapController.move(_mapController.camera.center, _mapController.camera.zoom + 1)),
              const SizedBox(height: 8),
              _MapFab(icon: Icons.remove, onTap: () => _mapController.move(_mapController.camera.center, _mapController.camera.zoom - 1)),
              const SizedBox(height: 8),
              _MapFab(
                icon: Icons.my_location_outlined,
                onTap: () => _focusRegion(store, store.selectedRegionId),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MapFab extends StatelessWidget {
  const _MapFab({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      elevation: 2,
      shadowColor: ClinicColors.primaryDeep.withValues(alpha: 0.2),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(width: 42, height: 42, child: Icon(icon, color: ClinicColors.primaryDeep, size: 20)),
      ),
    );
  }
}

class _DoctorPin extends StatelessWidget {
  const _DoctorPin({required this.doctor, required this.selected});
  final Doctor doctor;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: selected ? ClinicColors.primary : Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: ClinicColors.primaryDeep.withValues(alpha: selected ? 0.28 : 0.14),
                blurRadius: selected ? 14 : 8,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(color: selected ? ClinicColors.primaryDeep : ClinicColors.border, width: selected ? 2 : 1),
          ),
          child: PhotoAvatar(name: doctor.fullName, size: selected ? 40 : 34, photo: doctor.profilePhoto, ring: false),
        ),
        CustomPaint(
          size: const Size(14, 10),
          painter: _PinTailPainter(color: selected ? ClinicColors.primary : Colors.white),
        ),
      ],
    );
  }
}

class _PinTailPainter extends CustomPainter {
  _PinTailPainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final path = ui.Path()
      ..moveTo(0, 0)
      ..lineTo(size.width / 2, size.height)
      ..lineTo(size.width, 0)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _PinTailPainter oldDelegate) => oldDelegate.color != color;
}

class _DoctorMapCard extends StatelessWidget {
  const _DoctorMapCard({
    required this.doctor,
    required this.onClose,
    required this.onOpen,
    required this.onBook,
    this.regionLabel,
  });

  final Doctor doctor;
  final String? regionLabel;
  final VoidCallback onClose;
  final VoidCallback onOpen;
  final VoidCallback onBook;

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PhotoAvatar(name: doctor.fullName, size: 58, photo: doctor.profilePhoto),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('د. ${doctor.fullName}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                    const SizedBox(height: 2),
                    Text(doctor.specialty, style: const TextStyle(color: ClinicColors.primary, fontWeight: FontWeight.w700, fontSize: 13)),
                    Text(
                      '${doctor.clinicName} · ${regionLabel ?? doctor.city}',
                      style: const TextStyle(color: ClinicColors.muted, fontSize: 12),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.star_rounded, size: 16, color: ClinicColors.star),
                        const SizedBox(width: 2),
                        Text(doctor.rating.toStringAsFixed(1), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
                        const SizedBox(width: 6),
                        Text('(${doctor.reviews})', style: const TextStyle(color: ClinicColors.muted, fontSize: 11)),
                        const SizedBox(width: 10),
                        if (doctor.yearsOfExperience > 0)
                          Text('${doctor.yearsOfExperience} سنة خبرة', style: const TextStyle(color: ClinicColors.muted, fontSize: 11)),
                      ],
                    ),
                  ],
                ),
              ),
              CircleIconBtn(icon: Icons.close_rounded, size: 36, onTap: onClose),
            ],
          ),
          if (doctor.workingHours.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(color: ClinicColors.tint, borderRadius: BorderRadius.circular(14)),
              child: Row(
                children: [
                  const Icon(Icons.schedule, size: 16, color: ClinicColors.primary),
                  const SizedBox(width: 6),
                  Expanded(child: Text(doctor.workingHours, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12))),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: GhostButton(label: 'عرض الملف', onTap: onOpen)),
              const SizedBox(width: 10),
              Expanded(child: OrangeButton(label: 'حجز موعد', icon: Icons.event_available_outlined, onTap: onBook)),
            ],
          ),
        ],
      ),
    );
  }
}
