import 'package:flutter/material.dart';

import '../models/models.dart';
import '../state/admin_store.dart';
import '../widgets/ui.dart';

class DoctorsScreen extends StatefulWidget {
  const DoctorsScreen({super.key});

  @override
  State<DoctorsScreen> createState() => _DoctorsScreenState();
}

class _DoctorsScreenState extends State<DoctorsScreen> with SingleTickerProviderStateMixin {
  late final TabController tabs;
  String search = '';

  @override
  void initState() {
    super.initState();
    tabs = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    tabs.dispose();
    super.dispose();
  }

  List<Doctor> _filter(List<Doctor> source) {
    final q = search.trim().toLowerCase();
    if (q.isEmpty) return source;
    return source.where((d) => d.fullName.toLowerCase().contains(q) || d.specialty.toLowerCase().contains(q)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final store = AdminScope.of(context);
    final pending = store.doctors.where((d) => d.status == 'pending').toList();
    final approved = store.doctors.where((d) => d.status == 'approved').toList();
    final suspended = store.doctors.where((d) => d.status == 'suspended').toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PageHeader(title: 'إدارة الأطباء', subtitle: '${store.doctors.length} طبيب إجمالاً · ${pending.length} قيد المراجعة'),
              SearchField(hint: 'بحث عن الأطباء...', onChanged: (v) => setState(() => search = v)),
              const SizedBox(height: 12),
              TabBar(controller: tabs, tabs: [
                Tab(text: 'قيد المراجعة (${pending.length})'),
                Tab(text: 'موافق عليهم (${approved.length})'),
                Tab(text: 'معلّقون (${suspended.length})'),
              ]),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: tabs,
            children: [
              _list(store, _filter(pending), empty: 'لا يوجد أطباء قيد المراجعة'),
              _list(store, _filter(approved), empty: 'لا يوجد أطباء موافق عليهم'),
              _list(store, _filter(suspended), empty: 'لا يوجد أطباء معلّقون'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _list(AdminStore store, List<Doctor> doctors, {required String empty}) {
    if (doctors.isEmpty) return EmptyHint(empty);
    return ListView.separated(
      padding: const EdgeInsets.all(24),
      itemCount: doctors.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (_, i) {
        final doc = doctors[i];
        return Card(
          child: ListTile(
            leading: AvatarCircle(name: doc.fullName, photo: doc.profilePhoto, colors: const [BrandPalette.accent, BrandPalette.primaryDeep]),
            title: Text('د. ${doc.fullName}'),
            subtitle: Text('${doc.specialty} · ${doc.clinicName} · ${doc.city}\nرقم الترخيص: ${doc.licenseNumber} · ${doc.phone}'),
            isThreeLine: true,
            trailing: Wrap(
              spacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                StatusChip(label: doctorStatusAr(doc.status), color: doctorStatusColor(doc.status)),
                if (doc.status == 'pending' || doc.status == 'suspended')
                  FilledButton.icon(
                    onPressed: () => store.approveDoctor(doc),
                    icon: const Icon(Icons.check, size: 16),
                    label: Text(doc.status == 'pending' ? 'موافقة' : 'إعادة تفعيل'),
                    style: FilledButton.styleFrom(backgroundColor: Colors.green.shade700),
                  ),
                if (doc.status == 'approved')
                  FilledButton.tonalIcon(
                    onPressed: () => store.suspendDoctor(doc),
                    icon: const Icon(Icons.block, size: 16),
                    label: const Text('تعليق'),
                    style: FilledButton.styleFrom(foregroundColor: Colors.red.shade700),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
