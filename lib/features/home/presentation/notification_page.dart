import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thai_safe/features/authentication/providers/auth_state_provider.dart';

class NotificationPage extends ConsumerWidget {
  const NotificationPage({super.key});

  String _getNotificationMessage(String status) {
    switch (status) {
      case 'Acknowledged': return 'กู้ภัยได้รับเรื่องเหตุการณ์นี้แล้ว';
      case 'In Progress': return 'กู้ภัยกำลังเดินทาง/ดำเนินการแก้ไข';
      case 'Resolved': return 'เหตุการณ์นี้ได้รับการแก้ไขสำเร็จแล้ว';
      case 'Cancelled': return 'เหตุการณ์นี้ถูกยกเลิกแล้ว';
      default: return 'มีการอัปเดตสถานะเหตุการณ์เป็น $status';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(authControllerProvider).user;

    if (currentUser == null) {
      return Scaffold(appBar: AppBar(title: const Text('การแจ้งเตือน')), body: const Center(child: Text('กรุณาเข้าสู่ระบบ')));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('การแจ้งเตือน'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      // เปลี่ยนมาดึงข้อมูลแบบไม่กรองด้วย query เพื่อป้องกันข้อมูลหายจากฝั่ง Server
      // เราจะมาคัดกรองเฉพาะที่เป็นของเราใน List ด้านล่างแทน
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('notifications')
            .orderBy('timestamp', descending: true)
            .limit(50) 
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData) {
            return const Center(child: Text('ไม่มีการแจ้งเตือน'));
          }

          // กรองข้อมูลในแอป (Local Filtering) เพื่อให้มั่นใจว่ารายการไม่หายวับไปจากหน้าจอ
          final docs = snapshot.data!.docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final List<dynamic> targetUsers = data['target_users'] ?? [];
            return targetUsers.contains(currentUser.id);
          }).toList();

          if (docs.isEmpty) {
            return const Center(child: Text('ไม่มีการแจ้งเตือนใหม่', style: TextStyle(color: Colors.grey)));
          }

          return ListView.separated(
            itemCount: docs.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;
              
              final String incidentTitle = data['incident_title'] ?? 'เหตุการณ์';
              final String status = data['status'] ?? '';
              final String actionBy = data['action_by'] ?? 'เจ้าหน้าที่';
              final Timestamp? timestamp = data['timestamp'];
              final List<String> readBy = List<String>.from(data['read_by'] ?? []);
              
              final bool isRead = readBy.contains(currentUser.id);

              return ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                tileColor: isRead ? Colors.white : Colors.blue.shade50,
                leading: CircleAvatar(
                  backgroundColor: isRead ? Colors.grey.shade200 : Colors.blue.shade100,
                  child: Icon(
                    status == 'Resolved' ? Icons.check_circle : Icons.notifications_active,
                    color: status == 'Resolved' ? Colors.green : (isRead ? Colors.grey : Colors.blue),
                  ),
                ),
                title: Text(incidentTitle, style: TextStyle(fontWeight: isRead ? FontWeight.normal : FontWeight.bold)),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    Text('${_getNotificationMessage(status)} โดย $actionBy', style: TextStyle(color: Colors.grey.shade800)),
                    const SizedBox(height: 4),
                    Text(
                      timestamp != null ? _formatTime(timestamp.toDate()) : '',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
                onTap: () async {
                  if (!isRead) {
                    try {
                      // อัปเดตสถานะการอ่าน
                      await FirebaseFirestore.instance.collection('notifications').doc(doc.id).update({
                        'read_by': FieldValue.arrayUnion([currentUser.id])
                      });
                    } catch (e) {
                      debugPrint('Update Error: $e');
                    }
                  }
                },
              );
            },
          );
        },
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);
    if (difference.inDays > 0) return '${difference.inDays} วันที่แล้ว';
    if (difference.inHours > 0) return '${difference.inHours} ชั่วโมงที่แล้ว';
    if (difference.inMinutes > 0) return '${difference.inMinutes} นาทีที่แล้ว';
    return 'เพิ่งเกิดขึ้น';
  }
}