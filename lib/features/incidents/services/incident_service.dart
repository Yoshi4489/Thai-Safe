import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../data/incident_model.dart';

class IncidentService {
  final CollectionReference<Map<String, dynamic>> _incidentsRef =
      FirebaseFirestore.instance.collection('incidents');
  
  final Reference _storageRef = FirebaseStorage.instance.ref().child('incident_proofs');

  Future<void> createIncident({
    required IncidentModel incident,
    File? imageFile,
  }) async {
    List<String> uploadedUrls = [];

    // -----------------------------------------------------------------
    // BYPASS MODE: ระหว่างรอ (ไม่ Upload จริง)
    // -----------------------------------------------------------------
    if (imageFile != null) {
      print("⚠️ BYPASS: กำลังใช้รูปจำลองแทนการอัปโหลดจริง");
      
      // ใส่ URL รูปตัวอย่างแทน (เพื่อให้แอปทำงานต่อได้โดยไม่ Crash)
      uploadedUrls.add("https://placehold.co/600x400/png?text=Mock+Image"); 
      
      // หมายเหตุ: เมื่อได้แล้ว ให้ลบ 2 บรรทัดบนออก แล้วเปิด Comment ด้านล่างนี้แทน
      
      /* // --- โค้ดจริง (เก็บไว้ใช้ตอนอัปเกรด Blaze แล้ว) ---
      try {
        final String fileName = '${incident.id}_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final Reference imageUploadRef = _storageRef.child(fileName);
        
        await imageUploadRef.putFile(imageFile);
        final String downloadUrl = await imageUploadRef.getDownloadURL();
        uploadedUrls.add(downloadUrl);
      } catch (e) {
        print('Upload Error: $e');
        // กรณี Error จะยอมให้ผ่านไปก่อน (แต่ไม่มีรูป)
      }
      */
    }
    // -----------------------------------------------------------------

    // 2. เตรียมข้อมูลบันทึก
    Map<String, dynamic> data = incident.toMap();

    // อัปเดต URL (ในที่นี้คือ URL จำลอง)
    if (uploadedUrls.isNotEmpty) {
       data['image_urls'] = uploadedUrls; 
    }

    // 3. บันทึกลง Firestore (อันนี้ฟรี ไม่ต้องใช้บัตร)
    await _incidentsRef.doc(incident.id).set(data);
  }

  Stream<List<IncidentModel>> getIncidentsStream() {
    return _incidentsRef
        .orderBy('created_at', descending: true) 
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        try {
          return IncidentModel.fromMap(doc.data());
        } catch (e) {
          print('Error parsing incident ${doc.id}: $e');
          // ดัก Error ไว้ เพื่อไม่ให้ Stream พังถ้าข้อมูลแถวใดแถวหนึ่งเสีย
          // อาจจะ return IncidentModel เปล่าๆ หรือกรองทิ้งที่ UI
          rethrow; 
        }
      }).toList();
    });
  }
}