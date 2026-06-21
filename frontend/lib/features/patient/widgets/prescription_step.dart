// lib/features/patient/widgets/prescription_step.dart - VERSION IDENTIQUE À PRESCRIPTION_FORM
import 'package:flutter/material.dart';
import 'package:frontend/features/prescription/models/ai_suggestion.dart';
import 'package:frontend/features/prescription/widgets/ai_suggestions_widget.dart';
import 'package:provider/provider.dart';
import 'package:frontend/core/constants/colors.dart';
import 'package:frontend/core/constants/primary_button.dart';
import 'package:frontend/core/constants/secondary_button.dart';
import 'package:frontend/core/constants/form_styles.dart';
import 'package:frontend/features/prescription/providers/medication_provider.dart';
import 'package:intl/intl.dart';

class PrescriptionStep extends StatefulWidget {
  final Function(Map<String, dynamic>) onNext;
  final VoidCallback onBack;
  final VoidCallback onSkip;
  final String? consultationId; // ✅ ID de consultation pour IA

  const PrescriptionStep({
    super.key,
    required this.onNext,
    required this.onBack,
    required this.onSkip,
    this.consultationId, // ✅ NOUVEAU PARAMÈTRE
  });

  @override
  State<PrescriptionStep> createState() => _PrescriptionStepState();
}

class _PrescriptionStepState extends State<PrescriptionStep> {
  final _formKey = GlobalKey<FormState>();
  final _notesController = TextEditingController();
  final _searchController = TextEditingController();

  // Form data (identique à prescription_form)
  String _prescriptionType = 'Regular';
  String _prescriptionStatus = 'Pending';
  int _validityDays = 30;
  String _priority = 'Routine';

