// lib/features/patient/widgets/consultation_step.dart - VERSION AMÉLIORÉE
import 'package:flutter/material.dart';
import 'package:frontend/core/constants/add_button.dart';
import 'package:frontend/core/constants/primary_button.dart';
import 'package:frontend/core/constants/secondary_button.dart';
import 'package:frontend/shared/widgets/forms/form_field.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/form_styles.dart';

class ConsultationStep extends StatefulWidget {
  final Function(Map<String, dynamic>) onNext;
  final VoidCallback onBack;

  const ConsultationStep({
    super.key,
    required this.onNext,
    required this.onBack,
  });

  @override
  State<ConsultationStep> createState() => _ConsultationStepState();
}

class _ConsultationStepState extends State<ConsultationStep> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _timeController = TextEditingController();
  final _notesController = TextEditingController();
  final _symptomController = TextEditingController();
  final _diagnosisController = TextEditingController();
  final _analysisController = TextEditingController();

  // Form data
  String? _consultationType = 'Consultation';
  String? _consultationStatus = 'Completed';
  DateTime _consultationDate = DateTime.now();
  DateTime _consultationStartTime =
      DateTime.now(); // Time when consultation started
  bool _isEmergency = false;

  // Dynamic lists
  final List<String> _symptoms = [];
  final List<String> _diagnosis = [];
  final List<String> _prescribedAnalyses = [];

  // Duration for quick selector
  int _duration = 15;
  final List<int> _quickDurations = [5, 10, 15, 20, 30, 45, 60];

  // Options
  final List<String> _consultationTypes = [
    'Check-up',
    'Test',
    'Consultation',
    'Control',
    'Follow-up',
    'Emergency'
  ];

  final List<String> _statusOptions = [
    'Scheduled',
    'Completed',
    'Canceled',
    'Waiting',
    'In Progress'
  ];

  @override
  void initState() {
    super.initState();
    // Record consultation start time when opening this step
    _consultationStartTime = DateTime.now();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_timeController.text.isEmpty) {
      _timeController.text = TimeOfDay.now().format(context);
    }
  }

  void _selectTime() async {
    TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (pickedTime != null) {
      setState(() {
        _timeController.text = pickedTime.format(context);
      });
    }
  }

  void _selectDate() async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _consultationDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (pickedDate != null) {
      setState(() {
        _consultationDate = pickedDate;
      });
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

    if (_symptoms.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add at least one symptom'),
          backgroundColor: Colors.orange,
        ),
      );
      return false;
    }

    if (_diagnosis.isEmpty) {
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

  void _saveAndProceed() {
    if (!_validateAndSave()) return;

    // Calculate duration between start and now (in minutes)
    final consultationEndTime = DateTime.now();
    final durationInMinutes =
        consultationEndTime.difference(_consultationStartTime).inMinutes;

    final consultationData = {
      'date': _consultationDate.toIso8601String(),
      'time': _timeController.text,
      'type': _consultationType!,
      'status': _consultationStatus!,
      'symptoms': _symptoms,
      'diagnosis': _diagnosis,
      'prescribedAnalyses': _prescribedAnalyses,
      'notes': _notesController.text.trim().isNotEmpty
          ? _notesController.text.trim()
          : null,
      'duration': durationInMinutes, // Calculated duration
      'startTime': _consultationStartTime.toIso8601String(),
      'endTime': consultationEndTime.toIso8601String(),
      'isEmergency': _isEmergency,
    };

    widget.onNext(consultationData);
  }

  Widget _buildCard(String title, Widget child) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: const Color.fromARGB(255, 255, 255, 255).withOpacity(0.2),
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
              child: AppFormField(
                label: hint,
                controller: controller,
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

  Widget _buildQuickDurationSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Duration: $_duration minutes',
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: _quickDurations.map((duration) {
            final isSelected = _duration == duration;
            return GestureDetector(
              onTap: () {
                setState(() {
                  _duration = duration;
                });
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : Colors.grey[200],
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${duration}min',
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.black87,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
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
                // General Information
                _buildCard(
                  'General Information',
                  Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: _selectDate,
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
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: GestureDetector(
                              onTap: _selectTime,
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
                                      _timeController.text.isNotEmpty
                                          ? _timeController.text
                                          : 'Select time',
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                  ],
                                ),
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
                              items: _consultationTypes.map((type) {
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
                              items: _statusOptions.map((status) {
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
                      // Emergency toggle
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
                    _diagnosis,
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
                  AppFormField(
                    label: 'Consultation notes...',
                    controller: _notesController,
                    //  maxLines: 3,
                  ),
                ),

                const SizedBox(height: 20),

                // Action buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    SecondaryButton(
                      text: "Back",
                      onPressed: widget.onBack,
                    ),
                    PrimaryButton(
                      text: "Next: Prescription",
                      onPressed: _saveAndProceed,
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
    _timeController.dispose();
    _notesController.dispose();
    _symptomController.dispose();
    _diagnosisController.dispose();
    _analysisController.dispose();
    super.dispose();
  }
}
