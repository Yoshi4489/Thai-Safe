import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geohash_plus/geohash_plus.dart' hide LatLng;
import 'package:cloud_firestore/cloud_firestore.dart';

// Import หน้าอื่นๆ
import 'report_incident_page.dart';
import 'incident_details_page.dart'; 

// Import Controllers (ปรับ path ให้ตรงกับโปรเจกต์ของคุณ)
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

  String _getIncidentTypeName(String type) {
      switch (type.toLowerCase()) {
        case 'fire': 
          return '🔥 อัคคีภัย (ไฟไหม้)';
        case 'flood': 
          return '🌊 อุทกภัย (น้ำท่วม)';
        case 'collapse': 
          return '🏢 อาคารถล่ม/แผ่นดินไหว';
        case 'chemical': 
          return '🧪 สารเคมีรั่วไหล';
        case 'violence': 
          return '⚠️ เหตุร้าย/ความรุนแรง'; // แก้ตรงนี้ครับ
        case 'other': 
          return '🆘 เหตุอื่นๆ';
        default: 
          return '⚠️ เหตุอื่นๆ ($type)';
      }
    }

  String _formatIncidentDetails(Map<String, dynamic> details) {
    if (details.isEmpty) return 'ไม่มีข้อมูลรายละเอียดเพิ่มเติม';
    List<String> formattedList = [];
    details.forEach((key, value) {
      String thKey = key;
      String thValue = value.toString();
      switch (key) {
        case 'fire_type': thKey = 'ลักษณะที่เกิดเหตุ'; break;
        case 'status': thKey = 'สถานการณ์'; break;
        case 'has_trapped': 
          thKey = 'มีคนติดอยู่'; 
          thValue = (value == true) ? 'มี' : 'ไม่มี'; 
          break;
        case 'trapped_count': 
          if (value == 0) return; 
          thKey = 'จำนวนคนติด'; 
          thValue = '$value คน';
          break;
        case 'building_floors': 
          if (value == 0) return; 
          thKey = 'จำนวนชั้นอาคาร'; 
          thValue = '$value ชั้น';
          break;
        case 'nearby_risk': thKey = 'ความเสี่ยงพื้นที่ข้างเคียง'; break;
        case 'water_source': thKey = 'แหล่งน้ำใกล้เคียง'; break;
        case 'urgent_needs': 
          thKey = 'ต้องการความช่วยเหลือด่วน'; 
          if (value is List) {
            thValue = value.join(', ');
          } else if (value is String) {
            try {
              List<dynamic> parsedList = jsonDecode(value);
              thValue = parsedList.join(', ');
            } catch (_) {}
          }
          break;
        case 'action_by': thKey = 'เจ้าหน้าที่รับเรื่อง'; break;
        case 'action_time': 
          thKey = 'เวลาอัปเดตสถานะ'; 
          try {
             thValue = DateTime.parse(value.toString()).toLocal().toString().substring(0, 16);
          } catch (_) {}
          break;
      }
      formattedList.add('• $thKey: $thValue');
    });
    return formattedList.join('\n');
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

  Future<void> _initLocationTracking() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() => _isLoadingLocation = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('กรุณาเปิด GPS (Location Services) บนอุปกรณ์ของคุณ')),
        );
      }
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('สิทธิ์ถูกปฏิเสธถาวร กรุณาอนุญาตในตั้งค่าของแอป')),
        );
      }
      return;
    }

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

  void _showIncidentBottomSheet(BuildContext context, dynamic incident, dynamic currentUser) {
    bool isOfficer = false;
    try {
      if (currentUser != null && (currentUser.role == 'officer' || currentUser.role == 'admin')) {
        isOfficer = true;
      }
    } catch (e) {
      debugPrint('User model might not have role property yet: $e');
    }

    final String coverPhoto = (incident.imageUrls != null && incident.imageUrls.isNotEmpty)
        ? incident.imageUrls.first 
        : 'https://via.placeholder.com/400x200.png?text=No+Image';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.only(bottom: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                child: Image.network(
                  coverPhoto,
                  width: double.infinity,
                  height: 180,
                  fit: BoxFit.cover,
                  errorBuilder: (ctx, err, stack) => Container(
                    height: 180,
                    color: Colors.grey.shade300,
                    child: const Icon(Icons.broken_image, size: 50, color: Colors.grey),
                  ),
                ),
              ),
              
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                incident.title ?? 'ไม่มีหัวข้อ',
                                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'แจ้งโดย: ${incident.reporterName} 📞 ${incident.reporterTel}',
                                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: incident.urgency == 'ถึงแก่ชีวิต' ? Colors.red.shade100 : Colors.orange.shade100,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                incident.urgency ?? 'ด่วน',
                                style: TextStyle(
                                  color: incident.urgency == 'ถึงแก่ชีวิต' ? Colors.red.shade800 : Colors.orange.shade800, 
                                  fontWeight: FontWeight.bold
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'สถานะ: ${incident.status}',
                              style: TextStyle(fontSize: 12, color: Colors.blue.shade700, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    Container(
                      padding: const EdgeInsets.all(12),
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'ประเภทเหตุ: ${_getIncidentTypeName(incident.type)}\nเวลาแจ้ง: ${incident.createdAt.toString().substring(0, 16)}\n\n${_formatIncidentDetails(incident.details)}',
                        style: TextStyle(color: Colors.grey.shade800, fontSize: 13, height: 1.5),
                        maxLines: 5, 
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    
                    const SizedBox(height: 20),

                    if (!isOfficer) ...[
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              // ✅ เพิ่มระบบบันทึกลง Firestore สำหรับปุ่มติดตาม
                              onPressed: () async {
                                Navigator.pop(context); // ปิด BottomSheet ก่อน
                                if (currentUser == null) return;
                                
                                try {
                                  await FirebaseFirestore.instance
                                      .collection('users')
                                      .doc(currentUser.uid)
                                      .collection('followed_incidents')
                                      .doc(incident.id)
                                      .set({
                                        'incident_id': incident.id,
                                        'followed_at': FieldValue.serverTimestamp(),
                                      });
                                      
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('คุณได้ติดตามเหตุการณ์นี้แล้ว'), backgroundColor: Colors.green),
                                    );
                                  }
                                } catch (e) {
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('เกิดข้อผิดพลาด: $e'), backgroundColor: Colors.red),
                                    );
                                  }
                                }
                              },
                              icon: const Icon(Icons.notifications_active),
                              label: const Text('ติดตาม'),
                              style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12)),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              // ✅ เพิ่ม Navigator ส่งไปหน้าดูรายละเอียด
                              onPressed: () {
                                Navigator.pop(context); // ปิด BottomSheet
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => IncidentDetailsPage(incident: incident),
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blueAccent,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                              child: const Text('ดูรายละเอียด', style: TextStyle(fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ],
                      ),
                    ] else ...[
                      const Divider(),
                      const Text('ส่วนปฏิบัติการของเจ้าหน้าที่', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo)),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: incident.status == 'กำลังดำเนินการ' || incident.status == 'เสร็จสิ้น'
                                  ? null 
                                  : () {
                                      Navigator.pop(context);
                                      _showOfficerActionDialog(context, incident, 'กำลังดำเนินการ');
                                    },
                              icon: const Icon(Icons.directions_run),
                              label: const Text('รับเรื่อง'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: incident.status == 'เสร็จสิ้น'
                                  ? null 
                                  : () {
                                      Navigator.pop(context);
                                      _showOfficerActionDialog(context, incident, 'เสร็จสิ้น');
                                    },
                              icon: const Icon(Icons.check_circle),
                              label: const Text('ปิดงาน'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showOfficerActionDialog(BuildContext context, dynamic incident, String actionStatus) {
    final TextEditingController agencyController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('ยืนยันสถานะ: $actionStatus'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('กรุณาระบุชื่อหน่วยงาน หรือ ชื่อผู้ดำเนินการ'),
              const SizedBox(height: 16),
              TextField(
                controller: agencyController,
                decoration: InputDecoration(
                  labelText: 'เช่น กู้ภัยมูลนิธิ..., ตำรวจ สน....',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('ยกเลิก', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () async {
                final agency = agencyController.text.trim();
                if (agency.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('กรุณาระบุหน่วยงานก่อนยืนยัน'), backgroundColor: Colors.red),
                  );
                  return;
                }
                
                Navigator.pop(ctx); 
                
                try {
                  Map<String, dynamic> updatedDetails = Map.from(incident.details);
                  updatedDetails['action_by'] = agency;
                  updatedDetails['action_time'] = DateTime.now().toIso8601String();

                  await FirebaseFirestore.instance
                      .collection('incidents')
                      .doc(incident.id)
                      .update({
                        'status': actionStatus,
                        'description': jsonEncode(updatedDetails), 
                      });
                  
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('อัปเดตสถานะเป็น "$actionStatus" โดย $agency แล้ว'), backgroundColor: Colors.green),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('เกิดข้อผิดพลาด: $e'), backgroundColor: Colors.red),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent, foregroundColor: Colors.white),
              child: const Text('ยืนยัน'),
            ),
          ],
        );
      },
    );
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

    final displayPhone = currentUser?.tel ?? authState.phoneNumber ?? 'ไม่มีเบอร์โทรศัพท์';

    int userStatus = 1;
    double alertRadius = 2000; 

    if (_currentPosition != null && incidents.isNotEmpty) {
      String userGeohash = GeoHash.encode(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
      ).hash;

      for (var incident in incidents) {
        String incidentGeohash = GeoHash.encode(
          incident.latitude,
          incident.longitude,
        ).hash;

        if (userGeohash.substring(0, 5) == incidentGeohash.substring(0, 5)) {
          userStatus = 3;
          alertRadius = 4000;
          break; 
        } else if (userGeohash.substring(0, 4) == incidentGeohash.substring(0, 4)) {
          if (userStatus < 2) {
            userStatus = 2;
            alertRadius = 15000;
          }
        }
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

    final Set<Marker> realMarkers = incidents.map((incident) {
      double hue = (incident.type == 'flood')
          ? BitmapDescriptor.hueAzure
          : (incident.urgency == 'ถึงแก่ชีวิต')
          ? BitmapDescriptor.hueRed
          : BitmapDescriptor.hueOrange;

      return Marker(
        markerId: MarkerId(incident.id),
        position: LatLng(incident.latitude, incident.longitude),
        onTap: () {
          _showIncidentBottomSheet(context, incident, currentUser);
        },
        icon: BitmapDescriptor.defaultMarkerWithHue(hue),
      );
    }).toSet();

    final Set<Circle> alertCircles = {};
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
          GoogleMap(
            mapType: MapType.normal,
            initialCameraPosition: CameraPosition(
              target: _currentPosition != null
              ? LatLng(_currentPosition!.latitude, _currentPosition!.longitude)
              : const LatLng(13.7649, 100.5383),
              zoom: 14.4746,
            ),
            markers: realMarkers,
            circles: alertCircles,
            onMapCreated: (GoogleMapController controller) {
              if (!_controller.isCompleted) {
                _controller.complete(controller);
              }
            },
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: true,
          ),

          Positioned(
            top: 0, left: 0, right: 0,
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

          Positioned(
            top: 50, right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 3)),
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
                        style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        displayPhone,
                        style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey.shade700),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: statusColor),
                        ),
                        child: Text(
                          statusText,
                          style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          Positioned(
            bottom: 30, left: 20,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 24.0),
              child: FloatingActionButton.extended(
                heroTag: 'report_btn',
                onPressed: () {
                  LatLng currentPos = const LatLng(13.7649, 100.5383);
                  if (_currentPosition != null) {
                    currentPos = LatLng(_currentPosition!.latitude, _currentPosition!.longitude);
                  }
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ReportIncidentPage(currentLocation: currentPos),
                    ),
                  );
                },
                backgroundColor: Colors.redAccent,
                elevation: 4,
                icon: const Icon(Icons.campaign, color: Colors.white),
                label: Text(
                  'แจ้งเหตุด่วน',
                  style: theme.textTheme.titleMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),

          Positioned(
            bottom: 110, right: 12,
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