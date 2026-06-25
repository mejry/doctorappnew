import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:frontend/core/constants/colors.dart';
import 'package:frontend/core/services/session_manager.dart';
import 'package:frontend/features/appointment/models/appointment.dart';
import 'package:frontend/features/appointment/services/appointment_service.dart';
import 'package:frontend/shared/widgets/forms/form_field.dart';

class AddAppointmentScreen extends StatefulWidget {
  final VoidCallback onBack;
  final VoidCallback onSaved;

  const AddAppointmentScreen({
    super.key,
    required this.onBack,
    required this.onSaved,
  });

  @override
  State<AddAppointmentScreen> createState() => _AddAppointmentScreenState();
}

class _AddAppointmentScreenState extends State<AddAppointmentScreen> {
  final _formKey = GlobalKey<FormState>();
  final AppointmentService _appointmentService = AppointmentService();
  final SessionManager _sessionManager = SessionManager();

  final TextEditingController _patientNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _doctorNameController = TextEditingController();
  final TextEditingController _doctorIdController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _timeController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  String _selectedType = 'Consultation';
  String _selectedDuration = '30';
  bool _saving = false;
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();

  @override
  void initState() {
    super.initState();
    _populateDoctorInfo();
    _updateDateTimeFields();
  }

  void _populateDoctorInfo() {
    final userInfo = _sessionManager.userInfo;
    if (userInfo != null) {
      final firstName = userInfo['firstname'] ?? '';
      final lastName = userInfo['lastname'] ?? '';
      final role = userInfo['role']?.toString().toLowerCase();
      if (role == 'doctor' || role == 'doctor') {
        _doctorNameController.text = '$firstName $lastName'.trim();
        _doctorIdController.text = userInfo['id'] ?? '';
      }
    }
  }

  void _updateDateTimeFields() {
    _dateController.text = DateFormat('yyyy-MM-dd').format(_selectedDate);
    final String hour = _selectedTime.hour.toString().padLeft(2, '0');
    final String minute = _selectedTime.minute.toString().padLeft(2, '0');
    _timeController.text = '$hour:$minute';
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date != null) {
      setState(() {
        _selectedDate = date;
        _updateDateTimeFields();
      });
    }
  }

  Future<void> _pickTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (time != null) {
      setState(() {
        _selectedTime = time;
        _updateDateTimeFields();
      });
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_doctorIdController.text.isEmpty || _doctorNameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Doctor name and ID are required.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _saving = true);

    try {
      final appointment = Appointment(
        patientName: _patientNameController.text.trim(),
        patientEmail: _emailController.text.trim().isEmpty
            ? null
            : _emailController.text.trim(),
        patientPhone: _phoneController.text.trim().isEmpty
            ? null
            : _phoneController.text.trim(),
        doctorName: _doctorNameController.text.trim(),
        doctorId: _doctorIdController.text.trim(),
        date: _selectedDate,
        time: _timeController.text,
        type: _selectedType,
        duration: int.tryParse(_selectedDuration) ?? 30,
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
      );

      await _appointmentService.createAppointment(appointment);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Appointment created successfully'),
          backgroundColor: Colors.green,
        ),
      );
      widget.onSaved();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving appointment: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('New Appointment',
            style: TextStyle(color: Colors.black)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: widget.onBack,
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Column(
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Appointment Details',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    AppFormField(
                      label: 'Patient Name *',
                      controller: _patientNameController,
                      required: true,
                    ),
                    const SizedBox(height: 14),
                    AppFormField(
                      label: 'Patient Email',
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 14),
                    AppFormField(
                      label: 'Patient Phone',
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 14),
                    AppFormField(
                      label: 'Doctor Name *',
                      controller: _doctorNameController,
                      required: true,
                    ),
                    const SizedBox(height: 14),
                    AppFormField(
                      label: 'Doctor ID *',
                      controller: _doctorIdController,
                      required: true,
                    ),
                    const SizedBox(height: 14),
                    AppFormField(
                      label: 'Date *',
                      controller: _dateController,
                      readOnly: true,
                      required: true,
                      onTap: _pickDate,
                    ),
                    const SizedBox(height: 14),
                    AppFormField(
                      label: 'Time *',
                      controller: _timeController,
                      readOnly: true,
                      required: true,
                      onTap: _pickTime,
                    ),
                    const SizedBox(height: 14),
                    AppDropdownField<String>(
                      label: 'Type *',
                      required: true,
                      value: _selectedType,
                      items: const [
                        DropdownMenuItem(
                          value: 'Consultation',
                          child: Text('Consultation'),
                        ),
                        DropdownMenuItem(
                          value: 'Follow-up',
                          child: Text('Follow-up'),
                        ),
                        DropdownMenuItem(
                          value: 'Emergency',
                          child: Text('Emergency'),
                        ),
                        DropdownMenuItem(
                          value: 'Test',
                          child: Text('Test'),
                        ),
                        DropdownMenuItem(
                          value: 'Procedure',
                          child: Text('Procedure'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _selectedType = value);
                        }
                      },
                    ),
                    const SizedBox(height: 14),
                    AppDropdownField<String>(
                      label: 'Duration (minutes)',
                      required: true,
                      value: _selectedDuration,
                      items: const [
                        DropdownMenuItem(value: '15', child: Text('15')),
                        DropdownMenuItem(value: '30', child: Text('30')),
                        DropdownMenuItem(value: '45', child: Text('45')),
                        DropdownMenuItem(value: '60', child: Text('60')),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _selectedDuration = value);
                        }
                      },
                    ),
                    const SizedBox(height: 14),
                    AppFormField(
                      label: 'Notes',
                      controller: _notesController,
                      keyboardType: TextInputType.multiline,
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _saving ? null : _submitForm,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: Text(
                          _saving ? 'Saving...' : 'Save Appointment',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
