// lib/features/prescription/screens/auto_prescription_screen.dart
import 'package:flutter/material.dart';
import 'package:frontend/core/constants/colors.dart';
import 'package:frontend/core/constants/primary_button.dart';
import 'package:frontend/core/constants/secondary_button.dart';
import 'package:frontend/features/consultation/models/consultation.dart';
import 'package:frontend/features/consultation/services/consultation_service.dart';
import 'package:frontend/features/patient/models/patient.dart';
import 'package:frontend/features/patient/services/patient_service.dart';

class AutoPrescriptionScreen extends StatefulWidget {
  final String patientId;
  final String consultationId;
  final VoidCallback onComplete;
  final VoidCallback onBack;

  const AutoPrescriptionScreen({
    super.key,
    required this.patientId,
    required this.consultationId,
    required this.onComplete,
    required this.onBack,
  });

  @override
  State<AutoPrescriptionScreen> createState() => _AutoPrescriptionScreenState();
}

class _AutoPrescriptionScreenState extends State<AutoPrescriptionScreen> {
  final PatientService _patientService = PatientService();
  final ConsultationService _consultationService = ConsultationService();

  Patient? _patient;
  Consultation? _consultation;
  bool _isLoading = true;
  bool _wantsPrescription = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final patient = await _patientService.getPatientById(widget.patientId);
      final consultation =
          await _consultationService.getConsultationById(widget.consultationId);

