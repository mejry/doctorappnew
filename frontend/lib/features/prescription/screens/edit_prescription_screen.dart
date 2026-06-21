// lib/features/prescription/screens/edit_prescription_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:frontend/core/constants/colors.dart';
import 'package:frontend/features/prescription/models/prescription.dart';
import 'package:frontend/features/prescription/providers/prescription_provider.dart';
import 'package:frontend/features/prescription/services/prescription_service.dart';
import 'package:intl/intl.dart';

class EditPrescriptionScreen extends StatefulWidget {
  final String prescriptionId;
  final VoidCallback onBack;
  final VoidCallback? onSaved;

  const EditPrescriptionScreen({
    super.key,
    required this.prescriptionId,
    required this.onBack,
    this.onSaved,
  });

  @override
  State<EditPrescriptionScreen> createState() => _EditPrescriptionScreenState();
}

class _EditPrescriptionScreenState extends State<EditPrescriptionScreen> {
  final PrescriptionService _prescriptionService = PrescriptionService();
  final _formKey = GlobalKey<FormState>();

  Prescription? _prescription;
  bool _isLoading = true;
  bool _isSaving = false;

  // Form controllers
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _validityDaysController = TextEditingController();

  String _selectedType = 'Regular';
  String _selectedStatus = 'Active';
  List<Map<String, dynamic>> _medications = [];

  final List<String> _prescriptionTypes = [
    'Regular',
    'Emergency',
    'Chronic',
    'Temporary',
    'Follow-up'
  ];

  final List<String> _prescriptionStatuses = [
    'Active',
    'Pending',
    'Completed',
    'Expired',
    'Cancelled'
  ];

  @override
  void initState() {
    super.initState();
    _loadPrescription();
  }

  @override
  void dispose() {
    _notesController.dispose();
    _validityDaysController.dispose();
    super.dispose();
  }

