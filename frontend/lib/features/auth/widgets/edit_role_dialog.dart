// lib/features/auth/widgets/edit_role_dialog.dart - FIX SIMPLE POUR MEDICATION MANAGEMENT
import 'package:flutter/material.dart';
import 'package:frontend/core/constants/colors.dart';
import 'package:frontend/core/constants/primary_button.dart';
import 'package:frontend/core/constants/secondary_button.dart';
import 'package:frontend/shared/widgets/forms/form_field.dart';

class EditRoleDialog extends StatefulWidget {
  final Map<String, dynamic> role;
  final List<String> allUsers;
  final List<String> allPermissions;
  final Future<void> Function(Map<String, dynamic>) onSave;

  const EditRoleDialog({
    super.key,
    required this.role,
    required this.allUsers,
    required this.allPermissions,
    required this.onSave,
  });

  @override
  State<EditRoleDialog> createState() => _EditRoleDialogState();
}

class _EditRoleDialogState extends State<EditRoleDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _userSearchController;
  late List<String> _selectedPermissions;
  late List<String> _selectedUsers;
  bool _isSaving = false;
  String _userSearchQuery = '';

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.role['name']);
    _userSearchController = TextEditingController();
    _selectedPermissions = List.from(widget.role['permissions'] ?? []);
    _selectedUsers = List.from(widget.role['users'] ?? []);

    _userSearchController.addListener(() {
      setState(() {
        _userSearchQuery = _userSearchController.text.toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _userSearchController.dispose();
    super.dispose();
  }

  List<String> get _filteredUsers {
    if (_userSearchQuery.isEmpty) {
      return widget.allUsers;
    }
    return widget.allUsers.where((user) {
      return user.toLowerCase().contains(_userSearchQuery);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    // ✅ FIX SIMPLE: S'assurer que les permissions medication sont toujours incluses
    final effectivePermissions =
        _ensureMedicationPermissions(widget.allPermissions);
    final groupedPermissions =
        _groupPermissionsWithMedication(effectivePermissions);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(
            minWidth: 900,
            maxWidth: 1200,
            maxHeight: 700,
          ),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.role['name'].isEmpty ? 'Add New Role' : 'Edit Role',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      AppFormField(
                        label: 'Role Name',
                        controller: _nameController,
                        required: true,
                      ),
                      const SizedBox(height: 24),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Permissions Section
                          Expanded(
                            flex: 4,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'PERMISSIONS',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF4C9FD7),
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: _toggleAllPermissions,
                                      child: Text(_selectedPermissions.length ==
                                              effectivePermissions.length
                                          ? 'Deselect All'
                                          : 'Select All'),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                // ✅ Construire les groupes avec medication toujours présent
                                ..._buildPermissionGroups(groupedPermissions),
                              ],
                            ),
                          ),
                          const SizedBox(width: 24),
                          // Users Section
                          Expanded(
                            flex: 2,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'ASSIGNED USERS',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF4C9FD7),
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: _toggleAllUsers,
                                      child: Text(_selectedUsers.length ==
                                              _filteredUsers.length
                                          ? 'Deselect All'
                                          : 'Select All'),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                _buildUsersSection(),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              _buildActionButtons(),
            ],
          ),
        ),
      ),
    );
  }

  // ✅ FIX SIMPLE: S'assurer que les permissions medication sont toujours présentes
  List<String> _ensureMedicationPermissions(List<String> permissions) {
    final medicationPermissions = [
      'view_medication',
      'create_medication',
      'update_medication',
      'delete_medication',
    ];

    final effectivePermissions = List<String>.from(permissions);

    for (String perm in medicationPermissions) {
      if (!effectivePermissions.contains(perm)) {
        effectivePermissions.add(perm);
      }
    }

    return effectivePermissions;
  }

  // ✅ SIMPLE: Grouper les permissions avec medication en premier
  Map<String, List<String>> _groupPermissionsWithMedication(
      List<String> permissions) {
    final groups = <String, List<String>>{
      // ✅ MEDICATION EN PREMIER
      'user_management': [],
      'role_management': [],
      'patient_management': [],
      'consultation_management': [],
      'prescription_management': [],
      'medication_management': [],
    };

    // Grouper les permissions
    for (var perm in permissions) {
      final parts = perm.split('_');
      if (parts.length >= 2) {
        final entity = parts.length > 2 ? parts.sublist(1).join('_') : parts[1];

        switch (entity) {
          case 'user':
            groups['user_management']!.add(perm);
            break;
          case 'role':
            groups['role_management']!.add(perm);
            break;
          case 'patient':
            groups['patient_management']!.add(perm);
            break;
          case 'consultation':
            groups['consultation_management']!.add(perm);
            break;
          case 'prescription':
            groups['prescription_management']!.add(perm);
            break;
          case 'medication':
            groups['medication_management']!.add(perm);
            break;
          default:
            groups.putIfAbsent('${entity}_management', () => []).add(perm);
        }
      }
    }

    // Retourner seulement les groupes qui ont des permissions
    return Map.fromEntries(
        groups.entries.where((entry) => entry.value.isNotEmpty));
  }

  // ✅ Construire les groupes de permissions avec style
  List<Widget> _buildPermissionGroups(
      Map<String, List<String>> groupedPermissions) {
    return groupedPermissions.entries.map((entry) {
      final allSelected =
          entry.value.every((p) => _selectedPermissions.contains(p));
      final someSelected =
          entry.value.any((p) => _selectedPermissions.contains(p));

      // ✅ Style spécial pour medication
      final isMedicationGroup = entry.key == 'medication_management';
      final groupColor = _getGroupColor(entry.key);
      final groupIcon = _getGroupIcon(entry.key);

      return Card(
        margin: const EdgeInsets.only(bottom: 16),
        elevation: isMedicationGroup ? 4 : 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: someSelected
                ? groupColor.withOpacity(isMedicationGroup ? 0.5 : 0.3)
                : Colors.grey[200]!,
            width: isMedicationGroup ? 3 : (someSelected ? 2 : 1),
          ),
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: someSelected
                ? LinearGradient(
                    colors: [
                      groupColor.withOpacity(isMedicationGroup ? 0.08 : 0.05),
                      groupColor.withOpacity(isMedicationGroup ? 0.04 : 0.02),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
          ),
          child: Padding(
            padding: EdgeInsets.all(isMedicationGroup ? 16 : 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Icône du groupe
                    Container(
                      padding: EdgeInsets.all(isMedicationGroup ? 8 : 6),
                      decoration: BoxDecoration(
                        color: groupColor
                            .withOpacity(isMedicationGroup ? 0.15 : 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: isMedicationGroup
                            ? Border.all(
                                color: groupColor.withOpacity(0.3), width: 2)
                            : null,
                      ),
                      child: Icon(
                        groupIcon,
                        size: isMedicationGroup ? 20 : 16,
                        color: groupColor,
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Nom du groupe
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _getGroupDisplayName(entry.key),
                            style: TextStyle(
                              fontSize: isMedicationGroup ? 14 : 12,
                              fontWeight: FontWeight.w700,
                              color: groupColor,
                              letterSpacing: 0.5,
                            ),
                          ),
                          if (isMedicationGroup)
                            Text(
                              'Specialized medication operations',
                              style: TextStyle(
                                fontSize: 10,
                                color: groupColor.withOpacity(0.7),
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                        ],
                      ),
                    ),
                    // Badge compteur
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: groupColor
                            .withOpacity(isMedicationGroup ? 0.15 : 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: isMedicationGroup
                            ? Border.all(color: groupColor.withOpacity(0.3))
                            : null,
                      ),
                      child: Text(
                        '${entry.value.where((p) => _selectedPermissions.contains(p)).length}/${entry.value.length}',
                        style: TextStyle(
                          fontSize: isMedicationGroup ? 11 : 10,
                          fontWeight: FontWeight.w600,
                          color: groupColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Checkbox
                    Checkbox(
                      value: allSelected ? true : (someSelected ? null : false),
                      tristate: true,
                      onChanged: (value) {
                        setState(() {
                          if (allSelected) {
                            _selectedPermissions
                                .removeWhere((p) => entry.value.contains(p));
                          } else {
                            for (String perm in entry.value) {
                              if (!_selectedPermissions.contains(perm)) {
                                _selectedPermissions.add(perm);
                              }
                            }
                          }
                        });
                      },
                      activeColor: groupColor,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Permissions sous forme de chips
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: entry.value.map((perm) {
                    final isSelected = _selectedPermissions.contains(perm);
                    final actionName = perm.split('_')[0].toUpperCase();

                    return FilterChip(
                      label: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _getActionIcon(actionName),
                            size: isMedicationGroup ? 14 : 12,
                            color: isSelected ? Colors.white : groupColor,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            actionName,
                            style: TextStyle(
                              fontSize: isMedicationGroup ? 12 : 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            _selectedPermissions.add(perm);
                          } else {
                            _selectedPermissions.remove(perm);
                          }
                        });
                      },
                      selectedColor: groupColor,
                      checkmarkColor: Colors.white,
                      backgroundColor: groupColor.withOpacity(0.1),
                      side: BorderSide(
                        color: isSelected
                            ? groupColor
                            : groupColor.withOpacity(0.3),
                        width: isSelected ? 2 : 1,
                      ),
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : groupColor,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.w500,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ),
      );
    }).toList();
  }

  // ✅ Couleurs pour chaque groupe
  Color _getGroupColor(String groupName) {
    switch (groupName) {
      case 'medication_management':
        return AppColors.secondary;
      case 'user_management':
        return AppColors.secondary;
      case 'role_management':
        return AppColors.secondary;
      case 'patient_management':
        return AppColors.secondary;
      case 'consultation_management':
        return AppColors.secondary;
      case 'prescription_management':
        return AppColors.secondary;
      default:
        return Colors.grey;
    }
  }

  // ✅ Icônes pour chaque groupe
  IconData _getGroupIcon(String groupName) {
    switch (groupName) {
      case 'user_management':
        return Icons.people;
      case 'role_management':
        return Icons.admin_panel_settings;
      case 'patient_management':
        return Icons.person;
      case 'consultation_management':
        return Icons.medical_services;
      case 'prescription_management':
        return Icons.receipt;
      case 'medication_management':
        return Icons.medication_liquid;
      default:
        return Icons.security;
    }
  }

  // ✅ Noms d'affichage pour les groupes
  String _getGroupDisplayName(String groupName) {
    switch (groupName) {
      case 'user_management':
        return 'USER MANAGEMENT';
      case 'role_management':
        return 'ROLE MANAGEMENT';
      case 'patient_management':
        return 'PATIENT MANAGEMENT';
      case 'consultation_management':
        return 'CONSULTATION MANAGEMENT';
      case 'prescription_management':
        return 'PRESCRIPTION MANAGEMENT';
      case 'medication_management':
        return 'MEDICATION MANAGEMENT';
      default:
        return groupName.replaceAll('_', ' ').toUpperCase();
    }
  }

  // ✅ Icônes pour les actions
  IconData _getActionIcon(String action) {
    switch (action.toLowerCase()) {
      case 'view':
        return Icons.visibility;
      case 'create':
        return Icons.add;
      case 'update':
        return Icons.edit;
      case 'delete':
        return Icons.delete;
      default:
        return Icons.security;
    }
  }

  Widget _buildUsersSection() {
    return Column(
      children: [
        // Barre de recherche
        Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(8),
          ),
          child: TextField(
            controller: _userSearchController,
            decoration: InputDecoration(
              hintText: 'Search users...',
              prefixIcon: Icon(Icons.search, size: 18, color: Colors.grey[600]),
              suffixIcon: _userSearchQuery.isNotEmpty
                  ? IconButton(
                      icon:
                          Icon(Icons.clear, size: 18, color: Colors.grey[600]),
                      onPressed: () => _userSearchController.clear(),
                    )
                  : null,
              border: InputBorder.none,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              isDense: true,
            ),
            style: const TextStyle(fontSize: 14),
          ),
        ),

        // Compteur d'utilisateurs sélectionnés
        if (_selectedUsers.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: Colors.blue[200]!),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.group, size: 14, color: Colors.blue[700]),
                const SizedBox(width: 4),
                Text(
                  '${_selectedUsers.length} selected',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.blue[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

        // Liste des utilisateurs
        Container(
          height: 320,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(8),
          ),
          child: _filteredUsers.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _userSearchQuery.isNotEmpty
                            ? Icons.search_off
                            : Icons.people_outline,
                        size: 32,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _userSearchQuery.isNotEmpty
                            ? 'No users found'
                            : 'No users available',
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: _filteredUsers.length,
                  itemBuilder: (context, index) {
                    final user = _filteredUsers[index];
                    final isSelected = _selectedUsers.contains(user);

                    return Container(
                      decoration: BoxDecoration(
                        color:
                            isSelected ? Colors.blue[50] : Colors.transparent,
                        border: Border(
                          bottom:
                              BorderSide(color: Colors.grey[200]!, width: 0.5),
                        ),
                      ),
                      child: CheckboxListTile(
                        title: Text(
                          user,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: isSelected
                                ? FontWeight.w500
                                : FontWeight.normal,
                            color:
                                isSelected ? Colors.blue[800] : Colors.black87,
                          ),
                        ),
                        value: isSelected,
                        onChanged: (bool? value) {
                          setState(() {
                            if (value == true) {
                              _selectedUsers.add(user);
                            } else {
                              _selectedUsers.remove(user);
                            }
                          });
                        },
                        dense: true,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 0),
                        controlAffinity: ListTileControlAffinity.leading,
                        activeColor: Colors.blue[600],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        SecondaryButton(
          text: 'Cancel',
          onPressed: _isSaving ? () {} : () => Navigator.pop(context),
        ),
        const SizedBox(width: 16),
        PrimaryButton(
          text: _isSaving ? 'Saving...' : 'Save',
          onPressed: _isSaving ? null : _saveChanges,
        ),
      ],
    );
  }

  void _toggleAllPermissions() {
    final effectivePermissions =
        _ensureMedicationPermissions(widget.allPermissions);
    setState(() {
      if (_selectedPermissions.length == effectivePermissions.length) {
        _selectedPermissions.clear();
      } else {
        _selectedPermissions = List.from(effectivePermissions);
      }
    });
  }

  void _toggleAllUsers() {
    setState(() {
      final filteredUsers = _filteredUsers;
      final allFilteredSelected =
          filteredUsers.every((user) => _selectedUsers.contains(user));

      if (allFilteredSelected) {
        _selectedUsers.removeWhere((user) => filteredUsers.contains(user));
      } else {
        for (String user in filteredUsers) {
          if (!_selectedUsers.contains(user)) {
            _selectedUsers.add(user);
          }
        }
      }
    });
  }

  Future<void> _saveChanges() async {
    if (_nameController.text.trim().isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enter a role name'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    if (_selectedPermissions.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select at least one permission'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final updatedRole = {
        'id': widget.role['id'],
        'name': _nameController.text.trim(),
        'permissions': _selectedPermissions,
        'users': _selectedUsers,
      };

      debugPrint('Saving role: $updatedRole');
      await widget.onSave(updatedRole);
      debugPrint('Role saved successfully in dialog');
    } catch (e) {
      debugPrint('Error saving role in dialog: $e');

      if (mounted) {
        setState(() {
          _isSaving = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving role: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
