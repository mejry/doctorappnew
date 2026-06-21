// lib/features/patient/screens/patient_profile_screen.dart - PARTIE 1
import 'package:flutter/material.dart';
import 'package:frontend/core/constants/colors.dart';
import 'package:frontend/core/constants/primary_button.dart';
import 'package:frontend/core/services/session_manager.dart';
import 'package:frontend/shared/widgets/permission_widget.dart';
import 'package:frontend/features/patient/models/patient.dart';
import 'package:frontend/features/patient/services/patient_service.dart';
import 'package:frontend/features/consultation/services/consultation_service.dart';
import 'package:frontend/features/consultation/models/consultation.dart';
import 'package:frontend/features/prescription/services/prescription_service.dart';
import 'package:frontend/features/prescription/models/prescription.dart';
import 'package:intl/intl.dart';

class PatientProfileScreen extends StatefulWidget {
  final String patientId;
  final VoidCallback onBack;
  final VoidCallback onNewConsultation;
  final VoidCallback onViewConsultations;
  final Function(String prescriptionId)? onEditPrescription;

  const PatientProfileScreen({
    super.key,
    required this.patientId,
    required this.onBack,
    required this.onNewConsultation,
    required this.onViewConsultations,
    this.onEditPrescription,
  });

  @override
  State<PatientProfileScreen> createState() => _PatientProfileScreenState();
}

