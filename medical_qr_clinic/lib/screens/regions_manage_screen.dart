import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../data/doctor_locations.dart';
import '../state/clinic_store.dart';
import '../widgets/mobile_kit.dart';
import '../widgets/ui.dart';

/// من لوحة التحكم: تحديد منطقة على الخريطة وإضافة أطباء إليها.
class RegionsManageScreen extends StatefulWidget {
  const RegionsManageScreen({super.key});

  @override
  State<RegionsManageScreen> createState() => _RegionsManageScreenState();
}

class _RegionsManageScreenState extends State<RegionsManageScreen> {
  final _mapController = MapController();
  final _nameCtrl = TextEditingController();
  String? _selectedRegionId;
  LatLng? _draftPoint;
  final Set<String> _selectedDoctorIds = {};
  bool _placing = false;

  @override
  void dispose() {
    _mapController.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  void _toast(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  void _selectRegion(ClinicStore store, MapRegion region) {
    setState(() {
      _selectedRegionId = region.id;
      _draftPoint = null;
      _placing = false;
      _nameCtrl.text = region.name;
      _selectedDoctorIds
        ..clear()
        ..addAll(store.doctors.where((d) => d.regionId == region.id).map((d) => d.id));
    });
    _mapController.move(regionCenter(region), region.zoom);
  }

  Future<void> _saveRegion(ClinicStore store) async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      _toast('أدخل اسم المنطقة');
      return;
    }
    if (_selectedRegionId == null) {
      final point = _draftPoint;
      if (point == null) {
        _toast('اضغط على الخريطة لتحديد موقع المنطقة');
        return;
      }
      final createdId = await store.createMapRegion(name: name, centerLat: point.latitude, centerLng: point.longitude);
      final created = createdId == null ? null : store.regionById(createdId);
      if (created != null) {
        await store.assignDoctorsToRegion(created.id, _selectedDoctorIds.toList());
        _selectRegion(store, created);
      } else {
        setState(() {
          _draftPoint = null;
          _placing = false;
          _nameCtrl.clear();
          _selectedDoctorIds.clear();
        });
      }
      return;
    }
    await store.updateMapRegion(_selectedRegionId!, {
      'name': name,
      if (_draftPoint != null) 'centerLat': _draftPoint!.latitude,
      if (_draftPoint != null) 'centerLng': _draftPoint!.longitude,
    });
    await store.assignDoctorsToRegion(_selectedRegionId!, _selectedDoctorIds.toList());
    final region = store.regionById(_selectedRegionId);
    if (region != null) _selectRegion(store, region);
  }

