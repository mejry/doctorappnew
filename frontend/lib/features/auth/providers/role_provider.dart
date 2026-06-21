// lib/features/auth/providers/role_provider.dart - FIX SIMPLE POUR MEDICATION
import 'package:flutter/foundation.dart';
import 'package:frontend/features/auth/models/role.dart';
import 'package:frontend/features/auth/services/role_api_service.dart';
import 'package:frontend/core/models/user.dart';

enum RoleManagementStatus {
  initial,
  loading,
  success,
  error,
}

class RoleProvider with ChangeNotifier {
  final RoleApiService _roleApiService = RoleApiService();

  RoleManagementStatus _status = RoleManagementStatus.initial;
  List<Role> _roles = [];
  List<User> _users = [];
  List<String> _allPermissions = [];
  String? _errorMessage;
  bool _isLoading = false;

  // Getters
  RoleManagementStatus get status => _status;
  List<Role> get roles => List.unmodifiable(_roles);
  List<User> get users => List.unmodifiable(_users);
  List<String> get allPermissions => List.unmodifiable(_allPermissions);
  String? get errorMessage => _errorMessage;
  bool get isLoading => _isLoading;

  // ✅ Load all roles avec leurs utilisateurs assignés
  Future<void> loadRoles() async {
    try {
      _setLoading(true);
      _clearError();

      final response = await _roleApiService.getAllRoles();

      if (response.success && response.data != null) {
        _roles = response.data!;
        _setStatus(RoleManagementStatus.success);
        debugPrint('Roles loaded successfully: ${_roles.length} roles');

        // ✅ Charger aussi les utilisateurs
        await loadUsers();
      } else {
        _setError(response.error ?? 'Failed to load roles');
      }
    } catch (e) {
      _setError('Error loading roles: $e');
    } finally {
      _setLoading(false);
    }
  }

  // ✅ Load all users with their roles
  Future<void> loadUsers() async {
    try {
      final response = await _roleApiService.getAllUsersWithRoles();

      if (response.success && response.data != null) {
        _users = response.data!;
        debugPrint('Users loaded successfully: ${_users.length} users');
        notifyListeners();
      } else {
        debugPrint('Failed to load users: ${response.error}');
      }
    } catch (e) {
      debugPrint('Error loading users: $e');
    }
  }

  // ✅ CORRIGÉ: Load all available permissions AVEC MEDICATION TOUJOURS INCLUS
  Future<void> loadPermissions() async {
    try {
      debugPrint('🔄 Loading permissions from API...');
      final response = await _roleApiService.getAllPermissions();

      if (response.success &&
          response.data != null &&
          response.data!.isNotEmpty) {
        _allPermissions = response.data!;
        debugPrint(
            '✅ Permissions loaded from API: ${_allPermissions.length} permissions');
      } else {
        debugPrint(
            '⚠️ API returned empty or failed, using default permissions');
        _allPermissions = [];
      }

      // ✅ TOUJOURS AJOUTER LES PERMISSIONS PAR DÉFAUT INCLUANT MEDICATION
      _ensureAllDefaultPermissions();

      debugPrint('📋 Final permissions count: ${_allPermissions.length}');
      debugPrint(
          '💊 Medication permissions: ${_allPermissions.where((p) => p.contains('medication')).toList()}');
    } catch (e) {
      debugPrint('❌ Error loading permissions: $e');
      _allPermissions = [];
      _ensureAllDefaultPermissions();
    }

    notifyListeners();
  }

  // ✅ NOUVELLE MÉTHODE: S'assurer que TOUTES les permissions par défaut sont présentes
  void _ensureAllDefaultPermissions() {
    final defaultPermissions = _getDefaultPermissions();

    for (String permission in defaultPermissions) {
      if (!_allPermissions.contains(permission)) {
        _allPermissions.add(permission);
      }
    }

    debugPrint('✅ Ensured all default permissions are present');
  }

