class AuthUser {
  final int userId;
  final String fullName;
  final String email;
  final String role;

  const AuthUser({
    required this.userId,
    required this.fullName,
    required this.email,
    required this.role,
  });

  bool get isAdmin => role == 'admin';

  bool get isOperator => role == 'operator';

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    final userId = json['user_id'];
    final fullName = json['full_name'];
    final email = json['email'];
    final role = json['role'];

    if (userId is! int || userId <= 0) {
      throw const FormatException('Invalid user ID.');
    }

    if (fullName is! String || fullName.trim().isEmpty) {
      throw const FormatException('Invalid user name.');
    }

    if (email is! String || email.trim().isEmpty) {
      throw const FormatException('Invalid email address.');
    }

    if (role != 'admin' && role != 'operator') {
      throw const FormatException('Invalid user role.');
    }

    return AuthUser(
      userId: userId,
      fullName: fullName,
      email: email,
      role: role as String,
    );
  }
}

class AuthSession {
  final String accessToken;
  final DateTime expiresAt;
  final AuthUser user;

  const AuthSession({
    required this.accessToken,
    required this.expiresAt,
    required this.user,
  });

  bool get isExpired => !DateTime.now().isBefore(expiresAt);

  factory AuthSession.fromJson(Map<String, dynamic> json) {
    final token = json['access_token'];
    final tokenType = json['token_type'];
    final expiresIn = json['expires_in'];
    final userData = json['user'];

    if (token is! String || token.trim().isEmpty) {
      throw const FormatException('Invalid access token.');
    }

    if (tokenType is! String || tokenType.toLowerCase() != 'bearer') {
      throw const FormatException('Invalid token type.');
    }

    if (expiresIn is! int || expiresIn <= 0) {
      throw const FormatException('Invalid session duration.');
    }

    if (userData is! Map<String, dynamic>) {
      throw const FormatException('Invalid user information.');
    }

    return AuthSession(
      accessToken: token,
      expiresAt: DateTime.now().add(Duration(seconds: expiresIn)),
      user: AuthUser.fromJson(userData),
    );
  }
}
