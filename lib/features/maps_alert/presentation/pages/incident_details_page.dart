import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:thai_safe/core/maps/open_street_map.dart';
import 'package:thai_safe/core/services/safety_functions_repository.dart';
import 'package:thai_safe/features/authentication/providers/auth_state_provider.dart';
import 'package:thai_safe/features/incidents/data/incident_model.dart';
import 'package:url_launcher/url_launcher.dart';

class IncidentDetailsPage extends ConsumerStatefulWidget {
  const IncidentDetailsPage({super.key, required this.incident});

  final IncidentModel incident;

  @override
  ConsumerState<IncidentDetailsPage> createState() =>
      _IncidentDetailsPageState();
}

class _IncidentDetailsPageState extends ConsumerState<IncidentDetailsPage> {
  final _repository = SafetyFunctionsRepository();
  final _noteController = TextEditingController();
  Map<String, dynamic>? _privateData;
  Map<String, dynamic>? _medicalSummary;
  late String _status;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _status = widget.incident.status;
    WidgetsBinding.instance.addPostFrameCallback((_) => _tryLoadPrivate());
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  bool get _isResponder {
    final role = ref.read(authControllerProvider).user?.role;
    return role == 'responder' || role == 'admin';
  }

  Future<void> _tryLoadPrivate() async {
    if (!_isResponder || _status == 'pending') return;
    try {
      final value = await _repository.getAssignedPrivate(widget.incident.id);
      if (mounted) setState(() => _privateData = value);
    } catch (_) {
      // Not every verified responder is assigned to this incident.
    }
  }

  Future<void> _accept() async {
    await _run(() async {
      await _repository.acceptIncident(widget.incident.id);
      _status = 'assigned';
      await _tryLoadPrivate();
    });
  }

  Future<void> _transition(String status) async {
    await _run(() async {
      await _repository.transitionStatus(
        incidentId: widget.incident.id,
        status: status,
        note: _noteController.text.trim(),
      );
      _status = status;
      _noteController.clear();
      if (status == 'resolved' || status == 'cancelled') {
        _privateData = null;
        _medicalSummary = null;
      }
    });
  }

  Future<void> _loadMedicalSummary() async {
    await _run(() async {
      _medicalSummary = await _repository.getMedicalSummary(widget.incident.id);
    });
  }

  Future<void> _run(Future<void> Function() operation) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await operation();
    } catch (error) {
      _error = error.toString();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  LatLng get _displayLocation {
    final exact = _privateData?['exactPosition'];
    if (exact is GeoPoint) return LatLng(exact.latitude, exact.longitude);
    return LatLng(widget.incident.latitude, widget.incident.longitude);
  }

  Future<void> _navigate() async {
    final location = _displayLocation;
    await launchUrl(
      Uri.parse(
        'https://www.openstreetmap.org/directions?'
        'engine=fossgis_osrm_car&route=;'
        '${location.latitude},${location.longitude}',
      ),
      mode: LaunchMode.externalApplication,
    );
  }

  Future<void> _callReporter() async {
    final phone = _privateData?['reporterPhone']?.toString();
    if (phone == null || phone.isEmpty) return;
    await launchUrl(Uri(scheme: 'tel', path: phone));
  }

  List<String> get _nextStatuses => switch (_status) {
    'assigned' => const ['in_progress', 'cancelled'],
    'in_progress' => const ['resolved', 'cancelled'],
    _ => const [],
  };

  @override
  Widget build(BuildContext context) {
    final incident = widget.incident;
    final location = _displayLocation;
    return Scaffold(
      appBar: AppBar(title: const Text('Incident details')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              Chip(label: Text(_status.replaceAll('_', ' '))),
              Chip(label: Text(incident.type)),
              Chip(label: Text(incident.urgency)),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            incident.title,
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            incident.details['summary']?.toString() ??
                'No public summary was added.',
          ),
          const SizedBox(height: 20),
          Card(
            color: _privateData == null
                ? Colors.blueGrey.shade50
                : Colors.green.shade50,
            child: ListTile(
              leading: Icon(
                _privateData == null
                    ? Icons.location_city
                    : Icons.verified_user,
              ),
              title: Text(
                _privateData == null
                    ? 'Approximate public location'
                    : 'Assignment-scoped exact location',
              ),
              subtitle: Text(
                _privateData == null
                    ? 'Exact coordinates are released only to the actively '
                          'assigned verified responder.'
                    : 'Access is audited and is revoked when this incident '
                          'closes.',
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 220,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: FlutterMap(
                options: MapOptions(
                  initialCenter: location,
                  initialZoom: _privateData == null ? 13 : 16,
                ),
                children: [
                  const OpenStreetMapTileLayer(),
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: location,
                        width: 48,
                        height: 48,
                        child: Icon(
                          _privateData == null
                              ? Icons.location_city
                              : Icons.location_pin,
                          color: _privateData == null
                              ? Colors.orange
                              : Colors.red,
                          size: 42,
                        ),
                      ),
                    ],
                  ),
                  const OpenStreetMapAttribution(),
                ],
              ),
            ),
          ),
          if (_privateData != null) ...[
            const SizedBox(height: 20),
            Text(
              'Private operational details',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text('Reporter: ${_privateData?['reporterName'] ?? 'Unknown'}'),
            Text('GPS accuracy: ${_privateData?['accuracyM'] ?? 'Unknown'} m'),
            Text(_privateData?['details']?.toString() ?? 'No private details.'),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: [
                FilledButton.icon(
                  onPressed: _callReporter,
                  icon: const Icon(Icons.call),
                  label: const Text('Contact reporter'),
                ),
                OutlinedButton.icon(
                  onPressed: _navigate,
                  icon: const Icon(Icons.navigation),
                  label: const Text('Navigate'),
                ),
                OutlinedButton.icon(
                  onPressed: _loadMedicalSummary,
                  icon: const Icon(Icons.medical_information),
                  label: const Text('Medical summary'),
                ),
              ],
            ),
          ],
          if (_medicalSummary != null) ...[
            const SizedBox(height: 16),
            Card(
              color: Colors.red.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Consent-based emergency medical summary\n'
                  '${_medicalSummary.toString()}',
                ),
              ),
            ),
          ],
          if (_isResponder && _status == 'pending') ...[
            const SizedBox(height: 24),
            SizedBox(
              height: 54,
              child: FilledButton.icon(
                onPressed: _busy ? null : _accept,
                icon: const Icon(Icons.assignment_turned_in),
                label: const Text('Accept as lead responder'),
              ),
            ),
          ],
          if (_isResponder && _nextStatuses.isNotEmpty) ...[
            const SizedBox(height: 24),
            TextField(
              controller: _noteController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Operational note (optional)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: _nextStatuses
                  .map(
                    (status) => FilledButton(
                      onPressed: _busy ? null : () => _transition(status),
                      child: Text(status.replaceAll('_', ' ')),
                    ),
                  )
                  .toList(),
            ),
          ],
          if (_error != null) ...[
            const SizedBox(height: 16),
            Text(_error!, style: const TextStyle(color: Colors.red)),
          ],
          if (_busy) ...[
            const SizedBox(height: 16),
            const LinearProgressIndicator(),
          ],
        ],
      ),
    );
  }
}
