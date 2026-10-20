import 'package:flutter/material.dart';

import '../state/clinic_store.dart';
import '../widgets/brand_logo.dart';
import '../widgets/mobile_kit.dart';
import '../widgets/ui.dart';
import 'appointments_screen.dart';
import 'availability_screen.dart';
import 'book_appointment_screen.dart';
import 'doctor_calendar_screen.dart';
import 'doctor_dashboard_screen.dart';
import 'doctor_profile_screen.dart';
import 'doctor_public_screen.dart';
import 'doctor_stats_screen.dart';
import 'doctors_map_screen.dart';
import 'home_screen.dart';
import 'messages_screen.dart';
import 'mobile_home_screen.dart';
import 'mobile_specialists_screen.dart';
import 'more_menu_screen.dart';
import 'my_patients_screen.dart';
import 'my_records_screen.dart';
import 'notifications_screen.dart';
import 'patient_dashboard_screen.dart';
import 'patient_profile_screen.dart';
import 'patient_record_screen.dart';
import 'scan_qr_screen.dart';
import 'settings_screen.dart';
import 'social_screen.dart';
import 'regions_manage_screen.dart';

/// شريط رجوع علوي يظهر في الجوال عندما يوجد صفحة سابقة في سجل التنقل.
class _BackBar extends StatelessWidget {
  const _BackBar({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 4, 10, 0),
      child: Row(
        children: [
          CircleIconBtn(icon: Icons.arrow_forward_ios, size: 38, onTap: onTap),
          const SizedBox(width: 6),
          const Text('رجوع', style: TextStyle(fontWeight: FontWeight.w700, color: ClinicColors.muted)),
        ],
      ),
    );
  }
}

class _NavItem {
  const _NavItem(this.page, this.icon, this.label, {this.badge = false, this.primary = false});
  final ClinicPage page;
  final IconData icon;
  final String label;
  final bool badge;

  /// يظهر كزر دائري بارز في منتصف الشريط السفلي.
  final bool primary;
}

class ClinicShell extends StatefulWidget {
  const ClinicShell({super.key});

  @override
  State<ClinicShell> createState() => _ClinicShellState();
}

