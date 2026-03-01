class UserModel {
  final String uid;
  final String email;
  final String role; // 'victim' or 'ngo'
  final String name;

  UserModel({
    required this.uid,
    required this.email,
    required this.role,
    required this.name,
  });

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'role': role,
      'name': name,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map, String uid) {
    return UserModel(
      uid: uid,
      email: map['email'] ?? '',
      role: map['role'] ?? 'victim',
      name: map['name'] ?? '',
    );
  }
}
