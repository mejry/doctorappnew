// lib/features/auth/screens/two_factor_screen.dart - VERSION AVEC SESSION
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:frontend/core/constants/primary_button.dart';
import 'package:frontend/features/auth/providers/auth_provider.dart';

class TwoFactorAuthScreen extends StatefulWidget {
  final String email;
  final String userId;
  final VoidCallback onSuccess;

  const TwoFactorAuthScreen({
    super.key,
    required this.email,
    required this.userId,
    required this.onSuccess,
  });

  @override
  State<TwoFactorAuthScreen> createState() => _TwoFactorAuthScreenState();
}

class _TwoFactorAuthScreenState extends State<TwoFactorAuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  void _verifyCode() async {
    if (_formKey.currentState!.validate()) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      debugPrint(
          '🔢 Attempting 2FA verification with code: ${_codeController.text}');

      final success = await authProvider.verify2FA(_codeController.text);

      if (success && mounted) {
        debugPrint('✅ 2FA verification successful');

        if (authProvider.isAuthenticated && authProvider.user != null) {
          debugPrint('🎉 User authenticated, calling onSuccess');

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Login successful!'),
              backgroundColor: Color(0xFF05A44F),
              duration: Duration(seconds: 2),
            ),
          );

          // ✅ Fermer l'écran 2FA et laisser AuthWrapper gérer la navigation
          Navigator.of(context).pop();
          widget.onSuccess();
        }
      } else {
        debugPrint('❌ 2FA verification failed');
        // Les erreurs sont gérées par le Consumer et affichées automatiquement
      }
    }
  }

  void _resendCode() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    debugPrint('📱 Resending 2FA code to: ${widget.email}');

    final success = await authProvider.resend2FACode();

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Verification code sent successfully!'),
          backgroundColor: Color(0xFF05A44F),
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.errorMessage ?? 'Failed to resend code'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final cardWidth = screenWidth > 300 ? 450.0 : screenWidth * 0.9;

    return Scaffold(
      backgroundColor: const Color(0xFFF3F9FD),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1A1A1A)),
          onPressed: () {
            debugPrint('🔙 Going back to login screen');
            Navigator.pop(context);
          },
        ),
      ),
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          return Center(
            child: SingleChildScrollView(
              child: Container(
                width: cardWidth,
                constraints:
                    const BoxConstraints(maxWidth: 466, minHeight: 200),
                padding: const EdgeInsets.all(40),
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
                      // Security icon
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: const Color(0xFF05A44F).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(40),
                        ),
                        child: const Icon(
                          Icons.security,
                          size: 40,
                          color: Color(0xFF05A44F),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Title
                      const Text(
                        'Two-Factor Authentication',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A1A1A),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),

                      // Description
                      Text(
                        "We've sent a 6-digit verification code to\n${widget.email}",
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF6B7280),
                          height: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),

                      // Extra info
                      const Text(
                        'This code will expire in 10 minutes.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF6B7280),
                          fontStyle: FontStyle.italic,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),

                      // Error message
                      if (authProvider.status == AuthStatus.error &&
                          authProvider.errorMessage != null)
                        Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border:
                                Border.all(color: Colors.red.withOpacity(0.3)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.error_outline,
                                  color: Colors.red, size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  authProvider.errorMessage!,
                                  style: const TextStyle(
                                    color: Colors.red,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                      // Verification code input field
                      SizedBox(
                        width: double.infinity,
                        child: TextFormField(
                          controller: _codeController,
                          textAlign: TextAlign.center,
                          keyboardType: TextInputType.number,
                          maxLength: 6,
                          enabled: !authProvider.isLoading,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 8,
                          ),
                          decoration: InputDecoration(
                            hintText: '123456',
                            hintStyle: TextStyle(
                              color: Colors.grey.withOpacity(0.5),
                              letterSpacing: 8,
                            ),
                            counterText: '',
                            filled: true,
                            fillColor: const Color(0xFFF9FAFB),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: Colors.grey.withOpacity(0.3),
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: Colors.grey.withOpacity(0.3),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Color(0xFF05A44F),
                                width: 2,
                              ),
                            ),
                            errorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Colors.red,
                              ),
                            ),
                            focusedErrorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Colors.red,
                                width: 2,
                              ),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 20,
                            ),
                          ),
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(6),
                          ],
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter the verification code';
                            }
                            if (value.length != 6) {
                              return 'Code must be 6 digits';
                            }
                            if (!RegExp(r'^\d{6}$').hasMatch(value)) {
                              return 'Code must only contain digits';
                            }
                            return null;
                          },
                          onChanged: (value) {
                            // Auto-submit when 6 digits are entered
                            if (value.length == 6 && !authProvider.isLoading) {
                              debugPrint(
                                  '🔢 Auto-submitting 6-digit code: $value');
                              _verifyCode();
                            }
                          },
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Verify button
                      SizedBox(
                        width: double.infinity,
                        child: PrimaryButton(
                          text: authProvider.isLoading
                              ? 'Verifying...'
                              : 'Verify Code',
                          onPressed:
                              authProvider.isLoading ? null : _verifyCode,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Resend code
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            "Didn't receive a code? ",
                            style: TextStyle(
                              fontSize: 14,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                          TextButton(
                            onPressed:
                                authProvider.isLoading ? null : _resendCode,
                            child: const Text(
                              'Resend',
                              style: TextStyle(
                                fontSize: 14,
                                color: Color(0xFF05A44F),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Back to login
                      TextButton(
                        onPressed: authProvider.isLoading
                            ? null
                            : () {
                                debugPrint('🔙 Returning to login');
                                Navigator.pop(context);
                              },
                        child: const Text(
                          'Back to Login',
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
