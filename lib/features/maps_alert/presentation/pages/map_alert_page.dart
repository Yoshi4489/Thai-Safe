import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geohash_plus/geohash_plus.dart' hide LatLng;

// นำเข้า Widget และ Helpers 
import 'package:thai_safe/features/incidents/presentation/pages/report_incident_page.dart';
import '../widgets/profile_status_badge.dart';
import '../widgets/incident_bottom_sheet.dart';

// Import Controllers
import 'package:thai_safe/features/incidents/controllers/incident_controller.dart';
import 'package:thai_safe/features/authentication/providers/auth_state_provider.dart';

class MapAlertPage extends ConsumerStatefulWidget {
  const MapAlertPage({super.key});

  @override
  ConsumerState<MapAlertPage> createState() => _MapAlertPageState();
}

class _MapAlertPageState extends ConsumerState<MapAlertPage> {
  final Completer<GoogleMapController> _controller = Completer();
  Position? _currentPosition;
  StreamSubscription<Position>? _positionStream;
  bool _isLoadingLocation = true;

  @override
  void initState() {
    super.initState();
    _initLocationTracking();
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    super.dispose();
  }

  Future<void> _moveCameraToUser(Position position) async {
    final controller = await _controller.future;
    controller.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: LatLng(position.latitude, position.longitude), zoom: 15),
      ),
    );
  }

  Future<void> _initLocationTracking() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() => _isLoadingLocation = false);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('กรุณาเปิด GPS บนอุปกรณ์ของคุณ')));
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() => _isLoadingLocation = false);
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      setState(() => _isLoadingLocation = false);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('สิทธิ์ถูกปฏิเสธถาวร กรุณาอนุญาตในตั้งค่าของแอป')));
      return;
    }

    try {
      final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      if (!mounted) return;
      setState(() {
        _currentPosition = pos;
        _isLoadingLocation = false;
      });
      _moveCameraToUser(pos);
    } catch (e) {
      setState(() => _isLoadingLocation = false);
      debugPrint("Error getting location: $e");
    }
  }

  Future<void> _goToCurrentLocation() async {
    if (_currentPosition != null) {
      _moveCameraToUser(_currentPosition!);
    } else {
      _initLocationTracking();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('กำลังค้นหาตำแหน่ง GPS ของคุณ...')));
    }
  }

  // Logic แยกส่วนตัวช่วยคำนวณสถานะพื้นที่ (Geohash)
  Map<String, dynamic> _calculateAreaStatus(List<dynamic> incidents) {
    int userStatus = 1;
    double alertRadius = 2000;
    
    if (_currentPosition != null && incidents.isNotEmpty) {
      String userGeohash = GeoHash.encode(_currentPosition!.latitude, _currentPosition!.longitude).hash;

      for (var incident in incidents) {
        String incidentGeohash = GeoHash.encode(incident.latitude, incident.longitude).hash;
        if (userGeohash.substring(0, 5) == incidentGeohash.substring(0, 5)) {
          userStatus = 3; alertRadius = 4000; break;
        } else if (userGeohash.substring(0, 4) == incidentGeohash.substring(0, 4)) {
          if (userStatus < 2) { userStatus = 2; alertRadius = 15000; }
        }
      }
    }

    return {
      'text': userStatus == 3 ? 'ประสบภัย (ใกล้ตัวมาก)' : userStatus == 2 ? 'เสี่ยงภัย (เฝ้าระวัง)' : 'ปกติ (ปลอดภัย)',
      'color': userStatus == 3 ? Colors.red : userStatus == 2 ? Colors.orange : Colors.green,
      'radius': alertRadius,
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final incidents = ref.watch(incidentControllerProvider).incidents;
    final authState = ref.watch(authControllerProvider);
    final currentUser = authState.user;

    // จัดเตรียมข้อมูลผู้ใช้
    String displayFullName = 'ไม่ระบุชื่อ';
    if (currentUser != null) {
      final fname = currentUser.firstName ?? '';
      final lname = currentUser.lastName ?? '';
      if (fname.isNotEmpty || lname.isNotEmpty) displayFullName = '$fname $lname'.trim();
    }
    final displayPhone = currentUser?.tel ?? authState.phoneNumber ?? 'ไม่มีเบอร์โทรศัพท์';

    // คำนวณสถานะความปลอดภัย
    final areaStatus = _calculateAreaStatus(incidents);

    // เตรียม Markers และ Circles
    final Set<Marker> realMarkers = incidents.map((incident) {
      double hue = (incident.type == 'flood') ? BitmapDescriptor.hueAzure
          : (incident.urgency == 'ถึงแก่ชีวิต') ? BitmapDescriptor.hueRed : BitmapDescriptor.hueOrange;
      return Marker(
        markerId: MarkerId(incident.id),
        position: LatLng(incident.latitude, incident.longitude),
        onTap: () => IncidentBottomSheet.show(context, incident, currentUser), // ✅ เรียกใช้ผ่าน Class ที่แยกไว้
        icon: BitmapDescriptor.defaultMarkerWithHue(hue),
      );
    }).toSet();

    final Set<Circle> alertCircles = {};
    if (_currentPosition != null) {
      alertCircles.add(
        Circle(
          circleId: const CircleId('user_alert_zone'),
          center: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
          radius: areaStatus['radius'],
          fillColor: areaStatus['color'].withOpacity(0.15),
          strokeColor: areaStatus['color'],
          strokeWidth: 2,
        ),
      );
    }

    return Scaffold(
      body: Stack(
        children: [
          // --- Layer 1: Map ---
          GoogleMap(
            mapType: MapType.normal,
            initialCameraPosition: CameraPosition(
              target: _currentPosition != null ? LatLng(_currentPosition!.latitude, _currentPosition!.longitude) : const LatLng(13.7649, 100.5383),
              zoom: 14.4746,
            ),
            markers: realMarkers,
            circles: alertCircles,
            onMapCreated: (c) { if (!_controller.isCompleted) _controller.complete(c); },
            myLocationEnabled: true, myLocationButtonEnabled: false, zoomControlsEnabled: true,
          ),

          // --- Layer 2: Gradient พื้นหลังป้ายชื่อ ---
          Positioned(
            top: 0, left: 0, right: 0,
            child: IgnorePointer(
              child: Container(
                height: 150,
                decoration: BoxDecoration(
                  gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.white.withOpacity(0.9), Colors.white.withOpacity(0.0)]),
                ),
              ),
            ),
          ),

          // --- Layer 3: Profile Badge ---
          Positioned(
            top: 50, right: 16,
            // ✅ เรียกใช้ Widget ที่แยกไว้
            child: ProfileStatusBadge(
              displayFullName: displayFullName,
              displayPhone: displayPhone,
              statusText: areaStatus['text'],
              statusColor: areaStatus['color'],
            ),
          ),

          // --- Layer 4: ปุ่มแจ้งเหตุด่วน ---
          Positioned(
            bottom: 30, left: 20,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 24.0),
              child: FloatingActionButton.extended(
                heroTag: 'report_btn',
                onPressed: () {
                  LatLng currentPos = _currentPosition != null 
                      ? LatLng(_currentPosition!.latitude, _currentPosition!.longitude) 
                      : const LatLng(13.7649, 100.5383);
                  Navigator.push(context, MaterialPageRoute(builder: (context) => ReportIncidentPage(currentLocation: currentPos)));
                },
                backgroundColor: Colors.redAccent, elevation: 4,
                icon: const Icon(Icons.campaign, color: Colors.white),
                label: Text('แจ้งเหตุด่วน', style: theme.textTheme.titleMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ),

          // --- Layer 5: ปุ่ม GPS ---
          Positioned(
            bottom: 110, right: 12,
            child: FloatingActionButton(
              mini: true, heroTag: 'gps_btn',
              onPressed: _goToCurrentLocation, backgroundColor: Colors.white,
              child: Icon(Icons.my_location, color: theme.colorScheme.primary),
            ),
          ),

          if (ref.watch(incidentControllerProvider).isLoading || authState.isLoading)
            const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }
}