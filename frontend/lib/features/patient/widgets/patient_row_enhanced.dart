// lib/features/patient/widgets/patient_row_enhanced.dart - AVEC BOUTON NEW CONSULTATION
import 'package:flutter/material.dart';
import 'package:frontend/core/constants/colors.dart';
import 'package:frontend/features/patient/models/patient.dart';
import 'package:frontend/shared/widgets/permission_widget.dart';
import 'package:intl/intl.dart';

class PatientRowEnhanced extends StatelessWidget {
  final Patient patient;
  final Function(String) onAction;

  const PatientRowEnhanced({
    super.key,
    required this.patient,
    required this.onAction,
  });

  String _getPatientStatus() {
    final now = DateTime.now();
    final daysSinceRegistration =
        now.difference(patient.dateOfRegistration ?? now).inDays;

    if (daysSinceRegistration < 7) return "New";
    if (daysSinceRegistration < 30) return "Active";
    if (daysSinceRegistration < 90) return "Follow-up";
    return "Inactive";
  }

  Color _statusColor(String status) {
    switch (status) {
      case "Active":
        return Colors.green;
      case "Follow-up":
        return Colors.orange;
      case "Inactive":
        return Colors.grey;
      case "New":
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = _getPatientStatus();

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.black12)),
      ),
      child: Row(
        children: [
          // Patient Name + Age + Email
          Expanded(
            flex: 4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  patient.fullName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '${patient.age} years • ${patient.email}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          // Last Consultation
          Expanded(
            flex: 2,
            child: Text(
              patient.dateOfRegistration != null
                  ? DateFormat('dd/MM/yyyy').format(patient.dateOfRegistration!)
                  : 'N/A',
              style: const TextStyle(fontSize: 13),
              overflow: TextOverflow.ellipsis,
            ),
          ),

          // Status
          Expanded(
            flex: 2,
            child: Row(
              children: [
                CircleAvatar(radius: 5, backgroundColor: _statusColor(status)),
                const SizedBox(width: 6),
                Text(
                  status,
                  style: const TextStyle(fontSize: 13),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          // ✅ ACTIONS - AVEC NOUVEAU BOUTON NEW CONSULTATION
          Expanded(
            flex: 4, // ✅ AUGMENTÉ pour faire de la place au nouveau bouton
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // ✅ VIEW PROFILE
                PermissionActionButton(
                  permission: 'view_patient',
                  icon: Icons.visibility,
                  color: AppColors.primary,
                  tooltip: 'View Profile',
                  size: 16,
                  onPressed: () {
                    debugPrint(
                        '🔍 View Profile clicked for patient: ${patient.id}');
                    onAction("view_profile");
                  },
                ),

                // ✅ NOUVEAU: NEW CONSULTATION - BOUTON PRINCIPAL
                PermissionActionButton(
                  permission: 'create_consultation',
                  icon: Icons.add_box,
                  color: Colors.green,
                  tooltip: 'New Consultation',
                  size: 16,
                  onPressed: () {
                    debugPrint(
                        '🆕 New Consultation clicked for patient: ${patient.id}');
                    onAction("new_consultation");
                  },
                ),

                // ✅ VIEW CONSULTATIONS
                PermissionActionButton(
                  permission: 'view_consultation',
                  icon: Icons.list_alt,
                  color: Colors.blue,
                  tooltip: 'View Consultations',
                  size: 16,
                  onPressed: () {
                    debugPrint(
                        '📋 View Consultations clicked for patient: ${patient.id}');
                    onAction("view_consultations");
                  },
                ),

                // ✅ EDIT PATIENT
                PermissionActionButton(
                  permission: 'update_patient',
                  icon: Icons.edit,
                  color: Colors.orange,
                  tooltip: 'Edit Patient',
                  size: 16,
                  onPressed: () {
                    debugPrint(
                        '✏️ Edit Patient clicked for patient: ${patient.id}');
                    onAction("edit");
                  },
                ),

                // ✅ DELETE PATIENT
                PermissionActionButton(
                  permission: 'delete_patient',
                  icon: Icons.delete,
                  color: Colors.red,
                  tooltip: 'Delete Patient',
                  size: 16,
                  onPressed: () {
                    debugPrint(
                        '🗑️ Delete Patient clicked for patient: ${patient.id}');
                    onAction("delete");
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ✅ WIDGET: PermissionActionButton simplifié
class PermissionActionButton extends StatelessWidget {
  final String permission;
  final IconData icon;
  final Color color;
  final String tooltip;
  final double size;
  final VoidCallback onPressed;

  const PermissionActionButton({
    super.key,
    required this.permission,
    required this.icon,
    required this.color,
    required this.tooltip,
    required this.size,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return PermissionWidget(
      permission: permission,
      fallback: const SizedBox.shrink(),
      child: Tooltip(
        message: tooltip,
        child: IconButton(
          icon: Icon(icon, color: color, size: size),
          onPressed: onPressed,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
      ),
    );
  }
}
