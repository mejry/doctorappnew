// lib/features/auth/widgets/roles_table_header.dart - Version spacieuse et élégante
import 'package:flutter/material.dart';
import 'package:frontend/core/constants/colors.dart';

class RolesTableHeader extends StatelessWidget {
  const RolesTableHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF4C9FD7), Color(0xFF5BA8DD)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: const Row(
        children: [
          // ROLE NAME
          Expanded(
            flex: 3,
            child: Text(
              'ROLE NAME',
              style: _headerStyle,
            ),
          ),
          // PERMISSIONS
          Expanded(
            flex: 6,
            child: Text(
              'PERMISSIONS',
              style: _headerStyle,
            ),
          ),
          // ASSIGNED USERS
          Expanded(
            flex: 4,
            child: Text(
              'ASSIGNED USERS',
              style: _headerStyle,
            ),
          ),
          // ACTIONS
          SizedBox(
            width: 100,
            child: Text(
              'ACTIONS',
              style: _headerStyle,
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  static const _headerStyle = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w700,
    color: Colors.white,
    letterSpacing: 0.8,
  );
}
