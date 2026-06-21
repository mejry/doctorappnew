// lib/features/patient/screens/patient_list_screen.dart - VERSION AVEC CONTRÔLE PERMISSIONS
import 'package:flutter/material.dart';
import 'package:frontend/core/constants/colors.dart';
import 'package:frontend/features/patient/widgets/patient_row_enhanced.dart';
import 'package:frontend/features/patient/widgets/table_header.dart';
import 'package:frontend/shared/widgets/buttons/icon_button.dart';
import 'package:frontend/shared/widgets/permission_widget.dart';
import 'package:frontend/features/patient/services/patient_service.dart';
import 'package:frontend/features/patient/models/patient.dart';

class PatientListScreen extends StatefulWidget {
  final VoidCallback onAddPatientPressed;
  final Function(String, String) onPatientAction;

  const PatientListScreen({
    super.key,
    required this.onAddPatientPressed,
    required this.onPatientAction,
  });

  @override
  State<PatientListScreen> createState() => _PatientListScreenState();
}

class _PatientListScreenState extends State<PatientListScreen> {
  final PatientService _patientService = PatientService();
  List<Patient> _patients = [];
  List<Patient> _filteredPatients = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadPatients();
  }

  Future<void> _loadPatients() async {
    setState(() => _isLoading = true);
    try {
      final patients = await _patientService.getAllPatients();
      setState(() {
        _patients = patients;
        _filteredPatients = patients;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading patients: $e')),
      );
    }
  }

  void _filterPatients(String query) {
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _filteredPatients = _patients;
      } else {
        _filteredPatients = _patients.where((patient) {
          return patient.fullName.toLowerCase().contains(query.toLowerCase()) ||
              patient.email.toLowerCase().contains(query.toLowerCase());
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // ✅ VÉRIFICATION PERMISSION PRINCIPALE
    return PermissionWidget(
      permission: 'view_patient',
      fallback: _buildAccessDenied(),
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          title: const Text('Patients List',
              style: TextStyle(color: Colors.black)),
          actions: [
            Container(
              width: 300,
              height: 40,
              margin: const EdgeInsets.symmetric(vertical: 10),
              child: TextField(
                onChanged: _filterPatients,
                decoration: InputDecoration(
                  hintText: 'Search patients...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                ),
              ),
            ),
            const SizedBox(width: 8),
            AppIconButton(
              icon: Icons.filter_list,
              onPressed: () => _showFilterDialog(),
            ),
            const SizedBox(width: 8),

            // ✅ BOUTON ADD PATIENT SEULEMENT SI PERMISSION
            PermissionAddButton(
              permission: 'create_patient',
              text: 'Add Patient',
              onPressed: widget.onAddPatientPressed,
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
                            TableHeader("Patient", color: Colors.white),
                            TableHeader("Last Consultation",
                                color: Colors.white),
                            TableHeader("Status", color: Colors.white),
                            TableHeader("Actions", color: Colors.white),
                          ],
                        ),
                      ),
                      const Divider(height: 1, thickness: 1),

                      // Liste des patients
                      Expanded(
                        child: _filteredPatients.isEmpty
                            ? const Center(
                                child: Text(
                                  'No patients found',
                                  style: TextStyle(
                                      fontSize: 16, color: Colors.grey),
                                ),
                              )
                            : ListView.builder(
                                itemCount: _filteredPatients.length,
                                itemBuilder: (context, index) {
                                  final patient = _filteredPatients[index];
                                  return PatientRowEnhanced(
                                    patient: patient,
                                    onAction: (action) => widget
                                        .onPatientAction(patient.id!, action),
                                  );
                                },
                              ),
                      ),

                      // Pagination
                      Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Total: ${_filteredPatients.length} patients'),
                            const Row(
                              children: [
                                Icon(Icons.arrow_back_ios, size: 16),
                                SizedBox(width: 4),
                                Text("1  2  3  ..."),
                                SizedBox(width: 4),
                                Icon(Icons.arrow_forward_ios, size: 16),
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
        title: const Text('Patients', style: TextStyle(color: Colors.black)),
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
              'You do not have permission to view patients.',
              style: TextStyle(fontSize: 16, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter Patients'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Filter options coming soon...'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }
}
