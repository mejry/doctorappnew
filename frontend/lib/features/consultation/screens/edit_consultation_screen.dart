// lib/features/consultation/screens/edit_consultation_screen.dart - VERSION COMPLÈTE AVEC DURÉE
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:frontend/core/constants/colors.dart';
import 'package:frontend/core/constants/primary_button.dart';
import 'package:frontend/core/constants/secondary_button.dart';
import 'package:frontend/core/constants/add_button.dart';
import 'package:frontend/core/constants/form_styles.dart';
import 'package:frontend/features/consultation/models/consultation.dart';
import 'package:frontend/features/consultation/services/consultation_service.dart';
import 'package:intl/intl.dart';

class EditConsultationScreen extends StatefulWidget {
  final String consultationId;
  final VoidCallback onBack;
  final VoidCallback onSaved;

  const EditConsultationScreen({
    super.key,
    required this.consultationId,
    required this.onBack,
    required this.onSaved,
  });

  @override
  State<EditConsultationScreen> createState() => _EditConsultationScreenState();
}

class _EditConsultationScreenState extends State<EditConsultationScreen> {
  final _formKey = GlobalKey<FormState>();
  final ConsultationService _consultationService = ConsultationService();

  // Controllers
  final _notesController = TextEditingController();
  final _symptomController = TextEditingController();
  final _diagnosisController = TextEditingController();
  final _analysisController = TextEditingController();
  final _durationController = TextEditingController(); // 🆕 AJOUT DURÉE

  // Form data
  Consultation? _originalConsultation;
  String? _consultationType;
  String? _consultationStatus;
  DateTime? _consultationDate;
  TimeOfDay? _consultationTime;
  bool _isEmergency = false;
  int _duration = 30; // 🆕 DURÉE PAR DÉFAUT

