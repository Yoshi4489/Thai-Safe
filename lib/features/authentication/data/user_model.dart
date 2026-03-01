import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String id;
  final String firstName;
  final String lastName;
  final String tel;
  final String profile_url;
  final String role;
  final String gender;
  final DateTime birthdate;
  final bool firstLogin;
  final DateTime createdAt;

  UserModel({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.tel,
    required this.profile_url,
    required this.role,
    required this.gender,
    required this.birthdate,
    required this.firstLogin,
    required this.createdAt,
  });

  /// 🔹 Save to Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'first_name': firstName,
      'last_name': lastName,
      'tel': tel,
      'profile_url': profile_url,
      'role': role,
      'gender': gender,
      'birthdate': Timestamp.fromDate(birthdate),
      'firstLogin': firstLogin,
      'created_at': Timestamp.fromDate(createdAt),
    };
  }

  /// 🔹 Read from Firestore
 factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      // ใช้ ?? เพื่อบอกว่าถ้าข้อมูลเป็น null ให้ใช้ค่าว่าง (หรือค่า Default) แทน
      id: map['id'] ?? '',
      firstName: map['first_name'] ?? '',
      lastName: map['last_name'] ?? '',
      tel: map['tel'] ?? '',
      profile_url: map['profile_url'] ?? '',
      role: map['role'] ?? 'user', // ตั้งค่าเริ่มต้นเป็น user
      gender: map['gender'] ?? '',
      
      // จัดการ Timestamp อย่างปลอดภัย
      birthdate: map['birthdate'] != null 
          ? (map['birthdate'] as Timestamp).toDate() 
          : DateTime.now(), // ถ้าไม่มีวันเกิด ให้ใส่วันนี้ไปก่อน
          
      firstLogin: map['firstLogin'] ?? true, // ถ้าไม่มีข้อมูล ให้ถือว่าเพิ่งล็อกอินครั้งแรก
      
      createdAt: map['created_at'] != null 
          ? (map['created_at'] as Timestamp).toDate() 
          : DateTime.now(),
    );
  }

  UserModel copyWith({
    String? id,
    String? firstName,
    String? lastName,
    String? tel,
    String? profile_url,
    String? role,
    String? gender,
    DateTime? birthdate,
    bool? firstLogin,
    DateTime? createdAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      tel: tel ?? this.tel,
      profile_url: profile_url ?? this.profile_url,
      role: role ?? this.role,
      gender: gender ?? this.gender,
      birthdate: birthdate ?? this.birthdate,
      firstLogin: firstLogin ?? this.firstLogin,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
