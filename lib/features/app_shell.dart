import 'package:flutter/material.dart';
import 'package:thai_safe/features/admin/presentation/admin_page.dart';
import 'package:thai_safe/features/incident_management/presentation/incident_management_page.dart';
import 'package:thai_safe/features/rescue_approval/presentation/rescue_approval_page.dart';
import 'package:thai_safe/features/home/presentation/home_page.dart';
import 'package:thai_safe/features/maps_alert/presentation/pages/map_alert_page.dart';
import 'package:thai_safe/features/profile/presentation/profile_page.dart';
import 'package:thai_safe/features/setting/presentation/setting_page.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thai_safe/features/authentication/providers/auth_state_provider.dart';

class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {

    final authState = ref.watch(authControllerProvider);
    final role = authState.user?.role.toLowerCase();

    final userItems = [
      {
        'icon': const Icon(Icons.home),
        'label': "Home",
      },
      {
        'icon': const Icon(Icons.location_on_outlined),
        'label': "Map",
      },
      {
        'icon': const Icon(Icons.person),
        'label': "Profile",
      },
      {
        'icon': const Icon(Icons.settings),
        'label': "Settings",
      }
    ];

    final userPages = [
      const HomePage(),
      const MapAlertPage(),
      const ProfilePage(),
      const SettingPage(),
    ];

    final adminItems = [
      {
        'icon': const Icon(Icons.dashboard),
        'label': "Dashboard",
      },
      {
        'icon': const Icon(Icons.warning),
        'label': "Incidents",
      },
      {
        'icon': const Icon(Icons.verified_user),
        'label': "Approvals",
      },
      {
        'icon': const Icon(Icons.settings),
        'label': "Settings",
      }
    ];

    final adminPages = [
      AdminHomePage(onNavigate: _onItemTapped,),
      const IncidentManagementPage(),
      const RescueApprovalPage(),
      const SettingPage(),
    ];

    final items = role == "admin" ? adminItems : userItems;
    final pages = role == "admin" ? adminPages : userPages;

    if (authState.isLoading || role == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        items: items.map<BottomNavigationBarItem>((item) {
          return BottomNavigationBarItem(
            icon: item['icon'] as Widget,
            label: item['label'] as String,
          );
        }).toList(),
      ),
    );
  }
}
