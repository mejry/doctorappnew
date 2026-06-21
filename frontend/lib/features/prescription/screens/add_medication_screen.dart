import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:frontend/core/constants/primary_button.dart';
import 'package:frontend/core/constants/secondary_button.dart';
import 'package:frontend/shared/widgets/forms/form_field.dart';
import 'package:frontend/features/prescription/providers/medication_provider.dart';
import '../../../core/constants/button_styles.dart';
import '../../../core/constants/colors.dart';

class MedicationForm extends StatefulWidget {
  final VoidCallback onBack;
  final VoidCallback onCancel;

  const MedicationForm({
    super.key,
    required this.onBack,
    required this.onCancel,
  });

  @override
  State<MedicationForm> createState() => _MedicationFormState();
}

class _MedicationFormState extends State<MedicationForm> {
  final _formKey = GlobalKey<FormState>();
  bool _isSaving = false;

  // List of valid options (same as update dialog)
  final List<String> _formOptions = [
    'Tablet',
    'Capsule',
    'Solution',
    'Injection',
    'Cream',
    'Suppository',
    'Suspension',
    'Aerosol',
    'Powder',
    'Patch',
    'Drops',
    'Other'
  ];

  final List<String> _routeOptions = [
    'Oral',
    'Sublingual',
    'Topical',
    'IV',
    'IM',
    'SC',
    'Rectal',
    'Inhalation',
    'Other'
  ];

  final List<String> _pregnancyCategories = ['A', 'B', 'C', 'D', 'X'];

  // Controllers
  final _nameController = TextEditingController();
  final _genericNameController = TextEditingController();
  final _internalCodeController = TextEditingController();
  final _brandNamesController = TextEditingController();
  final _manufacturerNameController = TextEditingController();
  final _manufacturerCountryController = TextEditingController();
  String _selectedForm = 'Tablet';
  final _ingredientController = TextEditingController();
  final _strengthController = TextEditingController();
  String _selectedRoute = 'Oral';
  String _selectedPregnancyCategory = 'C';
  final _storageConditionsController = TextEditingController();
  final _shelfLifeController = TextEditingController();
  final _dosageController = TextEditingController();
  final _stockController = TextEditingController(text: '0');

  @override
  void dispose() {
    _disposeControllers();
    super.dispose();
  }

  void _disposeControllers() {
    _nameController.dispose();
    _genericNameController.dispose();
    _internalCodeController.dispose();
    _brandNamesController.dispose();
    _manufacturerNameController.dispose();
    _manufacturerCountryController.dispose();
    _ingredientController.dispose();
    _strengthController.dispose();
    _storageConditionsController.dispose();
    _shelfLifeController.dispose();
    _dosageController.dispose();
    _stockController.dispose();
  }

  Future<void> _saveMedication() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final medicationData = _buildMedicationData();
      debugPrint('Creating medication with data: $medicationData');

