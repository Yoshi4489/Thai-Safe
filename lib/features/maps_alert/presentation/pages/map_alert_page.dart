import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geohash_plus/geohash_plus.dart' hide LatLng;
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:thai_safe/core/maps/open_street_map.dart';
import 'package:thai_safe/features/authentication/providers/auth_state_provider.dart';
import 'package:thai_safe/features/incidents/controllers/incident_controller.dart';
import 'package:thai_safe/features/incidents/presentation/pages/report_incident_page.dart';

import '../widgets/incident_bottom_sheet.dart';
import '../widgets/profile_status_badge.dart';

class MapAlertPage extends ConsumerStatefulWidget {
  const MapAlertPage({super.key});

  @override
  ConsumerState<MapAlertPage> createState() => _MapAlertPageState();
}

class _MapAlertPageState extends ConsumerState<MapAlertPage> {
  final MapController _mapController = MapController();
  Position? _currentPosition;
  StreamSubscription<Position>? _positionStream;
  bool _isLoadingLocation = true;
  bool _isMapReady = false;

  @override
  void initState() {
    super.initState();
    _initLocationTracking();
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    _mapController.dispose();
    super.dispose();
  }

  void _moveCameraToUser(Position position) {
    if (!_isMapReady) return;
    _mapController.move(LatLng(position.latitude, position.longitude), 15);
  }

