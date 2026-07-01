// lib/features/auth/providers/auth_provider.dart - VERSION AVEC DEBUG 2FA
import 'package:flutter/foundation.dart';
import 'package:frontend/core/models/user.dart';
import 'package:frontend/core/services/session_manager.dart';
import 'package:frontend/features/auth/services/auth_api_service.dart';
import 'package:frontend/features/auth/models/login_request.dart';
import 'package:frontend/features/auth/models/login_response.dart';
import 'package:frontend/features/auth/models/two_factor_request.dart';
import 'package:frontend/features/auth/models/forgot_password_request.dart';

enum AuthStatus {
  initial,
  loading,
  authenticated,
  twoFactorRequired,
  unauthenticated,
  error,
}

class AuthProvider with ChangeNotifier {
  final AuthApiService _authApiService = AuthApiService();
  final SessionManager _sessionManager = SessionManager();

  AuthStatus _status = AuthStatus.initial;
  User? _user;
  String? _errorMessage;
  String? _tempUserEmail;
  String? _tempUserId;

  // Getters
  AuthStatus get status => _status;
  bool get isAuthenticated => _status == AuthStatus.authenticated;
  bool get isLoading => _status == AuthStatus.loading;
  User? get user => _user;
  String? get errorMessage => _errorMessage;
  String? get tempUserEmail => _tempUserEmail;
  String? get tempUserId => _tempUserId;

  // Session Manager getters
  bool get hasSession => _sessionManager.isAuthenticated;
  List<String> get permissions => _sessionManager.permissions;

  AuthProvider() {
    _initializeAuth();
  }

  /// Initialise l'authentification au démarrage
  Future<void> _initializeAuth() async {
    debugPrint('🚀 Initializing AuthProvider...');

    try {
      _setStatus(AuthStatus.loading);

      // Tenter de restaurer la session depuis le storage
      final hasValidSession = await _sessionManager.initializeSession();

      if (hasValidSession) {
        debugPrint('✅ Valid session found, restoring user...');
        await _restoreUserFromSession();
      } else {
        debugPrint('❌ No valid session found');
        _setStatus(AuthStatus.unauthenticated);
      }
    } catch (e) {
      debugPrint('❌ Error initializing auth: $e');
      _setStatus(AuthStatus.unauthenticated);
    }
  }

  /// Restaure l'utilisateur depuis la session
  Future<void> _restoreUserFromSession() async {
    try {
      final userInfo = _sessionManager.userInfo;
      if (userInfo != null) {
        // Créer un objet User depuis les données de session
        _user = User(
          id: userInfo['id'] ?? '',
          email: userInfo['email'] ?? '',
          firstname: userInfo['firstname'] ?? userInfo['email'] ?? '',
          lastname: userInfo['lastname'] ?? '',
          role: userInfo['role'] ?? '',
          allPermissions: _sessionManager.permissions,
          allRoleNames: [userInfo['role'] ?? ''],
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          specialite: userInfo['specialite'],
        );

        debugPrint('✅ User restored from session: ${_user!.email}');
        _setStatus(AuthStatus.authenticated);
      } else {
        throw Exception('No user info in session');
      }
    } catch (e) {
      debugPrint('❌ Error restoring user from session: $e');
      await _sessionManager.clearSession();
      _setStatus(AuthStatus.unauthenticated);
    }
  }

  /// Login - Étape 1
  Future<bool> login(String email, String password) async {
    try {
      debugPrint('🔐 Attempting login for: $email');
      _setStatus(AuthStatus.loading);
      _clearError();

      final request = LoginRequest(email: email, password: password);
      final response = await _authApiService.login(request);

      debugPrint('🔍 ========== LOGIN RESPONSE DEBUG ==========');
      debugPrint('🔍 API Response success: ${response.success}');
      debugPrint('🔍 API Response error: ${response.error}');
      debugPrint('🔍 API Response data null: ${response.data == null}');

      if (response.data != null) {
        final loginData = response.data!;
        debugPrint(
            '🔍 Login data twoFactorRequired: ${loginData.twoFactorRequired}');
        debugPrint('🔍 Login data userId: ${loginData.userId}');
        debugPrint(
            '🔍 Login data hasAccessToken: ${loginData.accessToken != null}');
        debugPrint('🔍 Login data hasUser: ${loginData.user != null}');
      }
      debugPrint('🔍 ========================================');

      // ✅ CORRIGÉ: Traiter la réponse peu importe success
      if (response.data != null) {
        final loginData = response.data!;

        if (loginData.twoFactorRequired == true) {
          // ✅ 2FA requis - Sauvegarder les données temporaires
          _tempUserEmail = email;
          _tempUserId = loginData.userId;
          debugPrint('📱 Setting 2FA status...');
          debugPrint('📱 Temp email: $_tempUserEmail');
          debugPrint('📱 Temp userId: $_tempUserId');
          _setStatus(AuthStatus.twoFactorRequired);
          debugPrint('📱 Status set to: $_status');
          return true; // ✅ Retourner true car 2FA est un succès partiel
        } else if (loginData.accessToken != null && loginData.user != null) {
          // Login direct (pas de 2FA)
          await _handleSuccessfulLogin(loginData);
          return true;
        }
      }

      // ✅ Cas d'erreur
      _setError(response.error ?? 'Login failed');
      debugPrint('❌ Setting error status: ${response.error}');
      return false;
    } catch (e) {
      debugPrint('❌ Login exception: $e');
      _setError('Login failed: $e');
      return false;
    }
  }

