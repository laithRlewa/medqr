import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../models/models.dart';
import '../state/admin_store.dart';
import '../widgets/ui.dart';

class DoctorsMapScreen extends StatefulWidget {
  const DoctorsMapScreen({super.key});

  @override
  State<DoctorsMapScreen> createState() => _DoctorsMapScreenState();
}

class _DoctorsMapScreenState extends State<DoctorsMapScreen> {
  static const _baghdad = LatLng(33.3152, 44.3661);
  final _mapController = MapController();
  final _search = TextEditingController();
  String? _regionId;
  String _status = 'all';
  Doctor? _selected;

  @override
  void dispose() {
    _search.dispose();
    _mapController.dispose();
    super.dispose();
  }

  List<Doctor> _filtered(AdminStore store) {
    final q = _search.text.trim().toLowerCase();
    return store.doctors.where((d) {
      if (d.latitude == null || d.longitude == null) return false;
      if (_status != 'all' && d.status != _status) return false;
      if (_regionId != null && d.regionId != _regionId) return false;
      if (q.isEmpty) return true;
      return d.fullName.toLowerCase().contains(q) ||
          d.specialty.toLowerCase().contains(q) ||
          d.clinicName.toLowerCase().contains(q);
    }).toList();
  }

  void _select(Doctor doctor) {
    setState(() => _selected = doctor);
    _mapController.move(LatLng(doctor.latitude!, doctor.longitude!), 14);
  }