  @override
  Widget build(BuildContext context) {
    final store = ClinicScope.of(context);
    if (!store.canManageRegions) {
      return const Center(child: Text('إدارة المناطق متاحة للأطباء والإدارة فقط'));
    }
    final regions = [...store.regions]..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    final selected = store.regionById(_selectedRegionId);
    final approvedDoctors = store.doctors.where((d) => d.status == 'approved').toList()
      ..sort((a, b) => a.fullName.compareTo(b.fullName));

    return Column(
      children: [
        Padding(
          padding: clinicPadding(context).copyWith(bottom: 8),
          child: PageHeader(
            title: 'مناطق الخريطة',
            subtitle: 'حدد منطقة على الخريطة ثم أضف إليها الأطباء',
            icon: Icons.map_outlined,
            actions: [
              OutlinedButton.icon(
                onPressed: () => setState(() {
                  _selectedRegionId = null;
                  _draftPoint = null;
                  _placing = true;
                  _nameCtrl.clear();
                  _selectedDoctorIds.clear();
                }),
                icon: const Icon(Icons.add_location_alt_outlined),
                label: const Text('منطقة جديدة'),
              ),
            ],
          ),
        ),
        Expanded(
          child: LayoutBuilder(
            builder: (context, c) {
              final stacked = c.maxWidth < 900;
              final map = SoftCard(
                padding: EdgeInsets.zero,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(ClinicRadii.card),
                  child: Stack(
                    children: [
                      FlutterMap(
                        mapController: _mapController,
                        options: MapOptions(
                          initialCenter: selected != null ? regionCenter(selected) : baghdadCenter,
                          initialZoom: selected?.zoom ?? 12.2,
                          minZoom: 10.5,
                          maxZoom: 17,
                          interactionOptions: const InteractionOptions(flags: InteractiveFlag.all & ~InteractiveFlag.rotate),
                          onTap: (_, point) {
                            if (_placing || _selectedRegionId != null) {
                              setState(() => _draftPoint = point);
                            }
                          },
                        ),
                        children: [
                          TileLayer(
                            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                            userAgentPackageName: 'iq.medical.qr.clinic',
                          ),
                          MarkerLayer(
                            markers: [
                              for (final region in regions)
                                Marker(
                                  point: regionCenter(region),
                                  width: 44,
                                  height: 44,
                                  child: GestureDetector(
                                    onTap: () => _selectRegion(store, region),
                                    child: Icon(
                                      Icons.location_on,
                                      size: 40,
                                      color: region.id == _selectedRegionId ? ClinicColors.accent : ClinicColors.primary,
                                    ),
                                  ),
                                ),
                              if (_draftPoint != null)
                                Marker(
                                  point: _draftPoint!,
                                  width: 40,
                                  height: 40,
                                  child: const Icon(Icons.add_location_alt, color: Color(0xFFC62828), size: 36),
                                ),
                            ],
                          ),
                        ],
                      ),
                      if (_placing)
                        Positioned(
                          left: 12,
                          right: 12,
                          top: 12,
                          child: SoftCard(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            child: Text(
                              _draftPoint == null ? 'اضغط على الخريطة لتحديد مركز المنطقة' : 'تم تحديد الموقع — أكمل الاسم والأطباء ثم احفظ',
                              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );

              final side = SoftCard(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Text(
                      selected == null && !_placing ? 'اختر منطقة أو أنشئ واحدةً جديدة' : (_placing ? 'منطقة جديدة' : 'تعديل المنطقة'),
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                    ),
                    const SizedBox(height: 12),
                    if (regions.isNotEmpty && !_placing) ...[
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final region in regions)
                            FilterChip(
                              label: Text('${region.name} (${store.doctors.where((d) => d.regionId == region.id).length})'),
                              selected: region.id == _selectedRegionId,
                              onSelected: (_) => _selectRegion(store, region),
                            ),
                        ],
                      ),
                      const SizedBox(height: 14),
                    ],
                    if (_placing || selected != null) ...[
                      TextField(
                        controller: _nameCtrl,
                        decoration: const InputDecoration(labelText: 'اسم المنطقة', hintText: 'مثال: الكرادة'),
                      ),
                      const SizedBox(height: 14),
                      const Text('الأطباء في هذه المنطقة', style: TextStyle(fontWeight: FontWeight.w800)),
                      const SizedBox(height: 8),
                      if (approvedDoctors.isEmpty)
                        const Text('لا يوجد أطباء معتمدون', style: TextStyle(color: ClinicColors.muted))
                      else
                        ...approvedDoctors.map((doc) {
                          final checked = _selectedDoctorIds.contains(doc.id);
                          return CheckboxListTile(
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            value: checked,
                            title: Text('د. ${doc.fullName}'),
                            subtitle: Text(doc.specialty, style: const TextStyle(fontSize: 12, color: ClinicColors.muted)),
                            onChanged: (v) => setState(() {
                              if (v == true) {
                                _selectedDoctorIds.add(doc.id);
                              } else {
                                _selectedDoctorIds.remove(doc.id);
                              }
                            }),
                          );
                        }),
                      const SizedBox(height: 12),
                      FilledButton.icon(
                        onPressed: store.busy ? null : () => _saveRegion(store),
                        icon: const Icon(Icons.save_outlined),
                        label: Text(selected == null ? 'إنشاء وإضافة الأطباء' : 'حفظ التعديلات'),
                      ),
                      if (selected != null) ...[
                        const SizedBox(height: 8),
                        TextButton.icon(
                          onPressed: store.busy
                              ? null
                              : () async {
                                  await store.deleteMapRegion(selected.id);
                                  setState(() {
                                    _selectedRegionId = null;
                                    _nameCtrl.clear();
                                    _selectedDoctorIds.clear();
                                    _draftPoint = null;
                                  });
                                },
                          icon: const Icon(Icons.delete_outline, color: Color(0xFFC62828)),
                          label: const Text('حذف المنطقة', style: TextStyle(color: Color(0xFFC62828))),
                        ),
                      ],
                    ],
                  ],
                ),
              );

              if (stacked) {
                return Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Column(
                    children: [
                      SizedBox(height: 260, child: map),
                      const SizedBox(height: 12),
                      Expanded(child: side),
                    ],
                  ),
                );
              }
              return Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Row(
                  children: [
                    Expanded(flex: 3, child: map),
                    const SizedBox(width: 12),
                    Expanded(flex: 2, child: side),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
