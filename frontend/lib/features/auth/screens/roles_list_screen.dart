// lib/features/auth/screens/roles_screen.dart - VERSION AVEC CONTRÔLE AUTOMATIQUE PERMISSIONS
import 'package:flutter/material.dart';
import 'package:frontend/core/constants/colors.dart';
import 'package:frontend/features/auth/providers/auth_provider.dart';
import 'package:frontend/features/auth/providers/role_provider.dart';
import 'package:frontend/features/auth/widgets/edit_role_dialog.dart';
import 'package:frontend/features/auth/widgets/role_row.dart';
import 'package:frontend/features/auth/widgets/roles_table_header.dart';
import 'package:frontend/shared/widgets/permission_widget.dart';
import 'package:provider/provider.dart';

class RolesScreen extends StatefulWidget {
  const RolesScreen({super.key});

  @override
  State<RolesScreen> createState() => _RolesScreenState();
}

class _RolesScreenState extends State<RolesScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String? _lastCreatedRoleId;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (authProvider.canUpdateRole ||
          authProvider.canCreateRole ||
          authProvider.canViewRoles) {
        final roleProvider = Provider.of<RoleProvider>(context, listen: false);
        roleProvider.loadRoles();
        roleProvider.loadPermissions();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<dynamic> _getFilteredAndSortedRoles(List<dynamic> roles) {
    var filteredRoles = roles.where((role) {
      if (_searchQuery.isEmpty) return true;

      final roleName = role.name.toLowerCase();
      final permissions = role.permissions.join(' ').toLowerCase();
      final assignedUsers =
          _extractAssignedUserNames(role).join(' ').toLowerCase();

      return roleName.contains(_searchQuery) ||
          permissions.contains(_searchQuery) ||
          assignedUsers.contains(_searchQuery);
    }).toList();

    filteredRoles.sort((a, b) {
      if (_lastCreatedRoleId != null) {
        if (a.id == _lastCreatedRoleId) return -1;
        if (b.id == _lastCreatedRoleId) return 1;
      }
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });

    return filteredRoles;
  }

  @override
  Widget build(BuildContext context) {
    // ✅ VÉRIFICATION PERMISSION PRINCIPALE
    return PermissionWidget(
      permission: 'view_role',
      fallback: _buildAccessDenied(),
      child: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          return Scaffold(
            backgroundColor: Colors.white,
            appBar: AppBar(
              backgroundColor: Colors.white,
              elevation: 0,
              title: const Text('Roles Management',
                  style: TextStyle(color: Colors.black)),
              actions: [
                // ✅ BOUTON ADD SEULEMENT SI PERMISSION CREATE
                PermissionAddButton(
                  permission: 'create_role',
                  text: 'Add Role',
                  onPressed: _addRole,
                ),
              ],
            ),
            body: Column(
              children: [
                _buildSearchBar(),
                Expanded(child: _buildRoleList(authProvider)),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildAccessDenied() {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('Roles', style: TextStyle(color: Colors.black)),
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.security, size: 80, color: Colors.grey),
            SizedBox(height: 20),
            Text(
              'Access Denied',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            SizedBox(height: 10),
            Text(
              'You do not have permission to view roles.',
              style: TextStyle(fontSize: 16, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE0E0E0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Search roles, permissions, or users...',
            hintStyle: TextStyle(
              color: Colors.grey[500],
              fontSize: 15,
            ),
            prefixIcon: const Icon(
              Icons.search,
              color: Color(0xFF4C9FD7),
              size: 22,
            ),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: Icon(
                      Icons.clear,
                      color: Colors.grey[600],
                      size: 20,
                    ),
                    onPressed: () {
                      _searchController.clear();
                    },
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 36,
                      minHeight: 36,
                    ),
                  )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            isDense: false,
          ),
          style: const TextStyle(fontSize: 15),
        ),
      ),
    );
  }

  Widget _buildRoleList(AuthProvider authProvider) {
    return Consumer<RoleProvider>(
      builder: (context, roleProvider, child) {
        if (roleProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (roleProvider.status == RoleManagementStatus.error) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                const SizedBox(height: 16),
                Text(
                  roleProvider.errorMessage ?? 'An error occurred',
                  style: TextStyle(fontSize: 16, color: Colors.red[700]),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => roleProvider.loadRoles(),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        final allRoles = roleProvider.roles;
        final filteredRoles = _getFilteredAndSortedRoles(allRoles);

        if (allRoles.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.admin_panel_settings_outlined,
                    size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text('No roles found',
                    style: TextStyle(fontSize: 16, color: Colors.grey)),
              ],
            ),
          );
        }

        if (filteredRoles.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'No roles match your search',
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                ),
                const SizedBox(height: 8),
                Text(
                  'Try searching with different keywords',
                  style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                ),
              ],
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                const RolesTableHeader(),
                const Divider(height: 1, thickness: 1),
                if (_searchQuery.isNotEmpty)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    color: Colors.blue[50],
                    child: Row(
                      children: [
                        Icon(Icons.info_outline,
                            size: 16, color: Colors.blue[700]),
                        const SizedBox(width: 8),
                        Text(
                          'Showing ${filteredRoles.length} of ${allRoles.length} roles',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.blue[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                Expanded(
                  child: ListView.builder(
                    itemCount: filteredRoles.length,
                    itemBuilder: (context, index) {
                      final role = filteredRoles[index];
                      final assignedUsers = _extractAssignedUserNames(role);
                      final isNewRole = _lastCreatedRoleId == role.id;

                      return Container(
                        decoration: isNewRole
                            ? BoxDecoration(
                                color: Colors.green[50],
                                border: Border.all(
                                    color: Colors.green[200]!, width: 2),
                              )
                            : null,
                        child: RoleRow(
                          role: {
                            'id': role.id,
                            'name': role.name,
                            'permissions': role.permissions,
                            'users': assignedUsers,
                          },
                          // ✅ CONTRÔLE AUTOMATIQUE DES BOUTONS
                          showEditButton: authProvider.canUpdateRole,
                          showDeleteButton: authProvider.canDeleteRole,
                          onEditPressed: () => _editRole(role, roleProvider),
                          onDeletePressed: () =>
                              _deleteRole(role, roleProvider),
                          onPermissionChanged: (permission, isChecked) =>
                              _handlePermissionChange(
                                  role, permission, isChecked, roleProvider),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  List<String> _extractAssignedUserNames(dynamic role) {
    try {
      List<String> userNames = [];

      if (role.assignedUsersDetails != null &&
          role.assignedUsersDetails is List) {
        for (var userSummary in role.assignedUsersDetails) {
          if (userSummary != null) {
            String userName = '';

            if (userSummary.name != null) {
              userName = userSummary.name.toString();
            } else if (userSummary.fullName != null) {
              userName = userSummary.fullName.toString();
            } else if (userSummary.firstname != null &&
                userSummary.lastname != null) {
              userName = '${userSummary.firstname} ${userSummary.lastname}';
            }

            if (userName.isNotEmpty) {
              userNames.add(userName);
            }
          }
        }
      }

      return userNames;
    } catch (e) {
      debugPrint('Error extracting assigned user names: $e');
      return <String>[];
    }
  }

  Future<void> _handlePermissionChange(role, String permission, bool isChecked,
      RoleProvider roleProvider) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (!authProvider.canUpdateRole) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You do not have permission to modify roles'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (isChecked) {
      final updatedPermissions = List<String>.from(role.permissions)
        ..add(permission);
      final success = await roleProvider.updateRole(
        roleId: role.id,
        name: role.name,
        permissions: updatedPermissions,
      );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Permission "$permission" added successfully'),
            backgroundColor: AppColors.primary,
          ),
        );
      }
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Permission'),
        content: Text(
            'Are you sure you want to remove the "$permission" permission from "${role.name}" role?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remove', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final updatedPermissions = List<String>.from(role.permissions)
        ..remove(permission);

      if (updatedPermissions.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('A role must have at least one permission'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      final success = await roleProvider.updateRole(
        roleId: role.id,
        name: role.name,
        permissions: updatedPermissions,
      );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Permission "$permission" removed successfully'),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    }
  }

  void _deleteRole(role, RoleProvider roleProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Role'),
        content:
            Text('Are you sure you want to delete the "${role.name}" role?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final scaffoldMessenger = ScaffoldMessenger.of(context);
              final success = await roleProvider.deleteRole(role.id);

              scaffoldMessenger.showSnackBar(
                SnackBar(
                  content: Text(success
                      ? 'Role deleted successfully'
                      : 'Failed to delete role'),
                  backgroundColor: success ? Colors.green : Colors.red,
                ),
              );
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _editRole(role, RoleProvider roleProvider) async {
    final assignedUsers = _extractAssignedUserNames(role);
    final allUserNames =
        roleProvider.users.map<String>((user) => user.fullName).toList();

    try {
      final updatedRole = await showDialog<Map<String, dynamic>>(
        context: context,
        builder: (context) => EditRoleDialog(
          role: {
            'id': role.id,
            'name': role.name,
            'permissions': List<String>.from(role.permissions ?? []),
            'users': assignedUsers,
          },
          allUsers: allUserNames,
          allPermissions: roleProvider.allPermissions,
          onSave: (updatedRole) async {
            try {
              final selectedUserNames =
                  List<String>.from(updatedRole['users'] ?? []);
              final selectedUserIds =
                  roleProvider.convertUserNamesToIds(selectedUserNames);

              final success = await roleProvider.updateRole(
                roleId: role.id,
                name: updatedRole['name'],
                permissions:
                    List<String>.from(updatedRole['permissions'] ?? []),
                selectedUserIds: selectedUserIds,
              );

              if (success) {
                if (context.mounted) {
                  Navigator.of(context).pop(updatedRole);
                }
              } else {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                          roleProvider.errorMessage ?? 'Failed to update role'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
                throw Exception(
                    roleProvider.errorMessage ?? 'Failed to update role');
              }
            } catch (e) {
              debugPrint('Error in onSave callback: $e');
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error saving role: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
              rethrow;
            }
          },
        ),
      );

      if (updatedRole != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Role updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error in _editRole: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error editing role: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _addRole() async {
    final roleProvider = Provider.of<RoleProvider>(context, listen: false);
    final allUserNames =
        roleProvider.users.map<String>((user) => user.fullName).toList();

    try {
      final newRole = await showDialog<Map<String, dynamic>>(
        context: context,
        builder: (context) => EditRoleDialog(
          role: const {
            'id': '',
            'name': '',
            'permissions': [],
            'users': [],
          },
          allUsers: allUserNames,
          allPermissions: roleProvider.allPermissions,
          onSave: (newRole) async {
            try {
              final selectedUserNames =
                  List<String>.from(newRole['users'] ?? []);
              final selectedUserIds =
                  roleProvider.convertUserNamesToIds(selectedUserNames);

              final success = await roleProvider.createRole(
                name: newRole['name'],
                permissions: List<String>.from(newRole['permissions'] ?? []),
                selectedUserIds: selectedUserIds,
              );

              if (success) {
                final createdRole = roleProvider.roles.firstWhere(
                  (role) => role.name == newRole['name'],
                  orElse: () => null as dynamic,
                );

                if (createdRole != null) {
                  setState(() {
                    _lastCreatedRoleId = createdRole.id;
                  });

                  Future.delayed(const Duration(seconds: 3), () {
                    if (mounted) {
                      setState(() {
                        _lastCreatedRoleId = null;
                      });
                    }
                  });
                }

                if (context.mounted) {
                  Navigator.of(context).pop(newRole);
                }
              } else {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                          roleProvider.errorMessage ?? 'Failed to create role'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
                throw Exception(
                    roleProvider.errorMessage ?? 'Failed to create role');
              }
            } catch (e) {
              debugPrint('Error in onSave callback: $e');
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error creating role: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
              rethrow;
            }
          },
        ),
      );

      if (newRole != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Role created successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error in _addRole: $e');
    }
  }
}
