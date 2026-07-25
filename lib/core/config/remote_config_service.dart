import 'dart:convert';

import 'package:firebase_remote_config/firebase_remote_config.dart';

class EmergencyDirectoryEntry {
  const EmergencyDirectoryEntry({required this.label, required this.number});

  final String label;
  final String number;
}

class RemoteConfigService {
  RemoteConfigService._();

  static final instance = RemoteConfigService._();

  final FirebaseRemoteConfig _config = FirebaseRemoteConfig.instance;

  Future<void> initialize() async {
    await _config.setDefaults({
      'sos_enabled': true,
      'incident_enrichment_enabled': true,
      'responder_operations_enabled': true,
      'minimum_android_build': 1,
      'map_tile_url': 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
      'map_attribution': '© OpenStreetMap contributors',
      'emergency_directory':
          '[{"label":"Emergency Medical Services","number":"1669"},'
          '{"label":"Police Emergency","number":"191"},'
          '{"label":"Fire and Rescue","number":"199"}]',
    });
    await _config.setConfigSettings(
      RemoteConfigSettings(
        fetchTimeout: const Duration(seconds: 8),
        minimumFetchInterval: const Duration(hours: 1),
      ),
    );
    try {
      await _config.fetchAndActivate();
    } catch (_) {
      // Safe local defaults remain active when Remote Config is unavailable.
    }
  }

  bool get sosEnabled => _config.getBool('sos_enabled');
  bool get enrichmentEnabled => _config.getBool('incident_enrichment_enabled');
  bool get responderOperationsEnabled =>
      _config.getBool('responder_operations_enabled');
  int get minimumAndroidBuild => _config.getInt('minimum_android_build');
  String get mapTileUrl => _config.getString('map_tile_url');
  String get mapAttribution => _config.getString('map_attribution');

  List<EmergencyDirectoryEntry> get emergencyDirectory {
    try {
      final values = jsonDecode(_config.getString('emergency_directory'));
      return (values as List<dynamic>)
          .whereType<Map<String, dynamic>>()
          .map(
            (entry) => EmergencyDirectoryEntry(
              label: entry['label']?.toString() ?? 'Emergency',
              number: entry['number']?.toString() ?? '1669',
            ),
          )
          .toList(growable: false);
    } catch (_) {
      return const [
        EmergencyDirectoryEntry(
          label: 'Emergency Medical Services',
          number: '1669',
        ),
      ];
    }
  }
}