class _PatientProfileScreenState extends State<PatientProfileScreen>
    with TickerProviderStateMixin {
  final PatientService _patientService = PatientService();
  final ConsultationService _consultationService = ConsultationService();
  final PrescriptionService _prescriptionService = PrescriptionService();
  final SessionManager _sessionManager = SessionManager();

  late TabController _tabController;

  Patient? _patient;
  List<Consultation> _recentConsultations = [];
  List<Consultation> _filteredConsultations = [];
  List<Prescription> _recentPrescriptions = [];
  List<Prescription> _filteredPrescriptions = [];
  bool _isLoading = true;

  // 🔒 PERMISSIONS
  bool get _canViewConsultations =>
      SessionPermissions(_sessionManager).canViewConsultations;
  bool get _canCreateConsultation =>
      SessionPermissions(_sessionManager).canCreateConsultation;
  bool get _canViewPrescriptions =>
      SessionPermissions(_sessionManager).canViewPrescriptions;
  bool get _canCreatePrescription =>
      SessionPermissions(_sessionManager).canCreatePrescription;

  // Search controllers
  final TextEditingController _consultationSearchController =
      TextEditingController();
  final TextEditingController _prescriptionSearchController =
      TextEditingController();
  String _consultationSearchQuery = '';
  String _prescriptionSearchQuery = '';

  // Calculer le nombre de tabs disponibles selon les permissions
  int get _availableTabsCount {
    int count = 1; // Information tab always available
    if (_canViewConsultations) count++;
    if (_canViewPrescriptions) count++;
    return count;
  }

  List<Tab> get _availableTabs {
    List<Tab> tabs = [
      const Tab(
          text: 'Information', icon: Icon(Icons.person_outline, size: 20)),
    ];

    // ✅ CORRECTION: Vérifier la permission avant d'ajouter le tab
    if (_canViewConsultations) {
      tabs.add(const Tab(
          text: 'Consultations',
          icon: Icon(Icons.event_note_outlined, size: 20)));
    }

    if (_canViewPrescriptions) {
      tabs.add(const Tab(
          text: 'Prescriptions',
          icon: Icon(Icons.medication_outlined, size: 20)));
    }

    return tabs;
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _availableTabsCount, vsync: this);
    _loadPatientData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _consultationSearchController.dispose();
    _prescriptionSearchController.dispose();
    super.dispose();
  }

  Future<void> _loadPatientData() async {
    setState(() => _isLoading = true);
    try {
      final patient = await _patientService.getPatientById(widget.patientId);

      List<Consultation> consultations = [];
      List<Prescription> allPrescriptions = [];

      // Charger les consultations seulement si l'utilisateur a la permission
      if (_canViewConsultations) {
        try {
          consultations = await _consultationService
              .getConsultationsByPatientId(widget.patientId);

          // Charger les prescriptions seulement si l'utilisateur a la permission
          if (_canViewPrescriptions) {
            for (var consultation in consultations) {
              try {
                final prescriptions = await _prescriptionService
                    .getPrescriptionsByConsultation(consultation.id!);
                allPrescriptions.addAll(prescriptions);
              } catch (e) {
                debugPrint(
                    'Error loading prescriptions for consultation ${consultation.id}: $e');
              }
            }
          }
        } catch (e) {
          debugPrint('Error loading consultations: $e');
        }
      }

      setState(() {
        _patient = patient;
        _recentConsultations = consultations;
        _filteredConsultations = consultations;
        _recentPrescriptions = allPrescriptions
            .where((p) => p.prescriptionInfo.status != 'Cancelled')
            .toList();
        _filteredPrescriptions = _recentPrescriptions;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading patient data: $e')),
      );
    }
  }

  void _filterConsultations(String query) {
    setState(() {
      _consultationSearchQuery = query;
      if (query.isEmpty) {
        _filteredConsultations = _recentConsultations;
      } else {
        _filteredConsultations = _recentConsultations.where((consultation) {
          return consultation.type
                  .toLowerCase()
                  .contains(query.toLowerCase()) ||
              consultation.diagnosis
                  .any((d) => d.toLowerCase().contains(query.toLowerCase())) ||
              consultation.symptoms
                  .any((s) => s.toLowerCase().contains(query.toLowerCase()));
        }).toList();
      }
    });
  }

  void _filterPrescriptions(String query) {
    setState(() {
      _prescriptionSearchQuery = query;
      if (query.isEmpty) {
        _filteredPrescriptions = _recentPrescriptions;
      } else {
        _filteredPrescriptions = _recentPrescriptions.where((prescription) {
          return prescription.prescriptionInfo.type
                  .toLowerCase()
                  .contains(query.toLowerCase()) ||
              prescription.prescriptionInfo.status
                  .toLowerCase()
                  .contains(query.toLowerCase()) ||
              prescription.medications.any((med) =>
                  med.displayName.toLowerCase().contains(query.toLowerCase()));
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_patient == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Patient not found'),
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
          // Back button
          Container(
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.all(16),
            child: ElevatedButton.icon(
              onPressed: widget.onBack,
              icon: const Icon(Icons.arrow_back),
              label: const Text("Back to list"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey[200],
                foregroundColor: Colors.black,
                elevation: 0,
              ),
            ),
          ),

          // Patient header optimisé
          _buildOptimizedPatientHeader(),

          // Enhanced Tabs avec permissions
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: TabBar(
              controller: _tabController,
              labelColor: AppColors.primary,
              unselectedLabelColor: Colors.grey[600],
              indicatorColor: AppColors.primary,
              indicatorWeight: 3,
              indicatorPadding: const EdgeInsets.symmetric(horizontal: 20),
              labelStyle:
                  const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              unselectedLabelStyle:
                  const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
              tabs: _availableTabs,
            ),
          ),

          // Tab Content
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
                child: TabBarView(
                  controller: _tabController,
                  children: _buildTabViews(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildTabViews() {
    List<Widget> views = [_buildPatientInfoTab()];

    // ✅ IMPORTANT: Ajouter les vues seulement si les permissions correspondent
    if (_canViewConsultations) {
      views.add(_buildConsultationsTabWithSearch());
    }

    if (_canViewPrescriptions) {
      views.add(_buildPrescriptionsTabWithSearch());
    }

    return views;
  }

  Widget _buildOptimizedPatientHeader() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary,
            AppColors.primary.withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: CircleAvatar(
              radius: 35,
              backgroundColor: Colors.white,
              child: Text(
                _patient!.firstName[0] + _patient!.lastName[0],
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
          const SizedBox(width: 20),

          // Patient Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _patient!.fullName,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${_patient!.age} years old',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        _patient!.gender,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.email_outlined,
                        color: Colors.white70, size: 14),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        _patient!.email,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.white70,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // 🔒 Bouton New Consultation avec permission
          PermissionWidget(
            permission: 'create_consultation',
            hideIfNoPermission: true,
            child: Container(
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ElevatedButton.icon(
                onPressed: widget.onNewConsultation,
                icon: const Icon(Icons.add, size: 16),
                label: const Text(
                  'New',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppColors.primary,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 0,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPatientInfoTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _buildInfoCard('Personal Information', [
            _buildInfoRow('Full Name', _patient!.fullName),
            _buildInfoRow('Age', '${_patient!.age} years'),
            _buildInfoRow('Email', _patient!.email),
            _buildInfoRow('Phone', _patient!.phoneNumber ?? 'N/A'),
            _buildInfoRow('Gender', _patient!.gender),
            _buildInfoRow('Civil Status', _patient!.civilStatus ?? 'N/A'),
            _buildInfoRow('Address', _patient!.address ?? 'N/A'),
            _buildInfoRow(
                'Registration Date',
                _patient!.dateOfRegistration != null
                    ? DateFormat('dd/MM/yyyy')
                        .format(_patient!.dateOfRegistration!)
                    : 'N/A'),
          ]),
          if (_patient!.emergencyContacts?.isNotEmpty == true) ...[
            const SizedBox(height: 20),
            _buildInfoCard('Emergency Contact', [
              _buildInfoRow('Name', _patient!.emergencyContacts![0].name),
              _buildInfoRow('Phone', _patient!.emergencyContacts![0].phone),
              _buildInfoRow(
                  'Relationship', _patient!.emergencyContacts![0].relationship),
            ]),
          ],
          const SizedBox(height: 20),
          _buildInfoCard('Statistics', [
            // 🔒 Afficher les statistiques selon les permissions
            if (_canViewConsultations)
              _buildInfoRow(
                  'Total Consultations', '${_recentConsultations.length}'),
            if (_canViewPrescriptions)
              _buildInfoRow('Active Prescriptions',
                  '${_recentPrescriptions.where((p) => p.prescriptionInfo.status == 'Active').length}'),
            if (_canViewConsultations && _recentConsultations.isNotEmpty)
              _buildInfoRow(
                  'Last Visit',
                  DateFormat('dd/MM/yyyy')
                      .format(_recentConsultations.first.date))
            else if (!_canViewConsultations)
              _buildInfoRow('Last Visit', 'No access to consultation data'),
            if (!_canViewConsultations && !_canViewPrescriptions)
              _buildInfoRow('Statistics', 'Limited access to patient data'),
          ]),
        ],
      ),
    );
  }

// lib/features/patient/screens/patient_profile_screen.dart - PARTIE 2 (CONTINUATION)

  Widget _buildConsultationsTabWithSearch() {
    return Column(
      children: [
        // Search bar
        Container(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: _consultationSearchController,
            onChanged: _filterConsultations,
            decoration: InputDecoration(
              hintText: 'Search consultations...',
              prefixIcon: const Icon(Icons.search, color: AppColors.primary),
              suffixIcon: _consultationSearchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _consultationSearchController.clear();
                        _filterConsultations('');
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    BorderSide(color: AppColors.primary.withOpacity(0.3)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.primary),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
        ),

        // Header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Consultations (${_filteredConsultations.length})',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2E3440),
                ),
              ),
              // 🔒 View All button avec permission
              PermissionWidget(
                permission: 'view_consultation',
                hideIfNoPermission: true,
                child: TextButton.icon(
                  onPressed: widget.onViewConsultations,
                  icon: const Icon(Icons.visibility_outlined, size: 16),
                  label: const Text('View All'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 8),

        // Liste des consultations
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                if (_filteredConsultations.isEmpty)
                  _buildEmptyState(
                    Icons.event_note_outlined,
                    _consultationSearchQuery.isNotEmpty
                        ? 'No consultations found'
                        : 'No Consultations',
                    _consultationSearchQuery.isNotEmpty
                        ? 'No consultations match your search'
                        : 'This patient has no consultations yet.',
                  )
                else
                  ...(_filteredConsultations.map(
                      (consultation) => _buildConsultationCard(consultation))),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPrescriptionsTabWithSearch() {
    return Column(
      children: [
        // Search bar
        Container(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: _prescriptionSearchController,
            onChanged: _filterPrescriptions,
            decoration: InputDecoration(
              hintText: 'Search prescriptions...',
              prefixIcon: const Icon(Icons.search, color: AppColors.primary),
              suffixIcon: _prescriptionSearchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _prescriptionSearchController.clear();
                        _filterPrescriptions('');
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    BorderSide(color: AppColors.primary.withOpacity(0.3)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.primary),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
        ),

        // Header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Text(
                'Prescriptions (${_filteredPrescriptions.length})',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2E3440),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 8),

        // Liste des prescriptions
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                if (_filteredPrescriptions.isEmpty)
                  _buildEmptyState(
                    Icons.medication_outlined,
                    _prescriptionSearchQuery.isNotEmpty
                        ? 'No prescriptions found'
                        : 'No Prescriptions',
                    _prescriptionSearchQuery.isNotEmpty
                        ? 'No prescriptions match your search'
                        : 'This patient has no prescriptions yet.',
                  )
                else
                  ...(_filteredPrescriptions.map(
                      (prescription) => _buildPrescriptionCard(prescription))),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard(String title, List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: Color(0xFF2E3440),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConsultationCard(Consultation consultation) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                      Icons.event_note_outlined,
                      color: AppColors.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        DateFormat('dd/MM/yyyy').format(consultation.date),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Color(0xFF2E3440),
                        ),
                      ),
                      Text(
                        consultation.time,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _getStatusColor(consultation.status),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  consultation.status,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(Icons.medical_services_outlined,
                  size: 16, color: Colors.grey[600]),
              const SizedBox(width: 6),
              Text(
                'Type: ${consultation.type}',
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
              if (consultation.duration != null) ...[
                const SizedBox(width: 16),
                Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 6),
                Text(
                  '${consultation.duration} min',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
              ],
            ],
          ),
          if (consultation.diagnosis.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.withOpacity(0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Diagnosis:',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    consultation.diagnosis.join(', '),
                    style: const TextStyle(fontSize: 13),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
          if (consultation.symptoms.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.withOpacity(0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Symptoms:',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    consultation.symptoms.join(', '),
                    style: const TextStyle(fontSize: 13),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPrescriptionCard(Prescription prescription) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _getPrescriptionStatusColor(
                              prescription.prescriptionInfo.status)
                          .withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.medication_outlined,
                      color: _getPrescriptionStatusColor(
                          prescription.prescriptionInfo.status),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        DateFormat('dd/MM/yyyy')
                            .format(prescription.prescriptionInfo.date),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Color(0xFF2E3440),
                        ),
                      ),
                      Text(
                        prescription.prescriptionInfo.time,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _getPrescriptionStatusColor(
                      prescription.prescriptionInfo.status),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  prescription.prescriptionInfo.status,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Type and validity
          Row(
            children: [
              Icon(Icons.category_outlined, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 6),
              Text(
                'Type: ${prescription.prescriptionInfo.type}',
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
              const SizedBox(width: 16),
              Icon(Icons.schedule, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 6),
              Text(
                'Valid: ${prescription.prescriptionInfo.validityDays} days',
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Medications
          if (prescription.medications.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.primary.withOpacity(0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Medications:',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...prescription.medications
                      .take(3)
                      .map((med) => _buildMedicationRow(med)),
                  if (prescription.medications.length > 3) ...[
                    const SizedBox(height: 4),
                    Text(
                      '... and ${prescription.medications.length - 3} more medication(s)',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.withOpacity(0.2)),
              ),
              child: const Text(
                'No medications prescribed',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],

          // Notes
          if (prescription.prescriptionInfo.notes?.isNotEmpty == true) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.withOpacity(0.2)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.note_outlined, size: 16, color: Colors.blue),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      prescription.prescriptionInfo.notes!,
                      style: const TextStyle(fontSize: 13),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Actions avec permissions
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              // 🔒 View Details - toujours visible si on peut voir les prescriptions
              TextButton.icon(
                onPressed: () => _viewPrescriptionDetails(prescription),
                icon: const Icon(Icons.visibility_outlined, size: 16),
                label: const Text('View Details'),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  textStyle: const TextStyle(fontSize: 12),
                ),
              ),

              // 🔒 Edit Prescription - seulement si permission update_prescription
              PermissionWidget(
                permission: 'update_prescription',
                hideIfNoPermission: true,
                child: widget.onEditPrescription != null &&
                        prescription.prescriptionInfo.status != 'Completed'
                    ? Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: TextButton.icon(
                          onPressed: () =>
                              widget.onEditPrescription!(prescription.id!),
                          icon: const Icon(Icons.edit_outlined, size: 16),
                          label: const Text('Edit'),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.orange,
                            textStyle: const TextStyle(fontSize: 12),
                          ),
                        ),
                      )
                    : const SizedBox.shrink(),
              ),

              // Print button - visible si prescription active
              if (prescription.prescriptionInfo.status == 'Active') ...[
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: () => _printPrescription(prescription),
                  icon: const Icon(Icons.print_outlined, size: 16),
                  label: const Text('Print'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.green,
                    textStyle: const TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMedicationRow(PrescriptionMedication medication) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ',
              style: TextStyle(color: AppColors.primary, fontSize: 16)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  medication.displayName,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2E3440),
                  ),
                ),
                if (medication.dosage.displayText.isNotEmpty)
                  Text(
                    medication.dosage.displayText,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(IconData icon, String title, String subtitle) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 48,
              color: Colors.grey[400],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
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
      case 'Waiting':
        return Colors.amber;
      case 'Canceled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Color _getPrescriptionStatusColor(String status) {
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

  void _viewPrescriptionDetails(Prescription prescription) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.medication_outlined, color: AppColors.primary),
            SizedBox(width: 8),
            Text('Prescription Details'),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDetailRow(
                    'Date',
                    DateFormat('dd/MM/yyyy at HH:mm')
                        .format(prescription.prescriptionInfo.date)),
                _buildDetailRow('Type', prescription.prescriptionInfo.type),
                _buildDetailRow('Status', prescription.prescriptionInfo.status),
                _buildDetailRow('Validity',
                    '${prescription.prescriptionInfo.validityDays} days'),
                if (prescription.prescriptionInfo.notes?.isNotEmpty ==
                    true) ...[
                  const SizedBox(height: 16),
                  const Text(
                    'Notes:',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, color: AppColors.primary),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(prescription.prescriptionInfo.notes!),
                  ),
                ],
                const SizedBox(height: 16),
                const Text(
                  'Medications:',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: AppColors.primary),
                ),
                const SizedBox(height: 8),
                if (prescription.medications.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'No medications prescribed',
                      style: TextStyle(
                          fontStyle: FontStyle.italic, color: Colors.grey),
                    ),
                  )
                else
                  ...prescription.medications.map((med) => Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(12),
                          color: Colors.grey[50],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Icon(
                                    Icons.medication,
                                    size: 16,
                                    color: AppColors.primary,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    med.displayName,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: Color(0xFF2E3440),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            if (med.dosage.strength?.isNotEmpty == true)
                              _buildDetailRow('Dosage', med.dosage.strength!),
                            if (med.dosage.frequency?.isNotEmpty == true)
                              _buildDetailRow(
                                  'Frequency', med.dosage.frequency!),
                            if (med.dosage.duration?.isNotEmpty == true)
                              _buildDetailRow('Duration', med.dosage.duration!),
                            if (med.dosage.route?.isNotEmpty == true)
                              _buildDetailRow('Route', med.dosage.route!),
                            if (med.dosage.instructions?.isNotEmpty == true)
                              _buildDetailRow(
                                  'Instructions', med.dosage.instructions!),
                            if (med.quantity?.prescribed != null)
                              _buildDetailRow('Prescribed Quantity',
                                  '${med.quantity!.prescribed}'),
                            if (med.refills?.allowed != null)
                              _buildDetailRow(
                                  'Allowed Refills', '${med.refills!.allowed}'),
                          ],
                        ),
                      )),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF2E3440),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _printPrescription(Prescription prescription) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Print functionality is under development'),
        backgroundColor: Colors.blue,
      ),
    );
  }
}

// FIN DE LA PARTIE 2 - Code complet terminé