  // Medications
  List<Map<String, dynamic>> _medications = [];
  List<Map<String, dynamic>> _filteredMedications = [];
  bool _showMedicationList = false;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MedicationProvider>().loadMedications();
    });
  }

  void _filterMedications(String query) {
    if (query.isEmpty) {
      setState(() {
        _filteredMedications = [];
        _showMedicationList = false;
      });
      return;
    }

    final provider = context.read<MedicationProvider>();
    final allMedications = provider.medicationsAsMap;

    setState(() {
      _filteredMedications = allMedications
          .where((med) =>
              med['name']
                  .toString()
                  .toLowerCase()
                  .contains(query.toLowerCase()) ||
              (med['genericName'] ?? '')
                  .toString()
                  .toLowerCase()
                  .contains(query.toLowerCase()))
          .take(5)
          .toList();
      _showMedicationList = _filteredMedications.isNotEmpty;
    });
  }

  void _addMedicationFromDatabase(Map<String, dynamic> selectedMed) {
    setState(() {
      _medications.add({
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'medicationType': 'database',
        'medicationId': selectedMed['id'],
        'name': selectedMed['name'],
        'genericName': selectedMed['genericName'] ?? '',
        'defaultDosage': selectedMed['dosage'] ?? '',
        'strength': '',
        'frequency': '',
        'duration': '',
        'route': 'Oral',
        'instructions': '',
      });

      _searchController.clear();
      _filteredMedications = [];
      _showMedicationList = false;
    });
  }

  void _addCustomMedication() {
    setState(() {
      _medications.add({
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'medicationType': 'custom',
        'customName': '',
        'strength': '',
        'frequency': '',
        'duration': '',
        'route': 'Oral',
        'instructions': '',
      });
    });
  }

  void _addSuggestionAsMedication(AISuggestion suggestion) {
    setState(() {
      _medications.add({
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'medicationType': 'ai_suggestion',
        'name': suggestion.medication,
        'customName': suggestion.medication,
        'category': suggestion.category,
        'confidence': suggestion.confidence,
        'strength': '',
        'frequency': '',
        'duration': '',
        'route': 'Oral',
        'instructions': suggestion.reason ?? 'AI suggested medication',
        'aiSuggested': true,
      });
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('✨ Added AI suggestion: ${suggestion.medication}'),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _removeMedication(int index) {
    setState(() {
      _medications.removeAt(index);
    });
  }

  Widget _buildMedicationForm(int index) {
    final medication = _medications[index];
    final isCustom = medication['medicationType'] == 'custom';
    final isAISuggested = medication['medicationType'] == 'ai_suggestion';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color:
              isAISuggested ? Colors.blue.withOpacity(0.3) : Colors.grey[300]!,
          width: isAISuggested ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header avec info médication et bouton supprimer
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: isAISuggested
                      ? Colors.blue.withOpacity(0.1)
                      : isCustom
                          ? Colors.orange.withOpacity(0.1)
                          : Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  isAISuggested
                      ? Icons.auto_awesome
                      : isCustom
                          ? Icons.edit
                          : Icons.medication,
                  color: isAISuggested
                      ? Colors.blue
                      : isCustom
                          ? Colors.orange
                          : Colors.green,
                  size: 16,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Medication ${index + 1}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: isAISuggested
                                ? Colors.blue.withOpacity(0.2)
                                : isCustom
                                    ? Colors.orange.withOpacity(0.2)
                                    : Colors.green.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (isAISuggested) ...[
                                const Icon(Icons.auto_awesome,
                                    size: 10, color: Colors.blue),
                                const SizedBox(width: 2),
                              ],
                              Text(
                                isAISuggested
                                    ? 'AI Suggested'
                                    : isCustom
                                        ? 'Custom'
                                        : 'Database',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: isAISuggested
                                      ? Colors.blue[800]
                                      : isCustom
                                          ? Colors.orange[800]
                                          : Colors.green[800],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    // Afficher infos supplémentaires pour suggestions IA
                    if (isAISuggested && medication['confidence'] != null) ...[
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(
                            Icons.psychology,
                            size: 12,
                            color: Colors.blue[600],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Confidence: ${(medication['confidence'] * 100).toInt()}% • ${medication['category']}',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.blue[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],

                    if (!isCustom &&
                        !isAISuggested &&
                        medication['name'] != null)
                      Text(
                        medication['name'],
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => _removeMedication(index),
                icon: const Icon(Icons.delete_outline,
                    color: Colors.red, size: 20),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.red.withOpacity(0.1),
                  padding: const EdgeInsets.all(6),
                  minimumSize: const Size(32, 32),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Nom du médicament (pour custom et AI)
          if (isCustom || isAISuggested) ...[
            TextFormField(
              initialValue:
                  isAISuggested ? medication['name'] : medication['customName'],
              decoration: AppFormStyles.inputDecoration("Medication name *"),
              style: const TextStyle(fontSize: 13),
              onChanged: (value) {
                setState(() {
                  if (isAISuggested) {
                    _medications[index]['name'] = value;
                    _medications[index]['customName'] = value;
                  } else {
                    _medications[index]['customName'] = value;
                  }
                });
              },
              validator: (value) =>
                  value?.isEmpty ?? true ? 'Name required' : null,
            ),
            const SizedBox(height: 10),
          ] else if (medication['name'] != null) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.withOpacity(0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    medication['name'],
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  if (medication['genericName']?.isNotEmpty == true)
                    Text(
                      'Generic: ${medication['genericName']}',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  if (medication['defaultDosage']?.isNotEmpty == true)
                    Text(
                      'Suggested: ${medication['defaultDosage']}',
                      style: TextStyle(
                        color: Colors.blue[600],
                        fontSize: 11,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 10),
          ],

          // Informations de dosage
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  initialValue: medication['strength'],
                  decoration: AppFormStyles.inputDecoration("Strength *"),
                  style: const TextStyle(fontSize: 13),
                  onChanged: (value) {
                    setState(() {
                      _medications[index]['strength'] = value;
                    });
                  },
                  validator: (value) =>
                      value?.isEmpty ?? true ? 'Required' : null,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextFormField(
                  initialValue: medication['frequency'],
                  decoration: AppFormStyles.inputDecoration("Frequency *"),
                  style: const TextStyle(fontSize: 13),
                  onChanged: (value) {
                    setState(() {
                      _medications[index]['frequency'] = value;
                    });
                  },
                  validator: (value) =>
                      value?.isEmpty ?? true ? 'Required' : null,
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          Row(
            children: [
              Expanded(
                child: TextFormField(
                  initialValue: medication['duration'],
                  decoration: AppFormStyles.inputDecoration("Duration *"),
                  style: const TextStyle(fontSize: 13),
                  onChanged: (value) {
                    setState(() {
                      _medications[index]['duration'] = value;
                    });
                  },
                  validator: (value) =>
                      value?.isEmpty ?? true ? 'Required' : null,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: medication['route'],
                  decoration: AppFormStyles.inputDecoration("Route"),
                  style: const TextStyle(fontSize: 13),
                  items: const [
                    'Oral',
                    'Sublingual',
                    'Topical',
                    'IV',
                    'IM',
                    'SC',
                    'Rectal',
                    'Inhalation',
                    'Other'
                  ].map((route) {
                    return DropdownMenuItem(
                      value: route,
                      child: Text(route),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _medications[index]['route'] = value!;
                    });
                  },
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          TextFormField(
            initialValue: medication['instructions'],
            decoration: AppFormStyles.inputDecoration("Instructions"),
            style: const TextStyle(fontSize: 13),
            maxLines: 2,
            onChanged: (value) {
              setState(() {
                _medications[index]['instructions'] = value;
              });
            },
          ),
        ],
      ),
    );
  }

  void _saveAndProceed() {
    if (!_formKey.currentState!.validate()) return;

    if (_medications.isEmpty) {
      _skipPrescription();
      return;
    }

    // Validate each medication
    for (int i = 0; i < _medications.length; i++) {
      final med = _medications[i];

      if ((med['medicationType'] == 'custom' ||
              med['medicationType'] == 'ai_suggestion') &&
          med['customName'].toString().trim().isEmpty &&
          med['name'].toString().trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Please enter medication name for item ${i + 1}"),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      if (med['strength'].toString().trim().isEmpty ||
          med['frequency'].toString().trim().isEmpty ||
          med['duration'].toString().trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Please complete dosage for medication ${i + 1}"),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }
    }

    final prescriptionData = <String, dynamic>{
      'prescriptionInfo': {
        'type': _prescriptionType,
        'status': _prescriptionStatus,
        'date': DateTime.now().toIso8601String(),
        'time': DateFormat('HH:mm').format(DateTime.now()),
        'validityDays': _validityDays,
        'notes': _notesController.text.trim().isNotEmpty
            ? _notesController.text.trim()
            : null,
      },
      'clinicalContext': {
        'priority': _priority,
      },
      'medications': _medications.map((med) {
        if (med['medicationType'] == 'custom' ||
            med['medicationType'] == 'ai_suggestion') {
          return {
            'customMedication': {
              'name': med['name'] ?? med['customName'] ?? '',
              'description': med['medicationType'] == 'ai_suggestion'
                  ? 'AI suggested medication (${med['category']}, confidence: ${(med['confidence'] * 100).toInt()}%)'
                  : null,
            },
            'dosage': {
              'strength': med['strength'],
              'frequency': med['frequency'],
              'duration': med['duration'],
              'route': med['route'],
              'instructions': med['instructions'],
            },
          };
        } else {
          return {
            'medication': med['medicationId'],
            'dosage': {
              'strength': med['strength'],
              'frequency': med['frequency'],
              'duration': med['duration'],
              'route': med['route'],
              'instructions': med['instructions'],
            },
          };
        }
      }).toList(),
    };

    widget.onNext(prescriptionData);
  }

  void _skipPrescription() {
    final emptyPrescriptionData = <String, dynamic>{
      'prescriptionInfo': {
        'type': 'Regular',
        'status': 'Pending',
        'date': DateTime.now().toIso8601String(),
        'time': DateFormat('HH:mm').format(DateTime.now()),
        'validityDays': 30,
        'notes': 'Prescription to be completed later',
      },
      'medications': <Map<String, dynamic>>[],
    };

    widget.onNext(emptyPrescriptionData);
  }

  Widget _buildAddMedicationSection() {
    return Column(
      children: [
        // Widget des suggestions IA
        if (widget.consultationId != null)
          AISuggestionsWidget(
            consultationId: widget.consultationId!,
            onSuggestionSelected: _addSuggestionAsMedication,
          ),

        const SizedBox(height: 8),

        // Section d'ajout manuel
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(Icons.add_circle_outline,
                        color: Colors.orange, size: 16),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Add Medication Manually',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              Consumer<MedicationProvider>(
                builder: (context, provider, child) {
                  return Column(
                    children: [
                      TextFormField(
                        controller: _searchController,
                        decoration: AppFormStyles.inputDecoration(
                          "Search medication in database...",
                          suffixIcon: const Icon(Icons.search),
                        ),
                        onChanged: _filterMedications,
                      ),

                      // Search results
                      if (_showMedicationList) ...[
                        const SizedBox(height: 8),
                        Container(
                          constraints: const BoxConstraints(maxHeight: 150),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey[300]!),
                            borderRadius: BorderRadius.circular(8),
                            color: Colors.grey[50],
                          ),
                          child: provider.isLoading
                              ? const Center(
                                  child: Padding(
                                    padding: EdgeInsets.all(20),
                                    child: CircularProgressIndicator(),
                                  ),
                                )
                              : ListView.builder(
                                  shrinkWrap: true,
                                  itemCount: _filteredMedications.length,
                                  itemBuilder: (context, index) {
                                    final med = _filteredMedications[index];
                                    return ListTile(
                                      dense: true,
                                      leading: const Icon(Icons.medication,
                                          color: Colors.green, size: 18),
                                      title: Text(med['name'],
                                          style: const TextStyle(fontSize: 13)),
                                      subtitle: Text(
                                        '${med['genericName'] ?? ''} - ${med['dosage'] ?? ''}',
                                        style: const TextStyle(fontSize: 11),
                                      ),
                                      trailing: const Icon(Icons.add_circle,
                                          color: AppColors.primary, size: 18),
                                      onTap: () =>
                                          _addMedicationFromDatabase(med),
                                    );
                                  },
                                ),
                        ),
                      ],
                    ],
                  );
                },
              ),

              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 8),

              // Add custom medication button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _addCustomMedication,
                  icon: const Icon(Icons.edit, size: 18),
                  label: const Text('Add Custom Medication'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMedicationsHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child:
                const Icon(Icons.list_alt, color: AppColors.primary, size: 16),
          ),
          const SizedBox(width: 8),
          Text(
            'Medications (${_medications.length})',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          const Spacer(),
          IconButton(
            onPressed: () {
              _searchController.clear();
              _filteredMedications = [];
              _showMedicationList = false;
            },
            icon: const Icon(Icons.add, color: AppColors.primary, size: 18),
            style: IconButton.styleFrom(
              backgroundColor: AppColors.primary.withOpacity(0.1),
              padding: const EdgeInsets.all(6),
              minimumSize: const Size(32, 32),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrescriptionInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(Icons.receipt_long,
                    color: Colors.blue, size: 16),
              ),
              const SizedBox(width: 8),
              const Text(
                'Prescription Details',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _prescriptionType,
                  decoration: AppFormStyles.inputDecoration("Type"),
                  items: const [
                    'Regular',
                    'Emergency',
                    'Hospital',
                    'Discharge',
                    'Renewal'
                  ].map((type) {
                    return DropdownMenuItem(
                      value: type,
                      child: Text(type),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _prescriptionType = value!;
                    });
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _prescriptionStatus,
                  decoration: AppFormStyles.inputDecoration("Status"),
                  items: const ['Active', 'Pending', 'Draft'].map((status) {
                    return DropdownMenuItem(
                      value: status,
                      child: Text(status),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _prescriptionStatus = value!;
                    });
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Text("Validity: ", style: TextStyle(fontSize: 12)),
              Expanded(
                child: Slider(
                  value: _validityDays.toDouble(),
                  min: 1,
                  max: 90,
                  divisions: 89,
                  label: "$_validityDays days",
                  activeColor: AppColors.primary,
                  onChanged: (value) {
                    setState(() {
                      _validityDays = value.toInt();
                    });
                  },
                ),
              ),
              Text("$_validityDays days", style: const TextStyle(fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNotesCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.purple.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child:
                    const Icon(Icons.note_add, color: Colors.purple, size: 16),
              ),
              const SizedBox(width: 8),
              const Text(
                'Additional Notes',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.purple,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _notesController,
            decoration: AppFormStyles.inputDecoration('Notes (optional)'),
            maxLines: 3,
            style: const TextStyle(fontSize: 13),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                // Prescription info
                _buildPrescriptionInfoCard(),
                const SizedBox(height: 12),

                // Add medication section
                _buildAddMedicationSection(),
                const SizedBox(height: 12),

                // Medications list
                if (_medications.isNotEmpty) ...[
                  _buildMedicationsHeader(),
                  ..._medications.asMap().entries.map((entry) {
                    return _buildMedicationForm(entry.key);
                  }),
                  const SizedBox(height: 12),
                ],

                // Notes
                _buildNotesCard(),

                const SizedBox(height: 20),

                // Action buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    SecondaryButton(
                      text: "Back",
                      onPressed: widget.onBack,
                    ),
                    if (_medications.isEmpty)
                      ElevatedButton.icon(
                        onPressed: _skipPrescription,
                        icon: const Icon(Icons.schedule, size: 18),
                        label: const Text('Skip & Complete'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                      ),
                    if (_medications.isNotEmpty)
                      PrimaryButton(
                        text: _isSaving ? "Saving..." : "Save Prescription",
                        onPressed: _isSaving ? null : _saveAndProceed,
                      ),
                    if (_medications.isEmpty)
                      PrimaryButton(
                        text: "Complete Without Prescription",
                        onPressed: _skipPrescription,
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
    _notesController.dispose();
    _searchController.dispose();
    super.dispose();
  }
}
