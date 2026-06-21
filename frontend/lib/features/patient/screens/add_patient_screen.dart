// lib/features/patient/screens/add_patient_screen.dart - VERSION AVEC PERMISSIONS
import 'package:flutter/material.dart';
import 'package:frontend/core/services/session_manager.dart';
import 'package:frontend/shared/widgets/permission_widget.dart';
import 'package:frontend/features/patient/widgets/consultation_step.dart';
import 'package:frontend/features/patient/widgets/health_assessment_step.dart';
import 'package:frontend/features/patient/widgets/patient_info_step.dart';
import 'package:frontend/features/patient/widgets/vitals_step.dart';
import 'package:frontend/features/patient/widgets/prescription_step.dart';
import 'package:frontend/features/patient/models/patient.dart';
import 'package:frontend/features/patient/models/medical_history.dart';
import 'package:frontend/features/patient/services/patient_service.dart';
import 'package:frontend/features/consultation/services/consultation_service.dart';
import 'package:frontend/features/consultation/models/consultation.dart';
import 'package:frontend/features/prescription/services/prescription_service.dart';

class AddPatientScreen extends StatefulWidget {
  final VoidCallback onBack;
  final String? patientId;
  final Function(String patientId, String consultationId)? onPatientCreated;

  const AddPatientScreen({
    super.key,
    required this.onBack,
    this.patientId,
    this.onPatientCreated,
  });

  @override
  State<AddPatientScreen> createState() => _AddPatientScreenState();
}

class _AddPatientScreenState extends State<AddPatientScreen> {
  int _currentStep = 1;
  bool _isLoading = false;

  final PatientService _patientService = PatientService();
  final ConsultationService _consultationService = ConsultationService();
  final PrescriptionService _prescriptionService = PrescriptionService();
  final SessionManager _sessionManager = SessionManager();

  // Data holders for each step
  Patient? _patientData;
  MedicalHistory? _medicalHistoryData;
  Consultation? _consultationData;
  Map<String, dynamic>? _prescriptionData;

  // IDs pour le flow complet
  String? _savedPatientId;
  String? _savedConsultationId;

  bool get _isEditMode => widget.patientId != null;

  // 🔒 PERMISSIONS CALCULÉES
  bool get _canViewConsultations =>
      SessionPermissions(_sessionManager).canViewConsultations;
  bool get _canCreateConsultation =>
      SessionPermissions(_sessionManager).canCreateConsultation;
  bool get _canViewPrescriptions =>
      SessionPermissions(_sessionManager).canViewPrescriptions;
  bool get _canCreatePrescription =>
      SessionPermissions(_sessionManager).canCreatePrescription;

  // Étapes disponibles selon les permissions
  bool get _hasConsultationStep =>
      _canViewConsultations && _canCreateConsultation;
  bool get _hasPrescriptionStep =>
      _canViewPrescriptions && _canCreatePrescription;

  // Nombre total d'étapes selon les permissions
  int get _totalSteps {
    if (_isEditMode) return 3; // Patient Info, Vitals, Health Assessment

    int steps =
        3; // Patient Info, Vitals, Health Assessment (toujours présentes)
    if (_hasConsultationStep) steps++;
    if (_hasPrescriptionStep) steps++;
    return steps;
  }

  // Mapping des étapes selon les permissions
  int get _consultationStepNumber {
    return 4; // Toujours après Health Assessment
  }

  int get _prescriptionStepNumber {
    if (_hasConsultationStep) return 5;
    return 4; // Si pas de consultation step, prescription vient après health assessment
  }

  @override
  void initState() {
    super.initState();
    if (_isEditMode) {
      _loadPatientForEdit();
    }
  }

