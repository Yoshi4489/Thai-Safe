import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:thai_safe/features/maps_alert/utils/incident_format_helper.dart';
import 'package:thai_safe/features/maps_alert/presentation/pages/incident_details_page.dart';

class IncidentBottomSheet {
  
  static void show(BuildContext context, dynamic incident, dynamic currentUser) {
    bool isOfficer = false;
    try {
      if (currentUser != null && (currentUser.role == 'officer' || currentUser.role == 'admin')) {
        isOfficer = true;
      }
    } catch (e) {
      debugPrint('User model check error: $e');
    }

    // --- Logic เช็คสถานะการติดตาม ---
    final List<dynamic> followers = incident.followers ?? [];
    final bool isFollowing = currentUser != null && followers.contains(currentUser.id);
    // ----------------------------

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
              // Cover Photo
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                child: Image.network(
                  coverPhoto,
                  width: double.infinity,
                  height: 180,
                  fit: BoxFit.cover,
                  errorBuilder: (ctx, err, stack) => Container(
                    height: 180, color: Colors.grey.shade300,
                    child: const Icon(Icons.broken_image, size: 50, color: Colors.grey),
                  ),
                ),
              ),
              
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Row
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
                                maxLines: 2, overflow: TextOverflow.ellipsis,
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
                                style: TextStyle(color: incident.urgency == 'ถึงแก่ชีวิต' ? Colors.red.shade800 : Colors.orange.shade800, fontWeight: FontWeight.bold),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text('สถานะ: ${incident.status}', style: TextStyle(fontSize: 12, color: Colors.blue.shade700, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Details
                    Container(
                      padding: const EdgeInsets.all(12),
                      width: double.infinity,
                      decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8)),
                      child: Text(
                        'ประเภทเหตุ: ${IncidentFormatHelper.getIncidentTypeName(incident.type)}\nเวลาแจ้ง: ${_formatThaiDate(incident.createdAt)}\n\n${IncidentFormatHelper.formatIncidentDetails(incident.details)}',
                        style: TextStyle(color: Colors.grey.shade800, fontSize: 13, height: 1.5),
                        maxLines: 5, overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Action Buttons
                    if (!isOfficer) ...[
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () async {
                                if (currentUser == null) return;
                                try {
                                  if (isFollowing) {
                                    // เลิกติดตาม
                                    await FirebaseFirestore.instance.collection('incidents').doc(incident.id).update({
                                      'followers': FieldValue.arrayRemove([currentUser.id])
                                    });
                                    if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('เลิกติดตามเหตุการณ์นี้แล้ว')));
                                  } else {
                                    // ติดตาม
                                    await FirebaseFirestore.instance.collection('incidents').doc(incident.id).update({
                                      'followers': FieldValue.arrayUnion([currentUser.id])
                                    });
                                    if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('คุณได้ติดตามเหตุการณ์นี้แล้ว'), backgroundColor: Colors.green));
                                  }
                                  if (context.mounted) Navigator.pop(context); // ปิดเพื่อรีเฟรชข้อมูลหน้าหลัก
                                } catch (e) {
                                  if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('เกิดข้อผิดพลาด: $e'), backgroundColor: Colors.red));
                                }
                              },
                              // เปลี่ยน Icon และ Text ตามสถานะ isFollowing
                              icon: Icon(isFollowing ? Icons.notifications_off : Icons.notifications_active), 
                              label: Text(isFollowing ? 'เลิกติดตาม' : 'ติดตาม'),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                side: BorderSide(color: isFollowing ? Colors.grey : Colors.blue),
                                foregroundColor: isFollowing ? Colors.grey.shade700 : Colors.blue,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.pop(context);
                                Navigator.push(context, MaterialPageRoute(builder: (context) => IncidentDetailsPage(incident: incident)));
                              },
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 12)),
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
                              onPressed: incident.status == 'กำลังดำเนินการ' || incident.status == 'เสร็จสิ้น' ? null : () {
                                Navigator.pop(context);
                                _showOfficerActionDialog(context, incident, 'กำลังดำเนินการ');
                              },
                              icon: const Icon(Icons.directions_run), label: const Text('รับเรื่อง'),
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 12)),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: incident.status == 'เสร็จสิ้น' ? null : () {
                                Navigator.pop(context);
                                _showOfficerActionDialog(context, incident, 'เสร็จสิ้น');
                              },
                              icon: const Icon(Icons.check_circle), label: const Text('ปิดงาน'),
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 12)),
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

  static void _showOfficerActionDialog(BuildContext context, dynamic incident, String actionStatus) {
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
                decoration: InputDecoration(labelText: 'เช่น กู้ภัยมูลนิธิ..., ตำรวจ สน....', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('ยกเลิก', style: TextStyle(color: Colors.grey))),
            ElevatedButton(
              onPressed: () async {
                final agency = agencyController.text.trim();
                if (agency.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('กรุณาระบุหน่วยงานก่อนยืนยัน'), backgroundColor: Colors.red));
                  return;
                }
                Navigator.pop(ctx); 
                try {
                  Map<String, dynamic> updatedDetails = {};
                  if (incident.details is Map) {
                    updatedDetails = Map<String, dynamic>.from(incident.details);
                  } else if (incident.details is String) {
                    updatedDetails = jsonDecode(incident.details);
                  }

                  updatedDetails['action_by'] = agency;
                  updatedDetails['action_time'] = DateTime.now().toIso8601String();

                  await FirebaseFirestore.instance.collection('incidents').doc(incident.id).update({
                    'status': actionStatus,
                    'description': jsonEncode(updatedDetails), 
                  });
                  if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('อัปเดตสถานะเป็น "$actionStatus" โดย $agency แล้ว'), backgroundColor: Colors.green));
                } catch (e) {
                  if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('เกิดข้อผิดพลาด: $e'), backgroundColor: Colors.red));
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

  static String _formatThaiDate(dynamic dateInput) {
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
}