import 'package:flutter/material.dart';
import 'package:frontend/core/constants/primary_button.dart';
import 'package:frontend/core/constants/secondary_button.dart';
import 'package:frontend/core/constants/colors.dart';
import 'package:frontend/shared/widgets/forms/form_field.dart';

class UpdateMedicationDialog extends StatefulWidget {
  final Map<String, dynamic> medication;
  final Function(Map<String, dynamic>) onUpdate;
  final VoidCallback? onCancel;

  const UpdateMedicationDialog({
    super.key,
    required this.medication,
    required this.onUpdate,
    this.onCancel,
  });

  @override
  State<UpdateMedicationDialog> createState() => _UpdateMedicationDialogState();
}

class _UpdateMedicationDialogState extends State<UpdateMedicationDialog> {
  final _formKey = GlobalKey<FormState>();
  bool _isUpdating = false;

  // List of valid options
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

  // Contrôleurs
  late TextEditingController _nameController;
  late TextEditingController _genericNameController;
  late TextEditingController _internalCodeController;
  late TextEditingController _brandNamesController;
  late TextEditingController _manufacturerNameController;
  late TextEditingController _manufacturerCountryController;
  late String _selectedForm;
  late TextEditingController _ingredientController;
  late TextEditingController _strengthController;
  late String _selectedRoute;
  late TextEditingController _storageConditionsController;
  late TextEditingController _shelfLifeController;
  late TextEditingController _dosageController;
  late TextEditingController _stockController;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    debugPrint(
        'Initializing controllers with medication data: ${widget.medication}');

    _nameController = TextEditingController(
        text: widget.medication['name']?.toString() ?? '');
    _genericNameController = TextEditingController(
        text: widget.medication['genericName']?.toString() ?? '');
    _internalCodeController = TextEditingController(
        text: widget.medication['code']?.toString() ?? '');
    _brandNamesController = TextEditingController(
        text: widget.medication['brandNames']?.toString() ?? '');
    _manufacturerNameController = TextEditingController(
        text: widget.medication['manufacturerName']?.toString() ??
            widget.medication['manufacturer']?.toString() ??
            '');
    _manufacturerCountryController = TextEditingController(
        text: widget.medication['manufacturerCountry']?.toString() ?? '');

    // Handle invalid form values by defaulting to 'Tablet'
    _selectedForm = widget.medication['form']?.toString() ?? 'Tablet';
    if (!_formOptions.contains(_selectedForm)) {
      _selectedForm = 'Tablet';
    }

    _ingredientController = TextEditingController(
        text: widget.medication['ingredient']?.toString() ?? '');
    _strengthController = TextEditingController(
        text: widget.medication['strength']?.toString() ?? '');

    // Handle invalid route values by defaulting to 'Oral'
    _selectedRoute = widget.medication['route']?.toString() ?? 'Oral';
    if (!_routeOptions.contains(_selectedRoute)) {
      _selectedRoute = 'Oral';
    }

    _dosageController = TextEditingController(
        text: widget.medication['dosage']?.toString() ?? '');
    _storageConditionsController = TextEditingController(
        text: widget.medication['storageConditions']?.toString() ?? '');
    _shelfLifeController = TextEditingController(
        text: widget.medication['shelfLife']?.toString() ?? '');
    _stockController = TextEditingController(
        text: widget.medication['stock']?.toString() ?? '0');

    debugPrint('Stock value from medication: ${widget.medication['stock']}');
    debugPrint('Stock controller text: ${_stockController.text}');
  }

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

  void _handleCancel() {
    if (widget.onCancel != null) {
      widget.onCancel!();
    } else {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_isUpdating,
      onPopInvoked: (didPop) {
        if (!didPop && !_isUpdating) {
          _handleCancel();
        }
      },
      child: Dialog(
        backgroundColor: AppColors.textWhite,
        insetPadding: const EdgeInsets.all(20),
        child: Container(
          padding: const EdgeInsets.all(20),
          width: MediaQuery.of(context).size.width * 0.8,
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Update Medication',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textBlack,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 📌 IDENTIFICATION
                  _sectionTitle("Identification"),
                  const SizedBox(height: 8),
                  _rowFields([
                    AppFormField(
                      controller: _nameController,
                      label: 'Name',
                      required: true,
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
                        if (value == null || value.isEmpty) {
                          return 'Please enter stock quantity';
                        }
                        if (int.tryParse(value) == null) {
                          return 'Please enter a valid number';
                        }
                        if (int.parse(value) < 0) {
                          return 'Stock cannot be negative';
                        }
                        return null;
                      },
                    ),
                  ]),

                  const SizedBox(height: 30),

                  // Actions buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      SecondaryButton(
                        text: 'Cancel',
                        onPressed: _isUpdating ? () {} : _handleCancel,
                      ),
                      const SizedBox(width: 16),
                      PrimaryButton(
                        text: _isUpdating ? 'Updating...' : 'Update',
                        onPressed:
                            _isUpdating ? null : () => _updateMedication(),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _updateMedication() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isUpdating = true;
      });

      try {
        final formData = {
          // Identification
          'name': _nameController.text.trim(),
          'genericName': _genericNameController.text.trim(),
          'code': _internalCodeController.text.trim(),
          'brandNames': _brandNamesController.text.trim(),
          'manufacturerName': _manufacturerNameController.text.trim(),
          'manufacturerCountry': _manufacturerCountryController.text.trim(),

          // Pharmaceutical Properties
          'form': _selectedForm,
          'dosage': _dosageController.text.trim(),
          'ingredient': _ingredientController.text.trim(),
          'strength': _strengthController.text.trim(),
          'route': _selectedRoute,
          'storageConditions': _storageConditionsController.text.trim(),
          'shelfLife': _shelfLifeController.text.trim(),

          // Stock
          'stock': int.tryParse(_stockController.text.trim()) ?? 0,
        };

        debugPrint('Form data before calling onUpdate: $formData');

        await widget.onUpdate(formData);
      } catch (e) {
        debugPrint('Error in _updateMedication: $e');
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
            _isUpdating = false;
          });
        }
      }
    }
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
