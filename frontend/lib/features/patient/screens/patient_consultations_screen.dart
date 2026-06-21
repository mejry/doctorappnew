// lib/features/patient/screens/patient_consultations_screen.dart
import 'package:flutter/material.dart';
import 'package:frontend/core/constants/add_button.dart';
import 'package:frontend/core/constants/colors.dart';
import 'package:frontend/features/consultation/models/consultation.dart';
import 'package:frontend/features/consultation/services/consultation_service.dart';
import 'package:frontend/features/patient/models/patient.dart';
import 'package:frontend/features/patient/services/patient_service.dart';
import 'package:frontend/shared/widgets/permission_widget.dart';
import 'package:intl/intl.dart';

class PatientConsultationsScreen extends StatefulWidget {
  final String patientId;
  final VoidCallback onBack;
  final VoidCallback onNewConsultation;

  const PatientConsultationsScreen({
    super.key,
    required this.patientId,
    required this.onBack,
    required this.onNewConsultation,
  });

  @override
  State<PatientConsultationsScreen> createState() =>
      _PatientConsultationsScreenState();
}

class _PatientConsultationsScreenState
    extends State<PatientConsultationsScreen> {
  final ConsultationService _consultationService = ConsultationService();
  final PatientService _patientService = PatientService();

  Patient? _patient;
  List<Consultation> _consultations = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String? _selectedType;
  String? _selectedStatus;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final patient = await _patientService.getPatientById(widget.patientId);
      final consultations = await _consultationService
          .getConsultationsByPatientId(widget.patientId);

      setState(() {
        _patient = patient;
        _consultations = consultations;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading data: $e')),
      );
    }
  }

  List<Consultation> get _filteredConsultations {
    return _consultations.where((consultation) {
      final matchesSearch = _searchQuery.isEmpty ||
          consultation.type
              .toLowerCase()
              .contains(_searchQuery.toLowerCase()) ||
          consultation.diagnosis
              .any((d) => d.toLowerCase().contains(_searchQuery.toLowerCase()));

      final matchesType =
          _selectedType == null || consultation.type == _selectedType;
      final matchesStatus =
          _selectedStatus == null || consultation.status == _selectedStatus;

      return matchesSearch && matchesType && matchesStatus;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // Header avec bouton retour
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                ElevatedButton.icon(
                  onPressed: widget.onBack,
                  icon: const Icon(Icons.arrow_back),
                  label: const Text(
                      "Back to list"), // Changé de "Back to Patient" à "Back to list"
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[200],
                    foregroundColor: Colors.black,
                    elevation: 0,
                  ),
                ),
                const Spacer(),
                PermissionWidget(
                  permission: 'create_consultation',
                  hideIfNoPermission: true,
                  child: AddButton(
                    text: 'New Consultation',
                    onPressed: widget.onNewConsultation,
                  ),
                ),
              ],
            ),
          ),

          // Filters et search
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                // Search
                Expanded(
                  flex: 2,
                  child: TextField(
                    onChanged: (value) => setState(() => _searchQuery = value),
                    decoration: InputDecoration(
                      hintText: 'Search consultations...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 16),
                    ),
                  ),
                ),
                const SizedBox(width: 16),

                // Type Filter
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedType,
                    decoration: const InputDecoration(
                      labelText: 'Type',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      'Bilan',
                      'Test',
                      'Consultation',
                      'Control',
                      'Follow-up',
                      'Emergency'
                    ]
                        .map((type) =>
                            DropdownMenuItem(value: type, child: Text(type)))
                        .toList(),
                    onChanged: (value) => setState(() => _selectedType = value),
                  ),
                ),
                const SizedBox(width: 16),

                // Status Filter
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedStatus,
                    decoration: const InputDecoration(
                      labelText: 'Status',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      'Completed',
                      'Scheduled',
                      'InProgress',
                      'Canceled',
                      'Waiting'
                    ]
                        .map((status) => DropdownMenuItem(
                            value: status, child: Text(status)))
                        .toList(),
                    onChanged: (value) =>
                        setState(() => _selectedStatus = value),
                  ),
                ),
                const SizedBox(width: 16),

                // Clear Filters
                IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    setState(() {
                      _searchQuery = '';
                      _selectedType = null;
                      _selectedStatus = null;
                    });
                  },
                  tooltip: 'Clear Filters',
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Patient Info Header
          if (_patient != null)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.primary.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: AppColors.primary,
                    child: Text(
                      _patient!.firstName[0] + _patient!.lastName[0],
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _patient!.fullName,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                        Text('${_patient!.age} years • ${_patient!.email}'),
                        Text('Total Consultations: ${_consultations.length}'),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      _buildStatusCount('Completed', Colors.green),
                      _buildStatusCount('Scheduled', Colors.blue),
                      _buildStatusCount('InProgress', Colors.orange),
                    ],
                  ),
                ],
              ),
            ),

          const SizedBox(height: 16),

          // Consultations List
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                child: Column(
                  children: [
                    // Table Header
                    Container(
                      decoration: const BoxDecoration(
                        color: AppColors.secondary,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(12),
                          topRight: Radius.circular(12),
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(
                          vertical: 10, horizontal: 12),
                      child: const Row(
                        children: [
                          Expanded(
                              child: Text('Date',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold))),
                          Expanded(
                              child: Text('Type',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold))),
                          Expanded(
                              child: Text('Diagnosis',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold))),
                          Expanded(
                              child: Text('Status',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold))),
                          Expanded(
                              child: Text('Actions',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold))),
                        ],
                      ),
                    ),
                    const Divider(height: 1, thickness: 1),

                    // Consultations
                    Expanded(
                      child: _filteredConsultations.isEmpty
                          ? const Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.event_note,
                                      size: 64, color: Colors.grey),
                                  SizedBox(height: 16),
                                  Text(
                                    'No consultations found',
                                    style: TextStyle(
                                        fontSize: 16, color: Colors.grey),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              itemCount: _filteredConsultations.length,
                              itemBuilder: (context, index) {
                                final consultation =
                                    _filteredConsultations[index];
                                return _buildConsultationRow(consultation);
                              },
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCount(String status, Color color) {
    final count = _consultations.where((c) => c.status == status).length;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(radius: 4, backgroundColor: color),
          const SizedBox(width: 4),
          Text('$status: $count', style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildConsultationRow(Consultation consultation) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.black12)),
      ),
      child: Row(
        children: [
          // Date & Time
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  DateFormat('dd/MM/yyyy').format(consultation.date),
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                Text(
                  consultation.time,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),

          // Type
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _getTypeColor(consultation.type).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _getTypeColor(consultation.type)),
              ),
              child: Text(
                consultation.type,
                style: TextStyle(
                  color: _getTypeColor(consultation.type),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),

          // Diagnosis
          Expanded(
            child: Text(
              consultation.diagnosis.isNotEmpty
                  ? consultation.diagnosis.first
                  : 'No diagnosis',
              style: const TextStyle(fontSize: 12),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),

          // Status
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _getStatusColor(consultation.status),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                consultation.status,
                style: const TextStyle(color: Colors.white, fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ),
          ),

          // Actions
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Tooltip(
                  message: 'View Details',
                  child: IconButton(
                    icon: const Icon(Icons.visibility,
                        color: AppColors.primary, size: 20),
                    onPressed: () => _viewConsultationDetails(consultation),
                    padding: const EdgeInsets.all(4),
                  ),
                ),
                Tooltip(
                  message: 'View Prescription',
                  child: IconButton(
                    icon: const Icon(Icons.medication,
                        color: Colors.orange, size: 20),
                    onPressed: () => _viewPrescription(consultation),
                    padding: const EdgeInsets.all(4),
                  ),
                ),
                Tooltip(
                  message: 'Export PDF',
                  child: IconButton(
                    icon: const Icon(Icons.picture_as_pdf,
                        color: Colors.red, size: 20),
                    onPressed: () => _exportPDF(consultation),
                    padding: const EdgeInsets.all(4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Completed':
        return Colors.green;
      case 'Scheduled':
        return Colors.blue;
      case 'InProgress':
        return Colors.orange;
      case 'Canceled':
        return Colors.red;
      case 'Waiting':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'Emergency':
        return Colors.red;
      case 'Follow-up':
        return Colors.orange;
      case 'Consultation':
        return Colors.blue;
      case 'Control':
        return Colors.green;
      case 'Bilan':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  void _viewConsultationDetails(Consultation consultation) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Consultation Details'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                  'Date: ${DateFormat('dd/MM/yyyy HH:mm').format(consultation.date)}'),
              const SizedBox(height: 8),
              Text('Type: ${consultation.type}'),
              const SizedBox(height: 8),
              Text('Status: ${consultation.status}'),
              const SizedBox(height: 8),
              Text('Duration: ${consultation.duration ?? 'N/A'} minutes'),
              const SizedBox(height: 16),
              const Text('Symptoms:',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              ...consultation.symptoms.map((s) => Text('• $s')),
              const SizedBox(height: 16),
              const Text('Diagnosis:',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              ...consultation.diagnosis.map((d) => Text('• $d')),
              if (consultation.prescribedAnalyses?.isNotEmpty == true) ...[
                const SizedBox(height: 16),
                const Text('Prescribed Analyses:',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                ...consultation.prescribedAnalyses!.map((a) => Text('• $a')),
              ],
              if (consultation.notes?.isNotEmpty == true) ...[
                const SizedBox(height: 16),
                const Text('Notes:',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                Text(consultation.notes!),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _viewPrescription(Consultation consultation) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Opening prescription...')),
    );
  }

  void _exportPDF(Consultation consultation) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Exporting consultation as PDF...')),
    );
  }
}
