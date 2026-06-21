// lib/features/auth/screens/login_screen.dart - VERSION MISE À JOUR
import 'package:flutter/material.dart';
import 'package:frontend/features/auth/widgets/auth_card.dart';
import 'package:frontend/features/dashboard/screens/dashbaord_screen.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F9FD),
      body: Stack(
        children: [
          Center(
            child: SingleChildScrollView(
              child: AuthCard(
                onLoginSuccess: (user) {
                  debugPrint('✅ Login success, user: ${user.email}');
                  // La navigation est gérée automatiquement par AuthWrapper
                  // qui écoute les changements d'AuthProvider
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
