// lib/features/consultation/screens/add_consultation_with_steps_screen.dart - FINAL FIX
import 'package:flutter/material.dart';
import 'package:frontend/core/constants/colors.dart';
import 'package:frontend/core/constants/primary_button.dart';
import 'package:frontend/core/constants/secondary_button.dart';
import 'package:frontend/features/consultation/models/consultation.dart';
import 'package:frontend/features/consultation/services/consultation_service.dart';
import 'package:frontend/features/prescription/services/prescription_service.dart';
import 'package:frontend/features/patient/services/patient_service.dart';
import 'package:frontend/features/patient/models/patient.dart';
import 'package:frontend/features/consultation/widgets/consultation_form_step.dart';
import 'package:frontend/features/patient/widgets/prescription_step.dart';
import 'package:frontend/features/appointment/models/appointment.dart';

class AddConsultationWithStepsScreen extends StatefulWidget {
  final String? patientId;
  final Appointment? prefilledAppointment;
  final VoidCallback onBack;
  final Function(String consultationId, String prescriptionId)? onCompleted;

  const AddConsultationWithStepsScreen({
    super.key,
    this.patientId,
    this.prefilledAppointment,
    required this.onBack,
    this.onCompleted,
  });

  @override
  State<AddConsultationWithStepsScreen> createState() =>
      _AddConsultationWithStepsScreenState();
}

