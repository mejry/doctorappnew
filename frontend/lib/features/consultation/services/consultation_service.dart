// lib/features/consultation/services/consultation_service.dart
import 'dart:convert';
import 'dart:developer' as developer;
import 'package:frontend/core/services/session_manager.dart'; // ✅ AJOUT
import '../../../core/services/api_service.dart';
import '../../../config/api_config.dart';
import '../models/consultation.dart';

class ConsultationService {
  final ApiService _apiService = ApiService();
  final SessionManager _sessionManager = SessionManager(); // ✅ AJOUT

  // Get all consultations
  Future<List<Consultation>> getAllConsultations() async {
    try {
      // ✅ DEBUG: Vérifier les permissions avant l'appel
      developer.log('🔍 Getting all consultations...',
          name: 'ConsultationService');
      developer.log('🔍 User permissions: ${_sessionManager.permissions}',
          name: 'ConsultationService');
      developer.log(
          '🔍 Has view_consultation: ${_sessionManager.hasPermission("view_consultation")}',
          name: 'ConsultationService');

      final response =
          await _apiService.get('/api/consultations/', requireAuth: true);

      developer.log('📥 Response status: ${response.statusCode}',
          name: 'ConsultationService');

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        developer.log('✅ Successfully loaded ${data.length} consultations',
            name: 'ConsultationService');
        return data.map((json) => Consultation.fromJson(json)).toList();
      } else if (response.statusCode == 403) {
        // ✅ GESTION SPÉCIFIQUE 403
        developer.log(
            '❌ 403 Forbidden - Permission denied for viewing consultations',
            name: 'ConsultationService');
        developer.log('❌ Response body: ${response.body}',
            name: 'ConsultationService');
        throw Exception(
            'Access denied: You do not have permission to view consultations');
      } else {
        developer.log('❌ Failed with status: ${response.statusCode}',
            name: 'ConsultationService');
        developer.log('❌ Response body: ${response.body}',
            name: 'ConsultationService');
        throw Exception('Failed to load consultations: ${response.statusCode}');
      }
    } catch (e) {
      developer.log('❌ Error fetching consultations: $e',
          name: 'ConsultationService');
      throw Exception('Error fetching consultations: $e');
    }
  }

  // Get consultations by patient ID
  Future<List<Consultation>> getConsultationsByPatientId(
      String patientId) async {
    try {
      // ✅ DEBUG AMÉLIORÉ: Logs détaillés
      developer.log('🔍 Getting consultations for patient: $patientId',
          name: 'ConsultationService');
      developer.log('🔍 User permissions: ${_sessionManager.permissions}',
          name: 'ConsultationService');
      developer.log(
          '🔍 Has view_consultation: ${_sessionManager.hasPermission("view_consultation")}',
          name: 'ConsultationService');
      developer.log('🔍 User role: ${_sessionManager.userInfo?['role']}',
          name: 'ConsultationService');
      developer.log('🔍 User ID: ${_sessionManager.userInfo?['id']}',
          name: 'ConsultationService');

      // ✅ VÉRIFICATION PRÉALABLE DES PERMISSIONS
      if (!_sessionManager.hasPermission('view_consultation')) {
        developer.log('❌ No view_consultation permission - blocking request',
            name: 'ConsultationService');
        throw Exception(
            'Access denied: You do not have permission to view consultations');
      }

      final response = await _apiService.get(
        '/api/consultations/patient/$patientId',
        requireAuth: true,
      );

      developer.log('📥 Response status: ${response.statusCode}',
          name: 'ConsultationService');

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        developer.log(
            '✅ Successfully loaded ${data.length} consultations for patient $patientId',
            name: 'ConsultationService');
        return data.map((json) => Consultation.fromJson(json)).toList();
      } else if (response.statusCode == 403) {
        // ✅ GESTION DÉTAILLÉE DE L'ERREUR 403
        developer.log(
            '❌ 403 Forbidden - Backend denied access to patient consultations',
            name: 'ConsultationService');
        developer.log('❌ Response body: ${response.body}',
            name: 'ConsultationService');
        developer.log(
            '❌ Check if backend permission matches frontend: view_consultation',
            name: 'ConsultationService');
        throw Exception(
            'Access denied: Backend rejected request to view patient consultations. Check permissions configuration.');
      } else if (response.statusCode == 404) {
        developer.log('❌ 404 Not Found - Patient or consultations not found',
            name: 'ConsultationService');
        throw Exception('Patient not found or no consultations available');
      } else {
        developer.log('❌ Failed with status: ${response.statusCode}',
            name: 'ConsultationService');
        developer.log('❌ Response body: ${response.body}',
            name: 'ConsultationService');
        throw Exception('Failed to load consultations: ${response.statusCode}');
      }
    } catch (e) {
      developer.log('❌ Error fetching consultations by patient: $e',
          name: 'ConsultationService');
      // ✅ RE-THROW avec message plus clair
      if (e.toString().contains('Access denied')) {
        rethrow; // Garder le message d'erreur spécifique
      }
      throw Exception('Error fetching consultations: $e');
    }
  }

  // Create consultation
  Future<Consultation> createConsultation(Consultation consultation) async {
    try {
      // ✅ DEBUG: Vérifier les permissions pour créer
      developer.log('🔍 Creating consultation...', name: 'ConsultationService');
      developer.log(
          '🔍 Has create_consultation: ${_sessionManager.hasPermission("create_consultation")}',
          name: 'ConsultationService');

      // ✅ VÉRIFICATION PRÉALABLE DES PERMISSIONS
      if (!_sessionManager.hasPermission('create_consultation')) {
        developer.log('❌ No create_consultation permission - blocking request',
            name: 'ConsultationService');
        throw Exception(
            'Access denied: You do not have permission to create consultations');
      }

      final jsonData = consultation.toJson();
      developer.log('Creating consultation with data: $jsonData',
          name: 'ConsultationService');

      final response = await _apiService.post(
        '/api/consultations/',
        jsonData,
        requireAuth: true,
      );

      developer.log('Response status: ${response.statusCode}',
          name: 'ConsultationService');
      developer.log('Response body: ${response.body}',
          name: 'ConsultationService');

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        developer.log('✅ Consultation created successfully',
            name: 'ConsultationService');
        return Consultation.fromJson(data);
      } else if (response.statusCode == 403) {
        developer.log('❌ 403 Forbidden - Backend denied consultation creation',
            name: 'ConsultationService');
        developer.log('❌ Response body: ${response.body}',
            name: 'ConsultationService');
        throw Exception(
            'Access denied: Backend rejected consultation creation');
      } else {
        final errorBody = response.body;
        developer.log('Failed to create consultation: $errorBody',
            name: 'ConsultationService');
        throw Exception(
            'Failed to create consultation: ${response.statusCode} - $errorBody');
      }
    } catch (e) {
      developer.log('Error creating consultation: $e',
          name: 'ConsultationService');
      if (e.toString().contains('Access denied')) {
        rethrow;
      }
      throw Exception('Error creating consultation: $e');
    }
  }

  // Get consultation by ID
  Future<Consultation> getConsultationById(String id) async {
    try {
      // ✅ DEBUG: Logs pour consultation spécifique
      developer.log('🔍 Getting consultation by ID: $id',
          name: 'ConsultationService');
      developer.log(
          '🔍 Has view_consultation: ${_sessionManager.hasPermission("view_consultation")}',
          name: 'ConsultationService');

      final response = await _apiService.get(
        '/api/consultations/$id',
        requireAuth: true,
      );

      developer.log('📥 Response status: ${response.statusCode}',
          name: 'ConsultationService');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        developer.log('✅ Successfully loaded consultation $id',
            name: 'ConsultationService');
        return Consultation.fromJson(data);
      } else if (response.statusCode == 403) {
        developer.log('❌ 403 Forbidden - Access denied for consultation $id',
            name: 'ConsultationService');
        throw Exception(
            'Access denied: You do not have permission to view this consultation');
      } else if (response.statusCode == 404) {
        developer.log('❌ 404 Not Found - Consultation $id not found',
            name: 'ConsultationService');
        throw Exception('Consultation not found');
      } else {
        developer.log('❌ Failed with status: ${response.statusCode}',
            name: 'ConsultationService');
        throw Exception('Failed to load consultation: ${response.statusCode}');
      }
    } catch (e) {
      developer.log('Error fetching consultation by ID: $e',
          name: 'ConsultationService');
      if (e.toString().contains('Access denied') ||
          e.toString().contains('not found')) {
        rethrow;
      }
      throw Exception('Error fetching consultation: $e');
    }
  }

  // Update consultation
  Future<Consultation> updateConsultation(
      String id, Consultation consultation) async {
    try {
      // ✅ DEBUG: Vérifier les permissions pour mettre à jour
      developer.log('🔍 Updating consultation: $id',
          name: 'ConsultationService');
      developer.log(
          '🔍 Has update_consultation: ${_sessionManager.hasPermission("update_consultation")}',
          name: 'ConsultationService');

      if (!_sessionManager.hasPermission('update_consultation')) {
        developer.log('❌ No update_consultation permission - blocking request',
            name: 'ConsultationService');
        throw Exception(
            'Access denied: You do not have permission to update consultations');
      }

      final response = await _apiService.put(
        '/api/consultations/$id',
        consultation.toJson(),
        requireAuth: true,
      );

      developer.log('📥 Response status: ${response.statusCode}',
          name: 'ConsultationService');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        developer.log('✅ Consultation updated successfully',
            name: 'ConsultationService');
        return Consultation.fromJson(data);
      } else if (response.statusCode == 403) {
        developer.log('❌ 403 Forbidden - Backend denied consultation update',
            name: 'ConsultationService');
        throw Exception('Access denied: Backend rejected consultation update');
      } else {
        developer.log('❌ Failed with status: ${response.statusCode}',
            name: 'ConsultationService');
        throw Exception(
            'Failed to update consultation: ${response.statusCode}');
      }
    } catch (e) {
      developer.log('Error updating consultation: $e',
          name: 'ConsultationService');
      if (e.toString().contains('Access denied')) {
        rethrow;
      }
      throw Exception('Error updating consultation: $e');
    }
  }

  // Delete consultation
  Future<bool> deleteConsultation(String id) async {
    try {
      // ✅ DEBUG: Vérifier les permissions pour supprimer
      developer.log('🔍 Deleting consultation: $id',
          name: 'ConsultationService');
      developer.log(
          '🔍 Has delete_consultation: ${_sessionManager.hasPermission("delete_consultation")}',
          name: 'ConsultationService');

      if (!_sessionManager.hasPermission('delete_consultation')) {
        developer.log('❌ No delete_consultation permission - blocking request',
            name: 'ConsultationService');
        throw Exception(
            'Access denied: You do not have permission to delete consultations');
      }

      final response = await _apiService.delete(
        '/api/consultations/$id',
        requireAuth: true,
      );

      developer.log('📥 Response status: ${response.statusCode}',
          name: 'ConsultationService');

      if (response.statusCode == 200) {
        developer.log('✅ Consultation deleted successfully',
            name: 'ConsultationService');
        return true;
      } else if (response.statusCode == 403) {
        developer.log('❌ 403 Forbidden - Backend denied consultation deletion',
            name: 'ConsultationService');
        throw Exception(
            'Access denied: Backend rejected consultation deletion');
      } else {
        developer.log('❌ Failed with status: ${response.statusCode}',
            name: 'ConsultationService');
        return false;
      }
    } catch (e) {
      developer.log('Error deleting consultation: $e',
          name: 'ConsultationService');
      if (e.toString().contains('Access denied')) {
        rethrow;
      }
      throw Exception('Error deleting consultation: $e');
    }
  }

  // Search consultations
  Future<List<Consultation>> searchConsultations(String query) async {
    try {
      // ✅ DEBUG: Vérifier les permissions pour rechercher
      developer.log('🔍 Searching consultations with query: $query',
          name: 'ConsultationService');
      developer.log(
          '🔍 Has view_consultation: ${_sessionManager.hasPermission("view_consultation")}',
          name: 'ConsultationService');

      if (!_sessionManager.hasPermission('view_consultation')) {
        developer.log('❌ No view_consultation permission - blocking search',
            name: 'ConsultationService');
        throw Exception(
            'Access denied: You do not have permission to search consultations');
      }

      final response = await _apiService.get(
        '/api/consultations/search?q=$query',
        requireAuth: true,
      );

      developer.log('📥 Response status: ${response.statusCode}',
          name: 'ConsultationService');

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        developer.log('✅ Found ${data.length} consultations matching "$query"',
            name: 'ConsultationService');
        return data.map((json) => Consultation.fromJson(json)).toList();
      } else if (response.statusCode == 403) {
        developer.log('❌ 403 Forbidden - Backend denied consultation search',
            name: 'ConsultationService');
        throw Exception('Access denied: Backend rejected consultation search');
      } else {
        developer.log('❌ Failed with status: ${response.statusCode}',
            name: 'ConsultationService');
        throw Exception(
            'Failed to search consultations: ${response.statusCode}');
      }
    } catch (e) {
      developer.log('Error searching consultations: $e',
          name: 'ConsultationService');
      if (e.toString().contains('Access denied')) {
        rethrow;
      }
      throw Exception('Error searching consultations: $e');
    }
  }

  // ✅ NOUVELLE MÉTHODE: Vérifier les permissions avant appel
  bool canViewConsultations() {
    return _sessionManager.hasPermission('view_consultation');
  }

  bool canCreateConsultations() {
    return _sessionManager.hasPermission('create_consultation');
  }

  bool canUpdateConsultations() {
    return _sessionManager.hasPermission('update_consultation');
  }

  bool canDeleteConsultations() {
    return _sessionManager.hasPermission('delete_consultation');
  }
}
