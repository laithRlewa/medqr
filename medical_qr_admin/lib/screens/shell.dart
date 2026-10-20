import 'package:flutter/material.dart';

import '../models/models.dart';
import '../state/admin_store.dart';
import '../widgets/brand_logo.dart';
import 'activations_screen.dart';
import 'analytics_screen.dart';
import 'appearance_screen.dart';
import 'audit_screen.dart';
import 'dashboard_screen.dart';
import 'doctors_map_screen.dart';
import 'doctors_screen.dart';
import 'notifications_screen.dart';
import 'patients_screen.dart';
import 'posts_screen.dart';
import 'profile_screen.dart';
import 'settings_screen.dart';
import 'users_screen.dart';

class _NavItem {
  const _NavItem(this.page, this.icon, this.label);
  final AdminPage page;
  final IconData icon;
  final String label;
}

class AdminShell extends StatefulWidget {
  const AdminShell({super.key});

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  bool collapsed = false;

  List<_NavItem> items(AdminStore store) => [
        const _NavItem(AdminPage.dashboard, Icons.space_dashboard_outlined, 'لوحة التحكم'),
        const _NavItem(AdminPage.doctors, Icons.medical_services_outlined, 'الأطباء'),
        const _NavItem(AdminPage.doctorsMap, Icons.map_outlined, 'خريطة الأطباء'),
        const _NavItem(AdminPage.activations, Icons.credit_card_outlined, 'تفعيل الاشتراكات'),
        const _NavItem(AdminPage.patients, Icons.groups_outlined, 'المرضى'),
        const _NavItem(AdminPage.posts, Icons.article_outlined, 'المنشورات'),
        const _NavItem(AdminPage.users, Icons.manage_accounts_outlined, 'إدارة المستخدمين'),
        const _NavItem(AdminPage.appearance, Icons.palette_outlined, 'المظهر'),
        const _NavItem(AdminPage.audit, Icons.fact_check_outlined, 'سجلات التدقيق'),
        const _NavItem(AdminPage.analytics, Icons.bar_chart_outlined, 'التحليلات'),
        const _NavItem(AdminPage.settings, Icons.settings_outlined, 'الإعدادات'),
        const _NavItem(AdminPage.notifications, Icons.notifications_outlined, 'الإشعارات'),
      ];

  Widget _page(AdminPage page) => switch (page) {
        AdminPage.dashboard => const DashboardScreen(),
        AdminPage.doctors => const DoctorsScreen(),
        AdminPage.doctorsMap => const DoctorsMapScreen(),
        AdminPage.activations => const ActivationsScreen(),
        AdminPage.patients => const PatientsScreen(),
        AdminPage.posts => const PostsScreen(),
        AdminPage.users => const UsersScreen(),
        AdminPage.appearance => const AppearanceScreen(),
        AdminPage.audit => const AuditScreen(),
        AdminPage.analytics => const AnalyticsScreen(),
        AdminPage.settings => const SettingsScreen(),
        AdminPage.notifications => const NotificationsScreen(),
      };

  @override
  Widget build(BuildContext context) {
    final store = AdminScope.of(context);
    if (!store.isAdmin) {
      return const Scaffold(body: Center(child: Text('غير مصرح. هذه اللوحة للمديرين فقط.')));
    }
    final nav = items(store);
    final theme = Theme.of(context);
    final index = nav.indexWhere((e) => e.page == store.page);

    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            extended: !collapsed,
            minExtendedWidth: 240,
            selectedIndex: index < 0 ? 0 : index,
            onDestinationSelected: (value) => store.goTo(nav[value].page),
            leading: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
              child: Column(
                children: [
                  IconButton(
                    onPressed: () => setState(() => collapsed = !collapsed),
                    icon: Icon(collapsed ? Icons.menu : Icons.menu_open),
                  ),
                  if (!collapsed) ...[
                    if (store.branding.appLogo.isNotEmpty)
                      Image.network(store.branding.appLogo, width: 48, height: 48, errorBuilder: (_, _, _) => const BrandLogo(size: 48))
                    else
                      const BrandLogo(size: 48),
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(store.branding.appName, textAlign: TextAlign.center, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
                    ),
                  ],
                ],
              ),
            ),
            destinations: [
              for (final item in nav)
                NavigationRailDestination(
                  icon: item.page == AdminPage.notifications
                      ? Badge(isLabelVisible: store.unreadCount > 0, label: Text('${store.unreadCount}'), child: Icon(item.icon))
                      : Icon(item.icon),
                  label: Text(item.label),
                ),
            ],
          ),
          const VerticalDivider(width: 1),
          Expanded(
            child: Column(
              children: [
                Material(
                  color: theme.appBarTheme.backgroundColor,
                  child: Container(
                    height: 64,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    decoration: BoxDecoration(
                      border: Border(bottom: BorderSide(color: theme.dividerColor.withValues(alpha: 0.4))),
                    ),
                    child: Row(
                      children: [
                        const Chip(
                          avatar: Icon(Icons.shield_outlined, size: 16),
                          label: Text('لوحة الإدارة'),
                          visualDensity: VisualDensity.compact,
                        ),
                        const Spacer(),
                        IconButton(
                          onPressed: store.toggleDarkMode,
                          icon: Icon(store.darkMode ? Icons.light_mode : Icons.dark_mode_outlined),
                        ),
                        PopupMenuButton<String>(
                          onSelected: (value) {
                            if (value == 'profile') {
                              Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ProfileScreen()));
                            } else if (value == 'logout') {
                              store.logout();
                            }
                          },
                          itemBuilder: (_) => const [
                            PopupMenuItem(value: 'profile', child: Text('الملف الشخصي')),
                            PopupMenuItem(value: 'logout', child: Text('تسجيل الخروج')),
                          ],
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor: theme.colorScheme.primary,
                                  backgroundImage: store.currentUser!.profilePhoto.isEmpty ? null : NetworkImage(store.currentUser!.profilePhoto),
                                  child: store.currentUser!.profilePhoto.isEmpty
                                      ? Text(store.currentUser!.fullName.characters.first, style: const TextStyle(color: Colors.white))
                                      : null,
                                ),
                                const SizedBox(width: 8),
                                Text(store.currentUser!.fullName),
                                const Icon(Icons.expand_more),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(child: _page(store.page)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