  Future<void> _loadPatientForEdit() async {
    setState(() => _isLoading = true);
    try {
      final patient = await _patientService.getPatientById(widget.patientId!);
      final medicalHistory =
          await _patientService.getMedicalHistoryByPatientId(widget.patientId!);

      setState(() {
        _patientData = patient;
        if (medicalHistory.isNotEmpty) {
          _medicalHistoryData = medicalHistory.first;
        }
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading patient: $e')),
      );
    }
  }

  void _onStepTapped(int step) {
    // Vérifier les permissions avant de permettre la navigation
    if (step == _consultationStepNumber && !_hasConsultationStep) {
      _showPermissionError('consultation management');
      return;
    }

    if (step == _prescriptionStepNumber && !_hasPrescriptionStep) {
      _showPermissionError('prescription management');
      return;
    }

    // Empêcher la navigation vers l'étape prescription si les IDs ne sont pas disponibles
    if (step == _prescriptionStepNumber &&
        (_savedPatientId == null ||
            (_hasConsultationStep && _savedConsultationId == null))) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please complete the previous steps first'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _currentStep = step;
    });
  }

  void _showPermissionError(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('You do not have permission to access $feature'),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // Sauvegarde Patient, Medical History et Consultation
  Future<void> _savePatientConsultationAndProceed() async {
    setState(() => _isLoading = true);
    try {
      debugPrint('Starting patient and consultation save process...');

      // 1. Save/Update Patient
      Patient savedPatient;
      if (_isEditMode) {
        savedPatient = await _patientService.updatePatient(
            widget.patientId!, _patientData!);
      } else {
        savedPatient = await _patientService.createPatient(_patientData!);
      }

      debugPrint('Patient saved with ID: ${savedPatient.id}');
      _savedPatientId = savedPatient.id!;

      // 2. Save Medical History
      if (_medicalHistoryData != null) {
        if (_isEditMode && _medicalHistoryData!.id != null) {
          // Update existing medical history
        } else {
          // Create new medical history
          _medicalHistoryData =
              _medicalHistoryData!.copyWith(patientId: savedPatient.id!);
          await _patientService.addMedicalHistory(
              savedPatient.id!, _medicalHistoryData!);
        }
      }

      // 3. Create Consultation (seulement si permissions et pas en mode edit)
      if (!_isEditMode && _consultationData != null && _hasConsultationStep) {
        _consultationData =
            _consultationData!.copyWith(patientId: savedPatient.id!);

        debugPrint(
            'About to create consultation: ${_consultationData!.toJson()}');

        final savedConsultation =
            await _consultationService.createConsultation(_consultationData!);

        debugPrint('Consultation saved with ID: ${savedConsultation.id}');
        _savedConsultationId = savedConsultation.id!;

        // Navigation vers l'étape suivante
        if (_hasPrescriptionStep) {
          setState(() {
            _isLoading = false;
            _currentStep = _prescriptionStepNumber;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  'Patient and consultation created! Complete prescription...'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        } else {
          // Pas de step prescription, terminer ici
          _completeFlow();
        }
      } else {
        setState(() => _isLoading = false);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEditMode
                ? 'Patient updated successfully!'
                : 'Patient created successfully!'),
            backgroundColor: Colors.green,
          ),
        );

        widget.onBack();
      }
    } catch (e) {
      setState(() => _isLoading = false);
      debugPrint('Error saving patient and consultation: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving patient: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Sauvegarde finale avec prescription
  Future<void> _savePrescriptionAndComplete() async {
    setState(() => _isLoading = true);
    try {
      if (_prescriptionData != null && _savedConsultationId != null) {
        // Ajouter l'ID de consultation à la prescription
        _prescriptionData!['consultation'] = _savedConsultationId;

        debugPrint('Saving prescription: $_prescriptionData');

        await _prescriptionService.createPrescription(_prescriptionData!);

        setState(() => _isLoading = false);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Patient, consultation and prescription created successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        setState(() => _isLoading = false);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
                Text('Patient and consultation created! Prescription skipped.'),
            backgroundColor: Colors.blue,
          ),
        );
      }

      _completeFlow();
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving prescription: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Méthode finale pour compléter tout le flow
  void _completeFlow() {
    if (_savedPatientId != null && _savedConsultationId != null) {
      widget.onPatientCreated?.call(_savedPatientId!, _savedConsultationId!);
    } else {
      widget.onBack();
    }
  }

  Widget _buildStep(int stepNumber, String title,
      {bool isOptional = false, bool isLocked = false}) {
    bool isActive = _currentStep == stepNumber;
    bool isCompleted = stepNumber < _currentStep;
    bool isDisabled = isLocked ||
        (stepNumber == _prescriptionStepNumber &&
            (_savedPatientId == null ||
                (_hasConsultationStep && _savedConsultationId == null)));

    return GestureDetector(
      onTap: isDisabled ? null : () => _onStepTapped(stepNumber),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: CircleAvatar(
              radius: 18,
              backgroundColor: isDisabled
                  ? Colors.grey.shade300
                  : isCompleted
                      ? Colors.green
                      : isActive
                          ? const Color(0xFF4C9FD7)
                          : Colors.white,
              child: isCompleted
                  ? const Icon(Icons.check, color: Colors.white, size: 16)
                  : isDisabled
                      ? const Icon(Icons.lock, color: Colors.grey, size: 16)
                      : Text(
                          '$stepNumber',
                          style: TextStyle(
                            color: isActive ? Colors.white : Colors.black,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: isDisabled
                  ? Colors.grey
                  : isActive
                      ? Colors.black
                      : Colors.grey,
            ),
          ),
          if (isOptional)
            Text(
              isDisabled ? '(No Access)' : '(Optional)',
              style: TextStyle(
                fontSize: 8,
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
        return PatientInfoStep(
          initialData: _patientData,
          onNext: (patientData) {
            setState(() {
              _patientData = patientData;
              _currentStep = 2;
            });
          },
        );
      case 2:
        return VitalsStep(
          initialData: _medicalHistoryData,
          onNext: (vitalsData) {
            setState(() {
              _medicalHistoryData = _medicalHistoryData?.copyWith(
                    bloodGlucoseLevel: vitalsData['bloodGlucoseLevel'],
                    heartRate: vitalsData['heartRate'],
                    oxygenSaturation: vitalsData['oxygenSaturation'],
                    bloodPressure: vitalsData['bloodPressure'],
                    respiratoryRate: vitalsData['respiratoryRate'],
                    bodyTemperature: vitalsData['bodyTemperature'],
                    weight: vitalsData['weight'],
                    height: vitalsData['height'],
                  ) ??
                  MedicalHistory(
                    patientId: _patientData?.id ?? '',
                    bloodGlucoseLevel: vitalsData['bloodGlucoseLevel'],
                    heartRate: vitalsData['heartRate'],
                    oxygenSaturation: vitalsData['oxygenSaturation'],
                    bloodPressure: vitalsData['bloodPressure'],
                    respiratoryRate: vitalsData['respiratoryRate'],
                    bodyTemperature: vitalsData['bodyTemperature'],
                    weight: vitalsData['weight'],
                    height: vitalsData['height'],
                  );
              _currentStep = 3;
            });
          },
          onBack: () => setState(() => _currentStep = 1),
        );
      case 3:
        return HealthAssessmentStep(
          initialData: _medicalHistoryData,
          onNext: (healthData) {
            setState(() {
              _medicalHistoryData = _medicalHistoryData?.copyWith(
                    chronicDiseases: healthData['chronicDiseases'],
                    allergies: healthData['allergies'],
                    smokingStatus: healthData['smokingStatus'],
                    alcoholConsumption: healthData['alcoholConsumption'],
                    currentMedications: healthData['currentMedications'],
                  ) ??
                  MedicalHistory(
                    patientId: _patientData?.id ?? '',
                    chronicDiseases: healthData['chronicDiseases'],
                    allergies: healthData['allergies'],
                    smokingStatus: healthData['smokingStatus'],
                    alcoholConsumption: healthData['alcoholConsumption'],
                    currentMedications: healthData['currentMedications'],
                  );

              if (_isEditMode) {
                _savePatientConsultationAndProceed();
              } else if (_hasConsultationStep) {
                _currentStep = _consultationStepNumber;
              } else if (_hasPrescriptionStep) {
                // Sauvegarder patient d'abord, puis aller à prescription
                _savePatientConsultationAndProceed();
              } else {
                // Aucune étape supplémentaire, sauvegarder et terminer
                _savePatientConsultationAndProceed();
              }
            });
          },
          onBack: () => setState(() => _currentStep = 2),
        );
      case 4:
        if (_isEditMode) {
          return const Center(child: Text('Editing complete'));
        }

        // Étape 4 peut être consultation ou prescription selon les permissions
        if (_currentStep == _consultationStepNumber && _hasConsultationStep) {
          return PermissionWidget(
            permissions: ['view_consultation', 'create_consultation'],
            requireAll: true,
            child: ConsultationStep(
              onNext: (consultationData) {
                setState(() {
                  DateTime consultationDate;
                  if (consultationData['date'] is String) {
                    consultationDate = DateTime.parse(consultationData['date']);
                  } else if (consultationData['date'] is DateTime) {
                    consultationDate = consultationData['date'];
                  } else {
                    throw Exception(
                        'Invalid date format: ${consultationData['date']}');
                  }

                  _consultationData = Consultation(
                    patientId: _patientData?.id ?? '',
                    date: consultationDate,
                    time: consultationData['time'],
                    type: consultationData['type'],
                    status: consultationData['status'],
                    symptoms:
                        List<String>.from(consultationData['symptoms'] ?? []),
                    diagnosis:
                        List<String>.from(consultationData['diagnosis'] ?? []),
                    prescribedAnalyses: List<String>.from(
                        consultationData['prescribedAnalyses'] ?? []),
                    notes: consultationData['notes'],
                    duration: consultationData['duration'],
                    isEmergency: consultationData['isEmergency'] ?? false,
                  );
                });
                _savePatientConsultationAndProceed();
              },
              onBack: () => setState(() => _currentStep = 3),
            ),
            fallback:
                _buildNoPermissionStep('Consultation', 'manage consultations'),
          );
        } else if (_currentStep == _prescriptionStepNumber &&
            _hasPrescriptionStep) {
          return _buildPrescriptionStep();
        }

        return const Center(child: Text('Invalid step configuration'));

      case 5:
        if (_hasPrescriptionStep && _currentStep == _prescriptionStepNumber) {
          return _buildPrescriptionStep();
        }
        return const Center(child: Text('Invalid step'));

      default:
        return const SizedBox.shrink();
    }
  }

// Modification dans add_patient_screen.dart - Méthode _buildPrescriptionStep() mise à jour

  Widget _buildPrescriptionStep() {
    if (_savedPatientId == null ||
        (_hasConsultationStep && _savedConsultationId == null)) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              color: Colors.red,
              size: 64,
            ),
            const SizedBox(height: 16),
            const Text(
              'Missing required data',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Patient ID: ${_savedPatientId ?? "Missing"}',
              style: const TextStyle(color: Colors.grey),
            ),
            if (_hasConsultationStep)
              Text(
                'Consultation ID: ${_savedConsultationId ?? "Missing"}',
                style: const TextStyle(color: Colors.grey),
              ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => setState(() => _currentStep =
                  _hasConsultationStep ? _consultationStepNumber : 3),
              child: const Text('Go Back'),
            ),
          ],
        ),
      );
    }

    return PermissionWidget(
      permissions: ['view_prescription', 'create_prescription'],
      requireAll: true,
      fallback: _buildNoPermissionStep('Prescription', 'manage prescriptions'),
      child: PrescriptionStep(
        // ✅ NOUVEAU: Passer l'ID de consultation pour les suggestions IA
        consultationId: _savedConsultationId,
        onNext: (prescriptionData) {
          setState(() {
            _prescriptionData = prescriptionData;
          });
          _savePrescriptionAndComplete();
        },
        onBack: () => setState(() =>
            _currentStep = _hasConsultationStep ? _consultationStepNumber : 3),
        onSkip: () => _completeFlow(),
      ),
    );
  }

  Widget _buildNoPermissionStep(String stepName, String permission) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.security,
            color: Colors.grey,
            size: 64,
          ),
          const SizedBox(height: 16),
          Text(
            'No Access to $stepName',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'You do not have permission to $permission.',
            style: const TextStyle(color: Colors.grey),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => setState(() => _currentStep = 3),
            child: const Text('Go Back'),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildStepsIndicator() {
    List<Widget> steps = [
      _buildStep(1, "Patient\nInfo"),
      _buildStep(2, "Vitals"),
      _buildStep(3, "Health\nAssessment"),
    ];

    if (!_isEditMode) {
      if (_hasConsultationStep) {
        steps.add(_buildStep(_consultationStepNumber, "Consultation",
            isLocked: !_hasConsultationStep));
      }

      if (_hasPrescriptionStep) {
        steps.add(_buildStep(_prescriptionStepNumber, "Prescription",
            isOptional: true, isLocked: !_hasPrescriptionStep));
      }
    }

    return steps;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Back button
        Container(
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.all(4),
          child: ElevatedButton.icon(
            onPressed: widget.onBack,
            icon: const Icon(Icons.arrow_back),
            label: const Text("Back to list"),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color.fromARGB(137, 238, 238, 238),
              foregroundColor: Colors.black,
              elevation: 0,
            ),
          ),
        ),

        // Stepper navigation
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  _isEditMode ? "Edit Patient" : "Add Patient",
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 70,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Progress line
                    Positioned.fill(
                      top: -20,
                      child: Center(
                        child: Container(
                          height: 4,
                          margin: const EdgeInsets.symmetric(horizontal: 40),
                          child: LinearProgressIndicator(
                            value: _currentStep / _totalSteps,
                            backgroundColor:
                                const Color.fromARGB(80, 100, 180, 246),
                            valueColor: const AlwaysStoppedAnimation<Color>(
                                Color(0xFF4C9FD7)),
                          ),
                        ),
                      ),
                    ),
                    // Steps
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: _buildStepsIndicator(),
                    ),
                  ],
                ),
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
    );
  }
}

