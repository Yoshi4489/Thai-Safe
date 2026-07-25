import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thai_safe/features/admin/presentation/admin_page.dart';
import 'package:thai_safe/features/authentication/providers/auth_state_provider.dart';
import 'package:thai_safe/features/home/presentation/home_page.dart';
import 'package:thai_safe/features/incident_management/presentation/incident_management_page.dart';
import 'package:thai_safe/features/maps_alert/presentation/pages/map_alert_page.dart';
import 'package:thai_safe/features/profile/presentation/profile_page.dart';
import 'package:thai_safe/features/rescue_approval/presentation/rescue_approval_page.dart';
import 'package:thai_safe/features/responder/presentation/assigned_incidents_page.dart';
import 'package:thai_safe/features/setting/presentation/setting_page.dart';

class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final role = authState.user?.role;
    if (role == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final List<Widget> pages;
    final List<BottomNavigationBarItem> items;
    if (role == 'admin') {
      pages = [
        AdminHomePage(
          onNavigate: (index) => setState(() => _selectedIndex = index),
        ),
        const IncidentManagementPage(),
        const RescueApprovalPage(),
        const SettingsPage(),
      ];
      items = const [
        BottomNavigationBarItem(
          icon: Icon(Icons.dashboard),
          label: 'Dashboard',
        ),
        BottomNavigationBarItem(icon: Icon(Icons.warning), label: 'Incidents'),
        BottomNavigationBarItem(
          icon: Icon(Icons.verified_user),
          label: 'Approvals',
        ),
        BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
      ];
    } else if (role == 'responder') {
      pages = const [
        HomePage(),
        AssignedIncidentsPage(),
        MapAlertPage(),
        ProfilePage(),
        SettingsPage(),
      ];
      items = const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
        BottomNavigationBarItem(
          icon: Icon(Icons.assignment),
          label: 'Assigned',
        ),
        BottomNavigationBarItem(icon: Icon(Icons.map), label: 'Map'),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
      ];
    } else {
      pages = const [HomePage(), MapAlertPage(), ProfilePage(), SettingsPage()];
      items = const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
        BottomNavigationBarItem(icon: Icon(Icons.map), label: 'Map'),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
      ];
    }

    final selected = _selectedIndex < pages.length ? _selectedIndex : 0;
    return Scaffold(
      body: IndexedStack(index: selected, children: pages),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: selected,
        onTap: (index) => setState(() => _selectedIndex = index),
        type: BottomNavigationBarType.fixed,
        items: items,
      ),
    );
  }
}
