// lib/shared/widgets/permission_widget.dart - VERSION COMPLÈTE
import 'package:flutter/material.dart';
import 'package:frontend/core/services/session_manager.dart';

/// Widget principal pour contrôler l'affichage basé sur les permissions
class PermissionWidget extends StatelessWidget {
  final String? permission;
  final List<String>? permissions;
  final bool requireAll;
  final Widget child;
  final Widget? fallback;
  final bool hideIfNoPermission;

  const PermissionWidget({
    super.key,
    this.permission,
    this.permissions,
    this.requireAll = false,
    required this.child,
    this.fallback,
    this.hideIfNoPermission = false,
  }) : assert(permission != null || permissions != null,
            'Either permission or permissions must be provided');

  @override
  Widget build(BuildContext context) {
    final sessionManager = SessionManager();
    bool hasAccess = false;

    if (permission != null) {
      hasAccess = sessionManager.hasPermission(permission!);
    } else if (permissions != null) {
      hasAccess = requireAll
          ? sessionManager.hasAllPermissions(permissions!)
          : sessionManager.hasAnyPermission(permissions!);
    }

    if (!hasAccess) {
      if (hideIfNoPermission) {
        return const SizedBox.shrink();
      }
      return fallback ?? _buildAccessDenied();
    }

    return child;
  }

  Widget _buildAccessDenied() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.security, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Access Denied',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'You do not have permission to view this content.',
              style: TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// Widget pour boutons d'action conditionnels
class PermissionActionButton extends StatelessWidget {
  final String permission;
  final IconData icon;
  final Color color;
  final String tooltip;
  final VoidCallback onPressed;
  final double size;

  const PermissionActionButton({
    super.key,
    required this.permission,
    required this.icon,
    required this.color,
    required this.tooltip,
    required this.onPressed,
    this.size = 20,
  });

  @override
  Widget build(BuildContext context) {
    return PermissionWidget(
      permission: permission,
      hideIfNoPermission: true,
      child: Tooltip(
        message: tooltip,
        child: IconButton(
          icon: Icon(icon, color: color, size: size),
          onPressed: onPressed,
          padding: const EdgeInsets.all(4),
        ),
      ),
    );
  }
}

/// Widget pour boutons d'ajout conditionnels
class PermissionAddButton extends StatelessWidget {
  final String permission;
  final String text;
  final VoidCallback onPressed;
  final IconData? icon;

  const PermissionAddButton({
    super.key,
    required this.permission,
    required this.text,
    required this.onPressed,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return PermissionWidget(
      permission: permission,
      hideIfNoPermission: true,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon ?? Icons.add),
        label: Text(text),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF05A44F),
          foregroundColor: Colors.white,
        ),
      ),
    );
  }
}

/// Widget pour tabs conditionnels
class PermissionTab extends StatelessWidget {
  final String permission;
  final String text;
  final IconData icon;

  const PermissionTab({
    super.key,
    required this.permission,
    required this.text,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final sessionManager = SessionManager();

    if (!sessionManager.hasPermission(permission)) {
      return const SizedBox.shrink();
    }

    return Tab(
      text: text,
      icon: Icon(icon, size: 20),
    );
  }
}

/// Widget pour items de menu conditionnels
class PermissionMenuItem extends StatelessWidget {
  final String permission;
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  const PermissionMenuItem({
    super.key,
    required this.permission,
    required this.title,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return PermissionWidget(
      permission: permission,
      hideIfNoPermission: true,
      child: ListTile(
        leading: Icon(icon, color: Colors.white, size: 22),
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        onTap: onTap,
      ),
    );
  }
}

/// Extension pour vérifier les permissions facilement
extension PermissionCheck on SessionManager {
  bool get canViewPatients => hasPermission('view_patient');
  bool get canCreatePatient => hasPermission('create_patient');
  bool get canUpdatePatient => hasPermission('update_patient');
  bool get canDeletePatient => hasPermission('delete_patient');

  bool get canViewConsultations => hasPermission('view_consultation');
  bool get canCreateConsultation => hasPermission('create_consultation');
  bool get canUpdateConsultation => hasPermission('update_consultation');
  bool get canDeleteConsultation => hasPermission('delete_consultation');

  bool get canViewPrescriptions => hasPermission('view_prescription');
  bool get canCreatePrescription => hasPermission('create_prescription');
  bool get canUpdatePrescription => hasPermission('update_prescription');
  bool get canDeletePrescription => hasPermission('delete_prescription');

  bool get canViewMedications => hasPermission('view_medication');
  bool get canCreateMedication => hasPermission('create_medication');
  bool get canUpdateMedication => hasPermission('update_medication');
  bool get canDeleteMedication => hasPermission('delete_medication');

  bool get canViewAppointments => hasPermission('view_appointment');
  bool get canCreateAppointment => hasPermission('create_appointment');
  bool get canUpdateAppointment => hasPermission('update_appointment');
  bool get canCancelAppointment => hasPermission('cancel_appointment');

  // Permissions complexes
  bool get canAccessConsultationFlow =>
      canViewConsultations && canCreateConsultation;
  bool get canAccessPrescriptionFlow =>
      canViewPrescriptions && canCreatePrescription;
  bool get canAccessFullPatientWorkflow =>
      canViewPatients && canCreatePatient && canAccessConsultationFlow;
}
