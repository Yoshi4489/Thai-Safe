import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart'; // เพิ่มเพื่อดึงพิกัด
import 'report_incident_page.dart';

class MapAlertPage extends ConsumerStatefulWidget {
  const MapAlertPage({super.key});

  @override
  ConsumerState<MapAlertPage> createState() => _MapAlertPageState();
}

class _MapAlertPageState extends ConsumerState<MapAlertPage> {
  final Completer<GoogleMapController> _controller = Completer();
  final Set<Marker> _markers = {};

  static const CameraPosition _kBangkok = CameraPosition(
    target: LatLng(13.7649, 100.5383),
    zoom: 14.4746,
  );

  @override
  void initState() {
    super.initState();
    _loadDummyAlerts();
  }

  // ฟังก์ชันเลื่อนแผนที่ไปที่ตำแหน่งปัจจุบัน
  Future<void> _goToCurrentLocation() async {
    final GoogleMapController controller = await _controller.future;
    
    // ตรวจสอบ Permission เบื้องต้น
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.whileInUse || permission == LocationPermission.always) {
      Position position = await Geolocator.getCurrentPosition();
      controller.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(position.latitude, position.longitude),
            zoom: 16.0,
          ),
        ),
      );
    }
  }

  void _loadDummyAlerts() {
    setState(() {
      _markers.addAll([
        Marker(
          markerId: const MarkerId('fire_01'),
          position: const LatLng(13.7650, 100.5380),
          infoWindow: const InfoWindow(title: '🔥 ไฟไหม้บ้านเรือน', snippet: 'ซอยราชวิถี 3'),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        ),
        Marker(
          markerId: const MarkerId('flood_01'),
          position: const LatLng(13.7600, 100.5400),
          infoWindow: const InfoWindow(title: '💧 น้ำท่วมขัง', snippet: 'สูง 20 ซม.'),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        ),
      ]);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Stack(
        children: [
          GoogleMap(
            mapType: MapType.normal,
            initialCameraPosition: _kBangkok,
            markers: _markers,
            onMapCreated: (GoogleMapController controller) {
              _controller.complete(controller);
            },
            myLocationEnabled: true,
            myLocationButtonEnabled: false, // ปิดปุ่มเดิมของ Google เพื่อใช้ปุ่ม Custom ของเรา
          ),

          // Layer ส่วนหัว
          Positioned(
            top: 0, left: 0, right: 0,
            child: Container(
              height: 120,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.white.withOpacity(0.9), Colors.white.withOpacity(0.0)],
                ),
              ),
              padding: const EdgeInsets.fromLTRB(20, 50, 20, 0),
              child: Text(
                'พื้นที่เฝ้าระวัง',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
          ),

          // --- ปุ่มแจ้งเหตุด่วน ---
          Positioned(
            bottom: 30,
            left: 20,
            child: FloatingActionButton.extended(
              heroTag: 'report_btn',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ReportIncidentPage(
                      currentLocation: LatLng(13.7649, 100.5383),
                    ),
                  ),
                );
              },
              backgroundColor: Colors.redAccent,
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

          // ปุ่ม Set พิกัดปัจจุบัน
          Positioned(
            bottom: 111,
            right: 10,
            child: FloatingActionButton(
              heroTag: 'gps_btn',
              onPressed: _goToCurrentLocation,
              backgroundColor: Colors.white,
              child: Icon(Icons.my_location, color: theme.colorScheme.primary),
            ),
          ),
        ],
      ),
    );
  }
}