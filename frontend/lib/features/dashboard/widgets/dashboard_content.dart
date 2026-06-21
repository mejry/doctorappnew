// lib/features/dashboard/widgets/dashboard_content.dart - VERSION AVEC PERMISSIONS
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:frontend/core/constants/colors.dart';
import 'package:frontend/core/models/user.dart';
import 'package:frontend/core/services/session_manager.dart'; // ✅ AJOUT
import 'package:frontend/features/patient/providers/patient_provider.dart';
import 'package:frontend/features/consultation/providers/consultation_provider.dart';
import 'package:frontend/features/prescription/providers/prescription_provider.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

class DashboardContent extends StatefulWidget {
  final User user;
  final Function(String)? onNavigate;

  const DashboardContent({
    super.key,
    required this.user,
    this.onNavigate,
  });

  @override
  State<DashboardContent> createState() => _DashboardContentState();
}

class _DashboardContentState extends State<DashboardContent> {
  final SessionManager _sessionManager = SessionManager(); // ✅ AJOUT

  String _formattedDate = '';
  String _formattedTime = '';
  late Timer _timer;
  bool _isLoading = true;

  // Statistics data with default values
  int _totalPatients = 0;
  int _monthlyPatients = 0;
  int _totalConsultations = 0;
  int _todayConsultations = 0;
  int _recentConsultations = 0;
  int _monthlyConsultations = 0;
  int _activePrescriptions = 0;
  int _pendingPrescriptions = 0;
  List<dynamic> _recentPatients = [];
  List<dynamic> _todayAppointments = [];
  List<dynamic> _recentAppointments = [];
  List<dynamic> _urgentCases = [];

  // ✅ NOUVELLES PROPRIÉTÉS POUR LES PERMISSIONS
  bool get _canViewPatients =>
      SessionPermissions(_sessionManager).canViewPatients;
  bool get _canCreatePatient =>
      SessionPermissions(_sessionManager).canCreatePatient;
  bool get _canViewConsultations =>
      SessionPermissions(_sessionManager).canViewConsultations;
  bool get _canCreateConsultation =>
      SessionPermissions(_sessionManager).canCreateConsultation;
  bool get _canViewMedications =>
      SessionPermissions(_sessionManager).canViewMedications;

