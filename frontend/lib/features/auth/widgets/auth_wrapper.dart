// lib/features/auth/widgets/auth_wrapper.dart - VERSION AVEC 2FA CORRIGÉE
import 'package:flutter/material.dart';
import 'package:frontend/features/auth/providers/auth_provider.dart';
import 'package:frontend/features/auth/screens/login_screen.dart';
import 'package:frontend/features/dashboard/screens/dashbaord_screen.dart';
import 'package:provider/provider.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        debugPrint('🔍 AuthWrapper state: ${authProvider.status}');
        debugPrint('🔍 IsAuthenticated: ${authProvider.isAuthenticated}');
        debugPrint('🔍 User: ${authProvider.user?.email}');

        switch (authProvider.status) {
          case AuthStatus.initial:
          case AuthStatus.loading:
            return const Scaffold(
              backgroundColor: Color(0xFFF3F9FD),
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text(
                      'Loading...',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            );

          case AuthStatus.authenticated:
            // ✅ Utilisateur authentifié -> Dashboard
            if (authProvider.user != null) {
              debugPrint(
                  '✅ Navigating to Dashboard for: ${authProvider.user!.email}');
              return DashboardScreen(user: authProvider.user!);
            } else {
              // Cas d'erreur: authentifié mais pas d'utilisateur
              debugPrint(
                  '❌ Authenticated but no user data, redirecting to login');
              WidgetsBinding.instance.addPostFrameCallback((_) {
                authProvider.logout();
              });
              return const LoginScreen();
            }

          case AuthStatus.twoFactorRequired:
            // ✅ CORRIGÉ: Rester sur l'écran de login pendant 2FA
            // AuthCard va gérer la navigation vers TwoFactorScreen
            debugPrint(
                '📱 2FA required - staying on login screen, AuthCard will handle navigation');
            return const LoginScreen();

          case AuthStatus.unauthenticated:
          case AuthStatus.error:
          default:
            // ✅ Non authentifié -> Login
            debugPrint('🔐 Showing login screen');
            return const LoginScreen();
        }
      },
    );
  }
}
