// lib/features/auth/widgets/auth_card.dart - VERSION AVEC NAVIGATION IMMÉDIATE 2FA
import 'package:flutter/material.dart';
import 'package:frontend/core/models/user.dart';
import 'package:provider/provider.dart';
import 'package:frontend/core/constants/primary_button.dart';
import 'package:frontend/core/constants/secondary_button.dart';
import 'package:frontend/features/auth/providers/auth_provider.dart';
import 'package:frontend/features/auth/screens/two_factor_screen.dart';
import 'package:frontend/features/auth/widgets/custom_text_field.dart';
import 'package:frontend/features/auth/screens/forgot_password_screen.dart';

class AuthCard extends StatefulWidget {
  final Function(User)? onLoginSuccess;

  const AuthCard({super.key, this.onLoginSuccess});

  @override
  State<AuthCard> createState() => _AuthCardState();
}

class _AuthCardState extends State<AuthCard> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  AuthStatus? _lastStatus; // ✅ AJOUTÉ: Pour tracker les changements de statut

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // ✅ AJOUTÉ: Détecter les changements de statut auth
    final authProvider = Provider.of<AuthProvider>(context);
    if (_lastStatus != authProvider.status) {
      debugPrint('📊 Status changed: $_lastStatus → ${authProvider.status}');

      if (authProvider.status == AuthStatus.twoFactorRequired &&
          _lastStatus != AuthStatus.twoFactorRequired) {
        debugPrint('📱 2FA detected in didChangeDependencies, navigating...');
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _navigateToTwoFactor(authProvider);
          }
        });
      }

      _lastStatus = authProvider.status;
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final cleanedPassword = _passwordController.text.trim();

      debugPrint('🔐 Starting login process...');

      final success = await authProvider.login(
        _emailController.text.trim(),
        cleanedPassword,
      );

      if (mounted) {
        debugPrint('🔍 Login completed, success: $success');
        debugPrint('🔍 Current auth status: ${authProvider.status}');

        // ✅ NAVIGATION IMMÉDIATE: Peu importe success, vérifier le statut
        if (authProvider.status == AuthStatus.twoFactorRequired) {
          debugPrint('📱 2FA required detected - navigating immediately');
          _navigateToTwoFactor(authProvider);
        } else if (authProvider.status == AuthStatus.authenticated) {
          debugPrint('✅ Direct authentication successful');
          if (authProvider.user != null) {
            widget.onLoginSuccess?.call(authProvider.user!);
          }
        } else if (authProvider.status == AuthStatus.error) {
          debugPrint('❌ Login failed with error: ${authProvider.errorMessage}');
        } else {
          debugPrint('⚠️ Unexpected status: ${authProvider.status}');
        }
      }
    }
  }

  void _navigateToForgotPassword() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ForgotPasswordScreen(),
      ),
    );
  }

  void _navigateToCreateAccount() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Create account functionality coming soon!'),
        backgroundColor: Color(0xFF05A44F),
      ),
    );
  }

  void _navigateToTwoFactor(AuthProvider authProvider) {
    debugPrint('📱 Navigating to 2FA screen...');
    debugPrint('📱 Email: ${authProvider.tempUserEmail}');
    debugPrint('📱 UserId: ${authProvider.tempUserId}');

    // ✅ Vérifier qu'on a les données nécessaires
    final email = authProvider.tempUserEmail ?? _emailController.text.trim();
    final userId = authProvider.tempUserId ?? '';

    if (email.isEmpty || userId.isEmpty) {
      debugPrint('❌ Missing 2FA data: email=$email, userId=$userId');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error: Missing 2FA data. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // ✅ NAVIGATION IMMÉDIATE vers TwoFactorScreen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TwoFactorAuthScreen(
          email: email,
          userId: userId,
          onSuccess: () {
            debugPrint('✅ 2FA verification completed successfully');
            if (authProvider.user != null) {
              widget.onLoginSuccess?.call(authProvider.user!);
            }
          },
        ),
      ),
    ).then((_) {
      // ✅ Quand on revient de l'écran 2FA, réinitialiser le statut si nécessaire
      if (authProvider.status == AuthStatus.twoFactorRequired) {
        debugPrint('🔄 Returned from 2FA screen, clearing 2FA status');
        // Note: On ne force pas le changement de statut ici pour éviter les conflits
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final cardWidth = screenWidth > 300 ? 550.0 : screenWidth * 0.9;

    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        return Container(
          width: cardWidth,
          constraints: const BoxConstraints(maxWidth: 566, minHeight: 250),
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 50),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Logo
                Image.asset(
                  'assets/icons/features/auth/User_fill.png',
                  width: 100,
                  height: 100,
                ),
                const SizedBox(height: 24),

                // Message d'erreur
                if (authProvider.status == AuthStatus.error)
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline,
                            color: Colors.red, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            authProvider.errorMessage ??
                                'Une erreur est survenue',
                            style: const TextStyle(
                              color: Colors.red,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Email Field
                CustomTextField(
                  controller: _emailController,
                  hintText: 'Email address',
                  keyboardType: TextInputType.emailAddress,
                  enabled: !authProvider.isLoading,
                  prefixIcon: const Padding(
                    padding: EdgeInsets.all(12),
                    child: Icon(Icons.email_outlined),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your email';
                    }
                    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                        .hasMatch(value)) {
                      return 'Please enter a valid email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                // Password Field
                CustomTextField(
                  controller: _passwordController,
                  hintText: 'Password',
                  obscureText: true,
                  enabled: !authProvider.isLoading,
                  prefixIcon: const Padding(
                    padding: EdgeInsets.all(12),
                    child: Icon(Icons.lock_outline),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your password';
                    }
                    if (value.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),

                // Forgot Password Link
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: authProvider.isLoading
                        ? null
                        : _navigateToForgotPassword,
                    child: const Text(
                      'Forgot Password?',
                      style: TextStyle(
                        color: Color(0xFF05A44F),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 40),

                // Buttons Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 190,
                      child: SecondaryButton(
                        text: 'Create account',
                        onPressed: authProvider.isLoading
                            ? () {}
                            : _navigateToCreateAccount,
                      ),
                    ),
                    const SizedBox(width: 16),
                    SizedBox(
                      width: 190,
                      child: PrimaryButton(
                        text:
                            authProvider.isLoading ? 'Logging in...' : 'Login',
                        onPressed: authProvider.isLoading ? null : _handleLogin,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