      setState(() {
        _patient = patient;
        _consultation = consultation;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading data: $e')),
      );
    }
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
      body: SafeArea(
        child: SingleChildScrollView(
          // 👈 AJOUT DU SCROLLVIEW
          padding: const EdgeInsets.all(24.0),
          child: Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 800),
              child: Column(
                mainAxisAlignment:
                    MainAxisAlignment.start, // 👈 CHANGÉ DE center À start
                children: [
                  // Success Icon
                  Container(
                    padding: const EdgeInsets.all(16), // 👈 RÉDUIT DE 20 À 16
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_circle,
                      color: Colors.green,
                      size: 60, // 👈 RÉDUIT DE 80 À 60
                    ),
                  ),

                  const SizedBox(height: 24), // 👈 RÉDUIT DE 32 À 24

                  // Success Message
                  const Text(
                    '🎉 Success!',
                    style: TextStyle(
                      fontSize: 28, // 👈 RÉDUIT DE 32 À 28
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),

                  const SizedBox(height: 12), // 👈 RÉDUIT DE 16 À 12

                  const Text(
                    'Patient and consultation created successfully!',
                    style: TextStyle(
                      fontSize: 16, // 👈 RÉDUIT DE 18 À 16
                      color: Colors.grey,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 24), // 👈 RÉDUIT DE 32 À 24

                  // Summary Cards - 👈 RESPONSIVE LAYOUT
                  LayoutBuilder(
                    builder: (context, constraints) {
                      // Si l'écran est trop petit, empiler verticalement
                      if (constraints.maxWidth < 600) {
                        return Column(
                          children: [
                            _buildSummaryCard(
                              '👤 Patient Created',
                              _patient?.fullName ?? 'Unknown',
                              '${_patient?.age} years • ${_patient?.email}',
                              Colors.blue,
                            ),
                            const SizedBox(height: 12),
                            _buildSummaryCard(
                              '📋 Consultation Created',
                              _consultation?.type ?? 'Unknown',
                              'Status: ${_consultation?.status}',
                              Colors.green,
                            ),
                          ],
                        );
                      } else {
                        return Row(
                          children: [
                            Expanded(
                              child: _buildSummaryCard(
                                '👤 Patient Created',
                                _patient?.fullName ?? 'Unknown',
                                '${_patient?.age} years • ${_patient?.email}',
                                Colors.blue,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildSummaryCard(
                                '📋 Consultation Created',
                                _consultation?.type ?? 'Unknown',
                                'Status: ${_consultation?.status}',
                                Colors.green,
                              ),
                            ),
                          ],
                        );
                      }
                    },
                  ),

                  const SizedBox(height: 24), // 👈 RÉDUIT DE 32 À 24

                  // Prescription Section
                  Container(
                    padding: const EdgeInsets.all(20), // 👈 RÉDUIT DE 24 À 20
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.orange.withOpacity(0.3)),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.orange.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.medication,
                                color: Colors.orange,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '💊 Prescription Ready',
                                    style: TextStyle(
                                      fontSize: 16, // 👈 RÉDUIT DE 18 À 16
                                      fontWeight: FontWeight.bold,
                                      color: Colors.orange,
                                    ),
                                  ),
                                  Text(
                                    'An empty prescription has been automatically created',
                                    style: TextStyle(
                                      color: Colors.grey,
                                      fontSize:
                                          12, // 👈 AJOUTÉ POUR RÉDUIRE LA TAILLE
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16), // 👈 RÉDUIT DE 20 À 16

                        const Text(
                          'Would you like to add medications to the prescription now?',
                          style: TextStyle(
                            fontSize: 14, // 👈 RÉDUIT DE 16 À 14
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),

                        const SizedBox(height: 16), // 👈 RÉDUIT DE 20 À 16

                        // Choice buttons - 👈 RESPONSIVE
                        LayoutBuilder(
                          builder: (context, constraints) {
                            if (constraints.maxWidth < 400) {
                              return Column(
                                children: [
                                  SizedBox(
                                    width: double.infinity,
                                    child: OutlinedButton.icon(
                                      onPressed: () {
                                        setState(
                                            () => _wantsPrescription = false);
                                        _completeLater();
                                      },
                                      icon: const Icon(Icons.schedule),
                                      label: const Text('Complete Later'),
                                      style: OutlinedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 12), // 👈 RÉDUIT
                                        side: const BorderSide(
                                            color: Colors.grey),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton.icon(
                                      onPressed: () {
                                        setState(
                                            () => _wantsPrescription = true);
                                        _completePrescriptionNow();
                                      },
                                      icon: const Icon(Icons.add_circle),
                                      label: const Text('Add Medications'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.orange,
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 12), // 👈 RÉDUIT
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            } else {
                              return Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: () {
                                        setState(
                                            () => _wantsPrescription = false);
                                        _completeLater();
                                      },
                                      icon: const Icon(Icons.schedule),
                                      label: const Text('Complete Later'),
                                      style: OutlinedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 12), // 👈 RÉDUIT
                                        side: const BorderSide(
                                            color: Colors.grey),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      onPressed: () {
                                        setState(
                                            () => _wantsPrescription = true);
                                        _completePrescriptionNow();
                                      },
                                      icon: const Icon(Icons.add_circle),
                                      label: const Text('Add Medications'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.orange,
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 12), // 👈 RÉDUIT
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            }
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24), // 👈 RÉDUIT DE 32 À 24

                  // Navigation Buttons
                  LayoutBuilder(
                    builder: (context, constraints) {
                      if (constraints.maxWidth < 400) {
                        return Column(
                          children: [
                            SizedBox(
                              width: double.infinity,
                              child: SecondaryButton(
                                text: "Back to Consultations",
                                onPressed: widget.onBack,
                              ),
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: PrimaryButton(
                                text: "View Patient Profile",
                                onPressed: widget.onComplete,
                              ),
                            ),
                          ],
                        );
                      } else {
                        return Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SecondaryButton(
                              text: "Back to Consultations",
                              onPressed: widget.onBack,
                            ),
                            const SizedBox(width: 16),
                            PrimaryButton(
                              text: "View Patient Profile",
                              onPressed: widget.onComplete,
                            ),
                          ],
                        );
                      }
                    },
                  ),

                  const SizedBox(
                      height:
                          24), // 👈 PADDING FINAL POUR ÉVITER LE DÉBORDEMENT
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard(
      String title, String subtitle, String description, Color color) {
    return Container(
      padding: const EdgeInsets.all(14), // 👈 RÉDUIT DE 16 À 14
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 12, // 👈 RÉDUIT DE 14 À 12
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 6), // 👈 RÉDUIT DE 8 À 6
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 14, // 👈 RÉDUIT DE 16 À 14
              fontWeight: FontWeight.w600,
            ),
            maxLines: 2, // 👈 LIMITE LE NOMBRE DE LIGNES
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 3), // 👈 RÉDUIT DE 4 À 3
          Text(
            description,
            style: const TextStyle(
              fontSize: 10, // 👈 RÉDUIT DE 12 À 10
              color: Colors.grey,
            ),
            maxLines: 1, // 👈 LIMITE LE NOMBRE DE LIGNES
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  void _completePrescriptionNow() {
    // Navigate to prescription form
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Opening prescription form...'),
        backgroundColor: Colors.orange,
      ),
    );

    // TODO: Navigate to prescription form with consultation ID
    Future.delayed(const Duration(seconds: 1), () {
      widget.onComplete();
    });
  }

  void _completeLater() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content:
            Text('Prescription saved as draft. You can complete it later.'),
        backgroundColor: Colors.blue,
      ),
    );

    Future.delayed(const Duration(seconds: 1), () {
      widget.onComplete();
    });
  }
}
