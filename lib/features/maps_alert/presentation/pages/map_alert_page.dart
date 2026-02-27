import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

// Import หน้าแจ้งเหตุ
import 'report_incident_page.dart';

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
        CameraPosition(
          target: LatLng(position.latitude, position.longitude),
          zoom: 15,
        ),
      ),
    );
  }

  // ฟังก์ชันขอสิทธิ์และเริ่มติดตามตำแหน่งแบบ Real-time
  Future<void> _initLocationTracking() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // ถ้าปิด GPS ไว้ ให้หยุดการทำงาน
      setState(() => _isLoadingLocation = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('กรุณาเปิด GPS (Location Services) บนอุปกรณ์ของคุณ'),
          ),
        );
      }
      return;
    }

    // 2. ตรวจสอบสิทธิ์การเข้าถึงตำแหน่ง
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // ถ้าผู้ใช้ปฏิเสธสิทธิ์
        setState(() => _isLoadingLocation = false);
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // ถ้าผู้ใช้ปฏิเสธสิทธิ์ถาวร ต้องไปเปิดใน Settings ของเครื่อง
      setState(() => _isLoadingLocation = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('สิทธิ์ถูกปฏิเสธถาวร กรุณาอนุญาตในตั้งค่าของแอป'),
          ),
        );
      }
      return;
    }

    // 3. ดึงตำแหน่งปัจจุบัน
    try {
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

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
    final GoogleMapController controller = await _controller.future;
    if (_currentPosition != null) {
      _moveCameraToUser(_currentPosition!);
    } else {
      _initLocationTracking();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กำลังค้นหาตำแหน่ง GPS ของคุณ...')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final incidentState = ref.watch(incidentControllerProvider);
    final incidents = incidentState.incidents;

    final authState = ref.watch(authControllerProvider);
    final currentUser = authState.user;

    String displayFullName = 'ไม่ระบุชื่อ';
    if (currentUser != null) {
      final firstName = currentUser.firstName ?? '';
      final lastName = currentUser.lastName ?? '';
      if (firstName.isNotEmpty || lastName.isNotEmpty) {
        displayFullName = '$firstName $lastName'.trim();
      }
    }

    final displayPhone =
        currentUser?.tel ?? authState.phoneNumber ?? 'ไม่มีเบอร์โทรศัพท์';

    // =========================================================
    // 2. คำนวณสถานะความปลอดภัย (รอ GPS ก่อนคำนวณ)
    // =========================================================
    int userStatus = 1;
    double alertRadius = 5000; // รัศมีเริ่มต้น 5 กม. กางตลอดเวลาที่มี GPS

    if (_currentPosition != null && incidents.isNotEmpty) {
      double minDistance = double.infinity;

      for (var incident in incidents) {
        double distance = Geolocator.distanceBetween(
          _currentPosition!.latitude,
          _currentPosition!.longitude,
          incident.latitude,
          incident.longitude,
        );
        if (distance < minDistance) minDistance = distance;
      }

      if (minDistance <= 5000) {
        userStatus = 3;
        alertRadius = 5000;
      } else if (minDistance <= 20000) {
        userStatus = 2;
        alertRadius = 20000;
      }
    }

    String statusText = 'ปกติ (ปลอดภัย)';
    Color statusColor = Colors.green;

    if (userStatus == 3) {
      statusText = 'ประสบภัย (ใกล้ตัวมาก)';
      statusColor = Colors.red;
    } else if (userStatus == 2) {
      statusText = 'เสี่ยงภัย (เฝ้าระวัง)';
      statusColor = Colors.orange;
    }

    // =========================================================
    // 3. เตรียม Marker และ Circle
    // =========================================================
    final Set<Marker> realMarkers = incidents.map((incident) {
      double hue = (incident.type == 'flood')
          ? BitmapDescriptor.hueAzure
          : (incident.urgency == 'ถึงแก่ชีวิต')
          ? BitmapDescriptor.hueRed
          : BitmapDescriptor.hueOrange;

      return Marker(
        markerId: MarkerId(incident.id),
        position: LatLng(incident.latitude, incident.longitude),
        infoWindow: InfoWindow(
          title: incident.title,
          snippet: '${incident.type} | ${incident.urgency}',
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(hue),
      );
    }).toSet();

    final Set<Circle> alertCircles = {};
    // ✅ เช็ก GPS ก่อนวาดวงกลม ถ้าเป็นเครื่องจริงเปิด Location ปุ๊บวงกลมขึ้นปั๊บ
    if (_currentPosition != null) {
      alertCircles.add(
        Circle(
          circleId: const CircleId('user_alert_zone'),
          center: LatLng(
            _currentPosition!.latitude,
            _currentPosition!.longitude,
          ),
          radius: alertRadius,
          fillColor: statusColor.withOpacity(0.15),
          strokeColor: statusColor,
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
              target: 
              _currentPosition != null
              ? LatLng(
                _currentPosition!.latitude,
                _currentPosition!.longitude,
              )
              : LatLng(
                13.7649, 100.5383
              ),
              zoom: 14.4746,
            ),
            markers: realMarkers,
            circles: alertCircles,
            onMapCreated: (GoogleMapController controller) {
              // Add this safety check
              if (!_controller.isCompleted) {
                _controller.complete(controller);
              }
            },
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: true,
          ),

          // --- Layer 2: Gradient ---
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
                      Colors.white.withOpacity(0.9),
                      Colors.white.withOpacity(0.0),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // --- Layer 3: Profile Badge ---
          Positioned(
            top: 50,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 8,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: Colors.grey.shade200,
                    child: const Icon(Icons.person, color: Colors.grey),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayFullName,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        displayPhone,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.grey.shade700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: statusColor),
                        ),
                        child: Text(
                          statusText,
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // --- Layer 4: ปุ่มแจ้งเหตุด่วน ---
          Positioned(
            bottom: 30,
            left: 20,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 24.0),
              child: FloatingActionButton.extended(
                heroTag: 'report_btn',
                onPressed: () {
                  // ส่งพิกัดปัจจุบันไป หรือใช้อนุสาวรีย์ฯ ถ้ายังหาไม่เจอ
                  LatLng currentPos = const LatLng(13.7649, 100.5383);
                  if (_currentPosition != null) {
                    currentPos = LatLng(
                      _currentPosition!.latitude,
                      _currentPosition!.longitude,
                    );
                  }
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          ReportIncidentPage(currentLocation: currentPos),
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

          // --- Layer 5: ปุ่ม GPS ---
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

          if (incidentState.isLoading || authState.isLoading)
            const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }
}
