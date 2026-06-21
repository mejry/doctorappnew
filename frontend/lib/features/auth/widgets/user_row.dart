// lib/features/auth/widgets/user_row.dart - Version avec contrôle des permissions visuelles
import 'package:flutter/material.dart';
import 'package:frontend/core/constants/colors.dart';

class UserRow extends StatelessWidget {
  final Map<String, dynamic> user;
  final bool showEditButton;
  final bool showDeleteButton;
  final bool canUpdateStatus;
  final VoidCallback onEditPressed;
  final VoidCallback onDeletePressed;
  final VoidCallback onStatusPressed;

  const UserRow({
    super.key,
    required this.user,
    required this.showEditButton,
    required this.showDeleteButton,
    required this.canUpdateStatus,
    required this.onEditPressed,
    required this.onDeletePressed,
    required this.onStatusPressed,
  });

  String _getFieldValue(String key) {
    final value = user[key];
    if (value == null) return '-';
    if (value is String) return value;
    return value.toString();
  }

  @override
  Widget build(BuildContext context) {
    final isActive = _getFieldValue('status') == 'Active';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey)),
      ),
      child: Row(
        children: [
          Expanded(flex: 2, child: Text(_getFieldValue('name'))),
          Expanded(flex: 2, child: Text(_getFieldValue('role'))),
          Expanded(
            flex: 2,
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                backgroundColor:
                    isActive ? const Color(0xFF4C9FD7) : Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                side: BorderSide(
                  color: isActive
                      ? const Color(0xFF4C9FD7)
                      : const Color.fromARGB(111, 158, 158, 158),
                ),
              ),
              // ✅ Bouton Status : cliquable seulement si permission
              onPressed: canUpdateStatus ? onStatusPressed : null,
              child: Text(
                _getFieldValue('status'),
                style: TextStyle(
                  color: canUpdateStatus
                      ? (isActive ? Colors.white : Colors.grey[700])
                      : Colors.grey[400],
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Row(
              children: [
                // ✅ Bouton Edit : affiché seulement si permission
                if (showEditButton)
                  IconButton(
                    icon: const Icon(Icons.edit, color: AppColors.primary),
                    onPressed: onEditPressed,
                    tooltip: 'Edit user',
                  )
                else
                  const SizedBox(
                      width: 48), // Espace pour maintenir l'alignement

                // ✅ Bouton Delete : affiché seulement si permission
                if (showDeleteButton)
                  IconButton(
                    icon: const Icon(
                      Icons.delete,
                      color: Color.fromARGB(255, 225, 42, 42),
                    ),
                    onPressed: onDeletePressed,
                    tooltip: 'Delete user',
                  )
                else
                  const SizedBox(
                      width: 48), // Espace pour maintenir l'alignement
              ],
            ),
          ),
        ],
      ),
    );
  }
}
