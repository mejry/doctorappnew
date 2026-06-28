// lib/shared/widgets/sidebar_menu.dart - VERSION AVEC PERMISSIONS FIXES
import 'package:flutter/material.dart';
import 'package:frontend/core/constants/colors.dart';
import 'package:frontend/features/auth/providers/auth_provider.dart';
import 'package:provider/provider.dart';

class SidebarMenu extends StatefulWidget {
  final Function(String)? onMenuItemSelected;

  const SidebarMenu({super.key, this.onMenuItemSelected});

  @override
  State<SidebarMenu> createState() => _SidebarMenuState();
}

class _SubMenuItem {
  final String title;
  final IconData icon;
  final bool Function(AuthProvider) hasPermission;

  _SubMenuItem(this.title, this.icon, this.hasPermission);
}

class _MenuItem {
  final String title;
  final dynamic icon;
  final bool Function(AuthProvider) hasPermission;
  final List<_SubMenuItem>? subItems;

  _MenuItem(this.title, this.icon, this.hasPermission, {this.subItems});
}

class _SidebarMenuState extends State<SidebarMenu> {
  bool _isSettingsExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        return Container(
          width: 250,
          decoration: const BoxDecoration(
            color: AppColors.secondary,
            borderRadius: BorderRadius.only(
              topRight: Radius.circular(20),
              bottomRight: Radius.circular(20),
            ),
          ),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _buildLogoSection(),
              const SizedBox(height: 20),
              Expanded(
                child: SingleChildScrollView(
                  child: _buildMenuItems(authProvider),
                ),
              ),
              _buildLogoutButton(authProvider),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLogoSection() {
    return Center(
      child: Image.asset(
        "assets/images/global/logoTreanos.png",
        width: 100,
        height: 100,
      ),
    );
  }

  Widget _buildMenuItems(AuthProvider authProvider) {
    // Définir les éléments de menu avec leurs permissions
    final menuItems = [
      // Dashboard - toujours visible
      _MenuItem(
        'Dashboard',
        Icons.dashboard_outlined,
        (auth) => true, // Toujours accessible
      ),

      _MenuItem(
        'Patient',
        'assets/icons/global/patient_icon.png',
        (auth) => auth.canViewPatients || auth.canCreatePatient,
      ),

      _MenuItem(
        'Consultation',
        Icons.medical_services_outlined,
        (auth) => auth.canViewConsultations || auth.canCreateConsultation,
      ),

      _MenuItem(
        'Appointment Cycle',
        Icons.event_available_outlined,
        (auth) => auth.canViewAppointments || auth.canCreateAppointment,
      ),

      _MenuItem(
        'Medications',
        'assets/icons/global/medication_icon.png',
        (auth) => auth.canViewMedications || auth.canCreateMedication,
      ),

      // ✅ MODIFIÉ: Settings - TOUJOURS visible car Account Information et Security sont pour tous
      _MenuItem(
        'Settings',
        Icons.settings,
        (auth) =>
            true, // ✅ Toujours accessible car contient Account et Security
        subItems: [
          // ✅ Account Information - TOUJOURS visible (chaque utilisateur peut gérer ses infos)
          _SubMenuItem(
            'Account Information',
            Icons.account_circle,
            (auth) => true, // ✅ Toujours accessible
          ),

          // Users - visible si permission view_user
          _SubMenuItem(
            'Users',
            Icons.people_alt,
            (auth) => auth.hasPermission('view_user'),
          ),

          // Roles - visible si permission view_role
          _SubMenuItem(
            'Roles',
            Icons.admin_panel_settings,
            (auth) => auth.hasPermission('view_role'),
          ),

          // ✅ Security & Privacy - TOUJOURS visible (chaque utilisateur peut changer son mot de passe)
          _SubMenuItem(
            'Security & Privacy',
            Icons.security,
            (auth) => true, // ✅ Toujours accessible
          ),
        ],
      ),
    ];

    // Filtrer les éléments selon les permissions
    final visibleItems =
        menuItems.where((item) => item.hasPermission(authProvider)).toList();

    return Column(
      children: visibleItems.map((item) {
        Widget leadingIcon;
        if (item.icon is String) {
          leadingIcon = Image.asset(
            item.icon,
            width: 22,
            height: 22,
            color: Colors.white,
          );
        } else {
          leadingIcon = Icon(
            item.icon,
            color: Colors.white,
            size: 22,
          );
        }

        // Filtrer les sous-éléments selon les permissions
        final visibleSubItems = item.subItems
            ?.where((subItem) => subItem.hasPermission(authProvider))
            .toList();
        final hasVisibleSubItems =
            visibleSubItems != null && visibleSubItems.isNotEmpty;

        return Column(
          children: [
            ListTile(
              minLeadingWidth: 20,
              leading: leadingIcon,
              title: Text(
                item.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              contentPadding: EdgeInsets.zero,
              horizontalTitleGap: 10,
              trailing: hasVisibleSubItems
                  ? Icon(
                      _isSettingsExpanded && item.title == 'Settings'
                          ? Icons.arrow_drop_up
                          : Icons.arrow_drop_down,
                      color: Colors.white,
                      size: 20,
                    )
                  : null,
              onTap: () {
                if (!hasVisibleSubItems) {
                  widget.onMenuItemSelected?.call(item.title);
                } else if (item.title == 'Settings') {
                  setState(() {
                    _isSettingsExpanded = !_isSettingsExpanded;
                  });
                }
              },
            ),

            // Afficher les sous-éléments seulement s'ils sont visibles et autorisés
            if (hasVisibleSubItems &&
                item.title == 'Settings' &&
                _isSettingsExpanded)
              ...visibleSubItems!.map((subItem) {
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.only(left: 32),
                  child: ListTile(
                    minLeadingWidth: 20,
                    leading: Icon(
                      subItem.icon,
                      color: Colors.white,
                      size: 18,
                    ),
                    title: Text(
                      subItem.title,
                      style: const TextStyle(
                        color: AppColors.textWhite,
                        fontSize: 13,
                      ),
                    ),
                    contentPadding: EdgeInsets.zero,
                    horizontalTitleGap: 10,
                    onTap: () => widget.onMenuItemSelected?.call(subItem.title),
                  ),
                );
              }).toList(),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildLogoutButton(AuthProvider authProvider) {
    return ListTile(
      minLeadingWidth: 20,
      leading: const Icon(
        Icons.logout_outlined,
        color: AppColors.buttonPrimaryText,
        size: 22,
      ),
      title: const Text(
        'Log out',
        style: TextStyle(
          color: AppColors.textWhite,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: () async {
        // ✅ SIMPLIFIÉ: Confirmation courte et directe
        final shouldLogout = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Logout'),
            content: const Text('Are you sure you want to log out?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Logout'),
              ),
            ],
          ),
        );

        // ✅ SIMPLIFIÉ: Logout direct sans loading dialog
        if (shouldLogout == true && mounted) {
          try {
            debugPrint('🚪 Starting logout...');

            // Logout direct - AuthWrapper gérera la navigation
            await authProvider.logout();

            debugPrint('✅ Logout completed');
          } catch (e) {
            debugPrint('❌ Logout error: $e');

            // Afficher seulement l'erreur si nécessaire
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Logout error: $e'),
                  backgroundColor: Colors.red,
                  duration: const Duration(seconds: 2),
                ),
              );
            }
          }
        }
      },
    );
  }
}
