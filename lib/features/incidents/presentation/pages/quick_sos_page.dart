import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:thai_safe/core/config/remote_config_service.dart';
import 'package:thai_safe/core/services/safety_functions_repository.dart';
import 'package:thai_safe/features/incidents/presentation/pages/report_incident_page.dart';
import 'package:thai_safe/features/incidents/services/incident_outbox_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:uuid/uuid.dart';

class QuickSosPage extends StatefulWidget {
  const QuickSosPage({super.key, this.fallbackLocation});

  final LatLng? fallbackLocation;

  @override
  State<QuickSosPage> createState() => _QuickSosPageState();
}

class _QuickSosPageState extends State<QuickSosPage> {
  final IncidentOutboxService _outboxService = IncidentOutboxService();
  final String _clientRequestId = const Uuid().v4();
  bool _isSending = false;
  bool _medicalConsent = false;
  bool _waitingToSend = false;
  String? _error;

  EmergencyDirectoryEntry get _emergency =>
      RemoteConfigService.instance.emergencyDirectory.first;

  Future<void> _callEmergency() async {
    await launchUrl(Uri(scheme: 'tel', path: _emergency.number));
  }

  Future<Position> _obtainLocation() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw StateError('Location services are disabled.');
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      throw StateError('Location permission is required to send an SOS.');
    }
    try {
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 12),
      );
    } catch (_) {
      final lastKnown = await Geolocator.getLastKnownPosition();
      if (lastKnown != null) return lastKnown;
      rethrow;
    }
  }

  Future<void> _send() async {
    if (_isSending || !RemoteConfigService.instance.sosEnabled) return;
    setState(() {
      _isSending = true;
      _error = null;
    });
    try {
      final lastKnown = await Geolocator.getLastKnownPosition();
      final position = await _obtainLocation();
      final request = QuickIncidentRequest(
        clientRequestId: _clientRequestId,
        latitude: position.latitude,
        longitude: position.longitude,
        accuracyM: position.accuracy,
        lastKnownLatitude:
            lastKnown?.latitude ?? widget.fallbackLocation?.latitude,
        lastKnownLongitude:
            lastKnown?.longitude ?? widget.fallbackLocation?.longitude,
        medicalSummaryConsent: _medicalConsent,
      );
      final result = await _outboxService.submitOrQueue(request);
      if (!mounted) return;
      if (result.state == QuickSubmissionState.queued) {
        setState(() {
          _waitingToSend = true;
          _isSending = false;
        });
        return;
      }
      await Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => ReportIncidentPage(
            incidentId: result.incidentId!,
            currentLocation: LatLng(position.latitude, position.longitude),
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString();
        _isSending = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final sosEnabled = RemoteConfigService.instance.sosEnabled;
    return Scaffold(
      appBar: AppBar(title: const Text('Quick SOS')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const Icon(Icons.sos_rounded, color: Colors.red, size: 88),
            const SizedBox(height: 16),
            Text(
              _waitingToSend ? 'Waiting to send' : 'Send emergency report?',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: _waitingToSend ? Colors.orange.shade900 : null,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _waitingToSend
                  ? 'This report is saved on this device but has NOT been '
                        'submitted. Thai Safe will retry when a connection is '
                        'available.'
                  : 'Thai Safe will immediately send your location and GPS '
                        'accuracy. You can add the incident type, details, and '
                        'photos after it is sent.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Card(
              color: Colors.amber.shade50,
              child: const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Thai Safe connects community members with verified '
                  'volunteer responders. It does not guarantee dispatch by '
                  'police, fire, ambulance, or another official emergency '
                  'service.',
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: _medicalConsent,
              onChanged: _waitingToSend
                  ? null
                  : (value) => setState(() => _medicalConsent = value ?? false),
              title: const Text(
                'Allow the assigned verified responder to request my '
                'emergency medical summary while this incident is active.',
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red),
              ),
            ],
            const SizedBox(height: 16),
            if (!_waitingToSend)
              Semantics(
                button: true,
                label: 'Confirm and send SOS report',
                child: SizedBox(
                  height: 72,
                  child: FilledButton.icon(
                    onPressed: sosEnabled && !_isSending ? _send : null,
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.red.shade700,
                    ),
                    icon: _isSending
                        ? const SizedBox.square(
                            dimension: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 3,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.send_rounded, size: 30),
                    label: Text(
                      sosEnabled
                          ? (_isSending ? 'Sending…' : 'CONFIRM SOS')
                          : 'SOS temporarily unavailable',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 14),
            SizedBox(
              height: 56,
              child: OutlinedButton.icon(
                onPressed: _callEmergency,
                icon: const Icon(Icons.call),
                label: Text('Call ${_emergency.label} (${_emergency.number})'),
              ),
            ),
            if (_waitingToSend) ...[
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Return to app — keep retrying'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
