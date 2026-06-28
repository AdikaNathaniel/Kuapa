enum UserRole { FARMER, BUYER, TRANSPORTER, ADMIN }

class AuthUser {
  final String id;
  final String? email;
  final String? phone;
  final String? username;
  final UserRole role;

  const AuthUser({required this.id, this.email, this.phone, this.username, required this.role});

  factory AuthUser.fromJson(Map<String, dynamic> json) => AuthUser(
        id: json['id'],
        email: json['email'],
        phone: json['phone'],
        username: json['username'],
        role: UserRole.values.firstWhere(
          (r) => r.name == json['role'],
          orElse: () => UserRole.BUYER,
        ),
      );

  Map<String, dynamic> toJson() => {'id': id, 'email': email, 'phone': phone, 'username': username, 'role': role.name};

  String get displayName => username ?? email ?? phone ?? 'User';
}

class AuthResponse {
  final String accessToken;
  final String refreshToken;
  final AuthUser user;

  const AuthResponse({required this.accessToken, required this.refreshToken, required this.user});

  factory AuthResponse.fromJson(Map<String, dynamic> json) => AuthResponse(
        accessToken: json['accessToken'],
        refreshToken: json['refreshToken'],
        user: AuthUser.fromJson(json['user']),
      );
}