  // Dynamic lists
  List<String> _symptoms = [];
  List<String> _diagnoses = [];
  List<String> _prescribedAnalyses = [];

  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadConsultation();
  }

  Future<void> _loadConsultation() async {
    setState(() => _isLoading = true);
    try {
      final consultation =
          await _consultationService.getConsultationById(widget.consultationId);

      setState(() {
        _originalConsultation = consultation;
        _consultationType = consultation.type;
        _consultationStatus = consultation.status;
        _consultationDate = consultation.date;
        _consultationTime = TimeOfDay(
          hour: int.parse(consultation.time.split(':')[0]),
          minute: int.parse(consultation.time.split(':')[1]),
        );
        _isEmergency = consultation.isEmergency;
        _symptoms = List<String>.from(consultation.symptoms);
        _diagnoses = List<String>.from(consultation.diagnosis);
        _prescribedAnalyses =
            List<String>.from(consultation.prescribedAnalyses);
        _notesController.text = consultation.notes ?? '';

        // 🆕 GESTION DE LA DURÉE
        _duration = consultation.duration ?? 30; // Si null, défaut 30
        if (_duration < 5) _duration = 30; // Si trop petit, défaut 30
        _durationController.text = _duration.toString();

        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading consultation: $e')),
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

  bool _hasChanges() {
    if (_originalConsultation == null) return false;

    final originalDuration = _originalConsultation!.duration ?? 30;

    return _consultationType != _originalConsultation!.type ||
        _consultationStatus != _originalConsultation!.status ||
        _consultationDate != _originalConsultation!.date ||
        _isEmergency != _originalConsultation!.isEmergency ||
        _duration != originalDuration || // 🆕 COMPARAISON DURÉE
        _notesController.text != (_originalConsultation!.notes ?? '') ||
        !_listEquals(_symptoms, _originalConsultation!.symptoms) ||
        !_listEquals(_diagnoses, _originalConsultation!.diagnosis) ||
        !_listEquals(
            _prescribedAnalyses, _originalConsultation!.prescribedAnalyses);
  }

  bool _listEquals(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_hasChanges()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No changes to save'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_symptoms.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add at least one symptom'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_diagnoses.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add at least one diagnosis'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final formattedTime =
          '${_consultationTime!.hour.toString().padLeft(2, '0')}:'
          '${_consultationTime!.minute.toString().padLeft(2, '0')}';

      final updatedConsultation = _originalConsultation!.copyWith(
        date: _consultationDate!,
        time: formattedTime,
        type: _consultationType!,
        status: _consultationStatus!,
        symptoms: _symptoms,
        diagnosis: _diagnoses,
        prescribedAnalyses: _prescribedAnalyses,
        notes: _notesController.text.trim().isNotEmpty
            ? _notesController.text.trim()
            : null,
        isEmergency: _isEmergency,
        duration: _duration, // 🆕 INCLURE LA DURÉE
      );

      await _consultationService.updateConsultation(
        widget.consultationId,
        updatedConsultation,
      );

      setState(() => _isSaving = false);
      widget.onSaved();
    } catch (e) {
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving consultation: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

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
                      onPressed: () {
                        if (_hasChanges()) {
                          _showUnsavedChangesDialog();
                        } else {
                          widget.onBack();
                        }
                      },
                      icon: const Icon(Icons.arrow_back),
                      label: const Text("Back"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[200],
                        foregroundColor: Colors.black,
                        elevation: 0,
                      ),
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        const Text(
                          'Edit Consultation',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                        if (_hasChanges()) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.orange.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.orange),
                            ),
                            child: const Text(
                              'Modified',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.orange,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // General Information
                _buildCard(
                  'General Information',
                  Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: _selectDate,
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.calendar_today, size: 18),
                                    const SizedBox(width: 8),
                                    Text(
                                      DateFormat('dd/MM/yyyy')
                                          .format(_consultationDate!),
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: InkWell(
                              onTap: _selectTime,
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.access_time, size: 18),
                                    const SizedBox(width: 8),
                                    Text(
                                      '${_consultationTime!.hour.toString().padLeft(2, '0')}:'
                                      '${_consultationTime!.minute.toString().padLeft(2, '0')}',
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
                              items: const [
                                'Bilan',
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
                                'InProgress',
                                'Canceled',
                                'Waiting'
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

                      // 🆕 CHAMP DURÉE AJOUTÉ
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _durationController,
                              decoration: AppFormStyles.inputDecoration(
                                  'Duration (minutes) *'),
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                LengthLimitingTextInputFormatter(3),
                              ],
                              onChanged: (value) {
                                final duration = int.tryParse(value);
                                if (duration != null) {
                                  setState(() {
                                    _duration = duration;
                                  });
                                }
                              },
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Duration is required';
                                }
                                final duration = int.tryParse(value);
                                if (duration == null) {
                                  return 'Must be a number';
                                }
                                if (duration < 5 || duration > 240) {
                                  return 'Duration must be between 5 and 240 minutes';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 10),
                          // 🆕 BOUTONS DURÉE PRÉDÉFINIE
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Quick select:',
                                  style: TextStyle(
                                      fontSize: 12, color: Colors.grey),
                                ),
                                const SizedBox(height: 4),
                                Wrap(
                                  spacing: 4,
                                  children: [15, 30, 45, 60].map((minutes) {
                                    return GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          _duration = minutes;
                                          _durationController.text =
                                              minutes.toString();
                                        });
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: _duration == minutes
                                              ? AppColors.primary
                                              : Colors.grey[200],
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          '${minutes}m',
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: _duration == minutes
                                                ? Colors.white
                                                : Colors.black,
                                          ),
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ],
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

                // Symptoms
                _buildCard(
                  'Symptoms *',
                  _buildDynamicList(
                    'Symptoms',
                    'Add symptom...',
                    _symptomController,
                    _symptoms,
                  ),
                ),

                // Diagnosis
                _buildCard(
                  'Diagnosis *',
                  _buildDynamicList(
                    'Diagnosis',
                    'Add diagnosis...',
                    _diagnosisController,
                    _diagnoses,
                  ),
                ),

                // Prescribed Tests
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
                      onPressed: () {
                        if (_hasChanges()) {
                          _showUnsavedChangesDialog();
                        } else {
                          widget.onBack();
                        }
                      },
                    ),
                    PrimaryButton(
                      text: _isSaving ? "Saving..." : "Save Changes",
                      onPressed: _isSaving ? null : _saveChanges,
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
                if (_hasChangesInSection(title)) ...[
                  const SizedBox(width: 8),
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Colors.orange,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
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

  bool _hasChangesInSection(String section) {
    if (_originalConsultation == null) return false;

    switch (section) {
      case 'General Information':
        final originalDuration = _originalConsultation!.duration ?? 30;
        return _consultationType != _originalConsultation!.type ||
            _consultationStatus != _originalConsultation!.status ||
            _consultationDate != _originalConsultation!.date ||
            _duration != originalDuration || // 🆕 AJOUT DURÉE
            _isEmergency != _originalConsultation!.isEmergency;
      case 'Symptoms *':
        return !_listEquals(_symptoms, _originalConsultation!.symptoms);
      case 'Diagnosis *':
        return !_listEquals(_diagnoses, _originalConsultation!.diagnosis);
      case 'Prescribed Tests':
        return !_listEquals(
            _prescribedAnalyses, _originalConsultation!.prescribedAnalyses);
      case 'Additional Notes':
        return _notesController.text != (_originalConsultation!.notes ?? '');
      default:
        return false;
    }
  }

  IconData _getIconForTitle(String title) {
    switch (title) {
      case 'General Information':
        return Icons.info_outline;
      case 'Symptoms *':
        return Icons.medical_services;
      case 'Diagnosis *':
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

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _consultationDate!,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && picked != _consultationDate) {
      setState(() {
        _consultationDate = picked;
      });
    }
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _consultationTime!,
    );
    if (picked != null && picked != _consultationTime) {
      setState(() {
        _consultationTime = picked;
      });
    }
  }

  void _showUnsavedChangesDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.orange),
            SizedBox(width: 8),
            Text('Unsaved Changes'),
          ],
        ),
        content: const Text(
            'You have unsaved changes. Are you sure you want to leave without saving?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Stay'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              widget.onBack();
            },
            child: const Text('Leave', style: TextStyle(color: Colors.red)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _saveChanges();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
            ),
            child: const Text('Save & Leave',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _notesController.dispose();
    _symptomController.dispose();
    _diagnosisController.dispose();
    _analysisController.dispose();
    _durationController.dispose(); // 🆕 DISPOSAL
    super.dispose();
  }
}
