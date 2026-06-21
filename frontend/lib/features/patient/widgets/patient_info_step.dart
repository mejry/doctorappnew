// lib/features/patient/widgets/patient_info_step.dart - MODIFIÉ
import 'package:flutter/material.dart';
import 'package:frontend/core/constants/primary_button.dart';
import 'package:frontend/core/constants/secondary_button.dart';
import 'package:frontend/features/patient/models/patient.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/form_styles.dart';

class PatientInfoStep extends StatefulWidget {
  final Patient? initialData;
  final Function(Patient) onNext;

  const PatientInfoStep({
    super.key,
    this.initialData,
    required this.onNext,
  });

  @override
  State<PatientInfoStep> createState() => _PatientInfoStepState();
}

class _PatientInfoStepState extends State<PatientInfoStep> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _emergencyContactNameController = TextEditingController();
  final _emergencyContactPhoneController = TextEditingController();
  final _emergencyContactRelationshipController = TextEditingController();
  final _dateOfBirthController = TextEditingController();
  final _registrationDateController = TextEditingController();

  String? _selectedGender;
  String? _selectedCivilStatus;
  DateTime? _dateOfBirth;
  DateTime? _registrationDate;

  @override
  void initState() {
    super.initState();

    // Initialize with existing data if available
    if (widget.initialData != null) {
      final patient = widget.initialData!;
      _firstNameController.text = patient.firstName;
      _lastNameController.text = patient.lastName;
      _emailController.text = patient.email;
      _phoneController.text = patient.phoneNumber ?? '';
      _addressController.text = patient.address ?? '';
      _selectedGender = patient.gender;
      _selectedCivilStatus = patient.civilStatus;
      _dateOfBirth = patient.dateOfBirth;
      _registrationDate = patient.dateOfRegistration;

      if (patient.emergencyContacts?.isNotEmpty == true) {
        final contact = patient.emergencyContacts!.first;
        _emergencyContactNameController.text = contact.name;
        _emergencyContactPhoneController.text = contact.phone;
        _emergencyContactRelationshipController.text = contact.relationship;
      }

      _dateOfBirthController.text =
          DateFormat('yyyy-MM-dd').format(_dateOfBirth!);
      _registrationDateController.text = _registrationDate != null
          ? DateFormat('yyyy-MM-dd').format(_registrationDate!)
          : DateFormat('yyyy-MM-dd').format(DateTime.now());
    } else {
      // Set default registration date for new patients
      _registrationDate = DateTime.now();
      _registrationDateController.text =
          DateFormat('yyyy-MM-dd').format(_registrationDate!);
    }
  }

  Widget _buildTextField(String label, TextEditingController controller,
      {bool required = false}) {
    return AppFormStyles.wrapWithShadow(
      TextFormField(
        controller: controller,
        decoration: AppFormStyles.inputDecoration(label),
        validator: required
            ? (value) => (value == null || value.isEmpty)
                ? 'This field is required'
                : null
            : null,
      ),
    );
  }

  Widget _buildDropdownField(String label, List<String> options, String? value,
      Function(String?) onChanged,
      {bool required = false}) {
    return AppFormStyles.wrapWithShadow(
      DropdownButtonFormField<String>(
        value: value,
        decoration: AppFormStyles.inputDecoration(label),
        items: options
            .map((option) =>
                DropdownMenuItem(value: option, child: Text(option)))
            .toList(),
        onChanged: onChanged,
        validator: required
            ? (value) => (value == null || value.isEmpty)
                ? 'Please select a value'
                : null
            : null,
      ),
    );
  }

  Widget _buildDatePickerField(
    String label,
    TextEditingController controller,
    DateTime? selectedDate,
    Function(DateTime) onDateSelected, {
    bool required = false,
  }) {
    return AppFormStyles.wrapWithShadow(
      TextFormField(
        controller: controller,
        readOnly: true,
        decoration: AppFormStyles.inputDecoration(label,
            suffixIcon: const Icon(Icons.calendar_today)),
        onTap: () async {
          DateTime? picked = await showDatePicker(
            context: context,
            initialDate: selectedDate ?? DateTime(1990),
            firstDate: DateTime(1900),
            lastDate: DateTime.now(),
          );
          if (picked != null) {
            onDateSelected(picked);
            controller.text = DateFormat('yyyy-MM-dd').format(picked);
          }
        },
        validator: required
            ? (value) =>
                (value == null || value.isEmpty) ? 'Date is required' : null
            : null,
      ),
    );
  }

  void _saveAndProceed() {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedGender == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a gender')),
      );
      return;
    }
    if (_dateOfBirth == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select date of birth')),
      );
      return;
    }

    final patient = Patient(
      id: widget.initialData?.id,
      firstName: _firstNameController.text.trim(),
      lastName: _lastNameController.text.trim(),
      email: _emailController.text.trim(),
      gender: _selectedGender!,
      dateOfBirth: _dateOfBirth!,
      address: _addressController.text.trim().isNotEmpty
          ? _addressController.text.trim()
          : null,
      civilStatus: _selectedCivilStatus,
      phoneNumber: _phoneController.text.trim().isNotEmpty
          ? _phoneController.text.trim()
          : null,
      emergencyContacts: _emergencyContactNameController.text.trim().isNotEmpty
          ? [
              EmergencyContact(
                name: _emergencyContactNameController.text.trim(),
                phone: _emergencyContactPhoneController.text.trim(),
                relationship:
                    _emergencyContactRelationshipController.text.trim(),
              )
            ]
          : null,
      dateOfRegistration: _registrationDate,
    );

    widget.onNext(patient);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 800),
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 30),
                  Wrap(
                    spacing: 20,
                    runSpacing: 20,
                    alignment: WrapAlignment.center,
                    children: [
                      SizedBox(
                        width: 350,
                        child: _buildTextField(
                            "First Name", _firstNameController,
                            required: true),
                      ),
                      SizedBox(
                        width: 350,
                        child: _buildTextField("Last Name", _lastNameController,
                            required: true),
                      ),
                      SizedBox(
                        width: 350,
                        child: _buildTextField("Email", _emailController,
                            required: true),
                      ),
                      SizedBox(
                        width: 350,
                        child: _buildDropdownField(
                          "Gender",
                          ["Male", "Female", "Other"],
                          _selectedGender,
                          (value) => setState(() => _selectedGender = value),
                          required: true,
                        ),
                      ),
                      SizedBox(
                        width: 350,
                        child: _buildDatePickerField(
                          "Date of Birth",
                          _dateOfBirthController,
                          _dateOfBirth,
                          (date) => setState(() => _dateOfBirth = date),
                          required: true,
                        ),
                      ),
                      SizedBox(
                        width: 350,
                        child: _buildDropdownField(
                          "Civil Status",
                          ["Single", "Married", "Divorced", "Widowed"],
                          _selectedCivilStatus,
                          (value) =>
                              setState(() => _selectedCivilStatus = value),
                        ),
                      ),
                      SizedBox(
                        width: 350,
                        child:
                            _buildTextField("Phone Number", _phoneController),
                      ),
                      SizedBox(
                        width: 350,
                        child: _buildTextField("Address", _addressController),
                      ),
                      // Emergency Contact Section
                      const SizedBox(width: 350, child: Divider()),
                      const SizedBox(
                        width: 350,
                        child: Text(
                          'Emergency Contact (Optional)',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 350,
                        child: _buildTextField(
                            "Contact Name", _emergencyContactNameController),
                      ),
                      SizedBox(
                        width: 350,
                        child: _buildTextField(
                            "Contact Phone", _emergencyContactPhoneController),
                      ),
                      SizedBox(
                        width: 350,
                        child: _buildTextField("Relationship",
                            _emergencyContactRelationshipController),
                      ),
                      SizedBox(
                        width: 350,
                        child: _buildDatePickerField(
                          "Date of Registration",
                          _registrationDateController,
                          _registrationDate,
                          (date) => setState(() => _registrationDate = date),
                          required: true,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SecondaryButton(
                        text: "Cancel",
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      const SizedBox(width: 16),
                      PrimaryButton(
                        text: "Next",
                        onPressed: _saveAndProceed,
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

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _emergencyContactNameController.dispose();
    _emergencyContactPhoneController.dispose();
    _emergencyContactRelationshipController.dispose();
    _dateOfBirthController.dispose();
    _registrationDateController.dispose();
    super.dispose();
  }
}
