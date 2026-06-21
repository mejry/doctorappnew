// lib/core/services/session_manager.dart - VERSION OPTIMISÉE
import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:frontend/core/services/storage_service.dart';
import 'package:frontend/core/services/api_service.dart';
import 'package:frontend/features/auth/services/auth_api_service.dart';
import 'package:jwt_decoder/jwt_decoder.dart';

class SessionManager {
  static final SessionManager _instance = SessionManager._internal();
  factory SessionManager() => _instance;
  SessionManager._internal();

  final StorageService _storage = StorageService();
  final ApiService _api = ApiService();
  final AuthApiService _authApi = AuthApiService();

  // Session state
  String? _accessToken;
  String? _refreshToken;
  Map<String, dynamic>? _userInfo;
  List<String> _permissions = [];
  Timer? _refreshTimer;

  // Stream controllers pour notifier les changements
  final StreamController<bool> _authStateController =
      StreamController<bool>.broadcast();
  final StreamController<List<String>> _permissionsController =
      StreamController<List<String>>.broadcast();

  // Getters
  bool get isAuthenticated =>
      _accessToken != null && !isTokenExpired(_accessToken!);
  String? get accessToken => _accessToken;
  String? get refreshToken => _refreshToken;
  Map<String, dynamic>? get userInfo => _userInfo;
  List<String> get permissions => List.unmodifiable(_permissions);

  // Streams
  Stream<bool> get authStateStream => _authStateController.stream;
  Stream<List<String>> get permissionsStream => _permissionsController.stream;

  /// Initialise la session depuis le storage local
  Future<bool> initializeSession() async {
    try {
      debugPrint('📱 Initializing session...');

      // Récupérer les tokens stockés
      _accessToken = await _storage.getToken();
      _refreshToken = await _storage.getRefreshToken();

      if (_accessToken == null || _refreshToken == null) {
        debugPrint('❌ No stored tokens found');
        return false;
      }

      // Vérifier si l'access token est expiré
      if (isTokenExpired(_accessToken!)) {
        debugPrint('🔄 Access token expired, attempting refresh...');
        final refreshed = await _refreshAccessToken();
        if (!refreshed) {
          debugPrint('❌ Failed to refresh token');
          await clearSession();
          return false;
        }
      }

      // Extraire les informations utilisateur et permissions du token
      await _extractTokenData();

      // Configurer l'auto-refresh
      _setupAutoRefresh();

      // Configurer l'API service avec les tokens
      _api.setTokens(_accessToken!, _refreshToken!);

      debugPrint('✅ Session initialized successfully');
      _authStateController.add(true);
      return true;
    } catch (e) {
      debugPrint('❌ Error initializing session: $e');
      await clearSession();
      return false;
    }
  }

  /// Sauvegarde une nouvelle session après login
  Future<void> saveSession({
    required String accessToken,
    required String refreshToken,
    required String serviceToken,
    required Map<String, dynamic> userData,
  }) async {
    try {
      debugPrint('💾 Saving new session...');

      _accessToken = accessToken;
      _refreshToken = refreshToken;

      // Sauvegarder dans le storage
      await _storage.saveToken(accessToken);
      await _storage.saveRefreshToken(refreshToken);
      await _storage.saveUserData(jsonEncode(userData));

      // Extraire les données du token
      await _extractTokenData();

      // Configurer l'auto-refresh
      _setupAutoRefresh();

      // Configurer l'API service
      _api.setTokens(accessToken, refreshToken);

      debugPrint('✅ Session saved successfully');
      _authStateController.add(true);
    } catch (e) {
      debugPrint('❌ Error saving session: $e');
      throw Exception('Failed to save session: $e');
    }
  }

  /// Extrait les données utilisateur et permissions du JWT
  Future<void> _extractTokenData() async {
    if (_accessToken == null) return;

    try {
      final decodedToken = JwtDecoder.decode(_accessToken!);

      // Extraire les informations utilisateur
      _userInfo = {
        'id': decodedToken['id'] ?? decodedToken['userId'],
        'email': decodedToken['email'],
        'firstname': decodedToken['firstname'],
        'lastname': decodedToken['lastname'],
        'role': decodedToken['role'],
        'permissions': decodedToken['permissions'] ?? [],
        'specialite': decodedToken['specialite'],
      };

      // Extraire les permissions
      _permissions = List<String>.from(decodedToken['permissions'] ?? []);

      debugPrint('👤 User: ${_userInfo?['email']}');
      debugPrint('🔑 Role: ${_userInfo?['role']}');
      debugPrint('🛡️ Permissions: $_permissions');

      _permissionsController.add(_permissions);
    } catch (e) {
      debugPrint('❌ Error extracting token data: $e');
      throw Exception('Invalid token format');
    }
  }

  /// Configure le refresh automatique du token
  void _setupAutoRefresh() {
    _refreshTimer?.cancel();

    if (_accessToken == null) return;

    try {
      final decodedToken = JwtDecoder.decode(_accessToken!);
      final exp = decodedToken['exp'] as int;
      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;

      // Calculer le temps restant avant expiration (en secondes)
      final timeUntilExpiry = exp - now;

      // Programmer le refresh 2 minutes avant l'expiration
      final refreshTime = timeUntilExpiry - 120; // 2 minutes avant

      if (refreshTime > 0) {
        debugPrint('⏰ Auto-refresh scheduled in ${refreshTime}s');
        _refreshTimer = Timer(Duration(seconds: refreshTime), () {
          _refreshAccessToken();
        });
      } else {
        // Token expire bientôt, refresh immédiatement
        debugPrint('⚡ Token expires soon, refreshing immediately');
        _refreshAccessToken();
      }
    } catch (e) {
      debugPrint('❌ Error setting up auto-refresh: $e');
    }
  }