  /// Vérification 2FA - Étape 2
  Future<bool> verify2FA(String code) async {
    try {
      debugPrint('🔢 Verifying 2FA code for user: $_tempUserId');
      _setStatus(AuthStatus.loading);
      _clearError();

      if (_tempUserId == null) {
        _setError('No pending 2FA verification');
        return false;
      }

      final request = TwoFactorRequest(userId: _tempUserId!, code: code);
      final response = await _authApiService.verify2FA(request);

      if (response.success && response.data != null) {
        debugPrint('✅ 2FA verification successful');
        await _handleSuccessfulLogin(response.data!);
        _clearTempData();
        return true;
      } else {
        _setError(response.error ?? '2FA verification failed');
        return false;
      }
    } catch (e) {
      debugPrint('❌ 2FA verification error: $e');
      _setError('2FA verification failed: $e');
      return false;
    }
  }

  /// Gère le login réussi (avec ou sans 2FA)
  Future<void> _handleSuccessfulLogin(LoginResponse loginData) async {
    try {
      debugPrint('✅ Handling successful login');

      // Vérifier que nous avons tous les tokens et l'utilisateur
      if (loginData.accessToken == null ||
          loginData.refreshToken == null ||
          loginData.user == null) {
        throw Exception('Incomplete login data');
      }

      // Sauvegarder la session
      await _sessionManager.saveSession(
        accessToken: loginData.accessToken!,
        refreshToken: loginData.refreshToken!,
        serviceToken: loginData.serviceToken ?? '',
        userData: loginData.user!.toJson(),
      );

      // Mettre à jour l'état local
      _user = loginData.user!;
      _setStatus(AuthStatus.authenticated);

      debugPrint('🎉 Login successful for: ${_user!.email}');
    } catch (e) {
      debugPrint('❌ Error handling successful login: $e');
      _setError('Failed to complete login: $e');
    }
  }

  /// Mot de passe oublié
  Future<bool> forgotPassword(String email) async {
    try {
      debugPrint('📧 Sending password reset for: $email');
      _clearError();

      final request = ForgotPasswordRequest(email: email);
      final response = await _authApiService.forgotPassword(request);

      if (response.success) {
        debugPrint('✅ Password reset email sent successfully');
        return true;
      } else {
        _setError(response.error ?? 'Failed to send reset email');
        return false;
      }
    } catch (e) {
      debugPrint('❌ Forgot password error: $e');
      _setError('Failed to send reset email: $e');
      return false;
    }
  }

  /// Renvoyer le code 2FA
  Future<bool> resend2FACode() async {
    try {
      if (_tempUserEmail == null) {
        _setError('No email available for resend');
        return false;
      }

      final response = await _authApiService.resend2FACode(_tempUserEmail!);
      return response.success;
    } catch (e) {
      debugPrint('❌ Resend 2FA error: $e');
      _setError('Failed to resend code: $e');
      return false;
    }
  }

  /// Déconnexion rapide
  Future<void> logout() async {
    try {
      debugPrint('🚪 Logging out user: ${_user?.email}');

      _user = null;
      _clearTempData();
      _clearError();
      _setStatus(AuthStatus.unauthenticated);

      await _sessionManager.clearSession();

      Future.microtask(() async {
        try {
          await _authApiService.logout();
          debugPrint('✅ Server logout completed');
        } catch (e) {
          debugPrint('⚠️ Server logout failed: $e');
        }
      });

      debugPrint('✅ Logout completed');
    } catch (e) {
      debugPrint('❌ Logout error: $e');
      _user = null;
      _clearTempData();
      _setStatus(AuthStatus.unauthenticated);
      await _sessionManager.clearSession();
    }
  }

  /// Met à jour les informations utilisateur
  void updateUser(User updatedUser) {
    _user = updatedUser;
    _sessionManager.updateUserInfo(updatedUser.toJson());
    notifyListeners();
  }

  // Méthodes pour les permissions
  bool hasPermission(String permission) {
    return _sessionManager.hasPermission(permission);
  }

  bool hasAnyPermission(List<String> permissions) {
    return _sessionManager.hasAnyPermission(permissions);
  }

  bool hasAllPermissions(List<String> permissions) {
    return _sessionManager.hasAllPermissions(permissions);
  }

  bool hasRole(String role) {
    return _sessionManager.hasRole(role);
  }

// Getters pour les permissions communes - VERSION AVEC MEDICATIONS
  bool get canViewUsers => hasPermission('view_user');
  bool get canCreateUser => hasPermission('create_user');
  bool get canUpdateUser => hasPermission('update_user');
  bool get canDeleteUser => hasPermission('delete_user');
  bool get canViewRoles => hasPermission('view_role');
  bool get canCreateRole => hasPermission('create_role');
  bool get canUpdateRole => hasPermission('update_role');
  bool get canDeleteRole => hasPermission('delete_role');
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

  // ✅ AJOUT: Medication permissions
  bool get canViewMedications => hasPermission('view_medication');
  bool get canCreateMedication => hasPermission('create_medication');
  bool get canUpdateMedication => hasPermission('update_medication');
  bool get canDeleteMedication => hasPermission('delete_medication');
  // Appointment permissions
  bool get canViewAppointments => hasPermission('view_appointment');
  bool get canCreateAppointment => hasPermission('create_appointment');
  bool get canUpdateAppointment => hasPermission('update_appointment');
  bool get canCancelAppointment => hasPermission('cancel_appointment');
  // Méthodes privées
  void _setStatus(AuthStatus status) {
    debugPrint('🔄 Status change: $_status → $status');
    _status = status;
    notifyListeners();
  }

  void _setError(String error) {
    debugPrint('❌ Setting error: $error');
    _errorMessage = error;
    _status = AuthStatus.error;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
  }

  void _clearTempData() {
    _tempUserEmail = null;
    _tempUserId = null;
  }

  @override
  void dispose() {
    _sessionManager.dispose();
    super.dispose();
  }
}