  // ✅ PERMISSIONS PAR DÉFAUT AVEC MEDICATION EN PREMIER
  List<String> _getDefaultPermissions() {
    return [
      // ✅ MEDICATION PERMISSIONS - TOUJOURS PRÉSENTES
      'view_medication',
      'create_medication',
      'update_medication',
      'delete_medication',

      // User permissions
      'view_user',
      'create_user',
      'update_user',
      'delete_user',

      // Role permissions
      'view_role',
      'create_role',
      'update_role',
      'delete_role',

      // Patient permissions
      'view_patient',
      'create_patient',
      'update_patient',
      'delete_patient',

      // Consultation permissions
      'view_consultation',
      'create_consultation',
      'update_consultation',
      'delete_consultation',

      // Prescription permissions
      'view_prescription',
      'create_prescription',
      'update_prescription',
      'delete_prescription',
    ];
  }

  // ✅ NOUVELLE MÉTHODE: Forcer le rechargement des permissions
  Future<void> refreshPermissions() async {
    debugPrint('🔄 Force refreshing permissions...');
    await loadPermissions();
  }

  // ✅ NOUVELLE MÉTHODE: Vérifier si les permissions medication sont disponibles
  bool get hasMedicationPermissions {
    return _allPermissions.any((p) => p.contains('medication'));
  }

  // ✅ NOUVELLE MÉTHODE: Obtenir uniquement les permissions medication
  List<String> get medicationPermissions {
    return _allPermissions.where((p) => p.contains('medication')).toList();
  }