      final provider = context.read<MedicationProvider>();
      final success = await provider.createMedication(medicationData);

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Medication created successfully!'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
          widget.onBack();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${provider.error ?? 'Unknown error'}'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error in _saveMedication: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Unexpected error: $e'),
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

  Map<String, dynamic> _buildMedicationData() {
    debugPrint('Building medication data...');
    debugPrint('Manufacturer name: ${_manufacturerNameController.text.trim()}');
    debugPrint(
        'Manufacturer country: ${_manufacturerCountryController.text.trim()}');

    final data = {
      'identification': {
        'name': _nameController.text.trim(),
        'genericName': _genericNameController.text.trim(),
        'brandNames': _brandNamesController.text.trim().isNotEmpty
            ? [_brandNamesController.text.trim()]
            : [],
        'manufacturer': _manufacturerNameController.text.trim().isNotEmpty
            ? {
                'name': _manufacturerNameController.text.trim(),
                'country': _manufacturerCountryController.text.trim().isNotEmpty
                    ? _manufacturerCountryController.text.trim()
                    : null
              }
            : null,
        'codes': {
          'internal': _internalCodeController.text.trim(),
          'national': _internalCodeController.text.trim(),
        }
      },
      'pharmaceuticalProperties': {
        'form': _selectedForm,
        'composition': _ingredientController.text.trim().isNotEmpty
            ? [
                {
                  'ingredient': _ingredientController.text.trim(),
                  'strength': _strengthController.text.trim(),
                }
              ]
            : [],
        'route': _selectedRoute,
        'storage': {
          'conditions': _storageConditionsController.text.trim(),
          'shelfLife': _shelfLifeController.text.trim(),
        }
      },
      'dosage': {
        'standard': {
          'adult': {
            'dose': _dosageController.text.trim().isNotEmpty
                ? _dosageController.text.trim()
                : 'As directed',
            'frequency': 'As needed',
            'maxDailyDose': 'As directed'
          }
        }
      },
      'safety': {
        'pregnancy': {'category': _selectedPregnancyCategory}
      },
      'inventory': {
        'currentStock': int.tryParse(_stockController.text.trim()) ?? 0,
        'unit': 'units',
        'threshold': 10,
        'status': 'In Stock'
      }
    };

    debugPrint(
        'Final manufacturer object: ${data['identification']?['manufacturer']}');
    return data;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_isSaving,
      onPopInvoked: (didPop) {
        if (!didPop && !_isSaving) {
          widget.onBack();
        }
      },
      child: SingleChildScrollView(
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
              children: [
                // 🔙 Back Button
                Container(
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.only(bottom: 24),
                  child: ElevatedButton.icon(
                    onPressed: _isSaving ? null : widget.onBack,
                    icon: const Icon(Icons.arrow_back),
                    label: const Text("Back to list"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(137, 238, 238, 238),
                      foregroundColor: Colors.black,
                      elevation: 0,
                    ),
                  ),
                ),

                // 📌 IDENTIFICATION
                _sectionTitle("Identification"),
                const SizedBox(height: 8),
                _rowFields([
                  AppFormField(
                    controller: _nameController,
                    label: 'Name',
                    required: true,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Name is required';
                      }
                      return null;
                    },
                  ),
                  AppFormField(
                    controller: _genericNameController,
                    label: 'Generic Name',
                  ),
                ]),
                const SizedBox(height: 16),
                _rowFields([
                  AppFormField(
                    controller: _brandNamesController,
                    label: 'Brand Names',
                  ),
                  AppFormField(
                    controller: _internalCodeController,
                    label: 'Internal Code',
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Internal code is required';
                      }
                      return null;
                    },
                  ),
                ]),
                const SizedBox(height: 16),
                _rowFields([
                  AppFormField(
                    controller: _manufacturerNameController,
                    label: 'Manufacturer Name',
                  ),
                  AppFormField(
                    controller: _manufacturerCountryController,
                    label: 'Manufacturer Country',
                  ),
                ]),

                const SizedBox(height: 24),

                // ⚗️ PHARMACEUTICAL PROPERTIES
                _sectionTitle("Pharmaceutical Properties"),
                const SizedBox(height: 8),
                _rowFields([
                  DropdownButtonFormField<String>(
                    value: _selectedForm,
                    items: _formOptions.map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedForm = value ?? 'Tablet';
                      });
                    },
                    decoration: const InputDecoration(
                      labelText: 'Form',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please select a form';
                      }
                      return null;
                    },
                  ),
                  AppFormField(
                    controller: _dosageController,
                    label: 'Dosage',
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Dosage is required';
                      }
                      return null;
                    },
                  ),
                ]),
                const SizedBox(height: 16),
                _rowFields([
                  AppFormField(
                    controller: _ingredientController,
                    label: 'Ingredient',
                  ),
                  AppFormField(
                    controller: _strengthController,
                    label: 'Strength',
                  ),
                ]),
                const SizedBox(height: 16),
                _rowFields([
                  DropdownButtonFormField<String>(
                    value: _selectedRoute,
                    items: _routeOptions.map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedRoute = value ?? 'Oral';
                      });
                    },
                    decoration: const InputDecoration(
                      labelText: 'Route',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please select a route';
                      }
                      return null;
                    },
                  ),
                  AppFormField(
                    controller: _storageConditionsController,
                    label: 'Storage Conditions',
                  ),
                ]),
                const SizedBox(height: 16),
                _rowFields([
                  AppFormField(
                    controller: _shelfLifeController,
                    label: 'Shelf Life',
                  ),
                  DropdownButtonFormField<String>(
                    value: _selectedPregnancyCategory,
                    items: _pregnancyCategories.map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text('Category $value'),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedPregnancyCategory = value ?? 'C';
                      });
                    },
                    decoration: const InputDecoration(
                      labelText: 'Pregnancy Category',
                      border: OutlineInputBorder(),
                      helperText: 'A=Safest, X=Contraindicated',
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please select pregnancy category';
                      }
                      return null;
                    },
                  ),
                ]),

                const SizedBox(height: 24),

                // 📦 STOCK
                _sectionTitle("Stock"),
                const SizedBox(height: 8),
                _rowFields([
                  AppFormField(
                    controller: _stockController,
                    label: 'Stock Quantity',
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter stock quantity';
                      }
                      final intValue = int.tryParse(value.trim());
                      if (intValue == null) {
                        return 'Please enter a valid number';
                      }
                      if (intValue < 0) {
                        return 'Stock cannot be negative';
                      }
                      return null;
                    },
                  ),
                ]),

                const SizedBox(height: 24),

                // ✅ Save & Cancel buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    // Cancel
                    SecondaryButton(
                      text: 'Cancel',
                      onPressed: _isSaving ? () {} : widget.onCancel,
                    ),
                    const SizedBox(width: 16),
                    // Save
                    PrimaryButton(
                      text: _isSaving ? 'Saving...' : 'Save',
                      onPressed: _isSaving ? null : () => _saveMedication(),
                    ),
                  ],
                ),

                // Indicateur de chargement
                if (_isSaving)
                  Container(
                    margin: const EdgeInsets.only(top: 16),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        SizedBox(width: 12),
                        Text(
                          'Creating medication...',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Container(
      alignment: Alignment.centerLeft,
      margin: const EdgeInsets.only(top: 16, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: AppColors.secondary,
        ),
      ),
    );
  }

  Widget _rowFields(List<Widget> fields) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: fields
            .map((field) => Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: field,
                  ),
                ))
            .toList(),
      ),
    );
  }
}
