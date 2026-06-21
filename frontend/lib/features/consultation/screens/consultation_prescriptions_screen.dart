// lib/features/consultation/screens/consultation_prescriptions_screen.dart - VERSION OPTIMISÉE
import 'package:flutter/material.dart';
import 'package:frontend/core/constants/colors.dart';
import 'package:frontend/core/constants/primary_button.dart';
import 'package:frontend/core/constants/secondary_button.dart';
import 'package:frontend/features/consultation/models/consultation.dart';
import 'package:frontend/features/consultation/services/consultation_service.dart';
import 'package:frontend/features/prescription/models/prescription.dart';
import 'package:frontend/features/prescription/services/prescription_service.dart';
import 'package:frontend/shared/widgets/prescription_card.dart';
import 'package:intl/intl.dart';

class ConsultationPrescriptionsScreen extends StatefulWidget {
  final String consultationId;
  final VoidCallback onBack;
  final VoidCallback onNewPrescription;

  const ConsultationPrescriptionsScreen({
    super.key,
    required this.consultationId,
    required this.onBack,
    required this.onNewPrescription,
  });

  @override
  State<ConsultationPrescriptionsScreen> createState() =>
      _ConsultationPrescriptionsScreenState();
}

class _ConsultationPrescriptionsScreenState
    extends State<ConsultationPrescriptionsScreen> {
  final ConsultationService _consultationService = ConsultationService();
  final PrescriptionService _prescriptionService = PrescriptionService();

  Consultation? _consultation;
  List<Prescription> _prescriptions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final consultationFuture =
          _consultationService.getConsultationById(widget.consultationId);
      final prescriptionsFuture = _prescriptionService
          .getPrescriptionsByConsultation(widget.consultationId);

      final results = await Future.wait([
        consultationFuture,
        prescriptionsFuture,
      ]);

      setState(() {
        _consultation = results[0] as Consultation;
        _prescriptions = results[1] as List<Prescription>;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnackBar('Error loading data: $e', Colors.red);
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: Column(
          children: [
            // Header compact
            _buildCompactHeader(),

            // Vue compacte de la consultation
            if (_consultation != null) _buildCompactConsultationView(),

            // Liste des prescriptions
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _buildPrescriptionsContent(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Back button
          IconButton(
            onPressed: widget.onBack,
            icon: const Icon(Icons.arrow_back, color: AppColors.primary),
            style: IconButton.styleFrom(
              backgroundColor: AppColors.primary.withOpacity(0.1),
              padding: const EdgeInsets.all(8),
            ),
          ),

          const SizedBox(width: 12),

          // Title avec icône
          Expanded(
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.medication,
                    color: AppColors.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Prescriptions',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // New prescription button
          ElevatedButton.icon(
            onPressed: widget.onNewPrescription,
            icon: const Icon(Icons.add, size: 18),
            label: const Text('New'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactConsultationView() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Ligne principale avec infos essentielles
          Row(
            children: [
              // Status indicator
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color:
                      _getStatusColor(_consultation!.status).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  Icons.event_note,
                  color: _getStatusColor(_consultation!.status),
                  size: 16,
                ),
              ),

              const SizedBox(width: 10),

              // Consultation info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          _consultation!.type,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: _getStatusColor(_consultation!.status),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            _consultation!.status,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      DateFormat('EEEE, dd MMM yyyy • HH:mm')
                          .format(_consultation!.date),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),

              // Quick stats
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${_prescriptions.length} Rx',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
              ),
            ],
          ),

          // Diagnostic et symptômes (si présents) - en accordéon
          if (_consultation!.diagnosis.isNotEmpty ||
              _consultation!.symptoms.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                children: [
                  if (_consultation!.diagnosis.isNotEmpty) ...[
                    Expanded(
                      child: _buildCompactInfoChip(
                        'Diagnosis',
                        _consultation!.diagnosis.take(2).join(', '),
                        Icons.psychology,
                        Colors.green,
                      ),
                    ),
                  ],
                  if (_consultation!.diagnosis.isNotEmpty &&
                      _consultation!.symptoms.isNotEmpty)
                    const SizedBox(width: 8),
                  if (_consultation!.symptoms.isNotEmpty) ...[
                    Expanded(
                      child: _buildCompactInfoChip(
                        'Symptoms',
                        _consultation!.symptoms.take(2).join(', '),
                        Icons.medical_services,
                        Colors.orange,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCompactInfoChip(
      String label, String value, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, size: 12, color: color),
        const SizedBox(width: 4),
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 10),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildPrescriptionsContent() {
    if (_prescriptions.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: Column(
        children: [
          // Header de la section prescriptions
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Text(
                  'Prescriptions (${_prescriptions.length})',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: _loadData,
                  icon: const Icon(Icons.refresh, size: 16),
                  label: const Text('Refresh'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.grey[600],
                    textStyle: const TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
          ),

          // Liste des prescriptions
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _prescriptions.length,
              itemBuilder: (context, index) {
                final prescription = _prescriptions[index];
                return PrescriptionCard(
                  prescription: prescription,
                  onViewDetails: () => _viewPrescriptionDetails(prescription),
                  onEdit: () => _editPrescription(prescription),
                  onExport: () => _exportPrescription(prescription),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.medication_outlined,
                size: 48,
                color: AppColors.primary.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'No Prescriptions Yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2E3440),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Create the first prescription for this consultation',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: widget.onNewPrescription,
              icon: const Icon(Icons.add, size: 20),
              label: const Text('Create First Prescription'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
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

  void _viewPrescriptionDetails(Prescription prescription) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(Icons.medication,
                  color: AppColors.primary, size: 20),
            ),
            const SizedBox(width: 8),
            const Text('Prescription Details'),
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
                    '${prescription.prescriptionInfo.validityDays ?? 30} days'),
                if (prescription.prescriptionInfo.notes?.isNotEmpty ==
                    true) ...[
                  const SizedBox(height: 12),
                  const Text(
                    'Notes:',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, color: AppColors.primary),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(prescription.prescriptionInfo.notes!),
                  ),
                ],
                const SizedBox(height: 12),
                const Text(
                  'Medications:',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: AppColors.primary),
                ),
                const SizedBox(height: 6),
                if (prescription.medications.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'No medications prescribed',
                      style: TextStyle(
                          fontStyle: FontStyle.italic, color: Colors.grey),
                    ),
                  )
                else
                  ...prescription.medications.map((med) => Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(8),
                          color: Colors.grey[50],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Icon(
                                    Icons.medication,
                                    size: 14,
                                    color: AppColors.primary,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    med.displayName,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            if (med.dosage.strength?.isNotEmpty == true)
                              _buildDetailRow('Dosage', med.dosage.strength!),
                            if (med.dosage.frequency?.isNotEmpty == true)
                              _buildDetailRow(
                                  'Frequency', med.dosage.frequency!),
                            if (med.dosage.duration?.isNotEmpty == true)
                              _buildDetailRow('Duration', med.dosage.duration!),
                            if (med.dosage.instructions?.isNotEmpty == true)
                              _buildDetailRow(
                                  'Instructions', med.dosage.instructions!),
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
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
                fontSize: 12,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  void _editPrescription(Prescription prescription) {
    _showSnackBar(
        'Edit prescription functionality coming soon...', Colors.orange);
  }

  Future<void> _exportPrescription(Prescription prescription) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Generating PDF...'),
            ],
          ),
        ),
      );

      final success =
          await _prescriptionService.exportPrescriptionAsPDF(prescription.id!);

      Navigator.of(context).pop();

      if (success) {
        _showSnackBar('✅ Prescription exported successfully!', Colors.green);
      }
    } catch (e) {
      Navigator.of(context).pop();
      _showSnackBar('❌ Export failed: $e', Colors.red);
    }
  }
}
