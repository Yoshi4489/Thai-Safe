import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:thai_safe/features/setting/services/user_safety_repository.dart';

class SafetyPrivacyPage extends StatefulWidget {
  const SafetyPrivacyPage({super.key});

  @override
  State<SafetyPrivacyPage> createState() => _SafetyPrivacyPageState();
}

class _SafetyPrivacyPageState extends State<SafetyPrivacyPage> {
  final _repository = UserSafetyRepository();
  final _contactName = TextEditingController();
  final _contactPhone = TextEditingController();
  final _contacts = <Map<String, String>>[];
  bool _notifications = true;
  double _radiusKm = 10;
  bool _loading = true;
  String? _message;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _contactName.dispose();
    _contactPhone.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final data = await _repository.load();
      final preferences = Map<String, dynamic>.from(
        data['notification_preferences'] as Map? ?? const {},
      );
      final contacts = (data['trusted_contacts'] as List? ?? const [])
          .whereType<Map>()
          .map(
            (value) => Map<String, String>.fromEntries(
              value.entries.map(
                (entry) =>
                    MapEntry(entry.key.toString(), entry.value.toString()),
              ),
            ),
          );
      if (!mounted) return;
      setState(() {
        _notifications = preferences['enabled'] != false;
        _radiusKm = (preferences['radius_km'] as num?)?.toDouble() ?? 10;
        _contacts
          ..clear()
          ..addAll(contacts);
        _loading = false;
      });
    } catch (error) {
      if (mounted) {
        setState(() {
          _loading = false;
          _message = error.toString();
        });
      }
    }
  }

  Future<void> _savePreferences() async {
    await _repository.saveNotificationPreferences(
      enabled: _notifications,
      radiusKm: _radiusKm,
      quietStart: '22:00',
      quietEnd: '07:00',
      categories: const [
        'fire',
        'flood',
        'collapse',
        'chemical',
        'violence',
        'medical',
        'other',
      ],
    );
    if (mounted) setState(() => _message = 'Notification preferences saved.');
  }

  Future<void> _addContact() async {
    if (_contactName.text.trim().isEmpty ||
        _contactPhone.text.trim().isEmpty ||
        _contacts.length >= 5) {
      return;
    }
    setState(() {
      _contacts.add({
        'name': _contactName.text.trim(),
        'phone': _contactPhone.text.trim(),
      });
      _contactName.clear();
      _contactPhone.clear();
    });
    await _repository.saveTrustedContacts(_contacts);
  }

  Future<void> _export() async {
    final data = await _repository.exportMyData();
    await Clipboard.setData(
      ClipboardData(text: const JsonEncoder.withIndent('  ').convert(data)),
    );
    if (mounted) {
      setState(() => _message = 'Your data export was copied to clipboard.');
    }
  }

  Future<void> _deleteAccount() async {
    final confirmation = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete account?'),
        content: const Text(
          'Your profile will be deleted and reports anonymized. This cannot '
          'be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmation == true) await _repository.deleteMyAccount();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Safety and privacy')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text('Notifications', style: Theme.of(context).textTheme.titleLarge),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Nearby incident notifications'),
            subtitle: const Text('Quiet hours: 22:00–07:00'),
            value: _notifications,
            onChanged: (value) => setState(() => _notifications = value),
          ),
          Text('Alert radius: ${_radiusKm.round()} km'),
          Slider(
            min: 1,
            max: 50,
            divisions: 49,
            value: _radiusKm,
            label: '${_radiusKm.round()} km',
            onChanged: (value) => setState(() => _radiusKm = value),
          ),
          FilledButton(
            onPressed: _savePreferences,
            child: const Text('Save preferences'),
          ),
          const Divider(height: 40),
          Text(
            'Trusted contacts',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const Text(
            'Up to five contacts can be stored for optional safety check-ins.',
          ),
          ..._contacts.map(
            (contact) => ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.contact_phone),
              title: Text(contact['name'] ?? ''),
              subtitle: Text(contact['phone'] ?? ''),
            ),
          ),
          TextField(
            controller: _contactName,
            decoration: const InputDecoration(labelText: 'Contact name'),
          ),
          TextField(
            controller: _contactPhone,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(labelText: 'Phone number'),
          ),
          TextButton.icon(
            onPressed: _contacts.length >= 5 ? null : _addContact,
            icon: const Icon(Icons.add),
            label: const Text('Add trusted contact'),
          ),
          const Divider(height: 40),
          Text('Your data', style: Theme.of(context).textTheme.titleLarge),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.download),
            title: const Text('Export my data'),
            onTap: _export,
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.delete_forever, color: Colors.red),
            title: const Text(
              'Delete account',
              style: TextStyle(color: Colors.red),
            ),
            onTap: _deleteAccount,
          ),
          if (_message != null)
            Text(_message!, style: const TextStyle(color: Colors.blue)),
        ],
      ),
    );
  }
}