  Future<void> _loadPrescription() async {
    setState(() => _isLoading = true);
    try {
      final prescription =
          await _prescriptionService.getPrescriptionById(widget.prescriptionId);

      setState(() {
        _prescription = prescription;
        _selectedType = prescription.prescriptionInfo.type;
        _selectedStatus = prescription.prescriptionInfo.status;
        _notesController.text = prescription.prescriptionInfo.notes ?? '';
        _validityDaysController.text =
            prescription.prescriptionInfo.validityDays?.toString() ?? '30';

        // Convert medications to editable format
        _medications = prescription.medications
            .map((med) => {
                  'id': med.medication ?? 'custom',
                  'name': med.displayName,
                  'dosage': {
                    'strength': med.dosage.strength ?? '',
                    'frequency': med.dosage.frequency ?? '',
                    'duration': med.dosage.duration ?? '',
                    'route': med.dosage.route ?? '',
                    'instructions': med.dosage.instructions ?? '',
                  },
                  'isCustom': med.customMedication != null,
                  'customMedication': med.customMedication != null
                      ? {
                          'name': med.customMedication!.name,
                          'description': med.customMedication!.description,
                        }
                      : null,
                })
            .toList();

        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading prescription: $e')),
      );
    }
  }

  Future<void> _savePrescription() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final updatedData = {
        'prescriptionInfo': {
          'type': _selectedType,
          'status': _selectedStatus,
          'date': _prescription!.prescriptionInfo.date.toIso8601String(),
          'time': _prescription!.prescriptionInfo.time,
          'validityDays': int.tryParse(_validityDaysController.text) ?? 30,
          'notes': _notesController.text.trim().isEmpty
              ? null
              : _notesController.text.trim(),
        },
        'medications': _medications
            .map((med) => {
                  if (med['isCustom'] == true)
                    'customMedication': med['customMedication']
                  else
                    'medication': med['id'],
                  'dosage': med['dosage'],
                })
            .toList(),
      };

      final provider = context.read<PrescriptionProvider>();
      final success =
          await provider.updatePrescription(widget.prescriptionId, updatedData);

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Prescription updated successfully!'),
              backgroundColor: Colors.green,
            ),
          );

          // Call callback if provided
          if (widget.onSaved != null) {
            widget.onSaved!();
          }

          // Go back
          widget.onBack();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ Error: ${provider.error ?? 'Unknown error'}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving prescription: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  void _addMedication() {
    showDialog(
      context: context,
      builder: (context) => _MedicationEditDialog(
        onSave: (medicationData) {
          setState(() {
            _medications.add(medicationData);
          });
        },
      ),
    );
  }

  void _editMedication(int index) {
    showDialog(
      context: context,
      builder: (context) => _MedicationEditDialog(
        initialData: _medications[index],
        onSave: (medicationData) {
          setState(() {
            _medications[index] = medicationData;
          });
        },
      ),
    );
  }

  void _removeMedication(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Medication'),
        content:
            Text('Remove "${_medications[index]['name']}" from prescription?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _medications.removeAt(index);
              });
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.grey[50],
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_prescription == null) {
      return Scaffold(
        backgroundColor: Colors.grey[50],
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              const Text('Prescription not found'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: widget.onBack,
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Column(
        children: [
          // Header
          _buildHeader(),

          // Form Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Prescription Info Card
                    _buildPrescriptionInfoCard(),

                    const SizedBox(height: 16),

                    // Medications Card
                    _buildMedicationsCard(),

                    const SizedBox(height: 24),

                    // Action Buttons
                    _buildActionButtons(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            IconButton(
              onPressed: widget.onBack,
              icon: const Icon(Icons.arrow_back, color: AppColors.primary),
              style: IconButton.styleFrom(
                backgroundColor: AppColors.primary.withOpacity(0.1),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Edit Prescription',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  Text(
                    'Created: ${DateFormat('dd/MM/yyyy at HH:mm').format(_prescription!.prescriptionInfo.date)}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _getStatusColor(_prescription!.prescriptionInfo.status),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                _prescription!.prescriptionInfo.status,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrescriptionInfoCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.info_outline,
                    color: AppColors.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Prescription Information',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Type and Status Row
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedType,
                    decoration: const InputDecoration(
                      labelText: 'Type',
                      border: OutlineInputBorder(),
                    ),
                    items: _prescriptionTypes
                        .map((type) =>
                            DropdownMenuItem(value: type, child: Text(type)))
                        .toList(),
                    onChanged: (value) =>
                        setState(() => _selectedType = value!),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedStatus,
                    decoration: const InputDecoration(
                      labelText: 'Status',
                      border: OutlineInputBorder(),
                    ),
                    items: _prescriptionStatuses
                        .map((status) => DropdownMenuItem(
                            value: status, child: Text(status)))
                        .toList(),
                    onChanged: (value) =>
                        setState(() => _selectedStatus = value!),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Validity Days
            TextFormField(
              controller: _validityDaysController,
              decoration: const InputDecoration(
                labelText: 'Validity (days)',
                border: OutlineInputBorder(),
                suffixText: 'days',
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty)
                  return 'Please enter validity days';
                final days = int.tryParse(value);
                if (days == null || days <= 0)
                  return 'Please enter a valid number';
                return null;
              },
            ),

            const SizedBox(height: 16),

            // Notes
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Notes (optional)',
                border: OutlineInputBorder(),
                hintText: 'Add any additional notes...',
              ),
              maxLines: 3,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMedicationsCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.medication_outlined,
                    color: Colors.orange,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Medications',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange,
                    ),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _addMedication,
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Add'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_medications.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.medication_outlined,
                      size: 48,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No medications prescribed',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Add medications to this prescription',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              )
            else
              ...(_medications.asMap().entries.map((entry) {
                final index = entry.key;
                final medication = entry.value;
                return _buildMedicationItem(medication, index);
              })),
          ],
        ),
      ),
    );
  }

  Widget _buildMedicationItem(Map<String, dynamic> medication, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(12),
        color: Colors.white,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: medication['isCustom'] == true
                      ? Colors.purple.withOpacity(0.1)
                      : AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  Icons.medication,
                  size: 16,
                  color: medication['isCustom'] == true
                      ? Colors.purple
                      : AppColors.primary,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      medication['name'],
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    if (medication['isCustom'] == true)
                      Container(
                        margin: const EdgeInsets.only(top: 4),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.purple.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text(
                          'Custom',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.purple,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => _editMedication(index),
                icon: const Icon(Icons.edit, color: Colors.blue, size: 20),
                tooltip: 'Edit medication',
              ),
              IconButton(
                onPressed: () => _removeMedication(index),
                icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                tooltip: 'Remove medication',
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Dosage Info
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: [
              if (medication['dosage']['strength']?.isNotEmpty == true)
                _buildDosageChip(
                    'Strength', medication['dosage']['strength'], Colors.green),
              if (medication['dosage']['frequency']?.isNotEmpty == true)
                _buildDosageChip('Frequency', medication['dosage']['frequency'],
                    Colors.blue),
              if (medication['dosage']['duration']?.isNotEmpty == true)
                _buildDosageChip('Duration', medication['dosage']['duration'],
                    Colors.orange),
              if (medication['dosage']['route']?.isNotEmpty == true)
                _buildDosageChip(
                    'Route', medication['dosage']['route'], Colors.purple),
            ],
          ),

          if (medication['dosage']['instructions']?.isNotEmpty == true) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.withOpacity(0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Instructions:',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    medication['dosage']['instructions'],
                    style: const TextStyle(fontSize: 13),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDosageChip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _isSaving ? null : widget.onBack,
            icon: const Icon(Icons.cancel_outlined),
            label: const Text('Cancel'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              side: const BorderSide(color: Colors.grey),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 2,
          child: ElevatedButton.icon(
            onPressed: _isSaving ? null : _savePrescription,
            icon: _isSaving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Icon(Icons.save),
            label: Text(_isSaving ? 'Saving...' : 'Save Changes'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Active':
        return Colors.green;
      case 'Pending':
        return Colors.orange;
      case 'Completed':
        return Colors.blue;
      case 'Expired':
        return Colors.amber;
      case 'Cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}

// 🆕 DIALOG POUR ÉDITER LES MÉDICAMENTS
class _MedicationEditDialog extends StatefulWidget {
  final Map<String, dynamic>? initialData;
  final Function(Map<String, dynamic>) onSave;

  const _MedicationEditDialog({
    this.initialData,
    required this.onSave,
  });

  @override
  State<_MedicationEditDialog> createState() => _MedicationEditDialogState();
}

class _MedicationEditDialogState extends State<_MedicationEditDialog> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _strengthController;
  late TextEditingController _frequencyController;
  late TextEditingController _durationController;
  late TextEditingController _instructionsController;

  String _selectedRoute = 'Oral';
  bool _isCustomMedication = false;

  final List<String> _routes = [
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

  @override
  void initState() {
    super.initState();

    _nameController =
        TextEditingController(text: widget.initialData?['name'] ?? '');
    _strengthController = TextEditingController(
        text: widget.initialData?['dosage']?['strength'] ?? '');
    _frequencyController = TextEditingController(
        text: widget.initialData?['dosage']?['frequency'] ?? '');
    _durationController = TextEditingController(
        text: widget.initialData?['dosage']?['duration'] ?? '');
    _instructionsController = TextEditingController(
        text: widget.initialData?['dosage']?['instructions'] ?? '');

    _selectedRoute = widget.initialData?['dosage']?['route'] ?? 'Oral';
    _isCustomMedication = widget.initialData?['isCustom'] ?? false;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _strengthController.dispose();
    _frequencyController.dispose();
    _durationController.dispose();
    _instructionsController.dispose();
    super.dispose();
  }

  void _saveMedication() {
    if (!_formKey.currentState!.validate()) return;

    final medicationData = {
      'id': _isCustomMedication ? 'custom' : 'medication_id',
      'name': _nameController.text.trim(),
      'isCustom': _isCustomMedication,
      'customMedication': _isCustomMedication
          ? {
              'name': _nameController.text.trim(),
              'description': 'Custom medication',
            }
          : null,
      'dosage': {
        'strength': _strengthController.text.trim(),
        'frequency': _frequencyController.text.trim(),
        'duration': _durationController.text.trim(),
        'route': _selectedRoute,
        'instructions': _instructionsController.text.trim(),
      },
    };

    widget.onSave(medicationData);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Icon(
              Icons.medication,
              color: Colors.orange,
              size: 20,
            ),
          ),
          const SizedBox(width: 8),
          Text(widget.initialData == null
              ? 'Add Medication'
              : 'Edit Medication'),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Medication Name
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Medication Name *',
                    border: OutlineInputBorder(),
                    hintText: 'Enter medication name',
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter medication name';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // Custom medication toggle
                CheckboxListTile(
                  value: _isCustomMedication,
                  onChanged: (value) =>
                      setState(() => _isCustomMedication = value!),
                  title: const Text('Custom Medication'),
                  subtitle: const Text(
                      'Check if this is a custom/compound medication'),
                  controlAffinity: ListTileControlAffinity.leading,
                ),

                const SizedBox(height: 16),

                // Strength
                TextFormField(
                  controller: _strengthController,
                  decoration: const InputDecoration(
                    labelText: 'Strength/Dosage',
                    border: OutlineInputBorder(),
                    hintText: 'e.g., 500mg, 10ml',
                  ),
                ),

                const SizedBox(height: 16),

                // Frequency
                TextFormField(
                  controller: _frequencyController,
                  decoration: const InputDecoration(
                    labelText: 'Frequency',
                    border: OutlineInputBorder(),
                    hintText: 'e.g., Twice daily, Every 8 hours',
                  ),
                ),

                const SizedBox(height: 16),

                // Duration and Route Row
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _durationController,
                        decoration: const InputDecoration(
                          labelText: 'Duration',
                          border: OutlineInputBorder(),
                          hintText: 'e.g., 7 days',
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedRoute,
                        decoration: const InputDecoration(
                          labelText: 'Route',
                          border: OutlineInputBorder(),
                        ),
                        items: _routes
                            .map((route) => DropdownMenuItem(
                                value: route, child: Text(route)))
                            .toList(),
                        onChanged: (value) =>
                            setState(() => _selectedRoute = value!),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Instructions
                TextFormField(
                  controller: _instructionsController,
                  decoration: const InputDecoration(
                    labelText: 'Instructions (optional)',
                    border: OutlineInputBorder(),
                    hintText: 'Special instructions for taking this medication',
                  ),
                  maxLines: 3,
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _saveMedication,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange,
            foregroundColor: Colors.white,
          ),
          child: const Text('Save'),
        ),
      ],
    );
  }
}