  // ✅ Create new role avec utilisateurs assignés
  Future<bool> createRole({
    required String name,
    required List<String> permissions,
    List<String> selectedUserIds = const [],
  }) async {
    try {
      _setLoading(true);
      _clearError();

      // ✅ DEBUG: Vérifier les permissions avant création
      debugPrint('🔄 Creating role "$name" with permissions: $permissions');
      final medicationPerms =
          permissions.where((p) => p.contains('medication')).toList();
      if (medicationPerms.isNotEmpty) {
        debugPrint('💊 Medication permissions in role: $medicationPerms');
      }

      final request = CreateRoleRequest(
        name: name,
        permissions: permissions,
        users: selectedUserIds,
      );

      final response = await _roleApiService.createRole(request);

      if (response.success && response.data != null) {
        _roles.add(response.data!);
        _setStatus(RoleManagementStatus.success);
        notifyListeners();
        debugPrint('✅ Role created successfully: ${response.data!.name}');

        await loadRoles();
        return true;
      } else {
        _setError(response.error ?? 'Failed to create role');
        return false;
      }
    } catch (e) {
      _setError('Error creating role: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ✅ Update role avec utilisateurs
  Future<bool> updateRole({
    required String roleId,
    String? name,
    List<String>? permissions,
    List<String>? selectedUserIds,
  }) async {
    try {
      _setLoading(true);
      _clearError();

      final request = UpdateRoleRequest(
        name: name,
        permissions: permissions,
        users: selectedUserIds,
      );

      final response = await _roleApiService.updateRole(roleId, request);

      if (response.success && response.data != null) {
        final index = _roles.indexWhere((r) => r.id == roleId);
        if (index != -1) {
          _roles[index] = response.data!;
          notifyListeners();
        }
        _setStatus(RoleManagementStatus.success);
        debugPrint('Role updated successfully: ${response.data!.name}');

        await loadRoles();
        return true;
      } else {
        _setError(response.error ?? 'Failed to update role');
        return false;
      }
    } catch (e) {
      _setError('Error updating role: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Delete role
  Future<bool> deleteRole(String roleId) async {
    try {
      _setLoading(true);
      _clearError();

      final response = await _roleApiService.deleteRole(roleId);

      if (response.success) {
        _roles.removeWhere((r) => r.id == roleId);
        _setStatus(RoleManagementStatus.success);
        notifyListeners();
        debugPrint('Role deleted successfully');
        return true;
      } else {
        _setError(response.error ?? 'Failed to delete role');
        return false;
      }
    } catch (e) {
      _setError('Error deleting role: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ✅ Assign additional role to user
  Future<bool> assignRoleToUser({
    required String userId,
    required String roleId,
  }) async {
    try {
      final response = await _roleApiService.assignRoleToUser(
        userId: userId,
        roleId: roleId,
      );

      if (response.success) {
        debugPrint('✅ Role assigned to user successfully');
        await loadUsers();
        return true;
      } else {
        _setError(response.error ?? 'Failed to assign role to user');
        return false;
      }
    } catch (e) {
      _setError('Error assigning role to user: $e');
      return false;
    }
  }

  // ✅ Remove role from user
  Future<bool> removeRoleFromUser({
    required String userId,
    required String roleId,
  }) async {
    try {
      final response = await _roleApiService.removeRoleFromUser(
        userId: userId,
        roleId: roleId,
      );

      if (response.success) {
        debugPrint('✅ Role removed from user successfully');
        await loadUsers();
        return true;
      } else {
        _setError(response.error ?? 'Failed to remove role from user');
        return false;
      }
    } catch (e) {
      _setError('Error removing role from user: $e');
      return false;
    }
  }

  // ✅ Bulk assign users to role
  Future<bool> bulkAssignUsersToRole({
    required List<String> userIds,
    required String roleId,
  }) async {
    try {
      final response = await _roleApiService.bulkAssignUsersToRole(
        userIds: userIds,
        roleId: roleId,
      );

      if (response.success) {
        debugPrint('✅ Users assigned to role successfully');
        await loadUsers();
        return true;
      } else {
        _setError(response.error ?? 'Failed to assign users to role');
        return false;
      }
    } catch (e) {
      _setError('Error bulk assigning users to role: $e');
      return false;
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

  // Get role by name
  Role? getRoleByName(String roleName) {
    try {
      return _roles.firstWhere((r) => r.name == roleName);
    } catch (e) {
      return null;
    }
  }

  // ✅ Get users assigned to a specific role
  List<UserSummary> getUsersByRole(String roleId) {
    final role = getRoleById(roleId);
    return role?.assignedUsersDetails ?? [];
  }

  // ✅ Get users by role name
  List<User> getUsersByRoleName(String roleName) {
    return _users.where((user) {
      return user.allRoleNames.contains(roleName);
    }).toList();
  }

  // ✅ Get user by ID
  User? getUserById(String userId) {
    try {
      return _users.firstWhere((u) => u.id == userId);
    } catch (e) {
      return null;
    }
  }

  // ✅ Convert user names to user IDs
  List<String> convertUserNamesToIds(List<String> userNames) {
    List<String> userIds = [];
    for (String userName in userNames) {
      try {
        final user = _users.firstWhere((u) => u.fullName == userName);
        userIds.add(user.id);
      } catch (e) {
        debugPrint('Warning: User not found for name: $userName');
      }
    }
    return userIds;
  }

  // ✅ Convert user IDs to user names
  List<String> convertUserIdsToNames(List<String> userIds) {
    List<String> userNames = [];
    for (String userId in userIds) {
      try {
        final user = _users.firstWhere((u) => u.id == userId);
        userNames.add(user.fullName);
      } catch (e) {
        debugPrint('Warning: User not found for ID: $userId');
      }
    }
    return userNames;
  }

  // Helper methods
  void _setStatus(RoleManagementStatus status) {
    _status = status;
    notifyListeners();
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    _status = RoleManagementStatus.error;
    debugPrint('Role management error: $error');
  }

  void _clearError() {
    _errorMessage = null;
  }

  // Clear all data
  void clear() {
    _roles.clear();
    _users.clear();
    _allPermissions.clear();
    _status = RoleManagementStatus.initial;
    _errorMessage = null;
    _isLoading = false;
    notifyListeners();
  }
}
