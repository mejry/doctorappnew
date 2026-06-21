// lib/features/consultation/screens/consultation_list_screen.dart - VERSION AVEC PERMISSIONS
import 'package:flutter/material.dart';
import 'package:frontend/core/constants/colors.dart';
import 'package:frontend/features/consultation/models/consultation.dart';
import 'package:frontend/features/consultation/services/consultation_service.dart';
import 'package:frontend/features/patient/services/patient_service.dart';
import 'package:frontend/features/patient/models/patient.dart';
import 'package:frontend/shared/widgets/permission_widget.dart';
import 'package:intl/intl.dart';

class ConsultationListScreen extends StatefulWidget {
  final VoidCallback onAddConsultationPressed;
  final Function(String consultationId)? onViewPrescriptions;
  final Function(String consultationId)? onEditConsultation;

  const ConsultationListScreen({
    super.key,
    required this.onAddConsultationPressed,
    this.onViewPrescriptions,
    this.onEditConsultation,
  });

  @override
  State<ConsultationListScreen> createState() => _ConsultationListScreenState();
}

class _ConsultationListScreenState extends State<ConsultationListScreen> {
  final ConsultationService _consultationService = ConsultationService();
  final PatientService _patientService = PatientService();

  List<Consultation> _consultations = [];
  Map<String, Patient> _patients = {};
  bool _isLoading = true;
  String _searchQuery = '';
  String? _selectedStatus;
  String? _selectedType;

  @override
  void initState() {
    super.initState();
    _loadConsultations();
  }

