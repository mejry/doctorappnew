// lib/features/auth/services/role_api_service.dart - Version complète et corrigée
import 'dart:convert';
import 'package:frontend/core/models/api_response.dart';
import 'package:frontend/core/services/api_service.dart';
import 'package:frontend/features/auth/models/role.dart';
import 'package:frontend/core/models/user.dart';

class RoleApiService {
  final ApiService _apiService = ApiService();

  // Get all roles
  Future<ApiResponse<List<Role>>> getAllRoles() async {
    try {
      final response =
          await _apiService.get('/api/auth/roles', requireAuth: true);

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

  // ✅ Get all users with their roles
  Future<ApiResponse<List<User>>> getAllUsersWithRoles() async {
    try {
      final response = await _apiService.get('/api/auth/users-with-roles',
          requireAuth: true);

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

  // Get role by ID
  Future<ApiResponse<Role>> getRoleById(String roleId) async {
    try {
      final response =
          await _apiService.get('/api/auth/roles/$roleId', requireAuth: true);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final Role role = Role.fromJson(data);

        return ApiResponse<Role>(
          success: true,
          data: role,
          message: 'Role retrieved successfully',
        );
      } else {
        final error = jsonDecode(response.body);
        return ApiResponse<Role>(
          success: false,
          error: error['error'] ?? 'Failed to fetch role',
        );
      }
    } catch (e) {
      return ApiResponse<Role>(
        success: false,
        error: 'Network error: $e',
      );
    }
  }

  // Create new role
  Future<ApiResponse<Role>> createRole(CreateRoleRequest request) async {
    try {
      final response = await _apiService.post(
        '/api/auth/roles',
        request.toJson(),
        requireAuth: true,
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final Role role = Role.fromJson(data);

        return ApiResponse<Role>(
          success: true,
          data: role,
          message: 'Role created successfully',
        );
      } else {
        final error = jsonDecode(response.body);
        return ApiResponse<Role>(
          success: false,
          error: error['error'] ?? 'Failed to create role',
        );
      }
    } catch (e) {
      return ApiResponse<Role>(
        success: false,
        error: 'Network error: $e',
      );
    }
  }

  // Update role
  Future<ApiResponse<Role>> updateRole(
      String roleId, UpdateRoleRequest request) async {
    try {
      final response = await _apiService.put(
        '/api/auth/roles/$roleId',
        request.toJson(),
        requireAuth: true,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final Role role = Role.fromJson(data);

        return ApiResponse<Role>(
          success: true,
          data: role,
          message: 'Role updated successfully',
        );
      } else {
        final error = jsonDecode(response.body);
        return ApiResponse<Role>(
          success: false,
          error: error['error'] ?? 'Failed to update role',
        );
      }
    } catch (e) {
      return ApiResponse<Role>(
        success: false,
        error: 'Network error: $e',
      );
    }
  }

  // Delete role
  Future<ApiResponse<void>> deleteRole(String roleId) async {
    try {
      final response = await _apiService.delete('/api/auth/roles/$roleId',
          requireAuth: true);

      if (response.statusCode == 200) {
        return ApiResponse<void>(
          success: true,
          message: 'Role deleted successfully',
        );
      } else {
        final error = jsonDecode(response.body);
        return ApiResponse<void>(
          success: false,
          error: error['error'] ?? 'Failed to delete role',
        );
      }
    } catch (e) {
      return ApiResponse<void>(
        success: false,
        error: 'Network error: $e',
      );
    }
  }

  // Get all available permissions
  Future<ApiResponse<List<String>>> getAllPermissions() async {
    try {
      final response =
          await _apiService.get('/api/auth/permissions', requireAuth: true);

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final List<String> permissions = List<String>.from(data);

        return ApiResponse<List<String>>(
          success: true,
          data: permissions,
          message: 'Permissions retrieved successfully',
        );
      } else {
        final error = jsonDecode(response.body);
        return ApiResponse<List<String>>(
          success: false,
          error: error['error'] ?? 'Failed to fetch permissions',
        );
      }
    } catch (e) {
      return ApiResponse<List<String>>(
        success: false,
        error: 'Network error: $e',
      );
    }
  }

  // ✅ Assign additional role to user
  Future<ApiResponse<void>> assignRoleToUser({
    required String userId,
    required String roleId,
  }) async {
    try {
      final response = await _apiService.post(
        '/api/auth/assign-role',
        {
          'userId': userId,
          'roleId': roleId,
        },
        requireAuth: true,
      );

      if (response.statusCode == 200) {
        return ApiResponse<void>(
          success: true,
          message: 'Role assigned successfully',
        );
      } else {
        final error = jsonDecode(response.body);
        return ApiResponse<void>(
          success: false,
          error: error['error'] ?? 'Failed to assign role',
        );
      }
    } catch (e) {
      return ApiResponse<void>(
        success: false,
        error: 'Network error: $e',
      );
    }
  }

  // ✅ Remove role from user
  Future<ApiResponse<void>> removeRoleFromUser({
    required String userId,
    required String roleId,
  }) async {
    try {
      final response = await _apiService.post(
        '/api/auth/remove-role',
        {
          'userId': userId,
          'roleId': roleId,
        },
        requireAuth: true,
      );

      if (response.statusCode == 200) {
        return ApiResponse<void>(
          success: true,
          message: 'Role removed successfully',
        );
      } else {
        final error = jsonDecode(response.body);
        return ApiResponse<void>(
          success: false,
          error: error['error'] ?? 'Failed to remove role',
        );
      }
    } catch (e) {
      return ApiResponse<void>(
        success: false,
        error: 'Network error: $e',
      );
    }
  }

  // ✅ Bulk assign users to role
  Future<ApiResponse<void>> bulkAssignUsersToRole({
    required List<String> userIds,
    required String roleId,
  }) async {
    try {
      final response = await _apiService.post(
        '/api/auth/bulk-assign-role',
        {
          'userIds': userIds,
          'roleId': roleId,
        },
        requireAuth: true,
      );

      if (response.statusCode == 200) {
        return ApiResponse<void>(
          success: true,
          message: 'Users assigned successfully',
        );
      } else {
        final error = jsonDecode(response.body);
        return ApiResponse<void>(
          success: false,
          error: error['error'] ?? 'Failed to assign users',
        );
      }
    } catch (e) {
      return ApiResponse<void>(
        success: false,
        error: 'Network error: $e',
      );
    }
  }

  // ✅ Get users assigned to a specific role
  Future<ApiResponse<Map<String, dynamic>>> getUsersByRole(
      String roleId) async {
    try {
      final response = await _apiService.get('/api/auth/roles/$roleId/users',
          requireAuth: true);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        return ApiResponse<Map<String, dynamic>>(
          success: true,
          data: data,
          message: 'Users by role retrieved successfully',
        );
      } else {
        final error = jsonDecode(response.body);
        return ApiResponse<Map<String, dynamic>>(
          success: false,
          error: error['error'] ?? 'Failed to fetch users by role',
        );
      }
    } catch (e) {
      return ApiResponse<Map<String, dynamic>>(
        success: false,
        error: 'Network error: $e',
      );
    }
  }

  // ✅ Add permission to role
  Future<ApiResponse<Role>> addPermissionToRole({
    required String roleId,
    required String permission,
  }) async {
    try {
      final response = await _apiService.post(
        '/api/auth/roles/$roleId/permissions',
        {'permission': permission},
        requireAuth: true,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final Role role = Role.fromJson(data);

        return ApiResponse<Role>(
          success: true,
          data: role,
          message: 'Permission added successfully',
        );
      } else {
        final error = jsonDecode(response.body);
        return ApiResponse<Role>(
          success: false,
          error: error['error'] ?? 'Failed to add permission',
        );
      }
    } catch (e) {
      return ApiResponse<Role>(
        success: false,
        error: 'Network error: $e',
      );
    }
  }

  // ✅ Remove permission from role
  Future<ApiResponse<Role>> removePermissionFromRole({
    required String roleId,
    required String permission,
  }) async {
    try {
      final response = await _apiService.delete(
        '/api/auth/roles/$roleId/permissions/$permission',
        requireAuth: true,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final Role role = Role.fromJson(data);

        return ApiResponse<Role>(
          success: true,
          data: role,
          message: 'Permission removed successfully',
        );
      } else {
        final error = jsonDecode(response.body);
        return ApiResponse<Role>(
          success: false,
          error: error['error'] ?? 'Failed to remove permission',
        );
      }
    } catch (e) {
      return ApiResponse<Role>(
        success: false,
        error: 'Network error: $e',
      );
    }
  }
}
