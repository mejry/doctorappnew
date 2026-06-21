// lib/features/auth/screens/users_list_screen.dart - VERSION AVEC CONTRÔLE AUTOMATIQUE PERMISSIONS
import 'package:flutter/material.dart';
import 'package:frontend/core/models/user.dart';
import 'package:frontend/features/auth/providers/auth_provider.dart';
import 'package:frontend/features/auth/providers/user_provider.dart';
import 'package:frontend/features/auth/providers/role_provider.dart';
import 'package:frontend/features/auth/widgets/UsersTableHeader.dart';
import 'package:frontend/features/auth/widgets/user_row.dart';
import 'package:frontend/features/auth/widgets/edit_user_dialog.dart';
import 'package:frontend/shared/widgets/permission_widget.dart';
import 'package:provider/provider.dart';

class UsersListScreen extends StatefulWidget {
  final VoidCallback? onAddUserPressed;

  const UsersListScreen({super.key, this.onAddUserPressed});

  @override
  State<UsersListScreen> createState() => _UsersListScreenState();
}

class _UsersListScreenState extends State<UsersListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (authProvider.canViewUsers) {
        Provider.of<UserProvider>(context, listen: false).loadUsers();
        Provider.of<UserProvider>(context, listen: false).loadRoles();
        Provider.of<RoleProvider>(context, listen: false).loadRoles();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // ✅ VÉRIFICATION PERMISSION PRINCIPALE
    return PermissionWidget(
      permission: 'view_user',
      fallback: _buildAccessDenied(),
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          title:
              const Text('Users List', style: TextStyle(color: Colors.black)),
          actions: [
            // ✅ BOUTON ADD USER SEULEMENT SI PERMISSION
            PermissionAddButton(
              permission: 'create_user',
              text: 'Add User',
              onPressed: widget.onAddUserPressed ?? () {},
            ),
          ],
        ),
        body: _buildUserList(),
      ),
    );
  }

  Widget _buildAccessDenied() {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('Users', style: TextStyle(color: Colors.black)),
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
              'You do not have permission to view users.',
              style: TextStyle(fontSize: 16, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserList() {
    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        if (userProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (userProvider.status == UserManagementStatus.error) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                const SizedBox(height: 16),
                Text(
                  userProvider.errorMessage ?? 'An error occurred',
                  style: TextStyle(fontSize: 16, color: Colors.red[700]),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => userProvider.loadUsers(),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        final users = userProvider.users;

        if (users.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.people_outline, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text('No users found',
                    style: TextStyle(fontSize: 16, color: Colors.grey)),
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
                const UsersTableHeader(),
                const Divider(height: 1, thickness: 1),
                Expanded(
                  child: ListView.builder(
                    itemCount: users.length,
                    itemBuilder: (context, index) {
                      final user = users[index];
                      return Consumer<AuthProvider>(
                        builder: (context, authProvider, _) {
                          return UserRow(
                            user: {
                              'id': user.id,
                              'name': user.fullName,
                              'role': user.role,
                              'additionalRoles': user.allRoleNames
                                  .where((name) => name != user.role)
                                  .toList(),
                              'status': user.active ? 'Active' : 'Blocked',
                              'email': user.email,
                              'specialite': user.specialite,
                            },
                            // ✅ CONTRÔLE AUTOMATIQUE DES BOUTONS SELON PERMISSIONS
                            showEditButton: authProvider.canUpdateUser,
                            showDeleteButton: authProvider.canDeleteUser,
                            canUpdateStatus: authProvider.canUpdateUser,
                            onEditPressed: () => _editUser(user, userProvider),
                            onDeletePressed: () =>
                                _deleteUser(user, userProvider),
                            onStatusPressed: () =>
                                _toggleUserStatus(user, userProvider),
                          );
                        },
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

  void _editUser(User user, UserProvider userProvider) {
    showDialog(
      context: context,
      builder: (context) => EditUserDialog(
        user: {
          'id': user.id,
          'firstname': user.firstname,
          'lastname': user.lastname,
          'email': user.email,
          'role': user.role,
          'allRoleNames': user.allRoleNames,
          'additionalRoleIds': user.additionalRoleIds,
          'specialite': user.specialite,
          'status': user.active ? 'Active' : 'Blocked',
        },
        onSave: (updatedUserData) async {
          final scaffoldMessenger = ScaffoldMessenger.of(context);

          final success = await userProvider.updateUser(
            userId: user.id,
            email: updatedUserData['email'],
            firstname: updatedUserData['firstname'],
            lastname: updatedUserData['lastname'],
            specialite: updatedUserData['specialite'],
            roleId: updatedUserData['roleId'],
            additionalRoleIds:
                updatedUserData['additionalRoleIds'] as List<String>?,
            active: updatedUserData['status'] == 'Active',
          );

          scaffoldMessenger.showSnackBar(
            SnackBar(
              content: Text(success
                  ? 'User updated successfully'
                  : 'Failed to update user'),
              backgroundColor: success ? Colors.green : Colors.red,
            ),
          );
        },
      ),
    );
  }

  void _deleteUser(User user, UserProvider userProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete User'),
        content: Text('Are you sure you want to delete ${user.fullName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final scaffoldMessenger = ScaffoldMessenger.of(context);
              final success = await userProvider.deleteUser(user.id);

              scaffoldMessenger.showSnackBar(
                SnackBar(
                  content: Text(success
                      ? 'User deleted successfully'
                      : 'Failed to delete user'),
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

  Future<void> _toggleUserStatus(User user, UserProvider userProvider) async {
    final action = user.active ? 'Block' : 'Unblock';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Action'),
        content: Text('Are you sure you want to $action ${user.fullName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(action),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final scaffoldMessenger = ScaffoldMessenger.of(context);
      final success = await userProvider.toggleUserStatus(user.id);

      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text(success
              ? 'User ${action.toLowerCase()}ed successfully'
              : 'Failed to ${action.toLowerCase()} user'),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    }
  }
}
