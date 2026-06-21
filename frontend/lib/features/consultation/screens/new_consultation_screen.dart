// lib/features/consultation/screens/new_consultation_screen.dart
import 'package:flutter/material.dart';
import 'package:frontend/core/constants/colors.dart';
import 'package:frontend/core/constants/primary_button.dart';
import 'package:frontend/core/constants/secondary_button.dart';
import 'package:frontend/core/constants/add_button.dart';
import 'package:frontend/core/constants/form_styles.dart';
import 'package:frontend/features/consultation/models/consultation.dart';
import 'package:frontend/features/consultation/services/consultation_service.dart';
import 'package:frontend/features/patient/services/patient_service.dart';
import 'package:frontend/features/patient/models/patient.dart';

class NewConsultationScreen extends StatefulWidget {
  final String? patientId;
  final VoidCallback onBack;
  final Function(String) onConsultationSaved;

  const NewConsultationScreen({
    super.key,
    this.patientId,
    required this.onBack,
    required this.onConsultationSaved,
  });

  @override
  State<NewConsultationScreen> createState() => _NewConsultationScreenState();
}

class _NewConsultationScreenState extends State<NewConsultationScreen> {
  final _formKey = GlobalKey<FormState>();
  final ConsultationService _consultationService = ConsultationService();
  final PatientService _patientService = PatientService();

  // Controllers
  final _patientSearchController = TextEditingController();
  final _notesController = TextEditingController();
  final _symptomController = TextEditingController();
  final _diagnosisController = TextEditingController();
  final _analysisController = TextEditingController();

  // Form data
  Patient? _selectedPatient;
  List<Patient> _searchResults = [];
  String? _consultationType = 'Consultation';
  String? _consultationStatus = 'Completed';
  DateTime _consultationDate = DateTime.now();
  DateTime _consultationStartTime = DateTime.now();
  bool _isEmergency = false;

  // Dynamic lists
  final List<String> _symptoms = [];
  final List<String> _diagnoses = [];
  final List<String> _prescribedAnalyses = [];

  bool _isLoading = false;
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _consultationStartTime =
        DateTime.now(); // Enregistre le moment de l'ouverture

