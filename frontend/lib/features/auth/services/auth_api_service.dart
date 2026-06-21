// lib/features/auth/services/auth_api_service.dart - VERSION CORRIGÉE
import 'dart:convert';
import 'package:frontend/features/auth/models/forgot_password_request.dart';
import 'package:frontend/features/auth/models/login_response.dart';
import 'package:frontend/features/auth/models/two_factor_request.dart';
import 'package:http/http.dart' as http;
import 'package:frontend/core/services/api_service.dart';
import 'package:frontend/core/models/api_response.dart';
import 'package:frontend/features/auth/models/login_request.dart';

class AuthApiService {
  final ApiService _apiService = ApiService();

  // Login - Étape 1
  Future<ApiResponse<LoginResponse>> login(LoginRequest request) async {
    try {
      final response =
          await _apiService.post('/api/auth/login', request.toJson());

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final loginResponse = LoginResponse.fromJson(data);
        return ApiResponse.success(loginResponse);
      } else {
        final errorData = jsonDecode(response.body);
        return ApiResponse.error(
          errorData['error'] ?? 'Login failed',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      return ApiResponse.error('Network error: $e');
    }
  }

  // Vérifier 2FA - Étape 2
  Future<ApiResponse<LoginResponse>> verify2FA(TwoFactorRequest request) async {
    try {
      final response =
          await _apiService.post('/api/auth/2fa/verify', request.toJson());

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final loginResponse = LoginResponse.fromJson(data);
        return ApiResponse.success(loginResponse,
            statusCode: response.statusCode);
      } else {
        final errorData = jsonDecode(response.body);
        return ApiResponse.error(
          errorData['error'] ?? '2FA verification failed',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      return ApiResponse.error('Network error: $e');
    }
  }

  // Renvoyer code 2FA
  Future<ApiResponse<void>> resend2FACode(String email) async {
    try {
      final response =
          await _apiService.post('/api/auth/2fa/send', {'email': email});

      if (response.statusCode == 200) {
        return ApiResponse.success(
          null,
          message: 'Code sent successfully',
          statusCode: response.statusCode,
        );
      } else {
        final errorData = jsonDecode(response.body);
        return ApiResponse.error(
          errorData['error'] ?? 'Failed to send code',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      return ApiResponse.error('Network error: $e');
    }
  }

  // Mot de passe oublié
  Future<ApiResponse<void>> forgotPassword(
      ForgotPasswordRequest request) async {
    try {
      final response =
          await _apiService.post('/api/auth/forget-password', request.toJson());

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return ApiResponse.success(
          null,
          message: data['message'] ?? 'Password reset email sent',
          statusCode: response.statusCode,
        );
      } else {
        final errorData = jsonDecode(response.body);
        return ApiResponse.error(
          errorData['error'] ?? 'Failed to send reset email',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      return ApiResponse.error('Network error: $e');
    }
  }

  // Refresh token
  Future<ApiResponse<LoginResponse>> refreshToken(String refreshToken) async {
    try {
      final response = await _apiService.post('/api/auth/refresh-token', {
        'refreshToken': refreshToken,
      });

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final loginResponse = LoginResponse.fromJson(data);
        return ApiResponse.success(loginResponse,
            statusCode: response.statusCode);
      } else {
        final errorData = jsonDecode(response.body);
        return ApiResponse.error(
          errorData['error'] ?? 'Token refresh failed',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      return ApiResponse.error('Network error: $e');
    }
  }

  // Logout
  Future<ApiResponse<void>> logout() async {
    try {
      final response =
          await _apiService.post('/api/auth/logout', {}, requireAuth: true);

      if (response.statusCode == 200) {
        return ApiResponse.success(
          null,
          message: 'Logged out successfully',
          statusCode: response.statusCode,
        );
      } else {
        final errorData = jsonDecode(response.body);
        return ApiResponse.error(
          errorData['error'] ?? 'Logout failed',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      return ApiResponse.error('Network error: $e');
    }
  }
}
