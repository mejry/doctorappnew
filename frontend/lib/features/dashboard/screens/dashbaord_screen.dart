// lib/features/dashboard/screens/dashboard_screen.dart - VERSION CORRIGÉE AVEC PERMISSIONS ET BREADCRUMB AMÉLIORÉ
import 'package:flutter/material.dart';
import 'package:frontend/core/constants/colors.dart';
import 'package:frontend/core/models/user.dart';
import 'package:frontend/core/services/session_manager.dart';
import 'package:frontend/features/auth/screens/account_information_screen.dart';
import 'package:frontend/features/auth/screens/add_user_screen.dart';
import 'package:frontend/features/auth/screens/roles_list_screen.dart';
import 'package:frontend/features/auth/screens/security_privacy_screen.dart';
import 'package:frontend/features/auth/screens/users_list_screen.dart';
import 'package:frontend/features/consultation/screens/add_consultation_with_steps_screen.dart';
import 'package:frontend/features/consultation/screens/consultation_prescriptions_screen.dart';
import 'package:frontend/features/consultation/screens/edit_consultation_screen.dart';
import 'package:frontend/features/appointment/screens/add_appointment_screen.dart';
import 'package:frontend/features/appointment/screens/appointment_list_screen.dart';
import 'package:frontend/features/patient/screens/add_patient_screen.dart';
import 'package:frontend/features/patient/screens/patient_list_screen.dart';
import 'package:frontend/features/patient/screens/patient_profile_screen.dart';
import 'package:frontend/features/patient/screens/patient_consultations_screen.dart';
import 'package:frontend/features/consultation/screens/consultation_list_screen.dart';
import 'package:frontend/features/consultation/screens/new_consultation_screen.dart';
import 'package:frontend/features/patient/services/patient_service.dart';
import 'package:frontend/features/appointment/services/appointment_service.dart';
import 'package:frontend/features/appointment/models/appointment.dart';
import 'package:frontend/features/prescription/screens/add_medication_screen.dart';
import 'package:frontend/features/prescription/screens/medicationList._screen.dart';
import 'package:frontend/features/prescription/screens/auto_prescription_screen.dart';
import 'package:frontend/features/prescription/screens/prescription_form_screen.dart';
import 'package:frontend/shared/widgets/sidebar_menu.dart';
import 'package:frontend/shared/widgets/top_app_bar.dart';
import 'package:frontend/features/dashboard/widgets/dashboard_content.dart';
import 'package:frontend/features/auth/providers/auth_provider.dart';
import 'package:frontend/features/auth/providers/user_provider.dart';
import 'package:provider/provider.dart';

// Define navigation context for consultation navigation
enum NavigationContext {
  fromPatientList,
  fromPatientProfile,
  fromConsultationList,
}

class DashboardScreen extends StatefulWidget {
  final User user;
  const DashboardScreen({super.key, required this.user});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late Widget _currentContent;
  User? _currentUser;
  String? _selectedPatientId;
  String? _selectedConsultationId;
  String? _selectedPrescriptionId;
  // 🆕 Ajouter une variable pour tracker le contexte actuel
  String _currentContext = 'Dashboard';

  final SessionManager _sessionManager = SessionManager();

  @override
  void initState() {
    super.initState();
    _currentUser = widget.user;
    _currentContent = DashboardContent(
      user: currentUser,
      onNavigate: _handleDashboardNavigation,
    );
  }

  User get currentUser => _currentUser ?? widget.user;

