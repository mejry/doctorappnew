// lib/features/auth/services/user_api_service.dart - MISE À JOUR pour les rôles
import 'dart:convert';
import 'package:frontend/core/models/api_response.dart';
import 'package:frontend/core/models/user.dart';
import 'package:frontend/core/services/api_service.dart';
import 'package:frontend/features/auth/models/user_request.dart';
import 'package:frontend/features/auth/models/role.dart';

class UserApiService {
  final ApiService _apiService = ApiService();

  // Get all users
  Future<ApiResponse<List<User>>> getAllUsers() async {
    try {
      final response = await _apiService.get('/api/users/', requireAuth: true);

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final List<User> users =
            data.map((json) => User.fromJson(json)).toList();

        return ApiResponse<List<User>>(
          success: true,
          data: users,
          message: 'Users retrieved successfully',
        );
      } else {
        final error = jsonDecode(response.body);
        return ApiResponse<List<User>>(
          success: false,
          error: error['error'] ?? 'Failed to fetch users',
        );
      }
    } catch (e) {
      return ApiResponse<List<User>>(
        success: false,
        error: 'Network error: $e',
      );
    }
  }

  // Get user by ID
  Future<ApiResponse<User>> getUserById(String userId) async {
    try {
      final response =
          await _apiService.get('/api/users/$userId', requireAuth: true);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final User user = User.fromJson(data);

        return ApiResponse<User>(
          success: true,
          data: user,
          message: 'User retrieved successfully',
        );
      } else {
        final error = jsonDecode(response.body);
        return ApiResponse<User>(
          success: false,
          error: error['error'] ?? 'Failed to fetch user',
        );
      }
    } catch (e) {
      return ApiResponse<User>(
        success: false,
        error: 'Network error: $e',
      );
    }
  }

  // Create new user
  Future<ApiResponse<User>> createUser(CreateUserRequest request) async {
    try {
      final response = await _apiService.post(
        '/api/users/',
        request.toJson(),
        requireAuth: true,
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final User user = User.fromJson(data);

        return ApiResponse<User>(
          success: true,
          data: user,
          message: 'User created successfully',
        );
      } else {
        final error = jsonDecode(response.body);
        return ApiResponse<User>(
          success: false,
          error: error['error'] ?? 'Failed to create user',
        );
      }
    } catch (e) {
      return ApiResponse<User>(
        success: false,
        error: 'Network error: $e',
      );
    }
  }

  // Update user
  Future<ApiResponse<User>> updateUser(
      String userId, UpdateUserRequest request) async {
    try {
      print(
          '🔄 Updating user $userId with data: ${request.toJson()}'); // Debug log

      final response = await _apiService.put(
        '/api/users/$userId',
        request.toJson(),
        requireAuth: true,
      );

      print('📝 Update response status: ${response.statusCode}'); // Debug log
      print('📝 Update response body: ${response.body}'); // Debug log

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final User user = User.fromJson(data);

        return ApiResponse<User>(
          success: true,
          data: user,
          message: 'User updated successfully',
        );
      } else {
        final error = jsonDecode(response.body);
        return ApiResponse<User>(
          success: false,
          error: error['error'] ?? 'Failed to update user',
        );
      }
    } catch (e) {
      return ApiResponse<User>(
        success: false,
        error: 'Network error: $e',
      );
    }
  }

  // Delete user
  Future<ApiResponse<void>> deleteUser(String userId) async {
    try {
      final response =
          await _apiService.delete('/api/users/$userId', requireAuth: true);

      if (response.statusCode == 200) {
        return ApiResponse<void>(
          success: true,
          message: 'User deleted successfully',
        );
      } else {
        final error = jsonDecode(response.body);
        return ApiResponse<void>(
          success: false,
          error: error['error'] ?? 'Failed to delete user',
        );
      }
    } catch (e) {
      return ApiResponse<void>(
        success: false,
        error: 'Network error: $e',
      );
    }
  }

  // Toggle user status (activate/deactivate)
  Future<ApiResponse<User>> toggleUserStatus(String userId) async {
    try {
      final response = await _apiService.put(
        '/api/users/$userId/status',
        {},
        requireAuth: true,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final User user = User.fromJson(data['user']);

        return ApiResponse<User>(
          success: true,
          data: user,
          message: data['message'] ?? 'User status updated',
        );
      } else {
        final error = jsonDecode(response.body);
        return ApiResponse<User>(
          success: false,
          error: error['error'] ?? 'Failed to update user status',
        );
      }
    } catch (e) {
      return ApiResponse<User>(
        success: false,
        error: 'Network error: $e',
      );
    }
  }

  // Get all roles (for user creation/editing) - ROUTE CORRIGÉE
  Future<ApiResponse<List<Role>>> getAllRoles() async {
    try {
      final response = await _apiService.get('/api/auth/roles',
          requireAuth: true); // Changé vers /api/auth/roles

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final List<Role> roles =
            data.map((json) => Role.fromJson(json)).toList();

        return ApiResponse<List<Role>>(
          success: true,
          data: roles,
          message: 'Roles retrieved successfully',
        );
      } else {
        final error = jsonDecode(response.body);
        return ApiResponse<List<Role>>(
          success: false,
          error: error['error'] ?? 'Failed to fetch roles',
        );
      }
    } catch (e) {
      return ApiResponse<List<Role>>(
        success: false,
        error: 'Network error: $e',
      );
    }
  }

// Change user password (by admin)
  Future<ApiResponse<void>> changeUserPassword({
    required String userId,
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    try {
      final response = await _apiService.put(
        '/api/users/$userId/password',
        {
          'currentPassword': currentPassword,
          'newPassword': newPassword,
          'confirmPassword': confirmPassword,
        },
        requireAuth: true,
      );

      if (response.statusCode == 200) {
        return ApiResponse<void>(
          success: true,
          message: 'Password changed successfully',
        );
      } else {
        final error = jsonDecode(response.body);
        return ApiResponse<void>(
          success: false,
          error: error['error'] ?? 'Failed to change password',
        );
      }
    } catch (e) {
      return ApiResponse<void>(
        success: false,
        error: 'Network error: $e',
      );
    }
  }

// Change own password
  Future<ApiResponse<void>> changeOwnPassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    try {
      final response = await _apiService.put(
        '/api/users/me/password/',
        {
          'currentPassword': currentPassword,
          'newPassword': newPassword,
          'confirmPassword': confirmPassword,
        },
        requireAuth: true,
      );

      if (response.statusCode == 200) {
        return ApiResponse<void>(
          success: true,
          message: 'Password changed successfully',
        );
      } else {
        final error = jsonDecode(response.body);
        return ApiResponse<void>(
          success: false,
          error: error['error'] ?? 'Failed to change password',
        );
      }
    } catch (e) {
      return ApiResponse<void>(
        success: false,
        error: 'Network error: $e',
      );
    }
  }
}
