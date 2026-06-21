// lib/features/auth/widgets/edit_user_dialog.dart - Version avec support multi-rôles
import 'package:flutter/material.dart';
import 'package:frontend/core/constants/primary_button.dart';
import 'package:frontend/core/constants/secondary_button.dart';
import 'package:frontend/shared/widgets/forms/form_field.dart';
import 'package:frontend/features/auth/providers/role_provider.dart';
import 'package:provider/provider.dart';

class EditUserDialog extends StatefulWidget {
  final Map<String, dynamic> user;
  final Future<void> Function(Map<String, dynamic>) onSave;

  const EditUserDialog({
    super.key,
    required this.user,
    required this.onSave,
  });

  @override
  State<EditUserDialog> createState() => _EditUserDialogState();
}

class _EditUserDialogState extends State<EditUserDialog> {
  late final TextEditingController _firstNameController;
  late final TextEditingController _lastNameController;
  late final TextEditingController _emailController;
  late final TextEditingController _specialiteController;

  String? _selectedPrimaryRole;
  List<String> _selectedAdditionalRoles = [];
  String _selectedStatus = 'Active';
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();

    // Initialiser les contrôleurs
    _firstNameController =
        TextEditingController(text: widget.user['firstname'] ?? '');
    _lastNameController =
        TextEditingController(text: widget.user['lastname'] ?? '');
    _emailController = TextEditingController(text: widget.user['email'] ?? '');
    _specialiteController =
        TextEditingController(text: widget.user['specialite'] ?? '');

    // Initialiser le statut
    _selectedStatus = widget.user['status'] ?? 'Active';

