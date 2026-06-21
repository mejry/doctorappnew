// lib/features/auth/widgets/role_row.dart - FIXED VERSION WITH RESPONSIVE LAYOUT
import 'package:flutter/material.dart';
import 'package:frontend/core/constants/colors.dart';
import 'package:frontend/shared/widgets/permission_widget.dart';

class RoleRow extends StatelessWidget {
  const RoleRow({
    super.key,
    required this.role,
    required this.showEditButton,
    required this.showDeleteButton,
    required this.onEditPressed,
    required this.onDeletePressed,
    required this.onPermissionChanged,
  });

  final Map<String, dynamic> role;
  final bool showEditButton;
  final bool showDeleteButton;
  final VoidCallback onEditPressed;
  final VoidCallback onDeletePressed;
  final Function(String, bool) onPermissionChanged;

  @override
  Widget build(BuildContext context) {
    final permissions = List<String>.from(role['permissions'] ?? []);
    final users = List<String>.from(role['users'] ?? []);
    final grouped = _groupPermissions(permissions);

    return Container(
      padding: const EdgeInsets.all(12),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Responsive breakpoint
          final isWide = constraints.maxWidth > 800;

          if (!isWide) {
            // Mobile/Tablet layout - Stack vertically
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Row 1: Role name + Actions
                Row(
                  children: [
                    Expanded(child: _buildRoleName(users)),
                    _buildActionsCompact(),
                  ],
                ),
                const SizedBox(height: 8),
                // Row 2: Permissions
                _buildPermissions(grouped, permissions, isCompact: true),
                const SizedBox(height: 8),
                // Row 3: Users
                _buildUsers(users, isCompact: true),
              ],
            );
          }

