class UserModel {
  final String id;
  final String firstName;
  final String lastName;
  final String tel;
  final String profile;
  final String role;
  final String gender;
  final int age;
  final bool firstLogin;
  final String createdAt;

  UserModel({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.tel,
    required this.profile,
    required this.role,
    required this.gender,
    required this.age,
    required this.firstLogin,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'first_name': firstName,
      'last_name': lastName,
      'tel': tel,
      'profile': profile,
      'role': role,
      'gender': gender,
      'age': age,
      'firstLogin': firstLogin,
      'created_at': createdAt,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'],
      firstName: map['first_name'],
      lastName: map['last_name'],
      tel: map['tel'],
      profile: map['profile'],
      role: map['role'],
      gender: map['gender'],
      age: map['age'],
      firstLogin: map['firstLogin'],
      createdAt: map['created_at'],
    );
  }

  UserModel copyWith({
    String? id,
    String? firstName,
    String? lastName,
    String? tel,
    String? profile,
    String? role,
    String? gender,
    int? age,
    bool? firstLogin,
    String? createdAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      tel: tel ?? this.tel,
      profile: profile ?? this.profile,
      role: role ?? this.role,
      gender: gender ?? this.gender,
      age: age ?? this.age,
      firstLogin: firstLogin ?? this.firstLogin,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
