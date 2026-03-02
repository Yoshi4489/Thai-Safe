import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

// หากคุณใช้ Model ชื่ออื่น กรุณาเปลี่ยน 'dynamic incident' 
// ใน constructor ให้เป็น Class ของคุณ เช่น 'final IncidentModel incident;'

class IncidentDetailsPage extends StatelessWidget {
  final dynamic incident; // รับค่า Model เข้ามา
  
  const IncidentDetailsPage({super.key, required this.incident});

// ฟังก์ชันแปลงประเภทเหตุเป็นภาษาไทย 
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
        return '⚠️ เหตุร้าย/ความรุนแรง';
      case 'other': 
        return '🆘 เหตุอื่นๆ';
      // เผื่อกรณีมีข้อมูลเก่าหลงเหลืออยู่
      default: 
        return '⚠️ เหตุอื่นๆ ($type)';
    }
  }

  // ฟังก์ชันแปลง Details เป็น Widget อ่านง่าย
  List<Widget> _buildDetailsList(Map<String, dynamic> details) {
    if (details.isEmpty) return [const Text('ไม่มีข้อมูลรายละเอียดเพิ่มเติม')];
    
    List<Widget> widgets = [];
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
          thKey = 'จำนวนคนติด'; thValue = '$value คน'; break;
        case 'building_floors': 
          if (value == 0) return; 
          thKey = 'จำนวนชั้นอาคาร'; thValue = '$value ชั้น'; break;
        case 'nearby_risk': thKey = 'ความเสี่ยงพื้นที่ข้างเคียง'; break;
        case 'water_source': thKey = 'แหล่งน้ำใกล้เคียง'; break;
        case 'urgent_needs': 
          thKey = 'ต้องการความช่วยเหลือด่วน'; 
          if (value is List) { thValue = value.join(', '); } 
          else if (value is String) {
            try { thValue = jsonDecode(value).join(', '); } catch (_) {}
          }
          break;
        case 'action_by': thKey = 'เจ้าหน้าที่รับเรื่อง'; break;
        case 'action_time': 
          thKey = 'เวลาอัปเดตสถานะ'; 
          try { thValue = DateTime.parse(value.toString()).toLocal().toString().substring(0, 16); } catch (_) {}
          break;
      }
      widgets.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.check_circle_outline, size: 18, color: Colors.blueAccent),
              const SizedBox(width: 8),
              Expanded(
                child: RichText(
                  text: TextSpan(
                    style: const TextStyle(color: Colors.black87, fontSize: 14),
                    children: [
                      TextSpan(text: '$thKey: ', style: const TextStyle(fontWeight: FontWeight.bold)),
                      TextSpan(text: thValue),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    });
    return widgets;
  }

  @override
  Widget build(BuildContext context) {
    // เช็ครูปภาพ
    final List<dynamic> imageUrls = incident.imageUrls ?? [];
    final String coverPhoto = imageUrls.isNotEmpty 
        ? imageUrls.first 
        : 'https://via.placeholder.com/400x300.png?text=No+Image';

    final LatLng incidentLocation = LatLng(incident.latitude, incident.longitude);

    return Scaffold(
      appBar: AppBar(
        title: const Text('รายละเอียดเหตุการณ์'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. ภาพหลัก
            GestureDetector(
              onTap: () {
                showDialog(
                  context: context,
                  builder: (context) => Center(
                    child: Container(
                      padding: EdgeInsets.all(20),
                      child: Image.network(
                        coverPhoto
                      ),
                    ),
                  ),
                );
              },
              child: Image.network(
                coverPhoto,
                width: double.infinity,
                height: 250,
                fit: BoxFit.cover,
                errorBuilder: (ctx, err, stack) => Container(
                  height: 250,
                  color: Colors.grey.shade300,
                  child: const Center(child: Icon(Icons.broken_image, size: 50, color: Colors.grey)),
                ),
              ),
            ),
            
            // ถ้ามีรูปมากกว่า 1 โชว์รูปเล็กๆ ด้านล่าง
            if (imageUrls.length > 1)
              SizedBox(
                height: 80,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: imageUrls.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          imageUrls[index],
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                        ),
                      ),
                    );
                  },
                ),
              ),

            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 2. หัวข้อ และ ป้ายสถานะ
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Chip(
                        label: Text(_getIncidentTypeName(incident.type)),
                        backgroundColor: Colors.blue.shade50,
                        labelStyle: TextStyle(color: Colors.blue.shade800, fontWeight: FontWeight.bold),
                      ),
                      Chip(
                        label: Text(incident.status ?? 'Pending'),
                        backgroundColor: Colors.green.shade50,
                        labelStyle: TextStyle(color: Colors.green.shade800, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  
                  Text(
                    incident.title ?? 'ไม่มีหัวข้อ',
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),

                  // 3. ข้อมูลผู้แจ้ง และ เวลา
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8)),
                    child: Row(
                      children: [
                        const Icon(Icons.person, color: Colors.grey),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('แจ้งโดย: ${incident.reporterName}'),
                              Text('เบอร์ติดต่อ: ${incident.reporterTel}', style: const TextStyle(fontWeight: FontWeight.bold)),
                              Text('เวลา: ${incident.createdAt.toString().substring(0, 16)}', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 4. รายละเอียดที่ฟอร์แมตแล้ว
                  const Text('ข้อมูลเพิ่มเติม', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const Divider(),
                  const SizedBox(height: 8),
                  ..._buildDetailsList(incident.details ?? {}),

                  const SizedBox(height: 24),

                  // 5. แผนที่ขนาดเล็กแสดงจุดเกิดเหตุ
                  const Text('จุดเกิดเหตุ', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const Divider(),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: SizedBox(
                      height: 200,
                      width: double.infinity,
                      child: GoogleMap(
                        initialCameraPosition: CameraPosition(target: incidentLocation, zoom: 16),
                        markers: {
                          Marker(
                            markerId: const MarkerId('incident_loc'),
                            position: incidentLocation,
                            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
                          )
                        },
                        // ปิดการเลื่อนแผนที่ เพื่อไม่ให้ชนกับการ Scroll ของหน้าเพจ
                        scrollGesturesEnabled: false,
                        zoomGesturesEnabled: false,
                        myLocationButtonEnabled: false,
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}