          // Desktop layout - Original row layout but fixed
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ROLE NAME
              Expanded(
                flex: 2,
                child: _buildRoleName(users),
              ),
              // PERMISSIONS
              Expanded(
                flex: 5,
                child: _buildPermissions(grouped, permissions),
              ),
              // ASSIGNED USERS
              Expanded(
                flex: 3,
                child: _buildUsers(users),
              ),
              // ACTIONS - Fixed width to prevent overflow
              SizedBox(
                width: 90, // Reduced from 100 to prevent overflow
                child: _buildActions(),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildRoleName(List<String> users) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          role['name'] as String,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 15,
            color: Color(0xFF1a1a1a),
          ),
        ),
        const SizedBox(height: 4),
        // Badge compact pour le nombre d'utilisateurs
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: users.isEmpty
                ? Colors.grey[100]
                : AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            '${users.length} ${users.length == 1 ? 'user' : 'users'}',
            style: TextStyle(
              fontSize: 10,
              color: users.isEmpty ? Colors.grey[600] : AppColors.primary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPermissions(
      Map<String, List<String>> grouped, List<String> permissions,
      {bool isCompact = false}) {
    if (grouped.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text(
          'No permissions',
          style: TextStyle(
            color: Colors.grey[500],
            fontStyle: FontStyle.italic,
            fontSize: 13,
          ),
        ),
      );
    }

    final maxGroups = isCompact ? 2 : 3;
    final maxPermsPerGroup = isCompact ? 4 : 6;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: grouped.entries.take(maxGroups).map((e) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                e.key.replaceAll('_', ' ').toUpperCase(),
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF4C9FD7),
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 3),
              Wrap(
                spacing: 3,
                runSpacing: 2,
                children: e.value.take(maxPermsPerGroup).map((perm) {
                  final selected = permissions.contains(perm);
                  final actionName = perm.split('_')[0].toUpperCase();

                  return GestureDetector(
                    onTap: showEditButton
                        ? () => onPermissionChanged(perm, !selected)
                        : null,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: selected
                            ? AppColors.primary.withOpacity(0.1)
                            : Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: selected
                              ? AppColors.primary.withOpacity(0.3)
                              : Colors.grey[300]!,
                          width: 0.5,
                        ),
                      ),
                      child: Text(
                        actionName,
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w500,
                          color:
                              selected ? AppColors.primary : Colors.grey[600],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              // Afficher "+X more" s'il y a plus de permissions
              if (e.value.length > maxPermsPerGroup)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    '+${e.value.length - maxPermsPerGroup} more',
                    style: TextStyle(
                      fontSize: 9,
                      color: Colors.grey[600],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildUsers(List<String> users, {bool isCompact = false}) {
    if (users.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text(
          'No users assigned',
          style: TextStyle(
            color: Colors.grey[500],
            fontStyle: FontStyle.italic,
            fontSize: 13,
          ),
        ),
      );
    }

    final maxUsers = isCompact ? 1 : 2;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Afficher les premiers utilisateurs seulement
        ...users.take(maxUsers).map((user) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 3),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Text(
                user,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF2a2a2a),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          );
        }).toList(),
        // Afficher "+X more" s'il y a plus d'utilisateurs
        if (users.length > maxUsers)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.blue[25],
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.blue[200]!),
            ),
            child: Text(
              '+${users.length - maxUsers} more',
              style: TextStyle(
                fontSize: 10,
                color: Colors.blue[700],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildActions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (showEditButton)
          PermissionActionButton(
            permission: 'update_role',
            icon: Icons.edit,
            color: AppColors.primary,
            tooltip: 'Edit role',
            onPressed: onEditPressed,
          ),
        if (showEditButton && _canDeleteRole(role['name']))
          const SizedBox(width: 4), // Reduced spacing from 8 to 4
        if (_canDeleteRole(role['name']))
          PermissionActionButton(
            permission: 'delete_role',
            icon: Icons.delete_outline,
            color: Colors.red[400]!,
            tooltip: 'Delete role',
            onPressed: onDeletePressed,
          ),
      ],
    );
  }

  Widget _buildActionsCompact() {
    // Compact version for mobile with smaller buttons
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showEditButton)
          IconButton(
            icon: Icon(Icons.edit, size: 18, color: AppColors.primary),
            onPressed: onEditPressed,
            padding: const EdgeInsets.all(4),
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            tooltip: 'Edit role',
          ),
        if (showEditButton && _canDeleteRole(role['name']))
          const SizedBox(width: 2),
        if (_canDeleteRole(role['name']))
          IconButton(
            icon: Icon(Icons.delete_outline, size: 18, color: Colors.red[400]),
            onPressed: onDeletePressed,
            padding: const EdgeInsets.all(4),
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            tooltip: 'Delete role',
          ),
      ],
    );
  }

  bool _canDeleteRole(String roleName) {
    // Empêcher la suppression des rôles système
    const systemRoles = ['Admin', 'Doctor', 'Secretary'];
    return !systemRoles.contains(roleName);
  }

  // Grouper les permissions avec support pour medications
  Map<String, List<String>> _groupPermissions(List<String> perms) {
    final map = <String, List<String>>{};
    for (final p in perms) {
      final parts = p.split('_');
      if (parts.length >= 2) {
        final entity = parts.length > 2 ? parts.sublist(1).join('_') : parts[1];
        map.putIfAbsent(entity, () => []).add(p);
      } else {
        // Si pas d'underscore, mettre dans "general"
        map.putIfAbsent('general', () => []).add(p);
      }
    }

    // Organiser les groupes dans un ordre logique
    final orderedMap = <String, List<String>>{};

    // Ordre préféré pour l'affichage
    const entityOrder = [
      'user',
      'role',
      'patient',
      'consultation',
      'prescription',
      'medication', // Medication inclus
    ];

    // Ajouter dans l'ordre préféré
    for (String entity in entityOrder) {
      if (map.containsKey(entity)) {
        orderedMap[entity] = map[entity]!;
        map.remove(entity);
      }
    }

    // Ajouter le reste (general, autres)
    orderedMap.addAll(map);

    return orderedMap;
  }
}