class _ClinicShellState extends State<ClinicShell> {
  bool collapsed = false;
  String? _seenMessage;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final store = ClinicScope.of(context);
    final message = store.lastMessage;
    if (message != null && message != _seenMessage) {
      _seenMessage = message;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
      });
    }
  }

  /// الشريط الجانبي (سطح المكتب) — مرتب حسب أولوية الاستخدام اليومي.
  List<_NavItem> desktopItems(ClinicStore store) {
    if (!store.loggedIn) {
      return [
        const _NavItem(ClinicPage.home, Icons.home_rounded, 'الرئيسية'),
        const _NavItem(ClinicPage.doctorsMap, Icons.map_rounded, 'خريطة الأطباء'),
        const _NavItem(ClinicPage.bookAppointment, Icons.medical_services_rounded, 'بحث طبيب'),
        const _NavItem(ClinicPage.social, Icons.public_rounded, 'المجتمع'),
        const _NavItem(ClinicPage.profile, Icons.login_rounded, 'تسجيل الدخول'),
      ];
    }
    if (store.isDoctor) {
      return [
        const _NavItem(ClinicPage.home, Icons.home_rounded, 'الرئيسية'),
        const _NavItem(ClinicPage.dashboard, Icons.space_dashboard_rounded, 'لوحة التحكم'),
        const _NavItem(ClinicPage.scanQr, Icons.qr_code_scanner_rounded, 'مسح QR'),
        const _NavItem(ClinicPage.appointments, Icons.event_available_rounded, 'المواعيد'),
        const _NavItem(ClinicPage.myPatients, Icons.groups_rounded, 'المرضى'),
        const _NavItem(ClinicPage.messages, Icons.forum_rounded, 'الرسائل', badge: true),
        if (store.canManageRegions) const _NavItem(ClinicPage.regionsManage, Icons.pin_drop_rounded, 'المناطق'),
        const _NavItem(ClinicPage.social, Icons.public_rounded, 'المجتمع'),
        const _NavItem(ClinicPage.notifications, Icons.notifications_rounded, 'الإشعارات', badge: true),
        const _NavItem(ClinicPage.profile, Icons.person_rounded, 'حسابي'),
      ];
    }
    return [
      const _NavItem(ClinicPage.home, Icons.home_rounded, 'الرئيسية'),
      const _NavItem(ClinicPage.dashboard, Icons.qr_code_2_rounded, 'رمزي الطبي'),
      const _NavItem(ClinicPage.doctorsMap, Icons.map_rounded, 'خريطة الأطباء'),
      const _NavItem(ClinicPage.bookAppointment, Icons.medical_services_rounded, 'بحث طبيب'),
      const _NavItem(ClinicPage.appointments, Icons.event_available_rounded, 'مواعيدي'),
      const _NavItem(ClinicPage.myRecords, Icons.folder_shared_rounded, 'سجلاتي'),
      const _NavItem(ClinicPage.messages, Icons.forum_rounded, 'الرسائل', badge: true),
      const _NavItem(ClinicPage.social, Icons.public_rounded, 'المجتمع'),
      const _NavItem(ClinicPage.notifications, Icons.notifications_rounded, 'الإشعارات', badge: true),
      const _NavItem(ClinicPage.profile, Icons.person_rounded, 'حسابي'),
    ];
  }

  /// الشريط السفلي (الجوال) — خمسة عناصر مع زر رئيسي بارز في المنتصف.
  List<_NavItem> mobileItems(ClinicStore store) {
    if (!store.loggedIn) {
      return [
        const _NavItem(ClinicPage.home, Icons.home_rounded, 'الرئيسية'),
        const _NavItem(ClinicPage.doctorsMap, Icons.map_rounded, 'الأطباء'),
        const _NavItem(ClinicPage.bookAppointment, Icons.medical_services_rounded, 'بحث', primary: true),
        const _NavItem(ClinicPage.social, Icons.public_rounded, 'المجتمع'),
        const _NavItem(ClinicPage.profile, Icons.login_rounded, 'دخول'),
      ];
    }
    if (store.isDoctor) {
      return [
        const _NavItem(ClinicPage.home, Icons.home_rounded, 'الرئيسية'),
        const _NavItem(ClinicPage.appointments, Icons.event_available_rounded, 'المواعيد'),
        const _NavItem(ClinicPage.scanQr, Icons.qr_code_scanner_rounded, 'مسح QR', primary: true),
        const _NavItem(ClinicPage.messages, Icons.forum_rounded, 'الرسائل', badge: true),
        const _NavItem(ClinicPage.profile, Icons.menu_rounded, 'المزيد'),
      ];
    }
    return [
      const _NavItem(ClinicPage.home, Icons.home_rounded, 'الرئيسية'),
      const _NavItem(ClinicPage.doctorsMap, Icons.map_rounded, 'الأطباء'),
      const _NavItem(ClinicPage.dashboard, Icons.qr_code_2_rounded, 'رمزي', primary: true),
      const _NavItem(ClinicPage.messages, Icons.forum_rounded, 'الرسائل', badge: true),
      const _NavItem(ClinicPage.profile, Icons.menu_rounded, 'المزيد'),
    ];
  }

  /// عناصر الشريط التي قد ترثها الصفحة الحالية، مرتبة حسب الأقرب دلالياً.
  /// تُستعمل لإبقاء التحديد صحيحاً في الصفحات الفرعية غير الموجودة في الشريط.
  List<ClinicPage> _navCandidates(ClinicPage page) => switch (page) {
        ClinicPage.availability || ClinicPage.doctorCalendar || ClinicPage.doctorStats => [ClinicPage.dashboard, ClinicPage.home],
        ClinicPage.patientRecord => [ClinicPage.myPatients, ClinicPage.home],
        ClinicPage.myRecords => [ClinicPage.myRecords, ClinicPage.dashboard, ClinicPage.home],
        ClinicPage.bookAppointment => [ClinicPage.bookAppointment, ClinicPage.doctorsMap, ClinicPage.home],
        ClinicPage.doctorPublic => [ClinicPage.doctorsMap, ClinicPage.bookAppointment, ClinicPage.home],
        ClinicPage.regionsManage => [ClinicPage.regionsManage, ClinicPage.doctorsMap, ClinicPage.dashboard, ClinicPage.home],
        ClinicPage.settings => [ClinicPage.profile, ClinicPage.home],
        _ => [page, ClinicPage.home],
      };

  int _selectedIndex(ClinicStore store, List<_NavItem> nav) {
    for (final candidate in _navCandidates(store.page)) {
      final index = nav.indexWhere((e) => e.page == candidate);
      if (index >= 0) return index;
    }
    return 0;
  }

  Widget pageOf(ClinicStore store) => switch (store.page) {
        ClinicPage.home => isMobileLayout(context) ? const MobileHomeScreen() : const HomeScreen(),
        ClinicPage.dashboard => store.isDoctor ? const DoctorDashboardScreen() : const PatientDashboardScreen(),
        ClinicPage.bookAppointment => isMobileLayout(context) && store.isPatient
            ? const MobileSpecialistsScreen()
            : const BookAppointmentScreen(),
        ClinicPage.appointments => const AppointmentsScreen(),
        ClinicPage.myPatients => const MyPatientsScreen(),
        ClinicPage.scanQr => const ScanQrScreen(),
        ClinicPage.notifications => const NotificationsScreen(),
        ClinicPage.profile => isMobileLayout(context)
            ? const MoreMenuScreen()
            : (store.isDoctor ? const DoctorProfileScreen() : const PatientProfileScreen()),
        ClinicPage.availability => const AvailabilityScreen(),
        ClinicPage.myRecords => const MyRecordsScreen(),
        ClinicPage.patientRecord => PatientRecordScreen(patientId: store.selectedPatientId ?? ''),
        ClinicPage.doctorPublic => DoctorPublicScreen(doctorId: store.selectedDoctorId ?? ''),
        ClinicPage.doctorStats => const DoctorStatsScreen(),
        ClinicPage.doctorCalendar => const DoctorCalendarScreen(),
        ClinicPage.social => const SocialScreen(),
        ClinicPage.messages => const MessagesScreen(),
        ClinicPage.doctorsMap => const DoctorsMapScreen(),
        ClinicPage.regionsManage => const RegionsManageScreen(),
        ClinicPage.settings => const SettingsScreen(),
      };

  bool _hideDock(ClinicPage page) => page == ClinicPage.doctorPublic || page == ClinicPage.patientRecord;

  @override
  Widget build(BuildContext context) {
    if (isMobileLayout(context)) return _mobile(context);
    return _desktop(context);
  }

  Widget _mobile(BuildContext context) {
    final store = ClinicScope.of(context);
    final nav = mobileItems(store);
    return PopScope(
      canPop: !store.canGoBack,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) store.back();
      },
      child: Scaffold(
        backgroundColor: ClinicColors.bg,
        body: Stack(
          children: [
            Positioned.fill(
              child: ColoredBox(
                color: ClinicColors.bg,
                child: SafeArea(
                  bottom: false,
                  child: Column(
                    children: [
                      if (store.canGoBack) _BackBar(onTap: store.back),
                      Expanded(child: pageOf(store)),
                    ],
                  ),
                ),
              ),
            ),
            if (!_hideDock(store.page))
              Align(
                alignment: Alignment.bottomCenter,
                child: FloatingDock(
                  selectedIndex: _selectedIndex(store, nav),
                  items: [
                    for (final item in nav)
                      DockItem(
                        icon: item.icon,
                        label: item.label,
                        badge: item.badge && store.unreadCount > 0,
                        primary: item.primary,
                      ),
                  ],
                  onSelected: (value) => store.goTo(nav[value].page),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _desktop(BuildContext context) {
    final store = ClinicScope.of(context);
    final nav = desktopItems(store);
    final theme = Theme.of(context);
    final index = _selectedIndex(store, nav);
    final name = store.currentDoctor?.fullName ?? store.currentPatient?.fullName ?? store.currentUser?.fullName ?? 'مستخدم';

    return Scaffold(
      body: Row(
        children: [
          // الشريط قابل للتمرير حتى لا يفيض عند النوافذ القصيرة.
          LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: NavigationRail(
                    extended: !collapsed,
                    minExtendedWidth: 220,
                    selectedIndex: index,
                    onDestinationSelected: (value) => store.goTo(nav[value].page),
                    leading: Padding(
                      padding: const EdgeInsets.fromLTRB(12, 16, 12, 12),
                      child: Column(
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const BrandLogo(size: 40),
                              if (!collapsed) ...[
                                const SizedBox(width: 10),
                                Flexible(
                                  child: Text(
                                    store.branding.appName,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontWeight: FontWeight.w800, height: 1.2),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 8),
                          IconButton(
                            tooltip: collapsed ? 'توسيع' : 'طي',
                            onPressed: () => setState(() => collapsed = !collapsed),
                            icon: Icon(collapsed ? Icons.chevron_left : Icons.chevron_right),
                          ),
                        ],
                      ),
                    ),
                    destinations: [
                      for (final item in nav)
                        NavigationRailDestination(
                          icon: Badge(
                            isLabelVisible: item.badge && store.unreadCount > 0,
                            label: Text('${store.unreadCount}'),
                            child: Icon(item.icon, size: 24, color: ClinicColors.muted),
                          ),
                          selectedIcon: Badge(
                            isLabelVisible: item.badge && store.unreadCount > 0,
                            label: Text('${store.unreadCount}'),
                            child: Icon(item.icon, size: 25, color: ClinicColors.primary),
                          ),
                          label: Text(item.label),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const VerticalDivider(width: 1),
          Expanded(
            child: Column(
              children: [
                Material(
                  color: theme.appBarTheme.backgroundColor,
                  child: SizedBox(
                    height: 64,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          if (store.canGoBack) ...[
                            IconButton(
                              tooltip: 'رجوع',
                              onPressed: store.back,
                              icon: const Icon(Icons.arrow_forward_ios, size: 18),
                            ),
                            const SizedBox(width: 4),
                          ],
                          StatusChip(label: roleAr(store.role), color: ClinicColors.primary),
                          if (store.doctorLocked) ...[
                            const SizedBox(width: 8),
                            StatusChip(
                              label: store.doctorPending ? 'بانتظار الموافقة' : 'اشتراك غير نشط',
                              color: Colors.orange.shade800,
                            ),
                          ],
                          const Spacer(),
                          IconButton(
                            tooltip: store.darkMode ? 'وضع نهاري' : 'وضع ليلي',
                            onPressed: store.toggleDark,
                            icon: Icon(store.darkMode ? Icons.light_mode_outlined : Icons.dark_mode_outlined),
                          ),
                          const SizedBox(width: 8),
                          PopupMenuButton<String>(
                            tooltip: name,
                            onSelected: (value) {
                              if (value == 'profile') store.goTo(ClinicPage.profile);
                              if (value == 'settings') store.goTo(ClinicPage.settings);
                              if (value == 'logout') store.logout();
                            },
                            itemBuilder: (context) => [
                              PopupMenuItem(enabled: false, child: Text(roleAr(store.role))),
                              const PopupMenuItem(value: 'profile', child: Text('الملف الشخصي')),
                              const PopupMenuItem(value: 'settings', child: Text('الإعدادات')),
                              const PopupMenuItem(value: 'logout', child: Text('تسجيل الخروج')),
                            ],
                            child: Row(
                              children: [
                                AvatarCircle(name: name),
                                const SizedBox(width: 8),
                                Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
                                const Icon(Icons.expand_more, size: 18),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const Divider(height: 1),
                Expanded(child: pageOf(store)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
