import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:thai_safe/features/rescue_approval/data/resque_request_model.dart';

enum RescueRequestStatus { pending, approved, rejected }

class RescueApprovalService {
  final CollectionReference<Map<String, dynamic>> _requestRef =
      FirebaseFirestore.instance.collection('rescue_requests');
  
  // อ้างอิงไปยัง Collection Users
  final CollectionReference<Map<String, dynamic>> _userRef =
      FirebaseFirestore.instance.collection('users');

// 1. ฟังก์ชันสำหรับให้ User ส่งคำขอ
  Future<void> createRescueRequest({
    required String userId,
    required String name,
    required String phone,
  }) async {
    // เช็คก่อนว่าเคยส่งคำขอที่กำลังรออนุมัติอยู่แล้วหรือไม่
    final existing = await _requestRef
        .where('userId', isEqualTo: userId)
        .where('status', isEqualTo: RescueRequestStatus.pending.name)
        .get();

    if (existing.docs.isNotEmpty) {
      throw Exception('คุณได้ส่งคำขอไปแล้ว กรุณารอการอนุมัติ');
    }

    // 1. สร้าง Document Reference ขึ้นมาก่อน เพื่อสุ่มรับ ID จาก Firebase
    final newDocRef = _requestRef.doc();

    // 2. นำ newDocRef.id ใส่เข้าไปเป็นฟิลด์ในข้อมูลด้วย
    await newDocRef.set({
      'id': newDocRef.id,          // เพิ่มฟิลด์ id ตาม Model
      'userId': userId,
      'name': name,
      'phone': phone,
      'status': RescueRequestStatus.pending.name,
      'created_at': FieldValue.serverTimestamp(),
      'reviewed_by': null,         // ส่งค่าว่างไปก่อนตามโครงสร้าง
      'reviewed_at': null,         // ส่งค่าว่างไปก่อนตามโครงสร้าง
    });
  }

  Stream<List<RescueRequestModel>> getRescueRequests() {
    return _requestRef
        .where("status", isEqualTo: RescueRequestStatus.pending.name)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => RescueRequestModel.fromMap(doc.data(), doc.id))
              .toList();
        });
  }

  // 2. อัปเดตฟังก์ชันอนุมัติ ให้เปลี่ยน Role ของ User
  Future<void> approveRescueRequest(String requestId, String reviewerId, String userId) async {
    // ใช้ WriteBatch เพื่อให้มั่นใจว่าข้อมูลอัปเดตพร้อมกันทั้ง 2 ที่
    WriteBatch batch = FirebaseFirestore.instance.batch();

    // อัปเดตสถานะคำขอ
    DocumentReference requestDoc = _requestRef.doc(requestId);
    batch.update(requestDoc, {
      'status': RescueRequestStatus.approved.name,
      "reviewedBy": reviewerId,
      "reviewedAt": FieldValue.serverTimestamp(),
    });

    // อัปเดต Role ของผู้ใช้เป็น 'rescue'
    DocumentReference userDoc = _userRef.doc(userId);
    batch.update(userDoc, {
      'role': 'rescue', 
    });

    await batch.commit();
  }

  Future<void> rejectRescueRequest(String requestId, String reviewerId) async {
    await _requestRef.doc(requestId).update({
      'status': RescueRequestStatus.rejected.name,
      "reviewedBy": reviewerId,
      "reviewedAt": FieldValue.serverTimestamp(),
    });
  }
}