    if (widget.patientId != null) {
      _loadPatient(widget.patientId!);
    }
  }

  Future<void> _loadPatient(String patientId) async {
    try {
      final patient = await _patientService.getPatientById(patientId);
      setState(() {
        _selectedPatient = patient;
        _patientSearchController.text = patient.fullName;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading patient: $e')),
      );
    }
  }

  Future<void> _searchPatients(String query) async {
    if (query.isEmpty) {
      setState(() => _searchResults.clear());
      return;
    }

    setState(() => _isSearching = true);
    try {
      final results = await _patientService.searchPatients(
        firstName: query.split(' ').first,
        lastName: query.split(' ').length > 1 ? query.split(' ').last : null,
      );
      setState(() {
        _searchResults = results;
        _isSearching = false;
      });
    } catch (e) {
      setState(() => _isSearching = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error searching patients: $e')),
      );
    }
  }

  void _addToList(
      String item, List<String> list, TextEditingController controller) {
    if (item.trim().isNotEmpty && !list.contains(item.trim())) {
      setState(() {
        list.add(item.trim());
        controller.clear();
      });
    }
  }

  void _removeFromList(int index, List<String> list) {
    setState(() {
      list.removeAt(index);
    });
  }

  bool _validateAndSave() {
    if (!_formKey.currentState!.validate()) {
      return false;
    }

    if (_selectedPatient == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a patient'),
          backgroundColor: Colors.orange,
        ),
      );
      return false;
    }

    if (_symptoms.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add at least one symptom'),
          backgroundColor: Colors.orange,
        ),
      );
      return false;
    }

    if (_diagnoses.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add at least one diagnosis'),
          backgroundColor: Colors.orange,
        ),
      );
      return false;
    }

    return true;
  }

  Future<void> _saveConsultation() async {
    if (!_validateAndSave()) return;

    setState(() => _isLoading = true);
    try {
      // Calculate duration automatically
      final consultationEndTime = DateTime.now();
      final durationInMinutes =
          consultationEndTime.difference(_consultationStartTime).inMinutes;

      // Format time as HH:MM with leading zeros
      final formattedTime =
          '${_consultationStartTime.hour.toString().padLeft(2, '0')}:'
          '${_consultationStartTime.minute.toString().padLeft(2, '0')}';

      final consultation = Consultation(
        patientId: _selectedPatient!.id!,
        date: _consultationDate,
        time: formattedTime,
        type: _consultationType!,
        status: _consultationStatus!,
        symptoms: _symptoms,
        diagnosis: _diagnoses,
        prescribedAnalyses: _prescribedAnalyses,
        notes: _notesController.text.trim().isNotEmpty
            ? _notesController.text.trim()
            : null,
        duration: durationInMinutes,
        isEmergency: _isEmergency,
      );

      final savedConsultation =
          await _consultationService.createConsultation(consultation);

      setState(() => _isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Consultation created successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      widget.onConsultationSaved(savedConsultation.id!);
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving consultation: $e')),
      );
    }
  }

  Widget _buildCard(String title, Widget child) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  _getIconForTitle(title),
                  color: AppColors.primary,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: child,
          ),
        ],
      ),
    );
  }

  IconData _getIconForTitle(String title) {
    switch (title) {
      case 'Patient Information':
        return Icons.person_outline;
      case 'General Information':
        return Icons.info_outline;
      case 'Symptoms':
        return Icons.medical_services;
      case 'Diagnosis':
        return Icons.psychology;
      case 'Prescribed Tests':
        return Icons.science;
      case 'Additional Notes':
        return Icons.note_add;
      default:
        return Icons.circle;
    }
  }

  Widget _buildDynamicList(
    String label,
    String hint,
    TextEditingController controller,
    List<String> items,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: controller,
                decoration: AppFormStyles.inputDecoration(hint),
                onFieldSubmitted: (value) {
                  _addToList(value, items, controller);
                },
              ),
            ),
            const SizedBox(width: 8),
            AddButton(
              text: '',
              icon: Icons.add,
              onPressed: () {
                _addToList(controller.text, items, controller);
              },
            ),
          ],
        ),
        if (items.isNotEmpty) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: items.asMap().entries.map((entry) {
              return Chip(
                label: Text(entry.value),
                onDeleted: () => _removeFromList(entry.key, items),
                deleteIcon: const Icon(Icons.close, size: 16),
                backgroundColor: AppColors.primary.withOpacity(0.1),
                labelStyle: const TextStyle(fontSize: 11),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }

  Widget _buildPatientSearchField() {
    return Column(
      children: [
        TextFormField(
          controller: _patientSearchController,
          decoration: AppFormStyles.inputDecoration(
            'Search patient by name...',
            suffixIcon: _isSearching
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.search),
          ),
          onChanged: _searchPatients,
        ),
        if (_searchResults.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 8),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            constraints: const BoxConstraints(maxHeight: 200),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _searchResults.length,
              itemBuilder: (context, index) {
                final patient = _searchResults[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppColors.primary,
                    child: Text(
                      patient.firstName[0] + patient.lastName[0],
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  title: Text(patient.fullName),
                  subtitle: Text('${patient.age} years • ${patient.email}'),
                  onTap: () {
                    setState(() {
                      _selectedPatient = patient;
                      _patientSearchController.text = patient.fullName;
                      _searchResults.clear();
                    });
                  },
                );
              },
            ),
          ),
        if (_selectedPatient != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: AppColors.primary,
                  child: Text(
                    _selectedPatient!.firstName[0] +
                        _selectedPatient!.lastName[0],
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _selectedPatient!.fullName,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                          '${_selectedPatient!.age} years • ${_selectedPatient!.email}'),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: () {
                    setState(() {
                      _selectedPatient = null;
                      _patientSearchController.clear();
                    });
                  },
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 252, 252, 252),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                // Header
                Row(
                  children: [
                    ElevatedButton.icon(
                      onPressed: widget.onBack,
                      icon: const Icon(Icons.arrow_back),
                      label: const Text("Back to list"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[200],
                        foregroundColor: Colors.black,
                        elevation: 0,
                      ),
                    ),
                    const Spacer(),
                    const Text(
                      'New Consultation',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Patient Information (only show if no patientId provided)
                if (widget.patientId == null)
                  _buildCard(
                    'Patient Information',
                    _buildPatientSearchField(),
                  ),

                // General Information
                _buildCard(
                  'General Information',
                  Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.calendar_today, size: 18),
                                  const SizedBox(width: 8),
                                  Text(
                                    '${_consultationDate.day}/${_consultationDate.month}/${_consultationDate.year}',
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.access_time, size: 18),
                                  const SizedBox(width: 8),
                                  Text(
                                    '${_consultationStartTime.hour.toString().padLeft(2, '0')}:'
                                    '${_consultationStartTime.minute.toString().padLeft(2, '0')}',
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _consultationType,
                              decoration: AppFormStyles.inputDecoration('Type'),
                              items: const [
                                'Check-up',
                                'Test',
                                'Consultation',
                                'Control',
                                'Follow-up',
                                'Emergency'
                              ].map((type) {
                                return DropdownMenuItem(
                                  value: type,
                                  child: Text(type),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  _consultationType = value;
                                  _isEmergency = value == 'Emergency';
                                });
                              },
                              validator: (value) =>
                                  value == null ? 'Required' : null,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _consultationStatus,
                              decoration:
                                  AppFormStyles.inputDecoration('Status'),
                              items: const [
                                'Completed',
                                'Scheduled',
                                'Canceled',
                                'Waiting',
                                'In Progress'
                              ].map((status) {
                                return DropdownMenuItem(
                                  value: status,
                                  child: Text(status),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  _consultationStatus = value;
                                });
                              },
                              validator: (value) =>
                                  value == null ? 'Required' : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SwitchListTile(
                        title: const Text('Emergency consultation'),
                        value: _isEmergency,
                        onChanged: (value) {
                          setState(() {
                            _isEmergency = value;
                          });
                        },
                        activeColor: AppColors.primary,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ],
                  ),
                ),

                // Symptoms (REQUIRED)
                _buildCard(
                  'Symptoms *',
                  _buildDynamicList(
                    'Symptoms',
                    'Add symptom...',
                    _symptomController,
                    _symptoms,
                  ),
                ),

                // Diagnosis (REQUIRED)
                _buildCard(
                  'Diagnosis *',
                  _buildDynamicList(
                    'Diagnosis',
                    'Add diagnosis...',
                    _diagnosisController,
                    _diagnoses,
                  ),
                ),

                // Prescribed Tests (OPTIONAL)
                _buildCard(
                  'Prescribed Tests',
                  _buildDynamicList(
                    'Tests',
                    'Add test...',
                    _analysisController,
                    _prescribedAnalyses,
                  ),
                ),

                // Additional Notes
                _buildCard(
                  'Additional Notes',
                  TextFormField(
                    controller: _notesController,
                    decoration:
                        AppFormStyles.inputDecoration('Consultation notes...'),
                    maxLines: 3,
                  ),
                ),

                const SizedBox(height: 20),

                // Action buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    SecondaryButton(
                      text: "Cancel",
                      onPressed: widget.onBack,
                    ),
                    PrimaryButton(
                      text: _isLoading ? "Saving..." : "Save Consultation",
                      onPressed: _isLoading ? null : _saveConsultation,
                    ),
                  ],
                ),

                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _patientSearchController.dispose();
    _notesController.dispose();
    _symptomController.dispose();
    _diagnosisController.dispose();
    _analysisController.dispose();
    super.dispose();
  }
}
