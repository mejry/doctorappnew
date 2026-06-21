// lib/shared/widgets/prescription_card.dart
import 'package:flutter/material.dart';
import 'package:frontend/core/constants/colors.dart';
import 'package:frontend/features/prescription/models/prescription.dart';
import 'package:intl/intl.dart';

class PrescriptionCard extends StatelessWidget {
  final Prescription prescription;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onExport;
  final VoidCallback? onViewDetails;
  final bool showActions;
  final bool isCompact;

  const PrescriptionCard({
    super.key,
    required this.prescription,
    this.onTap,
    this.onEdit,
    this.onDelete,
    this.onExport,
    this.onViewDetails,
    this.showActions = true,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              _buildHeader(),

              if (!isCompact) ...[
                const SizedBox(height: 12),
                // Content
                _buildContent(),

                if (showActions) ...[
                  const SizedBox(height: 12),
                  // Actions
                  _buildActions(),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        // Status indicator
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: prescription.statusColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.medication,
            color: prescription.statusColor,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),

        // Main info
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'Prescription #${prescription.id?.substring(0, 8) ?? 'Unknown'}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2E3440),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: prescription.statusColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      prescription.prescriptionInfo.status,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    Icons.access_time,
                    size: 14,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    DateFormat('dd/MM/yyyy à HH:mm')
                        .format(prescription.prescriptionInfo.date),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Icon(
                    Icons.category_outlined,
                    size: 14,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    prescription.prescriptionInfo.type,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Validity info
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.05),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: Colors.blue.withOpacity(0.2)),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.schedule,
                size: 16,
                color: Colors.blue,
              ),
              const SizedBox(width: 6),
              Text(
                'Valid for ${prescription.prescriptionInfo.validityDays ?? 30} days',
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.blue,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),

        // Medications
        if (prescription.hasMedications) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.05),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppColors.primary.withOpacity(0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.medication_outlined,
                      size: 16,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Medications (${prescription.medicationCount}):',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ...prescription.medications.take(2).map(
                      (med) => Padding(
                        padding: const EdgeInsets.only(bottom: 2),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('• ',
                                style: TextStyle(
                                    color: AppColors.primary, fontSize: 14)),
                            Expanded(
                              child: Text(
                                med.displayName,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                if (prescription.medicationCount > 2)
                  Text(
                    '... and ${prescription.medicationCount - 2} more',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.grey,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
              ],
            ),
          ),
        ] else ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.05),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.grey.withOpacity(0.2)),
            ),
            child: const Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 16,
                  color: Colors.grey,
                ),
                SizedBox(width: 6),
                Text(
                  'No medications prescribed yet',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ],

        // Notes
        if (prescription.prescriptionInfo.notes?.isNotEmpty == true) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.05),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.orange.withOpacity(0.2)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.note_outlined,
                  size: 16,
                  color: Colors.orange,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    prescription.prescriptionInfo.notes!,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.orange,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildActions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (onViewDetails != null)
          _buildActionButton(
            onPressed: onViewDetails!,
            icon: Icons.visibility_outlined,
            label: 'Details',
            color: AppColors.primary,
          ),
        if (onEdit != null) ...[
          const SizedBox(width: 8),
          _buildActionButton(
            onPressed: onEdit!,
            icon: Icons.edit_outlined,
            label: 'Edit',
            color: Colors.orange,
          ),
        ],
        if (onExport != null) ...[
          const SizedBox(width: 8),
          _buildActionButton(
            onPressed: onExport!,
            icon: Icons.print_outlined,
            label: 'Export',
            color: Colors.green,
          ),
        ],
        if (onDelete != null) ...[
          const SizedBox(width: 8),
          _buildActionButton(
            onPressed: onDelete!,
            icon: Icons.delete_outline,
            label: 'Delete',
            color: Colors.red,
          ),
        ],
      ],
    );
  }

  Widget _buildActionButton({
    required VoidCallback onPressed,
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return TextButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 16),
      label: Text(label),
      style: TextButton.styleFrom(
        foregroundColor: color,
        textStyle: const TextStyle(fontSize: 12),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }
}

// 🎨 Variantes du widget

class CompactPrescriptionCard extends StatelessWidget {
  final Prescription prescription;
  final VoidCallback? onTap;

  const CompactPrescriptionCard({
    super.key,
    required this.prescription,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return PrescriptionCard(
      prescription: prescription,
      onTap: onTap,
      showActions: false,
      isCompact: true,
    );
  }
}

class PrescriptionListTile extends StatelessWidget {
  final Prescription prescription;
  final VoidCallback? onTap;
  final Widget? trailing;

  const PrescriptionListTile({
    super.key,
    required this.prescription,
    this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: prescription.statusColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          Icons.medication,
          color: prescription.statusColor,
          size: 20,
        ),
      ),
      title: Text(
        'Prescription #${prescription.id?.substring(0, 8) ?? 'Unknown'}',
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            DateFormat('dd/MM/yyyy à HH:mm')
                .format(prescription.prescriptionInfo.date),
            style: const TextStyle(fontSize: 12),
          ),
          if (prescription.hasMedications)
            Text(
              '${prescription.medicationCount} medication(s)',
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[600],
              ),
            ),
        ],
      ),
      trailing: trailing ??
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: prescription.statusColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              prescription.prescriptionInfo.status,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
      onTap: onTap,
    );
  }
}

// 🎭 Extensions pour faciliter l'utilisation

extension PrescriptionCardExtension on Prescription {
  Widget toCard({
    VoidCallback? onTap,
    VoidCallback? onEdit,
    VoidCallback? onDelete,
    VoidCallback? onExport,
    VoidCallback? onViewDetails,
    bool showActions = true,
  }) {
    return PrescriptionCard(
      prescription: this,
      onTap: onTap,
      onEdit: onEdit,
      onDelete: onDelete,
      onExport: onExport,
      onViewDetails: onViewDetails,
      showActions: showActions,
    );
  }

  Widget toCompactCard({VoidCallback? onTap}) {
    return CompactPrescriptionCard(
      prescription: this,
      onTap: onTap,
    );
  }

  Widget toListTile({
    VoidCallback? onTap,
    Widget? trailing,
  }) {
    return PrescriptionListTile(
      prescription: this,
      onTap: onTap,
      trailing: trailing,
    );
  }
}