class _AddConsultationWithStepsScreenState
    extends State<AddConsultationWithStepsScreen> {
  int _currentStep = 1;
  bool _isLoading = false;

  final ConsultationService _consultationService = ConsultationService();
  final PrescriptionService _prescriptionService = PrescriptionService();
  final PatientService _patientService = PatientService();

  // Data holders
  Patient? _selectedPatient;
  Consultation? _consultationData;
  Map<String, dynamic>? _prescriptionData;

  // IDs for the complete flow
  String? _savedConsultationId;
  String? _savedPrescriptionId;

  @override
  void initState() {
    super.initState();
    if (widget.patientId != null) {
      _loadPatient();
    }
  }

  Future<void> _loadPatient() async {
    if (widget.patientId == null) return;

    setState(() => _isLoading = true);
    try {
      final patient = await _patientService.getPatientById(widget.patientId!);
      setState(() {
        _selectedPatient = patient;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnackBar('Error loading patient: $e', Colors.red);
    }
  }

  void _onStepTapped(int step) {
    // Prevent navigation to step 2 if consultation not saved
    if (step == 2 && _savedConsultationId == null) {
      _showSnackBar('Please complete the consultation first', Colors.orange);
      return;
    }
    setState(() => _currentStep = step);
  }

  Future<void> _saveConsultationAndProceed() async {
    setState(() => _isLoading = true);
    try {
      print('Saving consultation: ${_consultationData!.toJson()}');

      final savedConsultation =
          await _consultationService.createConsultation(_consultationData!);
      _savedConsultationId = savedConsultation.id!;

      print('Consultation saved with ID: $_savedConsultationId');

      // CRÉATION D'UNE PRESCRIPTION VIDE AVEC STATUS ACCEPTÉ
      final emptyPrescriptionData = {
        'consultation': _savedConsultationId,
        'prescriptionInfo': {
          'type': 'Regular',
          'status': 'Pending',
          'date': DateTime.now().toIso8601String(),
          'time': _formatCurrentTime(),
          'validityDays': 30,
          'notes': 'Prescription to be completed',
        },
        'medications': [
          {
            'customMedication': {
              'name': 'To be specified',
              'description': 'Medication to be added later',
            },
            'dosage': {
              'strength': 'To be specified',
              'frequency': 'To be specified',
              'duration': 'To be specified',
              'route': 'Oral',
              'instructions': 'To be completed by doctor',
            },
            'quantity': {
              'prescribed': 0,
              'dispensed': 0,
            },
            'refills': {
              'allowed': 0,
              'remaining': 0,
            },
          }
        ],
      };

      try {
        final savedPrescription = await _prescriptionService
            .createPrescription(emptyPrescriptionData);
        _savedPrescriptionId = savedPrescription.id!;
        print('Empty prescription created with ID: $_savedPrescriptionId');
      } catch (prescriptionError) {
        print(
            'Warning: Could not create empty prescription: $prescriptionError');
        _savedPrescriptionId = 'manual';
      }

      setState(() {
        _isLoading = false;
        _currentStep = 2;
      });

      _showSnackBar(
          'Consultation created! Complete prescription...', Colors.green);
    } catch (e) {
      setState(() => _isLoading = false);
      print('Error saving consultation: $e');
      _showSnackBar('Error saving consultation: $e', Colors.red);
    }
  }

  Future<void> _savePrescriptionAndComplete() async {
    setState(() => _isLoading = true);
    try {
      if (_prescriptionData != null) {
        _prescriptionData!['consultation'] = _savedConsultationId;
        _prescriptionData!['prescriptionInfo']['status'] = 'Active';

        print('Saving/updating prescription: $_prescriptionData');

        if (_savedPrescriptionId != null && _savedPrescriptionId != 'manual') {
          await _prescriptionService.updatePrescription(
              _savedPrescriptionId!, _prescriptionData!);
          print('Prescription updated successfully');
        } else {
          final newPrescription =
              await _prescriptionService.createPrescription(_prescriptionData!);
          _savedPrescriptionId = newPrescription.id!;
          print('New prescription created with ID: $_savedPrescriptionId');
        }

        _showSnackBar('Consultation and prescription completed successfully!',
            Colors.green);
      } else {
        _showSnackBar(
            'Consultation created with placeholder prescription', Colors.blue);
      }

      setState(() => _isLoading = false);
      _completeFlow();
    } catch (e) {
      setState(() => _isLoading = false);
      print('Error saving prescription: $e');
      _showSnackBar('Error saving prescription: $e', Colors.red);
    }
  }

  void _completeFlow() {
    if (_savedConsultationId != null) {
      final prescriptionId =
          _savedPrescriptionId == 'manual' ? 'pending' : _savedPrescriptionId;
      widget.onCompleted
          ?.call(_savedConsultationId!, prescriptionId ?? 'pending');
    } else {
      widget.onBack();
    }
  }

  String _formatCurrentTime() {
    final now = DateTime.now();
    return '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color),
    );
  }

  Widget _buildStep(int stepNumber, String title, {bool isOptional = false}) {
    bool isActive = _currentStep == stepNumber;
    bool isCompleted = stepNumber < _currentStep;
    bool isDisabled = stepNumber == 2 && _savedConsultationId == null;

    return GestureDetector(
      onTap: isDisabled ? null : () => _onStepTapped(stepNumber),
      child: Column(
        mainAxisSize: MainAxisSize.min, // 🔧 CRUCIAL: Taille minimale
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1), // 🔧 Shadow plus légère
                  blurRadius: 2, // 🔧 Blur réduit
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: CircleAvatar(
              radius: 20, // 🔧 Réduit de 24 à 20
              backgroundColor: isDisabled
                  ? Colors.grey.shade300
                  : isCompleted
                      ? Colors.green
                      : isActive
                          ? AppColors.primary
                          : Colors.white,
              child: isCompleted
                  ? const Icon(Icons.check,
                      color: Colors.white, size: 16) // 🔧 Taille réduite
                  : isDisabled
                      ? const Icon(Icons.lock, color: Colors.grey, size: 16)
                      : Text(
                          '$stepNumber',
                          style: TextStyle(
                            color: isActive ? Colors.white : Colors.black,
                            fontWeight: FontWeight.bold,
                            fontSize: 14, // 🔧 Taille réduite
                          ),
                        ),
            ),
          ),
          const SizedBox(height: 4), // 🔧 Espacement réduit de 8 à 4
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 10, // 🔧 Taille réduite de 12 à 10
              fontWeight: FontWeight.w600, // 🔧 Weight réduit
              color: isDisabled
                  ? Colors.grey
                  : isActive
                      ? Colors.black
                      : Colors.grey,
            ),
            maxLines: 2, // 🔧 Maximum 2 lignes
            overflow: TextOverflow.ellipsis,
          ),
          if (isOptional)
            Text(
              isDisabled ? '(Locked)' : '(Optional)',
              style: TextStyle(
                fontSize: 8, // 🔧 Taille réduite
                color: isDisabled ? Colors.red : Colors.grey,
              ),
            ),
        ],
      ),
    );
  }

  Widget _getCurrentStepContent() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Processing...'),
          ],
        ),
      );
    }

    switch (_currentStep) {
      case 1:
        return ConsultationFormStep(
          selectedPatient: _selectedPatient,
          prefilledAppointment: widget.prefilledAppointment,
          onNext: (consultationData, patient) {
            setState(() {
              _consultationData = consultationData;
              _selectedPatient = patient;
            });
            _saveConsultationAndProceed();
          },
          onBack: widget.onBack,
          allowPatientSelection: widget.patientId == null && widget.prefilledAppointment == null,
        );
      case 2:
        if (_savedConsultationId == null) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, color: Colors.red, size: 64),
                SizedBox(height: 16),
                Text('Missing consultation data',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                SizedBox(height: 8),
                Text('Please complete the consultation step first',
                    style: TextStyle(color: Colors.grey)),
              ],
            ),
          );
        }

        return PrescriptionStep(
          onNext: (prescriptionData) {
            setState(() => _prescriptionData = prescriptionData);
            _savePrescriptionAndComplete();
          },
          onBack: () => setState(() => _currentStep = 1),
          onSkip: () => _completeFlow(),
        );
      default:
        return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // Header with back button
          Container(
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                ElevatedButton.icon(
                  onPressed: widget.onBack,
                  icon: const Icon(Icons.arrow_back),
                  label: const Text("Back to list"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[200],
                    foregroundColor: Colors.black,
                    elevation: 0,
                  ),
                ),
                const Spacer(),
                Text(
                  widget.patientId != null
                      ? "New Consultation for Patient"
                      : "New Consultation",
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),

          // 🔧 STEPPER NAVIGATION CORRIGÉ - SANS CONTRAINTE DE HAUTEUR FIXE
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 8), // 🔧 Padding réduit
            child: Column(
              mainAxisSize: MainAxisSize.min, // 🔧 Taille minimale
              children: [
                // Progress line et steps dans un layout flexible
                Stack(
                  alignment: Alignment.center,
                  children: [
                    // Progress line
                    Container(
                      height: 2, // 🔧 Hauteur réduite
                      margin: const EdgeInsets.symmetric(
                          horizontal: 50), // 🔧 Margin ajusté
                      child: LinearProgressIndicator(
                        value: _currentStep / 2,
                        backgroundColor: Colors.grey.withOpacity(0.3),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                            AppColors.primary),
                      ),
                    ),
                    // Steps
                    Row(
                      mainAxisAlignment: MainAxisAlignment
                          .spaceEvenly, // 🔧 SpaceEvenly au lieu de spaceAround
                      children: [
                        _buildStep(1, "Consultation\nDetails"),
                        _buildStep(2, "Prescription", isOptional: true),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Content area
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              width: double.infinity,
              color: Colors.white,
              child: _getCurrentStepContent(),
            ),
          ),
        ],
      ),
    );
  }
}
