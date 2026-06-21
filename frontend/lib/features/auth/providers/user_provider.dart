// lib/features/auth/providers/user_provider.dart - Version avec support multi-rôles
import 'package:flutter/foundation.dart';
import 'package:frontend/core/models/user.dart';
import 'package:frontend/features/auth/models/role.dart';
import 'package:frontend/features/auth/models/user_request.dart';
import 'package:frontend/features/auth/services/user_api_service.dart';

enum UserManagementStatus {
  initial,
  loading,
  success,
  error,
}

class UserProvider with ChangeNotifier {
  final UserApiService _userApiService = UserApiService();

  UserManagementStatus _status = UserManagementStatus.initial;
  List<User> _users = [];
  List<Role> _roles = [];
  String? _errorMessage;
  bool _isLoading = false;

  // Getters
  UserManagementStatus get status => _status;
  List<User> get users => List.unmodifiable(_users);
  List<Role> get roles => List.unmodifiable(_roles);
  String? get errorMessage => _errorMessage;
  bool get isLoading => _isLoading;

  // Load all users
  Future<void> loadUsers() async {
    try {
      _setLoading(true);
      _clearError();

      final response = await _userApiService.getAllUsers();

      if (response.success && response.data != null) {
        _users = response.data!;
        _setStatus(UserManagementStatus.success);
        debugPrint('Users loaded successfully: ${_users.length} users');
      } else {
        _setError(response.error ?? 'Failed to load users');
      }
    } catch (e) {
      _setError('Error loading users: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Load all roles
  Future<void> loadRoles() async {
    try {
      final response = await _userApiService.getAllRoles();

      if (response.success && response.data != null) {
        _roles = List.from(response.data!);
        debugPrint('Roles loaded successfully: ${_roles.length} roles');
        notifyListeners();
      } else {
        debugPrint('Failed to load roles: ${response.error}');
      }
    } catch (e) {
      debugPrint('Error loading roles: $e');
    }
  }

  // ✅ UPDATED: Create new user with multi-role support
  Future<bool> createUser({
    required String email,
    required String password,
    required String firstname,
    required String lastname,
    String? specialite,
    required String roleId,
    List<String>? additionalRoleIds,
    bool? active,
  }) async {
    try {
      _setLoading(true);
      _clearError();

      debugPrint('🔄 Creating user with:');
      debugPrint('   Email: $email');
      debugPrint('   Name: $firstname $lastname');
      debugPrint('   Primary Role: $roleId');
      debugPrint('   Additional Roles: $additionalRoleIds');
      debugPrint('   Active: $active');

      final request = CreateUserRequest(
        email: email,
        password: password,
        firstname: firstname,
        lastname: lastname,
        specialite: specialite,
        role: roleId,
        additionalRoles: additionalRoleIds,
        active: active,
      );

      final response = await _userApiService.createUser(request);

      if (response.success && response.data != null) {
        _users.add(response.data!);
        _setStatus(UserManagementStatus.success);
        notifyListeners();
        debugPrint('✅ User created successfully: ${response.data!.email}');
        return true;
      } else {
        _setError(response.error ?? 'Failed to create user');
        debugPrint('❌ Failed to create user: ${response.error}');
        return false;
      }
    } catch (e) {
      _setError('Error creating user: $e');
      debugPrint('❌ Error creating user: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ✅ UPDATED: Update user with multi-role support
  Future<bool> updateUser({
    required String userId,
    String? email,
    String? firstname,
    String? lastname,
    String? specialite,
    String? roleId,
    List<String>? additionalRoleIds,
    bool? active,
  }) async {
    try {
      _setLoading(true);
      _clearError();

      final request = UpdateUserRequest(
        email: email,
        firstname: firstname,
        lastname: lastname,
        specialite: specialite,
        role: roleId,
        additionalRoles: additionalRoleIds,
        active: active,
      );

      final response = await _userApiService.updateUser(userId, request);

      if (response.success && response.data != null) {
        // Update the user in the list
        final index = _users.indexWhere((u) => u.id == userId);
        if (index != -1) {
          _users[index] = response.data!;
        }
        _setStatus(UserManagementStatus.success);
        notifyListeners(); // This is crucial!
        return true;
      } else {
        _setError(response.error ?? 'Failed to update user');
        return false;
      }
    } catch (e) {
      _setError('Error updating user: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> changeUserPassword({
    required String userId,
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    try {
      _setLoading(true);
      _clearError();

      final response = await _userApiService.changeUserPassword(
        userId: userId,
        currentPassword: currentPassword,
        newPassword: newPassword,
        confirmPassword: confirmPassword,
      );

      if (response.success) {
        _setStatus(UserManagementStatus.success);
        debugPrint('Password changed successfully for user: $userId');
        return true;
      } else {
        _setError(response.error ?? 'Failed to change password');
        return false;
      }
    } catch (e) {
      _setError('Error changing password: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

// Change own password
  Future<bool> changeOwnPassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    try {
      _setLoading(true);
      _clearError();

      final response = await _userApiService.changeOwnPassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
        confirmPassword: confirmPassword,
      );

      if (response.success) {
        _setStatus(UserManagementStatus.success);
        debugPrint('Own password changed successfully');
        return true;
      } else {
        _setError(response.error ?? 'Failed to change password');
        return false;
      }
    } catch (e) {
      _setError('Error changing password: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Delete user
  Future<bool> deleteUser(String userId) async {
    try {
      _setLoading(true);
      _clearError();

      final response = await _userApiService.deleteUser(userId);

      if (response.success) {
        _users.removeWhere((u) => u.id == userId);
        _setStatus(UserManagementStatus.success);
        notifyListeners();
        debugPrint('User deleted successfully');
        return true;
      } else {
        _setError(response.error ?? 'Failed to delete user');
        return false;
      }
    } catch (e) {
      _setError('Error deleting user: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Toggle user status
  Future<bool> toggleUserStatus(String userId) async {
    try {
      _setLoading(true);
      _clearError();

      final response = await _userApiService.toggleUserStatus(userId);

      if (response.success && response.data != null) {
        final index = _users.indexWhere((u) => u.id == userId);
        if (index != -1) {
          _users[index] = response.data!;
          notifyListeners();
        }
        _setStatus(UserManagementStatus.success);
        debugPrint('User status toggled successfully');
        return true;
      } else {
        _setError(response.error ?? 'Failed to toggle user status');
        return false;
      }
    } catch (e) {
      _setError('Error toggling user status: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Get user by ID
  User? getUserById(String userId) {
    try {
      return _users.firstWhere((u) => u.id == userId);
    } catch (e) {
      return null;
    }
  }

  // Get role by ID
  Role? getRoleById(String roleId) {
    try {
      return _roles.firstWhere((r) => r.id == roleId);
    } catch (e) {
      return null;
    }
  }

  // ✅ NEW: Get role by name
  Role? getRoleByName(String roleName) {
    try {
      return _roles.firstWhere((r) => r.name == roleName);
    } catch (e) {
      return null;
    }
  }

  // ✅ NEW: Get multiple roles by IDs
  List<Role> getRolesByIds(List<String> roleIds) {
    return _roles.where((role) => roleIds.contains(role.id)).toList();
  }

  // Search users
  List<User> searchUsers(String query) {
    if (query.isEmpty) return _users;

    final lowerQuery = query.toLowerCase();
    return _users.where((user) {
      return user.firstname.toLowerCase().contains(lowerQuery) ||
          user.lastname.toLowerCase().contains(lowerQuery) ||
          user.email.toLowerCase().contains(lowerQuery) ||
          user.role.toLowerCase().contains(lowerQuery);
    }).toList();
  }

  // Filter users by role
  List<User> getUsersByRole(String role) {
    return _users
        .where((user) => user.role.toLowerCase() == role.toLowerCase())
        .toList();
  }

  // ✅ NEW: Filter users by multiple roles
  List<User> getUsersByRoles(List<String> roles) {
    final lowerRoles = roles.map((r) => r.toLowerCase()).toList();
    return _users.where((user) {
      return lowerRoles.contains(user.role.toLowerCase()) ||
          user.allRoleNames
              .any((roleName) => lowerRoles.contains(roleName.toLowerCase()));
    }).toList();
  }

  // Get active users
  List<User> get activeUsers => _users.where((user) => user.active).toList();

  // Get inactive users
  List<User> get inactiveUsers => _users.where((user) => !user.active).toList();

  // ✅ NEW: Get users by speciality
  List<User> getUsersBySpeciality(String speciality) {
    return _users
        .where((user) =>
            user.specialite?.toLowerCase() == speciality.toLowerCase())
        .toList();
  }

  // ✅ NEW: Get all specialities
  List<String> get allSpecialities {
    final specialities = _users
        .where((user) => user.specialite != null && user.specialite!.isNotEmpty)
        .map((user) => user.specialite!)
        .toSet()
        .toList();
    specialities.sort();
    return specialities;
  }

  // Helper methods
  void _setStatus(UserManagementStatus status) {
    _status = status;
    notifyListeners();
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    _status = UserManagementStatus.error;
    debugPrint('User management error: $error');
  }

  void _clearError() {
    _errorMessage = null;
  }

  // Clear all data
  void clear() {
    _users.clear();
    _roles.clear();
    _status = UserManagementStatus.initial;
    _errorMessage = null;
    _isLoading = false;
    notifyListeners();
  }
}
