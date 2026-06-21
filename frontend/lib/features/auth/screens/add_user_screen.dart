// lib/features/auth/widgets/add_user_form.dart - Version avec multi-rôles
import 'package:flutter/material.dart';
import 'package:frontend/core/constants/primary_button.dart';
import 'package:frontend/core/constants/secondary_button.dart';
import 'package:frontend/shared/widgets/forms/form_field.dart';
import 'package:frontend/features/auth/providers/role_provider.dart';
import 'package:frontend/features/auth/providers/user_provider.dart';
import 'package:provider/provider.dart';

class AddUserForm extends StatefulWidget {
  final VoidCallback onBack;
  final Function(Map) onSave;

  const AddUserForm({
    super.key,
    required this.onBack,
    required this.onSave,
  });

  @override
  State<AddUserForm> createState() => _AddUserFormState();
}

class _AddUserFormState extends State<AddUserForm> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _specialiteController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  String? _selectedPrimaryRole;
  List<String> _selectedAdditionalRoles = [];
  bool _isActive = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    // Charger les rôles au démarrage
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final roleProvider = Provider.of<RoleProvider>(context, listen: false);
      if (roleProvider.roles.isEmpty) {
        roleProvider.loadRoles();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<RoleProvider>(
      builder: (context, roleProvider, child) {
        final availableRoles = roleProvider.roles;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Back Button
                  Container(
                    alignment: Alignment.centerLeft,
                    padding: const EdgeInsets.only(bottom: 16),
                    child: ElevatedButton.icon(
                      onPressed: _isSaving ? () {} : widget.onBack,
                      icon: const Icon(Icons.arrow_back, size: 20),
                      label: const Text("Back to list",
                          style: TextStyle(fontSize: 14)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            const Color.fromARGB(137, 238, 238, 238),
                        foregroundColor: Colors.black,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),

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
                      //    enabled: !_isSaving,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: AppFormField(
                          label: 'Last Name',
                          controller: _lastNameController,
                          required: true,
                     //     enabled: !_isSaving,
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
                        //  enabled: !_isSaving,
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter email';
                            }
                            if (!_isValidEmail(value)) {
                              return 'Please enter a valid email';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: AppFormField(
                          label: 'Speciality',
                          controller: _specialiteController,
                        //  enabled: !_isSaving,
                         // hint: 'e.g., Cardiology, Neurology...',
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
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(8),
                      color: _isSaving ? Colors.grey[100] : Colors.white,
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
                                _selectedAdditionalRoles.remove(newValue);
                              });
                            },
                      items:
                          availableRoles.map<DropdownMenuItem<String>>((role) {
                        return DropdownMenuItem<String>(
                          value: role.id,
                          child: Text(role.name),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Additional Roles Selection
                  const Text(
                    'Additional Roles (Optional)',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF374151),
                    ),
                  ),
                  const SizedBox(height: 8),
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

                              return CheckboxListTile(
                                title: Text(
                                  role.name,
                                  style: TextStyle(
                                    color:
                                        isDisabled ? Colors.grey : Colors.black,
                                    fontSize: 14,
                                  ),
                                ),
                                subtitle: Text(
                                  '${role.permissions.length} permissions',
                                  style: const TextStyle(
                                      fontSize: 12, color: Colors.grey),
                                ),
                                value:
                                    _selectedAdditionalRoles.contains(role.id),
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
                              );
                            },
                          ),
                  ),
                  const SizedBox(height: 16),

                  // Active Status
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: Row(
                      children: [
                        Checkbox(
                          value: _isActive,
                          onChanged: _isSaving
                              ? null
                              : (value) {
                                  setState(() {
                                    _isActive = value ?? true;
                                  });
                                },
                        ),
                        const Text(
                          'Account Active',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          _isActive ? Icons.check_circle : Icons.block,
                          size: 16,
                          color: _isActive ? Colors.green : Colors.red,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Security Section
                  _buildSectionTitle("Security"),
                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Expanded(
                        child: AppFormField(
                          label: 'Password',
                          controller: _passwordController,
                          required: true,
                       //   enabled: !_isSaving,
                          obscureText: true,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter password';
                            }
                            if (value.length < 6) {
                              return 'Password must be at least 6 characters';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: AppFormField(
                          label: 'Confirm Password',
                          controller: _confirmPasswordController,
                          required: true,
                       //   enabled: !_isSaving,
                          obscureText: true,
                          validator: (value) {
                            if (value != _passwordController.text) {
                              return 'Passwords do not match';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // Action Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      SecondaryButton(
                        text: 'Cancel',
                        onPressed: _isSaving ? () {} : widget.onBack,
                      ),
                      const SizedBox(width: 16),
                      PrimaryButton(
                        text: _isSaving ? 'Creating...' : 'Create User',
                        onPressed: _isSaving ? null : _saveUser,
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

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  Future<void> _saveUser() async {
    if (!_formKey.currentState!.validate()) {
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
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final roleProvider = Provider.of<RoleProvider>(context, listen: false);

      // Get role names for display
      final primaryRoleName =
          roleProvider.getRoleById(_selectedPrimaryRole!)?.name ?? '';
      final additionalRoleNames = _selectedAdditionalRoles
          .map((id) => roleProvider.getRoleById(id)?.name ?? '')
          .where((name) => name.isNotEmpty)
          .toList();

      final success = await userProvider.createUser(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        firstname: _firstNameController.text.trim(),
        lastname: _lastNameController.text.trim(),
        specialite: _specialiteController.text.trim().isNotEmpty
            ? _specialiteController.text.trim()
            : null,
        roleId: _selectedPrimaryRole!,
        additionalRoleIds: _selectedAdditionalRoles,
        active: _isActive,
      );

      if (success) {
        if (mounted) {
          // Create user data for callback
          final newUser = {
            'firstName': _firstNameController.text.trim(),
            'lastName': _lastNameController.text.trim(),
            'name':
                '${_firstNameController.text.trim()} ${_lastNameController.text.trim()}',
            'email': _emailController.text.trim(),
            'specialite': _specialiteController.text.trim(),
            'role': primaryRoleName,
            'additionalRoles': additionalRoleNames,
            'status': _isActive ? 'Active' : 'Inactive',
          };

          widget.onSave(newUser);
          widget.onBack();

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('User created successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content:
                  Text(userProvider.errorMessage ?? 'Failed to create user'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating user: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _specialiteController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
}