// Extensions existantes...
extension MedicalHistoryExtension on MedicalHistory {
  MedicalHistory copyWith({
    String? id,
    String? patientId,
    double? bloodGlucoseLevel,
    int? heartRate,
    int? oxygenSaturation,
    String? bloodPressure,
    int? respiratoryRate,
    double? bodyTemperature,
    double? weight,
    double? height,
    List<String>? chronicDiseases,
    List<String>? allergies,
    String? smokingStatus,
    String? alcoholConsumption,
    List<CurrentMedication>? currentMedications,
  }) {
    return MedicalHistory(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      bloodGlucoseLevel: bloodGlucoseLevel ?? this.bloodGlucoseLevel,
      heartRate: heartRate ?? this.heartRate,
      oxygenSaturation: oxygenSaturation ?? this.oxygenSaturation,
      bloodPressure: bloodPressure ?? this.bloodPressure,
      respiratoryRate: respiratoryRate ?? this.respiratoryRate,
      bodyTemperature: bodyTemperature ?? this.bodyTemperature,
      weight: weight ?? this.weight,
      height: height ?? this.height,
      chronicDiseases: chronicDiseases ?? this.chronicDiseases,
      allergies: allergies ?? this.allergies,
      smokingStatus: smokingStatus ?? this.smokingStatus,
      alcoholConsumption: alcoholConsumption ?? this.alcoholConsumption,
      currentMedications: currentMedications ?? this.currentMedications,
    );
  }
}

extension ConsultationExtension on Consultation {
  Consultation copyWith({
    String? id,
    String? patientId,
    DateTime? date,
    String? time,
    String? type,
    String? status,
    List<String>? symptoms,
    List<String>? diagnosis,
    List<String>? prescribedAnalyses,
    String? notes,
    int? duration,
    bool? isEmergency,
    String? medicalHistoryId,
  }) {
    return Consultation(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      date: date ?? this.date,
      time: time ?? this.time,
      type: type ?? this.type,
      status: status ?? this.status,
      symptoms: symptoms ?? this.symptoms,
      diagnosis: diagnosis ?? this.diagnosis,
      prescribedAnalyses: prescribedAnalyses ?? this.prescribedAnalyses,
      notes: notes ?? this.notes,
      duration: duration ?? this.duration,
      isEmergency: isEmergency ?? this.isEmergency,
      medicalHistoryId: medicalHistoryId ?? this.medicalHistoryId,
    );
  }
}