    // Charger les rôles et initialiser la sélection
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final roleProvider = Provider.of<RoleProvider>(context, listen: false);
      if (roleProvider.roles.isEmpty) {
        roleProvider.loadRoles().then((_) => _initializeRoles());
      } else {
        _initializeRoles();
      }
    });
  }

  void _initializeRoles() {
    final roleProvider = Provider.of<RoleProvider>(context, listen: false);

    // ✅ Initialiser le rôle principal
    final primaryRoleName = widget.user['role'] as String?;
    if (primaryRoleName != null) {
      final primaryRole = roleProvider.getRoleByName(primaryRoleName);
      if (primaryRole != null) {
        _selectedPrimaryRole = primaryRole.id;
      }
    }

    // ✅ Initialiser les rôles additionnels
    final additionalRoleIds = widget.user['additionalRoleIds'] as List<String>?;
    final allRoleNames = widget.user['allRoleNames'] as List<String>?;

    if (additionalRoleIds != null && additionalRoleIds.isNotEmpty) {
      // Si on a les IDs directement, les utiliser
      _selectedAdditionalRoles = List.from(additionalRoleIds);
    } else if (allRoleNames != null && allRoleNames.isNotEmpty) {
      // Sinon, convertir les noms en IDs (exclure le rôle principal)
      _selectedAdditionalRoles = [];
      for (String roleName in allRoleNames) {
        if (roleName != primaryRoleName) {
          final role = roleProvider.getRoleByName(roleName);
          if (role != null) {
            _selectedAdditionalRoles.add(role.id);
          }
        }
      }
    }

    debugPrint('🔄 Initialized roles:');
    debugPrint('   Primary role: $_selectedPrimaryRole');
    debugPrint('   Additional roles: $_selectedAdditionalRoles');

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<RoleProvider>(
      builder: (context, roleProvider, child) {
        final availableRoles = roleProvider.roles;

        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
          child: Center(
            child: Container(
              constraints: const BoxConstraints(
                minWidth: 600,
                maxWidth: 800,
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
                  // Header
                  Row(
                    children: [
                      const Text(
                        'Edit User',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed:
                            _isSaving ? null : () { Navigator.pop(context); },
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Content
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // User Information Section
                          _buildSectionTitle("User Information"),
                          const SizedBox(height: 16),

                          Row(
                            children: [
                              Expanded(
                                child: AppFormField(
                                  label: 'First Name',
                                  controller: _firstNameController,
                                  required: true,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: AppFormField(
                                  label: 'Last Name',
                                  controller: _lastNameController,
                                  required: true,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          Row(
                            children: [
                              Expanded(
                                child: AppFormField(
                                  label: 'Email Address',
                                  controller: _emailController,
                                  required: true,
                                  keyboardType: TextInputType.emailAddress,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: AppFormField(
                                  label: 'Speciality',
                                  controller: _specialiteController,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),

                          // Roles Section
                          _buildSectionTitle("Role Assignment"),
                          const SizedBox(height: 16),

                          // Primary Role Selection
                          const Text(
                            'Primary Role *',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF374151),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey[300]!),
                              borderRadius: BorderRadius.circular(8),
                              color:
                                  _isSaving ? Colors.grey[100] : Colors.white,
                            ),
                            child: DropdownButton<String>(
                              value: _selectedPrimaryRole,
                              hint: const Text('Select primary role'),
                              isExpanded: true,
                              underline: const SizedBox(),
                              onChanged: _isSaving
                                  ? null
                                  : (String? newValue) {
                                      setState(() {
                                        _selectedPrimaryRole = newValue;
                                        // Remove from additional roles if selected as primary
                                        _selectedAdditionalRoles
                                            .remove(newValue);
                                      });
                                    },
                              items: availableRoles
                                  .map<DropdownMenuItem<String>>((role) {
                                return DropdownMenuItem<String>(
                                  value: role.id,
                                  child: Row(
                                    children: [
                                      Text(role.name),
                                      if (role.id == _selectedPrimaryRole)
                                        const Padding(
                                          padding: EdgeInsets.only(left: 8),
                                          child: Icon(
                                            Icons.star,
                                            size: 16,
                                            color: Colors.orange,
                                          ),
                                        ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Additional Roles Section
                          const Text(
                            'Additional Roles (Optional)',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF374151),
                            ),
                          ),
                          const SizedBox(height: 8),

                          // Display selected additional roles count
                          if (_selectedAdditionalRoles.isNotEmpty)
                            Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.blue[50],
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.blue[200]!),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.group_add,
                                    size: 16,
                                    color: Colors.blue[700],
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '${_selectedAdditionalRoles.length} additional role${_selectedAdditionalRoles.length > 1 ? 's' : ''} selected',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.blue[700],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                          // Additional Roles List
                          Container(
                            width: double.infinity,
                            constraints: const BoxConstraints(maxHeight: 200),
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey[300]!),
                              borderRadius: BorderRadius.circular(8),
                              color: _isSaving ? Colors.grey[50] : Colors.white,
                            ),
                            child: availableRoles.isEmpty
                                ? const Center(
                                    child: Padding(
                                      padding: EdgeInsets.all(16),
                                      child: Text('Loading roles...'),
                                    ),
                                  )
                                : ListView.builder(
                                    shrinkWrap: true,
                                    itemCount: availableRoles.length,
                                    itemBuilder: (context, index) {
                                      final role = availableRoles[index];
                                      final isDisabled =
                                          role.id == _selectedPrimaryRole;
                                      final isSelected =
                                          _selectedAdditionalRoles
                                              .contains(role.id);

                                      return Container(
                                        decoration: BoxDecoration(
                                          color: isSelected
                                              ? Colors.blue[50]
                                              : (isDisabled
                                                  ? Colors.grey[50]
                                                  : Colors.transparent),
                                          borderRadius:
                                              BorderRadius.circular(4),
                                        ),
                                        child: CheckboxListTile(
                                          title: Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  role.name,
                                                  style: TextStyle(
                                                    color: isDisabled
                                                        ? Colors.grey
                                                        : (isSelected
                                                            ? Colors.blue[800]
                                                            : Colors.black),
                                                    fontSize: 14,
                                                    fontWeight: isSelected
                                                        ? FontWeight.w500
                                                        : FontWeight.normal,
                                                  ),
                                                ),
                                              ),
                                              if (isDisabled)
                                                Container(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                    horizontal: 6,
                                                    vertical: 2,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: Colors.orange[100],
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            4),
                                                  ),
                                                  child: Row(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      Icon(
                                                        Icons.star,
                                                        size: 12,
                                                        color:
                                                            Colors.orange[700],
                                                      ),
                                                      const SizedBox(width: 2),
                                                      Text(
                                                        'Primary',
                                                        style: TextStyle(
                                                          fontSize: 10,
                                                          color: Colors
                                                              .orange[700],
                                                          fontWeight:
                                                              FontWeight.w500,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                            ],
                                          ),
                                          subtitle: Text(
                                            '${role.permissions.length} permissions',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: isDisabled
                                                  ? Colors.grey[400]
                                                  : Colors.grey[600],
                                            ),
                                          ),
                                          value: isSelected,
                                          onChanged: isDisabled || _isSaving
                                              ? null
                                              : (bool? value) {
                                                  setState(() {
                                                    if (value == true) {
                                                      _selectedAdditionalRoles
                                                          .add(role.id);
                                                    } else {
                                                      _selectedAdditionalRoles
                                                          .remove(role.id);
                                                    }
                                                  });
                                                },
                                          dense: true,
                                          controlAffinity:
                                              ListTileControlAffinity.leading,
                                          activeColor: Colors.blue[600],
                                        ),
                                      );
                                    },
                                  ),
                          ),
                          const SizedBox(height: 24),

                          // Status Section
                          _buildSectionTitle("Status"),
                          const SizedBox(height: 16),

                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey[300]!),
                              borderRadius: BorderRadius.circular(8),
                              color:
                                  _isSaving ? Colors.grey[100] : Colors.white,
                            ),
                            child: DropdownButton<String>(
                              value: _selectedStatus,
                              isExpanded: true,
                              underline: const SizedBox(),
                              onChanged: _isSaving
                                  ? null
                                  : (String? newValue) {
                                      setState(() {
                                        _selectedStatus = newValue!;
                                      });
                                    },
                              items: [
                                'Active',
                                'Blocked'
                              ].map<DropdownMenuItem<String>>((String value) {
                                return DropdownMenuItem<String>(
                                  value: value,
                                  child: Row(
                                    children: [
                                      Icon(
                                        value == 'Active'
                                            ? Icons.check_circle
                                            : Icons.block,
                                        size: 18,
                                        color: value == 'Active'
                                            ? Colors.green
                                            : Colors.red,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(value),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Action Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      SecondaryButton(
                        text: 'Cancel',
                        onPressed: _isSaving
                            ? () {}
                            : () => Navigator.pop(context),
                      ),
                      const SizedBox(width: 16),
                      PrimaryButton(
                        text: _isSaving ? 'Saving...' : 'Save Changes',
                        onPressed: _isSaving ? null : _saveChanges,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: Color(0xFF4C9FD7),
      ),
    );
  }

  Future<void> _saveChanges() async {
    // Validation
    if (_firstNameController.text.trim().isEmpty ||
        _lastNameController.text.trim().isEmpty ||
        _emailController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all required fields'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_selectedPrimaryRole == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a primary role'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final updatedUserData = {
        'firstname': _firstNameController.text.trim(),
        'lastname': _lastNameController.text.trim(),
        'email': _emailController.text.trim(),
        'specialite': _specialiteController.text.trim().isNotEmpty
            ? _specialiteController.text.trim()
            : null,
        'roleId': _selectedPrimaryRole!,
        'additionalRoleIds': _selectedAdditionalRoles,
        'status': _selectedStatus,
      };

      debugPrint('🔄 Saving user changes: $updatedUserData');

      await widget.onSave(updatedUserData);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('User updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating user: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _specialiteController.dispose();
    super.dispose();
  }
}
