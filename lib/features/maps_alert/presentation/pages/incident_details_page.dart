import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

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
      default:
        return '⚠️ เหตุอื่นๆ ($type)';
    }
  }

  // ฟังก์ชันแปลงวันที่ให้สวยงาม
  String _formatThaiDate(dynamic dateInput) {
    if (dateInput == null) return '-';
    DateTime? dt;
    if (dateInput is Timestamp) {
      dt = dateInput.toDate();
    } else if (dateInput is DateTime) {
      dt = dateInput;
    } else if (dateInput is String) {
      dt = DateTime.tryParse(dateInput);
    }
    if (dt == null) return dateInput.toString();
    
    final day = dt.day.toString().padLeft(2, '0');
    final month = dt.month.toString().padLeft(2, '0');
    final year = dt.year + 543;
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$day/$month/$year เวลา $hour:$minute น.';
  }

  // ฟังก์ชันแปลง Details เป็น Widget พร้อมดักจับ Key จากทุกฟอร์ม
  List<Widget> _buildDetailsList(dynamic rawDetails) {
    if (rawDetails == null) return [const Text('ไม่มีข้อมูลรายละเอียดเพิ่มเติม')];

    Map<String, dynamic> details = {};
    if (rawDetails is String) {
      try {
        details = jsonDecode(rawDetails);
      } catch (_) {
        return [Text(rawDetails.toString())];
      }
    } else if (rawDetails is Map) {
      details = Map<String, dynamic>.from(rawDetails);
    } else {
      return [const Text('ไม่มีข้อมูลรายละเอียดเพิ่มเติม')];
    }

    if (details.isEmpty) return [const Text('ไม่มีข้อมูลรายละเอียดเพิ่มเติม')];

    List<Widget> widgets = [];
    details.forEach((key, value) {
      // ข้ามถ้าค่าว่าง หรือเป็น null หรือเป็น Array ว่าง
      if (value == null || value.toString().trim().isEmpty || value.toString() == 'null' || value.toString() == '[]') return;

      String cleanKey = key.trim();
      String thKey = cleanKey;
      String thValue = value.toString();

      switch (cleanKey) {
        // ================= ทั่วไป / อัคคีภัย / อุทกภัย =================
        case 'fire_type': thKey = 'ลักษณะที่เกิดเหตุ'; break;
        case 'status': thKey = 'สถานการณ์'; break;
        case 'has_people_waiting':
        case 'has_people__waiting':
          thKey = 'ผู้รอความช่วยเหลือ';
          thValue = (value == true || value.toString().toLowerCase() == 'true') ? 'มี' : 'ไม่มี';
          break;
        case 'people_count':
          if (value == 0 || value.toString() == '0') return;
          thKey = 'จำนวนผู้ประสบเหตุ'; thValue = '$value คน'; break;
        case 'has_electricity':
          thKey = 'ไฟฟ้า';
          thValue = (value == true || value.toString().toLowerCase() == 'true') ? 'มี (ใช้งานได้)' : 'ไม่มี (ถูกตัด)';
          break;
        case 'has_bedridden':
          thKey = 'ผู้ป่วยติดเตียง';
          thValue = (value == true || value.toString().toLowerCase() == 'true') ? 'มี' : 'ไม่มี';
          break;
        case 'water_current': thKey = 'กระแสน้ำ'; break;
        case 'boat_access': thKey = 'รถ/เรือเข้าถึงได้'; break;
        case 'supplies_status': thKey = 'สถานะเสบียง/น้ำดื่ม'; break;
        case 'medical_needs':
          thKey = 'ความต้องการทางการแพทย์';
          Map<String, dynamic> medMap = {};
          if (value is Map) {
            medMap = Map<String, dynamic>.from(value);
          } else if (value is String) {
            try { medMap = jsonDecode(value); } catch (_) {}
          }
          if (medMap.isNotEmpty) {
            List<String> meds = [];
            bool needMeds = (medMap['need_meds'] == true || medMap['need_meds'].toString() == 'true');
            bool severe = (medMap['severe_disease'] == true || medMap['severe_disease'].toString() == 'true');
            if (needMeds) meds.add('ต้องการยา: ${medMap['med_name'] ?? 'ไม่ระบุ'}');
            if (severe) meds.add('โรคประจำตัว: ${medMap['disease_name'] ?? 'ไม่ระบุ'}');
            thValue = meds.isEmpty ? 'ไม่มีความต้องการพิเศษ' : meds.join(', ');
          } else {
            thValue = 'ไม่มี';
          }
          break;

        // ================= สารเคมีรั่วไหล =================
        case 'characteristics': thKey = 'ลักษณะสารเคมี'; break;
        case 'color': thKey = 'สี'; break;
        case 'symptoms': thKey = 'อาการผู้ได้รับผลกระทบ'; break;
        case 'wind_direction': thKey = 'ทิศทางลม'; break;
        case 'affected_area': thKey = 'พื้นที่ได้รับผลกระทบ'; break;

        // ================= เหตุร้าย / กราดยิง / ความรุนแรง =================
        case 'type': thKey = 'ลักษณะเหตุการณ์'; break;
        case 'weapon': thKey = 'อาวุธที่ใช้'; break;
        case 'suspect_status': thKey = 'สถานะผู้ก่อเหตุ'; break;
        case 'fled_vehicle_detail': thKey = 'ยานพาหนะหลบหนี'; break;
        case 'suspect_info': thKey = 'รูปพรรณผู้ก่อเหตุ'; break;
        case 'injury_type': thKey = 'ลักษณะบาดแผล'; break;
        case 'reporter_safety': thKey = 'สถานะความปลอดภัยผู้แจ้ง'; break;

        // ================= อาคารถล่ม / แผ่นดินไหว =================
        case 'feeling': thKey = 'การรับรู้ถึงแรงสั่นสะเทือน'; break;
        case 'damage': thKey = 'ความเสียหายของอาคาร'; break;
        case 'secondary_risk': thKey = 'ความเสี่ยงซ้ำซ้อน'; break;
        case 'utilities_status':
          thKey = 'ระบบสาธารณูปโภค';
          if (value is List) {
            thValue = value.join(', ');
          } else if (value is String) {
            thValue = value.replaceAll('[', '').replaceAll(']', '');
          }
          break;

        // ================= ข้อมูลผู้บาดเจ็บ / ผลกระทบ (ใช้ร่วมกันหลายเหตุ) =================
        case 'has_injured':
          thKey = 'ผู้บาดเจ็บ';
          thValue = (value == true || value.toString().toLowerCase() == 'true') ? 'มี' : 'ไม่มี';
          break;
        case 'injured_count':
          if (value == 0 || value.toString() == '0') return;
          thKey = 'จำนวนผู้บาดเจ็บ'; thValue = '$value คน'; break;
        case 'has_affected':
          thKey = 'ผู้ได้รับผลกระทบ';
          thValue = (value == true || value.toString().toLowerCase() == 'true') ? 'มี' : 'ไม่มี';
          break;
        case 'affected_count':
          if (value == 0 || value.toString() == '0') return;
          thKey = 'จำนวนผู้ได้รับผลกระทบ'; thValue = '$value คน'; break;
        case 'has_trapped':
          thKey = 'มีคนติดอยู่';
          thValue = (value == true || value.toString().toLowerCase() == 'true') ? 'มี' : 'ไม่มี';
          break;
        case 'trapped_count':
          if (value == 0 || value.toString() == '0') return;
          thKey = 'จำนวนคนติด'; thValue = '$value คน'; break;
        case 'building_floors':
          if (value == 0 || value.toString() == '0') return;
          thKey = 'จำนวนชั้นอาคาร'; thValue = '$value ชั้น'; break;

        // ================= อื่น ๆ =================
        case 'nearby_risk': thKey = 'ความเสี่ยงพื้นที่ข้างเคียง'; break;
        case 'water_source': thKey = 'แหล่งน้ำใกล้เคียง'; break;
        case 'extra_note': thKey = 'หมายเหตุเพิ่มเติม'; break;
        case 'urgent_needs':
          thKey = 'ต้องการความช่วยเหลือด่วน';
          if (value is List) {
            thValue = value.join(', ');
          } else if (value is String) {
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
          padding: const EdgeInsets.only(bottom: 12.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.check_circle, size: 20, color: Colors.blueAccent),
              const SizedBox(width: 8),
              Expanded(
                child: RichText(
                  text: TextSpan(
                    style: const TextStyle(color: Colors.black87, fontSize: 15, height: 1.4),
                    children: [
                      TextSpan(
                        text: '$thKey: ',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
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

    final LatLng incidentLocation = LatLng(
      incident.latitude,
      incident.longitude,
    );

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
                  builder: (_) => Dialog(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Image.network(
                        coverPhoto,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) =>
                            const Icon(Icons.broken_image, size: 80),
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
                  child: const Center(
                    child: Icon(
                      Icons.broken_image,
                      size: 50,
                      color: Colors.grey,
                    ),
                  ),
                ),
              ),
            ),

            // ถ้ามีรูปมากกว่า 1 โชว์รูปเล็ก ๆ ด้านล่าง
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
                        labelStyle: TextStyle(
                          color: Colors.blue.shade800,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Chip(
                        label: Text(incident.status ?? 'Pending'),
                        backgroundColor: Colors.green.shade50,
                        labelStyle: TextStyle(
                          color: Colors.green.shade800,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  Text(
                    incident.title ?? 'ไม่มีหัวข้อ',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 3. ข้อมูลผู้แจ้ง และ เวลา
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.person, color: Colors.grey),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('แจ้งโดย: ${incident.reporterName}'),
                              Text(
                                'เบอร์ติดต่อ: ${incident.reporterTel}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'เวลา: ${_formatThaiDate(incident.createdAt)}',
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 4. รายละเอียดที่ฟอร์แมตแล้ว
                  const Text(
                    'ข้อมูลเพิ่มเติม',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const Divider(),
                  const SizedBox(height: 12),
                  
                  // ดึงข้อมูลผ่าน _buildDetailsList ที่อัปเดตแล้ว
                  ..._buildDetailsList(incident.details ?? {}),

                  const SizedBox(height: 24),

                  // 5. แผนที่ขนาดเล็กแสดงจุดเกิดเหตุ
                  const Text(
                    'จุดเกิดเหตุ',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const Divider(),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: SizedBox(
                      height: 200,
                      width: double.infinity,
                      child: GoogleMap(
                        initialCameraPosition: CameraPosition(
                          target: incidentLocation,
                          zoom: 16,
                        ),
                        markers: {
                          Marker(
                            markerId: const MarkerId('incident_loc'),
                            position: incidentLocation,
                            icon: BitmapDescriptor.defaultMarkerWithHue(
                              BitmapDescriptor.hueRed,
                            ),
                          ),
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