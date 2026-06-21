import 'package:frontend/core/models/user.dart';

class UserListResponse {
  final List<User> users;
  final int total;
  final String? message;

  UserListResponse({
    required this.users,
    required this.total,
    this.message,
  });

  factory UserListResponse.fromJson(Map<String, dynamic> json) {
    return UserListResponse(
      users:
          (json['users'] as List?)?.map((u) => User.fromJson(u)).toList() ?? [],
      total: json['total'] ?? 0,
      message: json['message'],
    );
  }
}

class UserResponse {
  final User user;
  final String? message;

  UserResponse({
    required this.user,
    this.message,
  });

  factory UserResponse.fromJson(Map<String, dynamic> json) {
    return UserResponse(
      user: User.fromJson(json['user'] ?? json),
      message: json['message'],
    );
  }
}
