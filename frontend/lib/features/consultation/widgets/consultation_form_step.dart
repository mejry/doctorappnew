// lib/features/consultation/widgets/consultation_form_step.dart - VERSION COMPLÈTE AVEC VISIBILITÉ CORRIGÉE
import 'package:flutter/material.dart';
import 'package:frontend/core/constants/colors.dart';
import 'package:frontend/core/constants/primary_button.dart';
import 'package:frontend/core/constants/secondary_button.dart';
import 'package:frontend/core/constants/add_button.dart';
import 'package:frontend/core/constants/form_styles.dart';
import 'package:frontend/features/consultation/models/consultation.dart';
import 'package:frontend/features/patient/services/patient_service.dart';
import 'package:frontend/features/patient/models/patient.dart';
import 'package:frontend/features/appointment/models/appointment.dart';

class ConsultationFormStep extends StatefulWidget {
  final Patient? selectedPatient;
  final Appointment? prefilledAppointment;
  final Function(Consultation, Patient) onNext;
  final VoidCallback onBack;
  final bool allowPatientSelection;

  const ConsultationFormStep({
    super.key,
    this.selectedPatient,
    this.prefilledAppointment,
    required this.onNext,
    required this.onBack,
    this.allowPatientSelection = true,
  });

  @override
  State<ConsultationFormStep> createState() => _ConsultationFormStepState();
}

class _ConsultationFormStepState extends State<ConsultationFormStep> {
  final _formKey = GlobalKey<FormState>();
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

  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _consultationStartTime = DateTime.now();

    if (widget.selectedPatient != null) {
      _selectedPatient = widget.selectedPatient;
      _patientSearchController.text =
          _formatPatientName(widget.selectedPatient!.fullName);
    }
    
