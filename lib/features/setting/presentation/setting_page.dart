import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thai_safe/core/config/remote_config_service.dart';
import 'package:thai_safe/features/authentication/providers/auth_state_provider.dart';
import 'package:thai_safe/features/rescue_approval/presentation/responder_application_page.dart';
import 'package:thai_safe/features/setting/presentation/pages/edit_profile_page.dart';
import 'package:thai_safe/features/setting/presentation/pages/safety_privacy_page.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  Future<void> _logout(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Log out'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Log out'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref.read(authControllerProvider.notifier).logout();
    if (context.mounted) {
      Navigator.pushNamedAndRemoveUntil(context, '/', (_) => false);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).user;
    final emergency = RemoteConfigService.instance.emergencyDirectory;
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          const _SectionTitle('Profile and safety'),
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('Edit profile and medical information'),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute<void>(builder: (_) => const EditProfilePage()),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.privacy_tip),
            title: const Text('Safety, notifications, and privacy'),
            subtitle: const Text(
              'Quiet hours, alert radius, trusted contacts, export, deletion',
            ),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (_) => const SafetyPrivacyPage(),
              ),
            ),
          ),
          if (user?.role == 'user')
            ListTile(
              leading: const Icon(Icons.volunteer_activism),
              title: const Text('Apply as a volunteer responder'),
              subtitle: const Text('Identity evidence and admin verification'),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => const ResponderApplicationPage(),
                ),
              ),
            ),
          const Divider(),
          const _SectionTitle('Emergency call fallback'),
          ...emergency.map(
            (entry) => ListTile(
              leading: const Icon(Icons.call, color: Colors.red),
              title: Text(entry.label),
              trailing: Text(entry.number),
              onTap: () => launchUrl(Uri(scheme: 'tel', path: entry.number)),
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              'Thai Safe does not guarantee official emergency-service '
              'dispatch. Use the call options above when danger is immediate.',
              style: TextStyle(color: Colors.black54),
            ),
          ),
          const Divider(),
          const _SectionTitle('Account'),
          ListTile(
            leading: const Icon(Icons.refresh),
            title: const Text('Refresh responder/admin access'),
            subtitle: const Text(
              'Use after an administrator changes your role',
            ),
            onTap: () async {
              await ref
                  .read(authControllerProvider.notifier)
                  .refreshRoleClaims();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Access refreshed.')),
                );
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Log out'),
            onTap: () => _logout(context, ref),
          ),
          const SizedBox(height: 24),
          const Center(
            child: Text(
              'Thai Safe v1.1.0 safety foundation',
              style: TextStyle(color: Colors.grey),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 8),
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.bold)),
    );
  }
}