  @override
  void initState() {
    super.initState();
    _updateTime();
    _timer =
        Timer.periodic(const Duration(minutes: 1), (Timer t) => _updateTime());

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDashboardData();
    });
  }

  void _updateTime() {
    final now = DateTime.now();
    setState(() {
      _formattedDate = DateFormat('EEEE, dd MMMM yyyy').format(now);
      _formattedTime =
          "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";
    });
  }

  // ✅ NOUVELLE MÉTHODE: Obtenir le titre approprié selon le rôle
  String _getUserTitle() {
    final userRole = widget.user.role?.toLowerCase() ?? '';

    switch (userRole) {
      case 'doctor':
      case 'docteur':
      case 'médecin':
        return 'Dr. ${widget.user.lastname}';
      case 'nurse':
      case 'infirmier':
      case 'infirmière':
        return 'Nurse ${widget.user.lastname}';
      case 'secretary':
      case 'secrétaire':
        return '${widget.user.firstname} ${widget.user.lastname}';
      case 'admin':
      case 'administrator':
        return 'Admin ${widget.user.lastname}';
      default:
        return '${widget.user.firstname} ${widget.user.lastname}';
    }
  }

  // ✅ NOUVELLE MÉTHODE: Obtenir le message de bienvenue approprié
  String _getWelcomeMessage() {
    final userRole = widget.user.role?.toLowerCase() ?? '';
    final hour = DateTime.now().hour;

    String timeGreeting;
    if (hour < 12) {
      timeGreeting = 'Good morning';
    } else if (hour < 17) {
      timeGreeting = 'Good afternoon';
    } else {
      timeGreeting = 'Good evening';
    }

    switch (userRole) {
      case 'doctor':
      case 'docteur':
      case 'médecin':
        return '$timeGreeting Dr. ${widget.user.lastname}';
      case 'nurse':
      case 'infirmier':
      case 'infirmière':
        return '$timeGreeting Nurse ${widget.user.lastname}';
      case 'secretary':
      case 'secrétaire':
        return '$timeGreeting ${widget.user.firstname}';
      case 'admin':
      case 'administrator':
        return '$timeGreeting Admin ${widget.user.lastname}';
      default:
        return '$timeGreeting ${widget.user.firstname}';
    }
  }

  Future<void> _loadDashboardData() async {
    if (!mounted) return;

    setState(() => _isLoading = true);

    try {
      // ✅ CHARGEMENT CONDITIONNEL BASÉ SUR LES PERMISSIONS

      // Load Patient Data seulement si permission
      if (_canViewPatients) {
        final hasPatientProvider =
            Provider.of<PatientProvider?>(context, listen: false) != null;

        if (hasPatientProvider) {
          final patientProvider =
              Provider.of<PatientProvider>(context, listen: false);
          await patientProvider.loadPatients();

          final patients = patientProvider.patients;
          final now = DateTime.now();
          final startOfMonth = DateTime(now.year, now.month, 1);

          setState(() {
            _totalPatients = patients.length;
            _monthlyPatients = patients
                .where((p) =>
                    p.dateOfRegistration != null &&
                    p.dateOfRegistration!.isAfter(startOfMonth))
                .length;

            final sortedPatients = List.from(patients);
            sortedPatients.sort((a, b) =>
                (b.dateOfRegistration ?? DateTime.now())
                    .compareTo(a.dateOfRegistration ?? DateTime.now()));
            _recentPatients = sortedPatients.take(5).toList();
          });
        }
      } else {
        // Si pas de permission, mettre des valeurs par défaut
        setState(() {
          _totalPatients = 0;
          _monthlyPatients = 0;
          _recentPatients = [];
        });
      }

      // Load Consultation Data seulement si permission
      if (_canViewConsultations) {
        final hasConsultationProvider =
            Provider.of<ConsultationProvider?>(context, listen: false) != null;

        if (hasConsultationProvider) {
          final consultationProvider =
              Provider.of<ConsultationProvider>(context, listen: false);
          await consultationProvider.loadConsultations();

          final consultations = consultationProvider.consultations;
          final now = DateTime.now();
          final startOfMonth = DateTime(now.year, now.month, 1);
          final endOfMonth = DateTime(now.year, now.month + 1, 1);
          final startOfToday = DateTime(now.year, now.month, now.day);
          final startOfTomorrow = startOfToday.add(const Duration(days: 1));
          final threeDaysAgo = now.subtract(const Duration(days: 3));

          final monthlyConsultationsList = consultations.where((c) {
            final isInMonth =
                c.date.isAfter(startOfMonth) && c.date.isBefore(endOfMonth);
            return isInMonth;
          }).toList();

          final todayConsultationsList = consultations.where((c) {
            final isToday = c.date.isAfter(startOfToday) &&
                c.date.isBefore(startOfTomorrow);
            return isToday;
          }).toList();

          final recentConsultationsList = consultations.where((c) {
            final isRecent = c.date.isAfter(threeDaysAgo);
            return isRecent;
          }).toList();

          final urgentCasesList = consultations.where((c) {
            final isUrgent = c.isEmergency == true ||
                c.type.toLowerCase().contains('emergency') ||
                c.status == 'InProgress';
            return isUrgent;
          }).toList();

          setState(() {
            _totalConsultations = consultations.length;
            _monthlyConsultations = monthlyConsultationsList.length;
            _todayConsultations = todayConsultationsList.length;
            _recentConsultations = recentConsultationsList.length;
            _urgentCases = urgentCasesList;

            if (todayConsultationsList.isEmpty) {
              _todayAppointments = recentConsultationsList.take(3).toList();
              _recentAppointments = recentConsultationsList;
            } else {
              _todayAppointments = todayConsultationsList;
              _recentAppointments = recentConsultationsList;
            }
          });
        }
      } else {
        // Si pas de permission, mettre des valeurs par défaut
        setState(() {
          _totalConsultations = 0;
          _monthlyConsultations = 0;
          _todayConsultations = 0;
          _recentConsultations = 0;
          _urgentCases = [];
          _todayAppointments = [];
          _recentAppointments = [];
        });
      }

      // Load Prescription Data seulement si permission
      if (SessionPermissions(_sessionManager).canViewPrescriptions) {
        final hasPrescriptionProvider =
            Provider.of<PrescriptionProvider?>(context, listen: false) != null;

        if (hasPrescriptionProvider) {
          final prescriptionProvider =
              Provider.of<PrescriptionProvider>(context, listen: false);
          await prescriptionProvider.loadPrescriptions();

          final prescriptions = prescriptionProvider.prescriptions;

          setState(() {
            _activePrescriptions = prescriptions
                .where(
                    (p) => p.prescriptionInfo.status.toLowerCase() == 'active')
                .length;
            _pendingPrescriptions = prescriptions
                .where(
                    (p) => p.prescriptionInfo.status.toLowerCase() == 'pending')
                .length;
          });
        }
      } else {
        // Si pas de permission, mettre des valeurs par défaut
        setState(() {
          _activePrescriptions = 0;
          _pendingPrescriptions = 0;
        });
      }

      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _isLoading = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading dashboard data: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color.fromARGB(255, 255, 255, 255),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 20),
            if (_isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(),
                ),
              )
            else ...[
              _buildStatsGrid(),
              const SizedBox(height: 20),
              LayoutBuilder(
                builder: (context, constraints) {
                  if (constraints.maxWidth > 1200) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 2,
                          child: Column(
                            children: [
                              // ✅ Afficher seulement si permission de voir les consultations
                              if (_canViewConsultations) ...[
                                _buildTodaySchedule(),
                                const SizedBox(height: 20),
                              ],
                              // ✅ Afficher seulement si permission de voir les patients
                              if (_canViewPatients) _buildRecentPatients(),
                            ],
                          ),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: Column(
                            children: [
                              _buildQuickActions(),
                              const SizedBox(height: 20),
                              // ✅ Afficher seulement si permission de voir les consultations
                              if (_canViewConsultations) _buildUrgentCases(),
                            ],
                          ),
                        ),
                      ],
                    );
                  } else {
                    return Column(
                      children: [
                        _buildQuickActions(),
                        const SizedBox(height: 20),
                        // ✅ Afficher seulement si permission de voir les consultations
                        if (_canViewConsultations) ...[
                          _buildTodaySchedule(),
                          const SizedBox(height: 20),
                        ],
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // ✅ Afficher seulement si permission de voir les patients
                            if (_canViewPatients)
                              Expanded(child: _buildRecentPatients()),
                            if (_canViewPatients && _canViewConsultations)
                              const SizedBox(width: 16),
                            // ✅ Afficher seulement si permission de voir les consultations
                            if (_canViewConsultations)
                              Expanded(child: _buildUrgentCases()),
                          ],
                        ),
                      ],
                    );
                  }
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primary.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    '$_formattedDate • $_formattedTime',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  _getWelcomeMessage(), // ✅ UTILISATION DE LA MÉTHODE PERSONNALISÉE
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _getSubtitleMessage(), // ✅ SOUS-TITRE PERSONNALISÉ
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                const Icon(Icons.local_hospital, color: Colors.white, size: 28),
                const SizedBox(height: 6),
                Text(
                  'Clinic',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ✅ NOUVELLE MÉTHODE: Sous-titre personnalisé selon le rôle
  String _getSubtitleMessage() {
    final userRole = widget.user.role?.toLowerCase() ?? '';

    switch (userRole) {
      case 'doctor':
      case 'docteur':
      case 'médecin':
        return 'Your medical dashboard with all essential patient information.';
      case 'nurse':
      case 'infirmier':
      case 'infirmière':
        return 'Your nursing dashboard for patient care management.';
      case 'secretary':
      case 'secrétaire':
        return 'Your administrative dashboard for clinic management.';
      case 'admin':
      case 'administrator':
        return 'Your administrative dashboard with system oversight.';
      default:
        return 'Your dashboard with available information.';
    }
  }

  Widget _buildStatsGrid() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Clinic Statistics',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2E3440),
              ),
            ),
            TextButton.icon(
              onPressed: _loadDashboardData,
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('Refresh'),
              style: TextButton.styleFrom(foregroundColor: AppColors.primary),
            ),
          ],
        ),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            // ✅ CRÉER DYNAMIQUEMENT LES CARTES SELON LES PERMISSIONS
            List<Widget> statCards = [];

            // Carte Patients (seulement si permission)
            if (_canViewPatients) {
              statCards.add(
                Expanded(
                  child: _buildStatCard(
                    'Total Patients',
                    '$_totalPatients',
                    '+$_monthlyPatients this month',
                    Icons.people_outline,
                    AppColors.primary,
                    _monthlyPatients > 0 ? 'up' : 'stable',
                  ),
                ),
              );
            }

            // Carte Consultations (seulement si permission)
            if (_canViewConsultations) {
              if (statCards.isNotEmpty) {
                statCards.add(const SizedBox(width: 12));
              }
              statCards.add(
                Expanded(
                  child: _buildStatCard(
                    'Total Consultations',
                    '$_totalConsultations',
                    '+$_monthlyConsultations this month',
                    Icons.event_note_outlined,
                    Colors.blue,
                    _monthlyConsultations > 0 ? 'up' : 'stable',
                  ),
                ),
              );
            }

            // Carte Prescriptions (seulement si permission)
            if (SessionPermissions(_sessionManager).canViewPrescriptions) {
              if (statCards.isNotEmpty) {
                statCards.add(const SizedBox(width: 12));
              }
              statCards.add(
                Expanded(
                  child: _buildStatCard(
                    'Prescriptions',
                    '$_activePrescriptions',
                    '$_pendingPrescriptions pending',
                    Icons.medication_outlined,
                    Colors.orange,
                    _pendingPrescriptions > 0 ? 'pending' : 'stable',
                  ),
                ),
              );
            }

            // Si aucune permission, afficher un message
            if (statCards.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: const Center(
                  child: Column(
                    children: [
                      Icon(Icons.info_outline, size: 48, color: Colors.grey),
                      SizedBox(height: 12),
                      Text(
                        'Limited Access',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                      ),
                      Text(
                        'You have limited access to clinic statistics.',
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            }

            if (constraints.maxWidth > 800) {
              return Row(children: statCards);
            } else {
              // Version responsive pour écrans plus petits
              if (statCards.length <= 2) {
                return Row(children: statCards);
              } else {
                return Column(
                  children: [
                    Row(children: statCards.take(2).toList()),
                    if (statCards.length > 2) ...[
                      const SizedBox(height: 12),
                      statCards[2],
                    ],
                  ],
                );
              }
            }
          },
        ),
      ],
    );
  }

  Widget _buildQuickActions() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
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
                    const Icon(Icons.flash_on, color: Colors.purple, size: 18),
              ),
              const SizedBox(width: 10),
              const Text(
                'Quick Actions',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2E3440),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // ✅ ACTIONS CONDITIONNELLES SELON LES PERMISSIONS

          // New Patient - seulement si permission de créer des patients
          if (_canCreatePatient)
            _buildActionButton(
              'New Patient',
              'Add a patient',
              Icons.person_add,
              AppColors.primary,
              () => _handleNavigation('Patient'),
            )
          else if (_canViewPatients)
            _buildActionButton(
              'View Patients',
              'Browse patients',
              Icons.people_outline,
              AppColors.primary,
              () => _handleNavigation('Patient'),
            ),

          if (_canCreatePatient || _canViewPatients) const SizedBox(height: 8),

          // New Consultation - seulement si permission de créer des consultations
          if (_canCreateConsultation)
            _buildActionButton(
              'New Consultation',
              'Create consultation',
              Icons.add_circle_outline,
              Colors.blue,
              () => _handleNavigation('Consultation'),
            )
          else if (_canViewConsultations)
            _buildActionButton(
              'View Consultations',
              'Browse consultations',
              Icons.event_note_outlined,
              Colors.blue,
              () => _handleNavigation('Consultation'),
            ),

          if (_canCreateConsultation || _canViewConsultations)
            const SizedBox(height: 8),

          // Medications - seulement si permission de voir les médicaments
          if (_canViewMedications)
            _buildActionButton(
              'Medications',
              'Manage medications',
              Icons.medication,
              Colors.orange,
              () => _handleNavigation('Medications'),
            ),

          // ✅ SI AUCUNE PERMISSION, AFFICHER UN MESSAGE
          if (!_canCreatePatient &&
              !_canViewPatients &&
              !_canCreateConsultation &&
              !_canViewConsultations &&
              !_canViewMedications)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: const Center(
                child: Column(
                  children: [
                    Icon(Icons.lock_outline, size: 32, color: Colors.grey),
                    SizedBox(height: 8),
                    Text(
                      'No Actions Available',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey,
                      ),
                    ),
                    Text(
                      'Contact administrator for access',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _handleNavigation(String destination) {
    if (widget.onNavigate != null) {
      widget.onNavigate!(destination);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Opening $destination...'),
          backgroundColor: AppColors.primary,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Widget _buildActionButton(String title, String subtitle, IconData icon,
      Color color, VoidCallback? onPressed) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.05),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(icon, color: color, size: 16),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                      color: color,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 12, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }

  // ✅ CONTINUER AVEC LES AUTRES WIDGETS (sans changement majeur car déjà conditionnels)
  Widget _buildStatCard(String title, String value, String subtitle,
      IconData icon, Color color, String trend) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              _buildTrendIcon(trend),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2E3440),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrendIcon(String trend) {
    switch (trend) {
      case 'up':
        return Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: Colors.green.withOpacity(0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: const Icon(Icons.trending_up, color: Colors.green, size: 14),
        );
      case 'pending':
        return Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: Colors.orange.withOpacity(0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: const Icon(Icons.schedule, color: Colors.orange, size: 14),
        );
      default:
        return Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: Colors.grey.withOpacity(0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: const Icon(Icons.remove, color: Colors.grey, size: 14),
        );
    }
  }

  Widget _buildTodaySchedule() {
    final bool hasToday = _todayConsultations > 0;
    final String scheduleTitle =
        hasToday ? 'Today\'s Consultations' : 'Recent Consultations';
    final int displayCount =
        hasToday ? _todayConsultations : _recentConsultations;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
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
                child: Icon(hasToday ? Icons.today : Icons.history,
                    color: Colors.blue, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  scheduleTitle,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2E3440),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$displayCount',
                  style: const TextStyle(
                    color: Colors.blue,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_todayAppointments.isEmpty)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Column(
                children: [
                  Icon(Icons.event_available, size: 40, color: Colors.grey),
                  SizedBox(height: 8),
                  Text(
                    'No recent consultations',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    'Quiet period',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            )
          else
            ...(_todayAppointments
                .take(3)
                .map((consultation) => _buildConsultationItem(consultation))),
        ],
      ),
    );
  }

  Widget _buildConsultationItem(dynamic consultation) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: _getStatusColor(consultation.status).withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Icon(
              Icons.person,
              color: _getStatusColor(consultation.status),
              size: 14,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  consultation.type,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
                Text(
                  '${consultation.time} • ${DateFormat('dd/MM').format(consultation.date)}',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: _getStatusColor(consultation.status),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              consultation.status,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 9,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentPatients() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
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
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(Icons.person_add,
                    color: AppColors.primary, size: 18),
              ),
              const SizedBox(width: 10),
              const Text(
                'New Patients',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2E3440),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_recentPatients.isEmpty)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Center(
                child: Column(
                  children: [
                    Icon(Icons.people_outline, size: 40, color: Colors.grey),
                    SizedBox(height: 8),
                    Text(
                      'No new patients',
                      style: TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                  ],
                ),
              ),
            )
          else
            ...(_recentPatients
                .take(4)
                .map((patient) => _buildPatientItem(patient))),
        ],
      ),
    );
  }

  Widget _buildPatientItem(dynamic patient) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: AppColors.primary,
            child: Text(
              patient.firstName[0] + patient.lastName[0],
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  patient.fullName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
                Text(
                  '${patient.age} years • ${patient.gender}',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          if (patient.dateOfRegistration != null)
            Text(
              DateFormat('dd/MM').format(patient.dateOfRegistration!),
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey[500],
                fontWeight: FontWeight.w500,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildUrgentCases() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
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
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(Icons.priority_high,
                    color: Colors.red, size: 18),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Urgent Cases',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2E3440),
                  ),
                ),
              ),
              if (_urgentCases.isNotEmpty)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${_urgentCases.length}',
                    style: const TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (_urgentCases.isEmpty)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Center(
                child: Column(
                  children: [
                    Icon(Icons.check_circle, size: 40, color: Colors.green),
                    SizedBox(height: 8),
                    Text(
                      'No urgent cases',
                      style: TextStyle(
                        color: Colors.green,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'All good!',
                      style: TextStyle(color: Colors.green, fontSize: 12),
                    ),
                  ],
                ),
              ),
            )
          else
            ...(_urgentCases
                .take(3)
                .map((case_) => _buildUrgentCaseItem(case_))),
        ],
      ),
    );
  }

  Widget _buildUrgentCaseItem(dynamic urgentCase) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Icon(
              urgentCase.isEmergency == true ||
                      urgentCase.type.toLowerCase().contains('emergency')
                  ? Icons.local_hospital
                  : Icons.warning,
              color: Colors.red,
              size: 14,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  urgentCase.type,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                    color: Colors.red,
                  ),
                ),
                Text(
                  urgentCase.status,
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Text(
            DateFormat('HH:mm').format(urgentCase.date),
            style: const TextStyle(
              fontSize: 10,
              color: Colors.red,
              fontWeight: FontWeight.w500,
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
      case 'Waiting':
        return Colors.amber;
      case 'Canceled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