    if (widget.prefilledAppointment != null) {
      _consultationType = widget.prefilledAppointment!.type;
      _consultationDate = widget.prefilledAppointment!.date;
      _isEmergency = _consultationType == 'Emergency';
      if (_selectedPatient == null && widget.prefilledAppointment!.patientId != null) {
        _loadPrefilledPatient(widget.prefilledAppointment!.patientId!);
      }
    }
  }

  Future<void> _loadPrefilledPatient(String patientId) async {
    try {
      final patient = await _patientService.getPatientById(patientId);
      setState(() {
        _selectedPatient = patient;
        _patientSearchController.text = _formatPatientName(patient.fullName);
      });
    } catch (e) {
      debugPrint('Error loading patient from appointment: $e');
    }
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
    setState(() => list.removeAt(index));
  }

  bool _validateAndSave() {
    if (!_formKey.currentState!.validate()) return false;

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

  void _proceedToNext() {
    if (!_validateAndSave()) return;

    // Calculate duration
    final consultationEndTime = DateTime.now();
    final durationInMinutes =
        consultationEndTime.difference(_consultationStartTime).inMinutes;

    // Format time
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

    widget.onNext(consultation, _selectedPatient!);
  }

  /// Formate le nom du patient pour un affichage compact
  String _formatPatientName(String fullName) {
    if (fullName.length <= 15) return fullName;

    final words = fullName.split(' ');
    if (words.length >= 2) {
      // Première lettre du prénom + nom complet
      return '${words[0][0]}. ${words.sublist(1).join(' ')}';
    }

    // Si un seul mot, tronquer à 15 caractères
    return fullName.length > 15 ? '${fullName.substring(0, 13)}...' : fullName;
  }

  /// Tronque l'email pour l'affichage
  String _truncateEmail(String email) {
    if (email.length <= 15) return email;

    final atIndex = email.indexOf('@');
    if (atIndex > 0) {
      final username = email.substring(0, atIndex);
      final domain = email.substring(atIndex);

      if (username.length > 8) {
        return '${username.substring(0, 6)}...$domain';
      }
    }

    return email.length > 15 ? '${email.substring(0, 13)}...' : email;
  }

  Widget _buildCard(String title, Widget child, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header plus compact
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
            ),
            child: Row(
              children: [
                Icon(icon, color: AppColors.primary, size: 14),
                const SizedBox(width: 4),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.all(8),
            child: child,
          ),
        ],
      ),
    );
  }

  Widget _buildDynamicList(
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
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.black, // 🔧 COULEUR EXPLICITE
                ),
                onFieldSubmitted: (value) =>
                    _addToList(value, items, controller),
              ),
            ),
            const SizedBox(width: 6),
            SizedBox(
              width: 32,
              height: 32,
              child: AddButton(
                text: '',
                icon: Icons.add,
                onPressed: () => _addToList(controller.text, items, controller),
              ),
            ),
          ],
        ),
        if (items.isNotEmpty) ...[
          const SizedBox(height: 6),
          Wrap(
            spacing: 4,
            runSpacing: 4,
            children: items.asMap().entries.map((entry) {
              return Chip(
                label: Text(
                  entry.value,
                  style: const TextStyle(
                    fontSize: 10,
                    color: Colors.black, // 🔧 COULEUR EXPLICITE
                  ),
                ),
                onDeleted: () => _removeFromList(entry.key, items),
                deleteIcon: const Icon(Icons.close, size: 14),
                backgroundColor: AppColors.primary.withOpacity(0.1),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                padding: const EdgeInsets.symmetric(horizontal: 4),
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
            'Search patient...',
            suffixIcon: _isSearching
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.search, size: 16),
          ),
          style: const TextStyle(
            fontSize: 12,
            color: Colors.black, // 🔧 COULEUR EXPLICITE
          ),
          onChanged: widget.allowPatientSelection ? _searchPatients : null,
          enabled: widget.allowPatientSelection,
        ),

        // Search results
        if (_searchResults.isNotEmpty && widget.allowPatientSelection)
          Container(
            margin: const EdgeInsets.only(top: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.grey[300]!),
            ),
            constraints: const BoxConstraints(maxHeight: 120),
            child: ListView.builder(
              shrinkWrap: true,
              padding: const EdgeInsets.all(4),
              itemCount: _searchResults.length,
              itemBuilder: (context, index) {
                final patient = _searchResults[index];
                return InkWell(
                  onTap: () {
                    setState(() {
                      _selectedPatient = patient;
                      _patientSearchController.text =
                          _formatPatientName(patient.fullName);
                      _searchResults.clear();
                    });
                  },
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 12,
                          backgroundColor: AppColors.primary,
                          child: Text(
                            (patient.firstName.isNotEmpty
                                    ? patient.firstName[0]
                                    : '') +
                                (patient.lastName.isNotEmpty
                                    ? patient.lastName[0]
                                    : ''),
                            style: const TextStyle(
                                color: Colors.white, fontSize: 10),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _formatPatientName(patient.fullName),
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black, // 🔧 COULEUR EXPLICITE
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                '${patient.age} ans',
                                style: const TextStyle(
                                  fontSize: 9,
                                  color: Colors.grey, // 🔧 COULEUR EXPLICITE
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

        // Selected patient
        if (_selectedPatient != null) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: AppColors.primary,
                  child: Text(
                    (_selectedPatient!.firstName.isNotEmpty
                            ? _selectedPatient!.firstName[0]
                            : '') +
                        (_selectedPatient!.lastName.isNotEmpty
                            ? _selectedPatient!.lastName[0]
                            : ''),
                    style: const TextStyle(color: Colors.white, fontSize: 11),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _formatPatientName(_selectedPatient!.fullName),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: Colors.black, // 🔧 COULEUR EXPLICITE
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '${_selectedPatient!.age} ans • ${_truncateEmail(_selectedPatient!.email)}',
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.grey, // 🔧 COULEUR EXPLICITE
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                if (widget.allowPatientSelection)
                  IconButton(
                    icon: const Icon(Icons.close, size: 14),
                    onPressed: () {
                      setState(() {
                        _selectedPatient = null;
                        _patientSearchController.clear();
                      });
                    },
                    padding: const EdgeInsets.all(2),
                    constraints:
                        const BoxConstraints(minWidth: 24, minHeight: 24),
                  ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildConsultationDetailsSection() {
    return Column(
      children: [
        // Date et heure
        Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[400]!),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      '${_consultationDate.day}/${_consultationDate.month}/${_consultationDate.year}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.black, // 🔧 COULEUR EXPLICITE
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[400]!),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.access_time, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      '${_consultationStartTime.hour.toString().padLeft(2, '0')}:'
                      '${_consultationStartTime.minute.toString().padLeft(2, '0')}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.black, // 🔧 COULEUR EXPLICITE
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Type et Status - AVEC COULEURS CORRIGÉES
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                value: _consultationType,
                decoration: AppFormStyles.inputDecoration('Type'),
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.black, // 🔧 COULEUR EXPLICITE
                ),
                isDense: true,
                dropdownColor: Colors.white, // 🔧 FOND DROPDOWN BLANC
                items: const [
                  'Check-up',
                  'Test',
                  'Consultation',
                  'Control',
                  'Follow-up',
                  'Emergency'
                ]
                    .map((type) => DropdownMenuItem(
                          value: type,
                          child: Text(
                            type,
                            style: const TextStyle(
                              color: Colors.black, // 🔧 COULEUR EXPLICITE
                              fontSize: 12,
                            ),
                          ),
                        ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _consultationType = value;
                    _isEmergency = value == 'Emergency';
                  });
                },
                validator: (value) => value == null ? 'Required' : null,
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: DropdownButtonFormField<String>(
                value: _consultationStatus,
                decoration: AppFormStyles.inputDecoration('Status'),
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.black, // 🔧 COULEUR EXPLICITE
                ),
                isDense: true,
                dropdownColor: Colors.white, // 🔧 FOND DROPDOWN BLANC
                items: const [
                  'Completed',
                  'Scheduled',
                  'Canceled',
                  'Waiting',
                  'In Progress'
                ]
                    .map((status) => DropdownMenuItem(
                          value: status,
                          child: Text(
                            status,
                            style: const TextStyle(
                              color: Colors.black, // 🔧 COULEUR EXPLICITE
                              fontSize: 12,
                            ),
                          ),
                        ))
                    .toList(),
                onChanged: (value) =>
                    setState(() => _consultationStatus = value),
                validator: (value) => value == null ? 'Required' : null,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),

        // Switch Emergency
        SwitchListTile(
          title: const Text(
            'Emergency consultation',
            style: TextStyle(
              fontSize: 12,
              color: Colors.black, // 🔧 COULEUR EXPLICITE
            ),
          ),
          value: _isEmergency,
          onChanged: (value) => setState(() => _isEmergency = value),
          activeColor: AppColors.primary,
          contentPadding: EdgeInsets.zero,
          dense: true,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            // Patient Selection
            if (widget.allowPatientSelection || _selectedPatient != null)
              _buildCard(
                'Patient Information',
                _buildPatientSearchField(),
                Icons.person_outline,
              ),

            // Consultation Details
            _buildCard(
              'Consultation Details',
              _buildConsultationDetailsSection(),
              Icons.info_outline,
            ),

            // Symptoms
            _buildCard(
              'Symptoms *',
              _buildDynamicList(
                  'Add symptom...', _symptomController, _symptoms),
              Icons.medical_services,
            ),

            // Diagnosis
            _buildCard(
              'Diagnosis *',
              _buildDynamicList(
                  'Add diagnosis...', _diagnosisController, _diagnoses),
              Icons.psychology,
            ),

            // Prescribed Tests
            _buildCard(
              'Prescribed Tests',
              _buildDynamicList(
                  'Add test...', _analysisController, _prescribedAnalyses),
              Icons.science,
            ),

            // Additional Notes
            _buildCard(
              'Additional Notes',
              TextFormField(
                controller: _notesController,
                decoration:
                    AppFormStyles.inputDecoration('Consultation notes...'),
                maxLines: 2,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.black, // 🔧 COULEUR EXPLICITE
                ),
              ),
              Icons.note_add,
            ),

            const SizedBox(height: 12),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: SecondaryButton(
                    text: "Back",
                    onPressed: widget.onBack,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: PrimaryButton(
                    text: "Save & Continue",
                    onPressed: _proceedToNext,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