  /// Refresh l'access token
  Future<bool> _refreshAccessToken() async {
    if (_refreshToken == null) return false;

    try {
      debugPrint('🔄 Refreshing access token...');

      final response = await _authApi.refreshToken(_refreshToken!);

      if (response.success && response.data != null) {
        final newAccessToken = response.data!.accessToken;

        if (newAccessToken != null) {
          _accessToken = newAccessToken;
          await _storage.saveToken(newAccessToken);

          // Extraire les nouvelles données
          await _extractTokenData();

          // Reconfigurer l'auto-refresh
          _setupAutoRefresh();

          // Mettre à jour l'API service
          _api.setTokens(newAccessToken, _refreshToken!);

          debugPrint('✅ Token refreshed successfully');
          return true;
        }
      }

      debugPrint('❌ Failed to refresh token: ${response.error}');
      return false;
    } catch (e) {
      debugPrint('❌ Error refreshing token: $e');
      return false;
    }
  }

  /// Vérifie si un token est expiré
  bool isTokenExpired(String token) {
    try {
      return JwtDecoder.isExpired(token);
    } catch (e) {
      debugPrint('❌ Error checking token expiration: $e');
      return true; // Considérer comme expiré si erreur
    }
  }

  /// Vérifie si l'utilisateur a une permission spécifique
  bool hasPermission(String permission) {
    return _permissions.contains(permission);
  }

  /// Vérifie si l'utilisateur a au moins une des permissions
  bool hasAnyPermission(List<String> permissions) {
    return permissions.any((perm) => _permissions.contains(perm));
  }

  /// Vérifie si l'utilisateur a toutes les permissions
  bool hasAllPermissions(List<String> permissions) {
    return permissions.every((perm) => _permissions.contains(perm));
  }

  /// Vérifie si l'utilisateur a un rôle spécifique
  bool hasRole(String role) {
    return _userInfo?['role']?.toLowerCase() == role.toLowerCase();
  }

  /// Met à jour les informations utilisateur
  Future<void> updateUserInfo(Map<String, dynamic> newUserInfo) async {
    try {
      _userInfo = {..._userInfo ?? {}, ...newUserInfo};
      await _storage.saveUserData(jsonEncode(_userInfo));
      debugPrint('✅ User info updated');
    } catch (e) {
      debugPrint('❌ Error updating user info: $e');
    }
  }

  /// ✅ OPTIMISÉ: Nettoie la session rapidement (logout)
  Future<void> clearSession() async {
    try {
      debugPrint('🧹 Clearing session...');

      // Annuler le timer de refresh immédiatement
      _refreshTimer?.cancel();
      _refreshTimer = null;

      // Nettoyer les variables en mémoire
      _accessToken = null;
      _refreshToken = null;
      _userInfo = null;
      _permissions.clear();

      // Nettoyer l'API service
      _api.clearTokens();

      // Notifier immédiatement les listeners
      _authStateController.add(false);
      _permissionsController.add([]);

      // ✅ OPTIMISÉ: Nettoyer le storage en arrière-plan (non bloquant)
      Future.microtask(() async {
        try {
          await _storage.clearAll();
          debugPrint('✅ Storage cleared');
        } catch (e) {
          debugPrint('⚠️ Error clearing storage: $e');
        }
      });

      debugPrint('✅ Session cleared');
    } catch (e) {
      debugPrint('❌ Error clearing session: $e');
    }
  }

  /// Nettoie les ressources
  void dispose() {
    _refreshTimer?.cancel();
    _authStateController.close();
    _permissionsController.close();
  }
}

// Extension pour les permissions communes - VERSION AVEC MEDICATIONS
extension SessionPermissions on SessionManager {
  // User permissions
  bool get canViewUsers => hasPermission('view_user');
  bool get canCreateUser => hasPermission('create_user');
  bool get canUpdateUser => hasPermission('update_user');
  bool get canDeleteUser => hasPermission('delete_user');

  // Role permissions
  bool get canViewRoles => hasPermission('view_role');
  bool get canCreateRole => hasPermission('create_role');
  bool get canUpdateRole => hasPermission('update_role');
  bool get canDeleteRole => hasPermission('delete_role');

  // Patient permissions
  bool get canViewPatients => hasPermission('view_patient');
  bool get canCreatePatient => hasPermission('create_patient');
  bool get canUpdatePatient => hasPermission('update_patient');
  bool get canDeletePatient => hasPermission('delete_patient');

  // Consultation permissions
  bool get canViewConsultations => hasPermission('view_consultation');
  bool get canCreateConsultation => hasPermission('create_consultation');
  bool get canUpdateConsultation => hasPermission('update_consultation');
  bool get canDeleteConsultation => hasPermission('delete_consultation');

  // Prescription permissions
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
}