  Future<void> _loadConsultations() async {
    setState(() => _isLoading = true);
    try {
      final consultations = await _consultationService.getAllConsultations();

      for (final consultation in consultations) {
        if (!_patients.containsKey(consultation.patientId)) {
          try {
            final patient =
                await _patientService.getPatientById(consultation.patientId);
            _patients[consultation.patientId] = patient;
          } catch (e) {
            _patients[consultation.patientId] = Patient(
              id: consultation.patientId,
              firstName: 'Unknown',
              lastName: 'Patient',
              email: 'unknown@example.com',
              gender: 'Unknown',
              dateOfBirth: DateTime.now(),
            );
          }
        }
      }

      setState(() {
        _consultations = consultations;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading consultations: $e')),
      );
    }
  }

  List<Consultation> get _filteredConsultations {
    return _consultations.where((consultation) {
      final patient = _patients[consultation.patientId];
      final matchesSearch = _searchQuery.isEmpty ||
          patient?.fullName
                  .toLowerCase()
                  .contains(_searchQuery.toLowerCase()) ==
              true ||
          consultation.type
              .toLowerCase()
              .contains(_searchQuery.toLowerCase()) ||
          consultation.diagnosis
              .any((d) => d.toLowerCase().contains(_searchQuery.toLowerCase()));

      final matchesStatus =
          _selectedStatus == null || consultation.status == _selectedStatus;
      final matchesType =
          _selectedType == null || consultation.type == _selectedType;

      return matchesSearch && matchesStatus && matchesType;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    // ✅ VÉRIFICATION PERMISSION PRINCIPALE
    return PermissionWidget(
      permission: 'view_consultation',
      fallback: _buildAccessDenied(),
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          title: const Text('Consultations',
              style: TextStyle(color: Colors.black)),
          actions: [
            // Search
            Container(
              width: 300,
              height: 40,
              margin: const EdgeInsets.symmetric(vertical: 10),
              child: TextField(
                onChanged: (value) => setState(() => _searchQuery = value),
                decoration: InputDecoration(
                  hintText: 'Search consultations...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                ),
              ),
            ),
            const SizedBox(width: 8),

            // Filter Button
            IconButton(
              icon: const Icon(Icons.filter_list),
              onPressed: _showFilterDialog,
            ),

            // Export Button
            IconButton(
              icon: const Icon(Icons.download),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Export feature coming soon')),
                );
              },
            ),

            const SizedBox(width: 8),

            // ✅ ADD CONSULTATION SEULEMENT SI PERMISSION
            PermissionAddButton(
              permission: 'create_consultation',
              text: 'New Consultation',
              onPressed: widget.onAddConsultationPressed,
            ),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Padding(
                padding: const EdgeInsets.all(16.0),
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
                      // Header
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
                                child: Text('Patient',
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

                      // Liste des consultations
                      Expanded(
                        child: _filteredConsultations.isEmpty
                            ? const Center(
                                child: Text(
                                  'No consultations found',
                                  style: TextStyle(
                                      fontSize: 16, color: Colors.grey),
                                ),
                              )
                            : ListView.builder(
                                itemCount: _filteredConsultations.length,
                                itemBuilder: (context, index) {
                                  final consultation =
                                      _filteredConsultations[index];
                                  final patient =
                                      _patients[consultation.patientId];
                                  return _buildConsultationRow(
                                      consultation, patient);
                                },
                              ),
                      ),

                      // Footer avec stats
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: const BorderRadius.only(
                            bottomLeft: Radius.circular(12),
                            bottomRight: Radius.circular(12),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                                'Total: ${_filteredConsultations.length} consultations'),
                            Row(
                              children: [
                                _buildStatusCount('Completed', Colors.green),
                                const SizedBox(width: 16),
                                _buildStatusCount('Scheduled', Colors.blue),
                                const SizedBox(width: 16),
                                _buildStatusCount('InProgress', Colors.orange),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildAccessDenied() {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title:
            const Text('Consultations', style: TextStyle(color: Colors.black)),
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.security, size: 80, color: Colors.grey),
            SizedBox(height: 20),
            Text(
              'Access Denied',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            SizedBox(height: 10),
            Text(
              'You do not have permission to view consultations.',
              style: TextStyle(fontSize: 16, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConsultationRow(Consultation consultation, Patient? patient) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.black12)),
      ),
      child: Row(
        children: [
          // Date
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  DateFormat('dd/MM/yyyy').format(consultation.date),
                  style: const TextStyle(
                      fontWeight: FontWeight.w500, fontSize: 13),
                ),
                Text(
                  consultation.time,
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
          ),

          // Patient
          Expanded(
            flex: 2,
            child: Text(
              patient?.fullName ?? 'Unknown Patient',
              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
              overflow: TextOverflow.ellipsis,
            ),
          ),

          // Type
          Expanded(
            flex: 2,
            child: Text(
              consultation.type,
              style: TextStyle(
                color: _getTypeColor(consultation.type),
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),

          // Diagnosis
          Expanded(
            flex: 2,
            child: Text(
              consultation.diagnosis.isNotEmpty
                  ? consultation.diagnosis.first
                  : 'No diagnosis',
              style: const TextStyle(fontSize: 11),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),

          // Status
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                color: _getStatusColor(consultation.status),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                consultation.status,
                style: const TextStyle(color: Colors.white, fontSize: 10),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),

          // ✅ ACTIONS AVEC PERMISSIONS
          Expanded(
            flex: 3,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // View Details
                Tooltip(
                  message: 'Details',
                  child: IconButton(
                    icon: const Icon(Icons.visibility,
                        color: AppColors.primary, size: 16),
                    onPressed: () => _viewConsultationDetails(consultation),
                    padding: const EdgeInsets.all(2),
                    constraints:
                        const BoxConstraints(minWidth: 24, minHeight: 24),
                  ),
                ),

                // ✅ View Prescriptions - Seulement si permission
                PermissionActionButton(
                  permission: 'view_prescription',
                  icon: Icons.medication,
                  color: Colors.orange,
                  tooltip: 'Prescriptions',
                  size: 16,
                  onPressed: () {
                    if (widget.onViewPrescriptions != null) {
                      widget.onViewPrescriptions!(consultation.id!);
                    } else {
                      _viewPrescription(consultation);
                    }
                  },
                ),

                // ✅ Edit Consultation - Seulement si permission
                PermissionActionButton(
                  permission: 'update_consultation',
                  icon: Icons.edit,
                  color: Colors.blue,
                  tooltip: 'Edit',
                  size: 16,
                  onPressed: () {
                    if (widget.onEditConsultation != null) {
                      widget.onEditConsultation!(consultation.id!);
                    } else {
                      _editConsultation(consultation);
                    }
                  },
                ),

                // Menu popup pour actions secondaires
                PopupMenuButton<String>(
                  icon:
                      const Icon(Icons.more_vert, size: 16, color: Colors.grey),
                  padding: const EdgeInsets.all(2),
                  constraints:
                      const BoxConstraints(minWidth: 24, minHeight: 24),
                  onSelected: (value) {
                    switch (value) {
                      case 'export':
                        _exportPDF(consultation);
                        break;
                      case 'delete':
                        _showDeleteDialog(consultation);
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'export',
                      child: Row(
                        children: [
                          Icon(Icons.picture_as_pdf,
                              color: Colors.red, size: 16),
                          SizedBox(width: 8),
                          Text('Export PDF', style: TextStyle(fontSize: 12)),
                        ],
                      ),
                    ),
                    // ✅ Delete seulement si permission
                    if (_hasDeletePermission())
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete_outline,
                                color: Colors.red, size: 16),
                            SizedBox(width: 8),
                            Text('Delete', style: TextStyle(fontSize: 12)),
                          ],
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ✅ Méthode pour vérifier permission delete
  bool _hasDeletePermission() {
    // Ici tu peux ajouter la logique pour vérifier la permission delete_consultation
    // Pour l'instant, on retourne true, mais tu peux l'adapter selon tes besoins
    return true;
  }

 void _showDeleteDialog(Consultation consultation) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.warning, color: Colors.red),
          SizedBox(width: 8),
          Text('Delete Consultation'),
        ],
      ),
      content: Text(
        'Are you sure you want to delete this consultation from ${DateFormat('dd/MM/yyyy').format(consultation.date)}?',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () async {
            Navigator.pop(context);

            try {
              final success = await _consultationService
                  .deleteConsultation(consultation.id!);

              if (success) {
                await _loadConsultations();

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Consultation deleted successfully'),
                    backgroundColor: Colors.green,
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Failed to delete consultation'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            } catch (e) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Delete error: $e'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
          ),
          child: const Text(
            'Delete',
            style: TextStyle(color: Colors.white),
          ),
        ),
      ],
    ),
  );
}

  void _editConsultation(Consultation consultation) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.edit, color: Colors.blue),
            SizedBox(width: 8),
            Text('Edit Consultation'),
          ],
        ),
        content: Text(
            'Edit consultation for ${consultation.type} on ${DateFormat('dd/MM/yyyy').format(consultation.date)}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content:
                      Text('Edit consultation functionality coming soon...'),
                  backgroundColor: Colors.blue,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
            child: const Text('Edit', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCount(String status, Color color) {
    final count = _consultations.where((c) => c.status == status).length;
    return Row(
      children: [
        CircleAvatar(radius: 4, backgroundColor: color),
        const SizedBox(width: 4),
        Text('$status: $count', style: const TextStyle(fontSize: 12)),
      ],
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

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter Consultations'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              value: _selectedStatus,
              decoration: const InputDecoration(labelText: 'Status'),
              items: [
                'Completed',
                'Scheduled',
                'InProgress',
                'Canceled',
                'Waiting'
              ]
                  .map((status) =>
                      DropdownMenuItem(value: status, child: Text(status)))
                  .toList(),
              onChanged: (value) => setState(() => _selectedStatus = value),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedType,
              decoration: const InputDecoration(labelText: 'Type'),
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
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _selectedStatus = null;
                _selectedType = null;
              });
              Navigator.pop(context);
            },
            child: const Text('Clear'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {});
            },
            child: const Text('Apply'),
          ),
        ],
      ),
    );
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
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.medication, color: Colors.orange),
            SizedBox(width: 8),
            Text('Prescriptions'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
                'View prescriptions for consultation on ${DateFormat('dd/MM/yyyy').format(consultation.date)}'),
            const SizedBox(height: 16),
            const Text(
              'This will open the prescriptions management screen.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Opening prescriptions...'),
                  backgroundColor: Colors.orange,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('View Prescriptions',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _exportPDF(Consultation consultation) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Exporting consultation as PDF...')),
    );
  }
}