  Future<void> _initLocationTracking() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) {
        setState(() => _isLoadingLocation = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('กรุณาเปิด GPS บนอุปกรณ์ของคุณ')),
        );
      }
      return;
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (mounted) setState(() => _isLoadingLocation = false);
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (mounted) {
        setState(() => _isLoadingLocation = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('สิทธิ์ถูกปฏิเสธถาวร กรุณาอนุญาตในตั้งค่าของแอป'),
          ),
        );
      }
      return;
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      if (!mounted) return;

      setState(() {
        _currentPosition = position;
        _isLoadingLocation = false;
      });
      _moveCameraToUser(position);
    } catch (error) {
      if (mounted) setState(() => _isLoadingLocation = false);
      debugPrint('Error getting location: $error');
    }
  }

  Future<void> _goToCurrentLocation() async {
    if (_currentPosition != null) {
      _moveCameraToUser(_currentPosition!);
      return;
    }

    _initLocationTracking();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กำลังค้นหาตำแหน่ง GPS ของคุณ...')),
      );
    }
  }

  Map<String, dynamic> _calculateAreaStatus(List<dynamic> incidents) {
    var userStatus = 1;
    var alertRadius = 2000.0;

    if (_currentPosition != null && incidents.isNotEmpty) {
      final userGeohash = GeoHash.encode(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
      ).hash;

      for (final incident in incidents) {
        final incidentGeohash = GeoHash.encode(
          incident.latitude,
          incident.longitude,
        ).hash;
        if (userGeohash.substring(0, 5) == incidentGeohash.substring(0, 5)) {
          userStatus = 3;
          alertRadius = 4000;
          break;
        } else if (userGeohash.substring(0, 4) ==
            incidentGeohash.substring(0, 4)) {
          if (userStatus < 2) {
            userStatus = 2;
            alertRadius = 15000;
          }
        }
      }
    }

    return {
      'text': userStatus == 3
          ? 'ประสบภัย (ใกล้ตัวมาก)'
          : userStatus == 2
          ? 'เสี่ยงภัย (เฝ้าระวัง)'
          : 'ปกติ (ปลอดภัย)',
      'color': userStatus == 3
          ? Colors.red
          : userStatus == 2
          ? Colors.orange
          : Colors.green,
      'radius': alertRadius,
    };
  }

  Color _markerColor(dynamic incident) {
    if (incident.type == 'flood') return Colors.blueAccent;
    if (incident.urgency == 'ถึงแก่ชีวิต') return Colors.red;
    return Colors.orange;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final incidentState = ref.watch(incidentControllerProvider);
    final incidents = incidentState.incidents;
    final authState = ref.watch(authControllerProvider);
    final currentUser = authState.user;

    var displayFullName = 'ไม่ระบุชื่อ';
    if (currentUser != null) {
      final firstName = currentUser.firstName;
      final lastName = currentUser.lastName;
      if (firstName.isNotEmpty || lastName.isNotEmpty) {
        displayFullName = '$firstName $lastName'.trim();
      }
    }
    final displayPhone =
        currentUser?.tel ?? authState.phoneNumber ?? 'ไม่มีเบอร์โทรศัพท์';
    final areaStatus = _calculateAreaStatus(incidents);

    final incidentMarkers = incidents.map<Marker>((incident) {
      final markerColor = _markerColor(incident);
      return Marker(
        point: LatLng(incident.latitude, incident.longitude),
        width: 48,
        height: 48,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => IncidentBottomSheet.show(context, incident, currentUser),
          child: Icon(
            Icons.location_pin,
            color: markerColor,
            size: 48,
            shadows: const [
              Shadow(
                color: Colors.black38,
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
        ),
      );
    }).toList();

    if (_currentPosition != null) {
      incidentMarkers.add(
        Marker(
          point: LatLng(
            _currentPosition!.latitude,
            _currentPosition!.longitude,
          ),
          width: 26,
          height: 26,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.blueAccent,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: const [
                BoxShadow(color: Colors.black26, blurRadius: 5),
              ],
            ),
          ),
        ),
      );
    }

    final alertCircles = <CircleMarker>[
      if (_currentPosition != null)
        CircleMarker(
          point: LatLng(
            _currentPosition!.latitude,
            _currentPosition!.longitude,
          ),
          radius: areaStatus['radius'] as double,
          useRadiusInMeter: true,
          color: (areaStatus['color'] as Color).withValues(alpha: 0.15),
          borderColor: areaStatus['color'] as Color,
          borderStrokeWidth: 2,
        ),
    ];

    final initialCenter = _currentPosition != null
        ? LatLng(_currentPosition!.latitude, _currentPosition!.longitude)
        : const LatLng(13.7649, 100.5383);

    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: initialCenter,
              initialZoom: 14.4746,
              minZoom: 3,
              maxZoom: 19,
              onMapReady: () {
                _isMapReady = true;
                if (_currentPosition != null) {
                  _moveCameraToUser(_currentPosition!);
                }
              },
            ),
            children: [
              const OpenStreetMapTileLayer(),
              CircleLayer(circles: alertCircles),
              MarkerLayer(markers: incidentMarkers),
              const OpenStreetMapAttribution(),
            ],
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: IgnorePointer(
              child: Container(
                height: 150,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.white.withValues(alpha: 0.9),
                      Colors.white.withValues(alpha: 0),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: 50,
            right: 16,
            child: ProfileStatusBadge(
              displayFullName: displayFullName,
              displayPhone: displayPhone,
              statusText: areaStatus['text'],
              statusColor: areaStatus['color'],
            ),
          ),
          Positioned(
            bottom: 30,
            left: 20,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: FloatingActionButton.extended(
                heroTag: 'report_btn',
                onPressed: () {
                  final currentPosition = _currentPosition != null
                      ? LatLng(
                          _currentPosition!.latitude,
                          _currentPosition!.longitude,
                        )
                      : const LatLng(13.7649, 100.5383);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          ReportIncidentPage(currentLocation: currentPosition),
                    ),
                  );
                },
                backgroundColor: Colors.redAccent,
                elevation: 4,
                icon: const Icon(Icons.campaign, color: Colors.white),
                label: Text(
                  'แจ้งเหตุด่วน',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 110,
            right: 12,
            child: FloatingActionButton(
              mini: true,
              heroTag: 'gps_btn',
              onPressed: _goToCurrentLocation,
              backgroundColor: Colors.white,
              child: Icon(Icons.my_location, color: theme.colorScheme.primary),
            ),
          ),
          if (_isLoadingLocation ||
              incidentState.isLoading ||
              authState.isLoading)
            const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }
}
