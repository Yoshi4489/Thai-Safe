import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thai_safe/features/authentication/providers/auth_state_provider.dart';

class SettingPage extends ConsumerWidget {
  const SettingPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text("Settings"), centerTitle: true),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _sectionTitle("App"),
          _settingsTile(
            icon: Icons.notifications,
            title: "Notifications",
            onTap: () {
              // TODO
            },
          ),
          _settingsTile(
            icon: Icons.privacy_tip,
            title: "Privacy & Security",
            onTap: () {
              // TODO
            },
          ),

          const SizedBox(height: 24),

          _sectionTitle("Danger zone"),
          _logoutTile(context, ref),
        ],
      ),
    );
  }

  // ---------- UI helpers ----------

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.grey,
        ),
      ),
    );
  }

  Widget _settingsTile({
    required IconData icon,
    required String title,
    VoidCallback? onTap,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }

  Widget _logoutTile(BuildContext context, WidgetRef ref) {
    return Card(
      color: Colors.red.shade50,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(Icons.logout, color: Colors.red.shade700),
        title: Text("Log out", style: TextStyle(color: Colors.red.shade700)),
        onTap: () => _confirmLogout(context, ref),
      ),
    );
  }

  // ---------- Logic ----------

  Future<void> _confirmLogout(BuildContext context, WidgetRef ref) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Log out"),
        content: const Text("Are you sure you want to log out?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Log out", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await ref.read(authControllerProvider.notifier).logout();
      Navigator.pushNamedAndRemoveUntil(context, "/", (route) => false);
    }
  }
}
