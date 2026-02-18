import 'package:flutter/material.dart';
import 'package:thai_safe/features/home/presentation/home_page.dart';
import 'package:thai_safe/features/maps_alert/presentation/pages/map_alert_page.dart';
import 'package:thai_safe/features/profile/presentation/profile_page.dart';
import 'package:thai_safe/features/setting/presentation/setting_page.dart';

class AppShell extends StatefulWidget {
  const AppShell({ super.key });

  _AppShellState createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _selectedIndex = 0;
  final Map<String, dynamic> items = {
    "home": {
      'icon': Icon(Icons.home),
      'label': "Home",
    },
    "map": {
      'icon': Icon(Icons.location_on_outlined),
      'label': "Map",
    },
    "profile": {
      'icon': Icon(Icons.person),
      'label': "Profile",
    },
    "setting": {
      'icon': Icon(Icons.settings),
      'label': "Settings",
    }
  };

   final List<Widget> _pages = [
    HomePage(),
    MapAlertPage(),
    ProfilePage(),
    SettingPage()
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        items: items.values.map<BottomNavigationBarItem>((item) {
          return BottomNavigationBarItem(
            icon: item['icon'],
            label: item['label']
          );
        }).toList(),
      ),
    );
  }
}