  void _handlePatientAction(String patientId, String action) {
    debugPrint('🎯 Patient Action: $action for patient: $patientId');

    setState(() {
      _selectedPatientId = patientId;
    });

    switch (action) {
      case "view_profile":
        if (!SessionPermissions(_sessionManager).canViewPatients) {
          _showPermissionError('view patient profiles');
          return;
        }
        setState(() {
          _currentContext = 'PatientProfile';
          _currentContent = PatientProfileScreen(
            patientId: patientId,
            onBack: () => _showPatientList(),
            onNewConsultation: SessionPermissions(_sessionManager)
                    .canCreateConsultation
                ? () => _showNewConsultationWithSteps(
                      patientId: patientId,
                      navigationContext: NavigationContext.fromPatientProfile,
                    )
                : () => _showPermissionError('create consultations'),
            onViewConsultations:
                SessionPermissions(_sessionManager).canViewConsultations
                    ? () => _showPatientConsultations(patientId)
                    : () => _showPermissionError('view consultations'),
            onEditPrescription: (prescriptionId) => _showEditPrescriptionForm(
                _selectedConsultationId!, prescriptionId),
          );
        });
        break;

      case "view_consultations":
        if (!SessionPermissions(_sessionManager).canViewConsultations) {
          _showPermissionError('view consultations');
          return;
        }
        _showPatientConsultations(patientId);
        break;

      // ✅ AJOUT: Action EDIT manquante
      case "edit":
        if (!SessionPermissions(_sessionManager).canUpdatePatient) {
          _showPermissionError('edit patients');
          return;
        }
        _showEditPatient(patientId);
        break;

      // ✅ AJOUT: Action DELETE manquante
      case "delete":
        if (!SessionPermissions(_sessionManager).canDeletePatient) {
          _showPermissionError('delete patients');
          return;
        }
        _showDeletePatientConfirmation(patientId);
        break;

      // ✅ AJOUT: Action NEW_CONSULTATION (optionnelle, si vous voulez l'ajouter)
      case "new_consultation":
        if (!SessionPermissions(_sessionManager).canCreateConsultation) {
          _showPermissionError('create consultations');
          return;
        }
        _showNewConsultationWithSteps(
          patientId: patientId,
          navigationContext: NavigationContext.fromPatientList,
        );
        break;

      default:
        debugPrint('❌ Unknown action: $action');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Unknown action: $action'),
            backgroundColor: Colors.orange,
          ),
        );
    }
  }

  void _showPermissionError(String action) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('You do not have permission to $action'),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
        action: SnackBarAction(
          label: 'Dismiss',
          textColor: Colors.white,
          onPressed: () {},
        ),
      ),
    );
  }

  void _showNewConsultationWithSteps({
    String? patientId,
    NavigationContext navigationContext =
        NavigationContext.fromConsultationList,
  }) {
    if (!SessionPermissions(_sessionManager).canCreateConsultation) {
      _showPermissionError('create consultations');
      return;
    }

    VoidCallback getBackFunction() {
      switch (navigationContext) {
        case NavigationContext.fromPatientList:
          return () => _showPatientList();
        case NavigationContext.fromPatientProfile:
          return () => _handlePatientAction(patientId!, "view_profile");
        case NavigationContext.fromConsultationList:
          return () => _showConsultationList();
      }
    }

    setState(() {
      _currentContext = 'NewConsultationSteps';
      _currentContent = AddConsultationWithStepsScreen(
        patientId: patientId,
        onBack: getBackFunction(),
        onCompleted: (consultationId, prescriptionId) {
          _selectedConsultationId = consultationId;
          _selectedPrescriptionId = prescriptionId;
          _showPostConsultationOptions();
        },
      );
    });
  }

  void _showConsultationPrescriptions(String consultationId) {
    if (!SessionPermissions(_sessionManager).canViewPrescriptions) {
      _showPermissionError('view prescriptions');
      return;
    }

    setState(() {
      _selectedConsultationId = consultationId;
      _currentContext = 'ConsultationPrescriptions';
      _currentContent = ConsultationPrescriptionsScreen(
        consultationId: consultationId,
        onBack: () => _showConsultationList(),
        onNewPrescription: () => _showNewPrescriptionForm(consultationId),
      );
    });
  }

  void _showNewPrescriptionForm(String consultationId) {
    if (!SessionPermissions(_sessionManager).canCreatePrescription) {
      _showPermissionError('create prescriptions');
      return;
    }

    setState(() {
      _selectedConsultationId = consultationId;
      _currentContext = 'PrescriptionForm';
      _currentContent = PrescriptionFormScreen(
        consultationId: consultationId,
        onBack: () => _showConsultationPrescriptions(consultationId),
        onSaved: (prescriptionId) {
          _showConsultationPrescriptions(consultationId);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content:
                  Text('✅ Prescription saved and email sent successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        },
      );
    });
  }

  void _showEditPrescriptionForm(String consultationId, String prescriptionId) {
    if (!SessionPermissions(_sessionManager).canUpdatePrescription) {
      _showPermissionError('edit prescriptions');
      return;
    }

    setState(() {
      _currentContext = 'EditPrescription';
      _currentContent = PrescriptionFormScreen(
        consultationId: consultationId,
        prescriptionId: prescriptionId,
        onBack: () => _showConsultationPrescriptions(consultationId),
        onSaved: (savedPrescriptionId) {
          _showConsultationPrescriptions(consultationId);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Prescription updated successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        },
      );
    });
  }

  void _showEditConsultation(String consultationId) {
    if (!SessionPermissions(_sessionManager).canUpdateConsultation) {
      _showPermissionError('edit consultations');
      return;
    }

    setState(() {
      _currentContext = 'EditConsultation';
      _currentContent = EditConsultationScreen(
        consultationId: consultationId,
        onBack: () => _showConsultationList(),
        onSaved: () {
          _showConsultationList();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Consultation updated successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        },
      );
    });
  }

  void _showPatientList() {
    if (!SessionPermissions(_sessionManager).canViewPatients) {
      setState(() {
        _currentContext = 'NoPermission';
        _currentContent = _buildNoPermissionScreen(
          'Patient List',
          'view patients',
          icon: Icons.people_outline,
        );
      });
      return;
    }

    setState(() {
      _currentContext = 'PatientList';
      _currentContent = PatientListScreen(
        onAddPatientPressed: _showAddPatientForm,
        onPatientAction: _handlePatientAction,
      );
    });
  }

  void _showAddPatientForm() {
    if (!(SessionPermissions(_sessionManager).canCreatePatient)) {
      _showPermissionError('create patients');
      return;
    }

    setState(() {
      _currentContext = 'AddPatient';
      _currentContent = AddPatientScreen(
        onBack: _showPatientList,
        onPatientCreated: (patientId, consultationId) {
          _selectedPatientId = patientId;
          _selectedConsultationId = consultationId;
          _showAutoPrescription();
        },
      );
    });
  }

  void _showNewConsultation({
    String? patientId,
    NavigationContext navigationContext =
        NavigationContext.fromConsultationList,
  }) {
    _showNewConsultationWithSteps(
      patientId: patientId,
      navigationContext: navigationContext,
    );
  }

  void _showPatientConsultations(String patientId) {
    if (!SessionPermissions(_sessionManager).canViewConsultations) {
      _showPermissionError('view patient consultations');
      return;
    }

    setState(() {
      _currentContext = 'PatientConsultations';
      _currentContent = PatientConsultationsScreen(
        patientId: patientId,
        onBack: _showPatientList,
        onNewConsultation: () => _showNewConsultationWithSteps(
          patientId: patientId,
          navigationContext: NavigationContext.fromPatientProfile,
        ),
      );
    });
  }

  void _showConsultationList() {
    if (!(SessionPermissions(_sessionManager).canViewConsultations)) {
      setState(() {
        _currentContext = 'NoPermission';
        _currentContent = _buildNoPermissionScreen(
          'Consultation List',
          'view consultations',
          icon: Icons.event_note_outlined,
        );
      });
      return;
    }

    setState(() {
      _currentContext = 'ConsultationList';
      _currentContent = ConsultationListScreen(
        onAddConsultationPressed: () => _showNewConsultationWithSteps(
          navigationContext: NavigationContext.fromConsultationList,
        ),
        onViewPrescriptions: (consultationId) =>
            _showConsultationPrescriptions(consultationId),
        onEditConsultation: (consultationId) =>
            _showEditConsultation(consultationId),
      );
    });
  }

  void _showAppointmentList() {
    if (!SessionPermissions(_sessionManager).canViewAppointments) {
      setState(() {
        _currentContext = 'NoPermission';
        _currentContent = _buildNoPermissionScreen(
          'Appointment List',
          'view appointments',
          icon: Icons.event_available_outlined,
        );
      });
      return;
    }

    setState(() {
      _currentContext = 'AppointmentList';
      _currentContent = AppointmentListScreen(
        onAddAppointmentPressed: _showAddAppointmentForm,
        onCompleteConsultation: _showCompleteConsultationFromAppointment,
      );
    });
  }

  void _showCompleteConsultationFromAppointment(Appointment appointment) {
    if (!SessionPermissions(_sessionManager).canCreateConsultation) {
      _showPermissionError('create consultations');
      return;
    }

    setState(() {
      _currentContext = 'NewConsultationSteps';
      _currentContent = AddConsultationWithStepsScreen(
        patientId: appointment.patientId,
        prefilledAppointment: appointment,
        onBack: () => _showAppointmentList(),
        onCompleted: (consultationId, prescriptionId) async {
          // Marquer le RDV comme complété après que la consultation a été créée
          try {
            final appointmentService = AppointmentService();
            await appointmentService.completeConsultation(appointment.id!);
          } catch (e) {
            debugPrint('Failed to complete appointment: $e');
          }
          
          _selectedConsultationId = consultationId;
          _selectedPrescriptionId = prescriptionId;
          _showPostConsultationOptions();
        },
      );
    });
  }

  void _showAddAppointmentForm() {
    if (!SessionPermissions(_sessionManager).canCreateAppointment) {
      _showPermissionError('create appointments');
      return;
    }

    setState(() {
      _currentContext = 'AddAppointment';
      _currentContent = AddAppointmentScreen(
        onBack: _showAppointmentList,
        onSaved: _showAppointmentList,
      );
    });
  }

  void _showAutoPrescription() {
    if (!SessionPermissions(_sessionManager).canCreatePrescription) {
      _showPermissionError('create prescriptions');
      return;
    }

    if (_selectedPatientId != null && _selectedConsultationId != null) {
      setState(() {
        _currentContext = 'AutoPrescription';
        _currentContent = AutoPrescriptionScreen(
          patientId: _selectedPatientId!,
          consultationId: _selectedConsultationId!,
          onComplete: () => _showPostConsultationOptions(),
          onBack: () => _showConsultationList(),
        );
      });
    }
  }

  void _showPostConsultationOptions() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 28),
            SizedBox(width: 12),
            Text('Consultation & Prescription Complete!'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '✅ Consultation saved successfully\n✅ Prescription created (draft)\n',
              style: TextStyle(fontSize: 14),
            ),
            Divider(),
            SizedBox(height: 8),
            Text('What would you like to do next?'),
            SizedBox(height: 16),
            Text(
              '• View/edit the prescription\n• View patient profile\n• Return to consultations list',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _showConsultationList();
            },
            child: const Text('Consultations List'),
          ),
          if (SessionPermissions(_sessionManager).canViewPatients)
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                if (_selectedPatientId != null) {
                  _handlePatientAction(_selectedPatientId!, "view_profile");
                }
              },
              child: const Text('Patient Profile'),
            ),
          if (SessionPermissions(_sessionManager).canViewPrescriptions)
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                if (_selectedConsultationId != null) {
                  _showConsultationPrescriptions(_selectedConsultationId!);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
              ),
              child: const Text('View Prescription',
                  style: TextStyle(color: Colors.white)),
            ),
        ],
      ),
    );
  }

  void _showEditPatient(String patientId) {
    if (!SessionPermissions(_sessionManager).canUpdatePatient) {
      _showPermissionError('edit patients');
      return;
    }

    setState(() {
      _currentContext = 'EditPatient';
      _currentContent = AddPatientScreen(
        patientId: patientId, // ✅ IMPORTANT: Passer l'ID pour le mode édition
        onBack: () => _showPatientList(),
        onPatientCreated: (_, __) {
          // Rafraîchir la liste après modification
          _showPatientList();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Patient updated successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        },
      );
    });
  }

  void _showDeletePatientConfirmation(String patientId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.red, size: 24),
            SizedBox(width: 8),
            Text('Delete Patient'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to delete this patient?',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text('This action will:'),
            Text('• Delete all patient data'),
            Text('• Delete all medical history'),
            Text('• Delete all consultations'),
            Text('• Delete all prescriptions'),
            SizedBox(height: 8),
            Text(
              'This action cannot be undone!',
              style: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _deletePatient(patientId);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

// ✅ NOUVELLE MÉTHODE: Supprimer réellement le patient
  Future<void> _deletePatient(String patientId) async {
    try {
      // Afficher un loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // Appeler le service pour supprimer
      final patientService = PatientService();
      final success = await patientService.deletePatient(patientId);

      // Fermer le loading
      Navigator.pop(context);

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Patient deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );

        // Rafraîchir la liste
        _showPatientList();
      } else {
        throw Exception('Delete operation failed');
      }
    } catch (e) {
      // Fermer le loading si ouvert
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Error deleting patient: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showMedicationList() {
    if (!SessionPermissions(_sessionManager).canViewMedications) {
      setState(() {
        _currentContext = 'NoPermission';
        _currentContent = _buildNoPermissionScreen(
          'Medication List',
          'view medications',
          icon: Icons.medication_outlined,
        );
      });
      return;
    }

    setState(() {
      _currentContext = 'MedicationList';
      _currentContent = MedicationListScreen(
        onAddMedicationPressed: _showAddMedicationForm,
      );
    });
  }

  void _showAddMedicationForm() {
    if (!(SessionPermissions(_sessionManager).canCreateMedication)) {
      _showPermissionError('create medications');
      return;
    }

    setState(() {
      _currentContext = 'AddMedication';
      _currentContent = MedicationForm(
        onBack: _showMedicationList,
        onCancel: _showMedicationList,
      );
    });
  }

  void _showUsersList() {
    if (!_sessionManager.canViewUsers) {
      setState(() {
        _currentContext = 'NoPermission';
        _currentContent = _buildNoPermissionScreen(
          'Users List',
          'view users',
          icon: Icons.people_outline,
        );
      });
      return;
    }

    setState(() {
      _currentContext = 'UsersList';
      _currentContent = UsersListScreen(
        onAddUserPressed: _showAddUserForm,
      );
    });
  }

  void _showAddUserForm() {
    if (!_sessionManager.canCreateUser) {
      _showPermissionError('create users');
      return;
    }

    setState(() {
      _currentContext = 'AddUser';
      _currentContent = AddUserForm(
        onBack: _showUsersList,
        onSave: (newUser) => _showUsersList(),
      );
    });
  }

  Future<void> _handleAccountUpdate(Map<String, dynamic> updateData) async {
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      final success = await userProvider.updateUser(
        userId: currentUser.id,
        firstname: updateData['firstname'],
        lastname: updateData['lastname'],
        email: updateData['email'],
        specialite: updateData['specialite'],
      );

      if (success && mounted) {
        final updatedUser = currentUser.copyWith(
          firstname: updateData['firstname'],
          lastname: updateData['lastname'],
          email: updateData['email'],
          specialite: updateData['specialite'],
        );

        setState(() => _currentUser = updatedUser);
        authProvider.updateUser(updatedUser);

        _currentContent = AccountInformationScreen(
          key: ValueKey('account_${updatedUser.id}_${DateTime.now()}'),
          user: updatedUser,
          onUpdate: _handleAccountUpdate,
        );

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully'),
            duration: Duration(seconds: 2),
            backgroundColor: Color(0xFF05A44F),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Update failed: ${e.toString()}')),
        );
      }
    }
  }

  // 🆕 MÉTHODE AMÉLIORÉE POUR GÉRER LES BREADCRUMBS
  List<String> _getBreadcrumb() {
    switch (_currentContext) {
      // Patient-related pages
      case 'PatientList':
        return ['Dashboard', 'Patient'];
      case 'AddPatient':
        return ['Dashboard', 'Patient', 'Add'];
      case 'EditPatient':
        return ['Dashboard', 'Patient', 'Edit'];
      case 'PatientProfile':
        return ['Dashboard', 'Patient', 'Profile'];
      case 'PatientConsultations':
        return ['Dashboard', 'Patient', 'Consultations'];

      // Consultation-related pages
      case 'ConsultationList':
        return ['Dashboard', 'Consultation'];
      case 'NewConsultationSteps':
        return ['Dashboard', 'Consultation', 'New (Steps)'];
      case 'EditConsultation':
        return ['Dashboard', 'Consultation', 'Edit'];
      case 'AutoPrescription':
        return ['Dashboard', 'Consultation', 'Auto Prescription'];

      // Appointment-related pages
      case 'AppointmentList':
        return ['Dashboard', 'Appointments'];
      case 'AddAppointment':
        return ['Dashboard', 'Appointments', 'Add'];

      // Prescription-related pages
      case 'ConsultationPrescriptions':
        return ['Dashboard', 'Consultation', 'Prescriptions'];
      case 'PrescriptionForm':
        return ['Dashboard', 'Consultation', 'Prescriptions', 'Form'];
      case 'EditPrescription':
        return ['Dashboard', 'Consultation', 'Prescriptions', 'Edit'];

      // Medication-related pages
      case 'MedicationList':
        return ['Dashboard', 'Medication'];
      case 'AddMedication':
        return ['Dashboard', 'Medication', 'Add'];

      // User management pages
      case 'UsersList':
        return ['Dashboard', 'Users'];
      case 'AddUser':
        return ['Dashboard', 'Users', 'Add'];

      // Account and settings pages
      case 'AccountInformation':
        return ['Dashboard', 'Account Information'];
      case 'Roles':
        return ['Dashboard', 'Roles'];
      case 'SecurityPrivacy':
        return ['Dashboard', 'Security & Privacy'];

      // Default case
      case 'Dashboard':
      default:
        return ['Dashboard'];
    }
  }

  Widget _buildBreadcrumb() {
    final breadcrumb = _getBreadcrumb();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
      ),
      child: Row(
        children: [
          for (int i = 0; i < breadcrumb.length; i++) ...[
            if (i > 0) ...[
              const SizedBox(width: 8),
              Icon(Icons.chevron_right, size: 16, color: Colors.grey[400]),
              const SizedBox(width: 8),
            ],
            Text(
              breadcrumb[i],
              style: TextStyle(
                fontSize: 12,
                color: i == breadcrumb.length - 1
                    ? AppColors.primary
                    : Colors.grey[600],
                fontWeight: i == breadcrumb.length - 1
                    ? FontWeight.w600
                    : FontWeight.normal,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildNoPermissionScreen(String feature, String permission,
      {IconData? icon}) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon ?? Icons.security, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 20),
            Text(
              'Access Denied',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'You do not have permission to $permission.',
              style: TextStyle(fontSize: 16, color: Colors.grey[500]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _currentContext = 'Dashboard';
                  _currentContent = DashboardContent(
                    user: currentUser,
                    onNavigate: _handleDashboardNavigation,
                  );
                });
              },
              icon: const Icon(Icons.dashboard),
              label: const Text('Back to Dashboard'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onMenuItemSelected(String menu) {
    setState(() {
      switch (menu) {
        case 'Dashboard':
          _currentContext = 'Dashboard';
          _currentContent = DashboardContent(
            user: currentUser,
            onNavigate: _handleDashboardNavigation,
          );
          break;
        case 'Patient':
          _showPatientList();
          break;
        case 'Consultation':
          _showConsultationList();
          break;
        case 'Appointment Cycle':
          _showAppointmentList();
          break;
        case 'Medications':
          _showMedicationList();
          break;
        case 'Account Information':
          _currentContext = 'AccountInformation';
          _currentContent = AccountInformationScreen(
            key: ValueKey('account_info_${currentUser.id}'),
            user: currentUser,
            onUpdate: _handleAccountUpdate,
          );
          break;
        case 'Users':
          _showUsersList();
          break;
        case 'Roles':
          if (!_sessionManager.canViewRoles) {
            _currentContext = 'NoPermission';
            _currentContent = _buildNoPermissionScreen(
              'Roles',
              'view roles',
              icon: Icons.admin_panel_settings,
            );
          } else {
            _currentContext = 'Roles';
            _currentContent = const RolesScreen();
          }
          break;
        case 'Security & Privacy':
          _currentContext = 'SecurityPrivacy';
          _currentContent = const SecurityPrivacyScreen();
          break;
        default:
          _currentContext = 'ComingSoon';
          _currentContent = const Center(child: Text('Coming soon...'));
      }
    });
  }

  void _handleDashboardNavigation(String destination) {
    switch (destination.toLowerCase()) {
      case 'patient':
        _showPatientList();
        break;
      case 'consultation':
        _showConsultationList();
        break;
      case 'medications':
        _showMedicationList();
        break;
      default:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Opening $destination...'),
            backgroundColor: AppColors.primary,
            duration: const Duration(seconds: 2),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Provider<User>.value(
      value: currentUser,
      child: Scaffold(
        body: Row(
          children: [
            SidebarMenu(onMenuItemSelected: _onMenuItemSelected),
            Expanded(
              child: Column(
                children: [
                  const TopAppBar(),
                  _buildBreadcrumb(),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: _currentContent,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}