  @override
  Widget build(BuildContext context) {
    final store = AdminScope.of(context);
    final theme = Theme.of(context);
    final doctors = _filtered(store);
    final withoutLocation = store.doctors.where((d) => d.latitude == null || d.longitude == null).length;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          PageHeader(
            title: 'خريطة الأطباء',
            subtitle: '${doctors.length} طبيب على الخريطة'
                '${withoutLocation > 0 ? ' — $withoutLocation بدون موقع محدد' : ''}',
            icon: Icons.map_outlined,
          ),
          Row(
            children: [
              SearchField(
                hint: 'بحث بالاسم أو التخصص أو العيادة',
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(width: 12),
              for (final s in const [('all', 'الكل'), ('approved', 'موافق عليه'), ('pending', 'قيد المراجعة'), ('suspended', 'معلّق')])
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(s.$2),
                    selected: _status == s.$1,
                    onSelected: (_) => setState(() => _status = s.$1),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: const Text('كل المناطق'),
                    selected: _regionId == null,
                    onSelected: (_) => setState(() => _regionId = null),
                  ),
                ),
                for (final region in store.regions)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(region.name),
                      selected: _regionId == region.id,
                      onSelected: (_) {
                        setState(() => _regionId = region.id);
                        _mapController.move(LatLng(region.centerLat, region.centerLng), region.zoom);
                      },
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Card(
              clipBehavior: Clip.antiAlias,
              margin: EdgeInsets.zero,
              child: Stack(
                children: [
                  FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: _baghdad,
                      initialZoom: 12,
                      minZoom: 10,
                      maxZoom: 18,
                      interactionOptions:
                          const InteractionOptions(flags: InteractiveFlag.all & ~InteractiveFlag.rotate),
                      onTap: (_, _) => setState(() => _selected = null),
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'iq.medical.qr.admin',
                        maxNativeZoom: 19,
                      ),
                      CircleLayer(
                        circles: [
                          for (final r in store.regions)
                            CircleMarker(
                              point: LatLng(r.centerLat, r.centerLng),
                              radius: 900,
                              useRadiusInMeter: true,
                              color: theme.colorScheme.primary.withValues(alpha: 0.06),
                              borderColor: theme.colorScheme.primary.withValues(alpha: 0.25),
                              borderStrokeWidth: 1.5,
                            ),
                        ],
                      ),
                      MarkerLayer(
                        markers: [
                          for (final r in store.regions)
                            Marker(
                              point: LatLng(r.centerLat, r.centerLng),
                              width: 120,
                              height: 24,
                              alignment: Alignment.topCenter,
                              child: IgnorePointer(
                                child: Text(
                                  r.name,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    color: theme.colorScheme.primary,
                                    shadows: const [Shadow(color: Colors.white, blurRadius: 4)],
                                  ),
                                ),
                              ),
                            ),
                          for (final doc in doctors)
                            Marker(
                              point: LatLng(doc.latitude!, doc.longitude!),
                              width: 130,
                              height: 60,
                              alignment: Alignment.topCenter,
                              child: GestureDetector(
                                onTap: () => _select(doc),
                                child: _DoctorPin(
                                  doctor: doc,
                                  color: doctorStatusColor(doc.status),
                                  selected: _selected?.id == doc.id,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                  Positioned(
                    left: 14,
                    bottom: 14,
                    child: Column(
                      children: [
                        FloatingActionButton.small(
                          heroTag: 'zin',
                          onPressed: () => _mapController.move(
                              _mapController.camera.center, _mapController.camera.zoom + 1),
                          child: const Icon(Icons.add),
                        ),
                        const SizedBox(height: 8),
                        FloatingActionButton.small(
                          heroTag: 'zout',
                          onPressed: () => _mapController.move(
                              _mapController.camera.center, _mapController.camera.zoom - 1),
                          child: const Icon(Icons.remove),
                        ),
                        const SizedBox(height: 8),
                        FloatingActionButton.small(
                          heroTag: 'home',
                          onPressed: () => _mapController.move(_baghdad, 12),
                          child: const Icon(Icons.my_location_outlined),
                        ),
                      ],
                    ),
                  ),
                  if (doctors.isEmpty)
                    Center(
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          child: Text(
                            withoutLocation > 0
                                ? 'لا توجد مواقع مطابقة — $withoutLocation طبيب بدون موقع محدد'
                                : 'لا يوجد أطباء بعد',
                          ),
                        ),
                      ),
                    ),
                  if (_selected != null)
                    Positioned(
                      left: 14,
                      right: 14,
                      bottom: 14,
                      child: _DoctorCard(
                        doctor: _selected!,
                        regionName: store.regionById(_selected!.regionId)?.name,
                        statusLabel: doctorStatusAr(_selected!.status),
                        statusColor: doctorStatusColor(_selected!.status),
                        onClose: () => setState(() => _selected = null),
                        onOpenDoctors: () => store.goTo(AdminPage.doctors),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DoctorPin extends StatelessWidget {
  const _DoctorPin({required this.doctor, required this.color, required this.selected});

  final Doctor doctor;
  final Color color;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color, width: selected ? 2 : 1),
            boxShadow: [BoxShadow(color: color.withValues(alpha: 0.25), blurRadius: 6, offset: const Offset(0, 2))],
          ),
          child: Text(
            'د. ${doctor.fullName}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
          ),
        ),
        Icon(Icons.location_on, color: color, size: selected ? 30 : 24),
      ],
    );
  }
}

class _DoctorCard extends StatelessWidget {
  const _DoctorCard({
    required this.doctor,
    required this.statusLabel,
    required this.statusColor,
    required this.onClose,
    required this.onOpenDoctors,
    this.regionName,
  });

  final Doctor doctor;
  final String statusLabel;
  final Color statusColor;
  final String? regionName;
  final VoidCallback onClose;
  final VoidCallback onOpenDoctors;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 6,
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            AvatarCircle(name: doctor.fullName, photo: doctor.profilePhoto),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('د. ${doctor.fullName}',
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                  Text(doctor.specialty, style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.w700)),
                  Text(
                    '${doctor.clinicName} · ${regionName ?? doctor.city}',
                    style: theme.textTheme.bodySmall,
                  ),
                  if (doctor.phone.isNotEmpty)
                    Text(doctor.phone, style: theme.textTheme.bodySmall, textDirection: TextDirection.ltr),
                ],
              ),
            ),
            StatusChip(label: statusLabel, color: statusColor),
            const SizedBox(width: 8),
            TextButton.icon(
              onPressed: onOpenDoctors,
              icon: const Icon(Icons.open_in_new, size: 16),
              label: const Text('إدارة الأطباء'),
            ),
            IconButton(onPressed: onClose, icon: const Icon(Icons.close)),
          ],
        ),
      ),
    );
  }
}
