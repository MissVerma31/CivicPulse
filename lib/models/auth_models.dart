class RegisterRequest {
  final String name;
  final String email;
  final String phoneNumber;
  final String city;
  final String ward;
  final String password;

  RegisterRequest({
    required this.name,
    required this.email,
    required this.phoneNumber,
    required this.city,
    required this.ward,
    required this.password,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'email': email,
    'phoneNumber': phoneNumber,
    'city': city,
    'ward': ward,
    'password': password,
  };
}

class LoginRequest {
  final String email;
  final String password;

  LoginRequest({required this.email, required this.password});

  Map<String, dynamic> toJson() => {'email': email, 'password': password};
}

class UserResponse {
  final int id;
  final String name;
  final String email;
  final String phoneNumber;
  final String city;
  final String ward;
  final String role;
  final String? department;
  final int reputationPoints;
  final DateTime createdAt;

  UserResponse({
    required this.id,
    required this.name,
    required this.email,
    required this.phoneNumber,
    required this.city,
    required this.ward,
    required this.role,
    this.department,
    required this.reputationPoints,
    required this.createdAt,
  });

  factory UserResponse.fromJson(Map<String, dynamic> json) => UserResponse(
    id: json['id'],
    name: json['name'] ?? '',
    email: json['email'] ?? '',
    phoneNumber: json['phoneNumber'] ?? '',
    city: json['city'] ?? '',
    ward: json['ward'] ?? '',
    role: json['role'] ?? '',
    department: json['department'],
    reputationPoints: json['reputationPoints'] ?? 0,
    createdAt: DateTime.parse(json['createdAt']),
  );
}