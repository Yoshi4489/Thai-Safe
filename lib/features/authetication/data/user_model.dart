class UserModel {
  final String id;
  final String firstName;
  final String lastName;
  final String tel;
  final String role;
  final String gender;
  final int age;
  final String password;
  final String createdAt;

  UserModel({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.tel,
    required this.role,
    required this.gender,
    required this.age,
    required this.password,
    required this.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      firstName: json['first_name'],
      lastName: json['last_name'],
      tel: json['tel'],
      role: json['role'],
      gender: json['gender'],
      age: json['age'],
      password: json['password'],
      createdAt: json['created_at'],
    );
  }
}