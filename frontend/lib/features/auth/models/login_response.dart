import 'package:frontend/core/models/user.dart';

class LoginResponse {
  final String? accessToken;
  final String? refreshToken;
  final String? serviceToken;
  final User? user;
  final bool? twoFactorRequired;
  final String? userId;
  final String? message;

  LoginResponse({
    this.accessToken,
    this.refreshToken,
    this.serviceToken,
    this.user,
    this.twoFactorRequired,
    this.userId,
    this.message,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      accessToken: json['accessToken'],
      refreshToken: json['refreshToken'],
      serviceToken: json['serviceToken'],
      user: json['user'] != null ? User.fromJson(json['user']) : null,
      twoFactorRequired: json['twoFactorRequired'],
      userId: json['userId'],
      message: json['message'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'accessToken': accessToken,
      'refreshToken': refreshToken,
      'serviceToken': serviceToken,
      'user': user?.toJson(),
      'twoFactorRequired': twoFactorRequired,
      'userId': userId,
      'message': message,
    };
  }
}
