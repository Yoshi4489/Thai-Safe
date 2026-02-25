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
  final String createdAt;

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

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'first_name': firstName,
      'last_name': lastName,
      'tel': tel,
      'profile_url': profile_url,
      'role': role,
      'gender': gender,
      'birthdate': birthdate,
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
      profile_url: map['profile_url'],
      role: map['role'],
      gender: map['gender'],
      birthdate: DateTime.parse(map['birthdate']),
      firstLogin: map['firstLogin'],
      createdAt: map['created_at'],
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
    String? createdAt,
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
