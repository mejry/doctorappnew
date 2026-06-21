// lib/features/prescription/services/prescription_service.dart - MISE À JOUR AVEC SUPPORT DRAFT
import 'dart:convert';
import 'dart:developer' as developer;
import '../../../core/services/api_service.dart';
import '../models/prescription.dart';
import '../models/ai_suggestion.dart'; // NOUVEAU IMPORT

class PrescriptionService {
  final ApiService _apiService = ApiService();

  // Base URL pour le service de prescription
  static const String _baseUrl = '/api/prescriptions';

  /// 🆕 NOUVELLE MÉTHODE: Obtenir les suggestions IA
  Future<AISuggestionsResponse> getAISuggestions(String consultationId) async {
    try {
      developer.log('Getting AI suggestions for consultation: $consultationId',
          name: 'PrescriptionService');

      final response = await _apiService.get(
        '$_baseUrl/ai-suggestions/$consultationId',
        requireAuth: true,
      );

      developer.log('AI suggestions response: ${response.statusCode}',
          name: 'PrescriptionService');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return AISuggestionsResponse.fromJson(data);
      } else {
        throw Exception(
            'Failed to get AI suggestions: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      developer.log('Error getting AI suggestions: $e',
          name: 'PrescriptionService');

      // Retourner une réponse d'erreur mais utilisable
      return AISuggestionsResponse(
        success: false,
        consultationId: consultationId,
        suggestions: [],
        aiAvailable: false,
        totalMedications: 0,
        error: e.toString(),
      );
    }
  }

  /// 🆕 NOUVELLE MÉTHODE: Créer une prescription vide (draft)
  Future<Prescription> createEmptyPrescription(String consultationId) async {
    try {
      final emptyPrescriptionData = {
        'consultation': consultationId,
        'prescriptionInfo': {
          'type': 'Regular',
          'status': 'Draft', // Status draft pour prescription vide
          'date': DateTime.now().toIso8601String(),
          'time': _formatCurrentTime(),
          'validityDays': 30,
          'notes': 'Prescription to be completed',
        },
        'medications': <Map<String, dynamic>>[],
      };

      developer.log(
          'Creating empty prescription for consultation: $consultationId',
          name: 'PrescriptionService');

      return await createPrescription(emptyPrescriptionData);
    } catch (e) {
      developer.log('Error creating empty prescription: $e',
          name: 'PrescriptionService');
      throw Exception('Error creating empty prescription: $e');
    }
  }

  /// Créer une nouvelle prescription
  Future<Prescription> createPrescription(
      Map<String, dynamic> prescriptionData) async {
    try {
      developer.log('Creating prescription with data: $prescriptionData',
          name: 'PrescriptionService');

      final response = await _apiService.post(
        '$_baseUrl/',
        prescriptionData,
        requireAuth: true,
      );

      developer.log('Response status: ${response.statusCode}',
          name: 'PrescriptionService');
      developer.log('Response body: ${response.body}',
          name: 'PrescriptionService');

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return Prescription.fromJson(data);
      } else {
        final errorBody = response.body;
        developer.log('Failed to create prescription: $errorBody',
            name: 'PrescriptionService');
        throw Exception(
            'Failed to create prescription: ${response.statusCode} - $errorBody');
      }
    } catch (e) {
      developer.log('Error creating prescription: $e',
          name: 'PrescriptionService');
      throw Exception('Error creating prescription: $e');
    }
  }

  /// 🆕 NOUVELLE MÉTHODE: Activer une prescription draft
  Future<Prescription> activateDraftPrescription(
      String prescriptionId, Map<String, dynamic> prescriptionData) async {
    try {
      // Mettre le status à 'Active' au lieu de 'Draft'
      if (prescriptionData.containsKey('prescriptionInfo')) {
        prescriptionData['prescriptionInfo']['status'] = 'Active';
      }

      developer.log('Activating draft prescription: $prescriptionId',
          name: 'PrescriptionService');

      return await updatePrescription(prescriptionId, prescriptionData);
    } catch (e) {
      developer.log('Error activating draft prescription: $e',
          name: 'PrescriptionService');
      throw Exception('Error activating prescription: $e');
    }
  }

  /// Obtenir toutes les prescriptions
  Future<List<Prescription>> getAllPrescriptions() async {
    try {
      final response = await _apiService.get(
        '$_baseUrl/',
        requireAuth: true,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => Prescription.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load prescriptions: ${response.statusCode}');
      }
    } catch (e) {
      developer.log('Error fetching prescriptions: $e',
          name: 'PrescriptionService');
      throw Exception('Error fetching prescriptions: $e');
    }
  }

  /// 🆕 NOUVELLE MÉTHODE: Obtenir les prescriptions draft
  Future<List<Prescription>> getDraftPrescriptions() async {
    try {
      final response = await _apiService.get(
        '$_baseUrl?status=Draft',
        requireAuth: true,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => Prescription.fromJson(json)).toList();
      } else {
        throw Exception(
            'Failed to load draft prescriptions: ${response.statusCode}');
      }
    } catch (e) {
      developer.log('Error fetching draft prescriptions: $e',
          name: 'PrescriptionService');
      throw Exception('Error fetching draft prescriptions: $e');
    }
  }

  /// Obtenir une prescription par ID
  Future<Prescription> getPrescriptionById(String id) async {
    try {
      final response = await _apiService.get(
        '$_baseUrl/$id',
        requireAuth: true,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return Prescription.fromJson(data);
      } else {
        throw Exception('Failed to load prescription: ${response.statusCode}');
      }
    } catch (e) {
      developer.log('Error fetching prescription by ID: $e',
          name: 'PrescriptionService');
      throw Exception('Error fetching prescription: $e');
    }
  }

  /// Obtenir les prescriptions par consultation
  Future<List<Prescription>> getPrescriptionsByConsultation(
      String consultationId) async {
    try {
      final response = await _apiService.get(
        '$_baseUrl/consultation/$consultationId',
        requireAuth: true,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => Prescription.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load prescriptions: ${response.statusCode}');
      }
    } catch (e) {
      developer.log('Error fetching prescriptions by consultation: $e',
          name: 'PrescriptionService');
      throw Exception('Error fetching prescriptions: $e');
    }
  }

  /// Mettre à jour une prescription
  Future<Prescription> updatePrescription(
      String id, Map<String, dynamic> prescriptionData) async {
    try {
      final response = await _apiService.put(
        '$_baseUrl/$id',
        prescriptionData,
        requireAuth: true,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return Prescription.fromJson(data);
      } else {
        throw Exception(
            'Failed to update prescription: ${response.statusCode}');
      }
    } catch (e) {
      developer.log('Error updating prescription: $e',
          name: 'PrescriptionService');
      throw Exception('Error updating prescription: $e');
    }
  }

  /// Supprimer une prescription
  Future<bool> deletePrescription(String id) async {
    try {
      final response = await _apiService.delete(
        '$_baseUrl/$id',
        requireAuth: true,
      );
      return response.statusCode == 200;
    } catch (e) {
      developer.log('Error deleting prescription: $e',
          name: 'PrescriptionService');
      throw Exception('Error deleting prescription: $e');
    }
  }

  /// Rechercher des prescriptions
  Future<List<Prescription>> searchPrescriptions(String query) async {
    try {
      final response = await _apiService.get(
        '$_baseUrl/search?q=${Uri.encodeComponent(query)}',
        requireAuth: true,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => Prescription.fromJson(json)).toList();
      } else {
        throw Exception(
            'Failed to search prescriptions: ${response.statusCode}');
      }
    } catch (e) {
      developer.log('Error searching prescriptions: $e',
          name: 'PrescriptionService');
      throw Exception('Error searching prescriptions: $e');
    }
  }

  /// Exporter une prescription en PDF
  Future<bool> exportPrescriptionAsPDF(String id) async {
    try {
      final response = await _apiService.get(
        '$_baseUrl/$id/export',
        requireAuth: true,
      );

      if (response.statusCode == 200) {
        developer.log('Prescription PDF exported successfully',
            name: 'PrescriptionService');
        return true;
      } else {
        throw Exception(
            'Failed to export prescription: ${response.statusCode}');
      }
    } catch (e) {
      developer.log('Error exporting prescription: $e',
          name: 'PrescriptionService');
      throw Exception('Error exporting prescription: $e');
    }
  }

  /// Utilise votre service medication existant
  Future<List<Map<String, dynamic>>> getAvailableMedications() async {
    try {
      // Utilise votre service de médicaments existant
      final response = await _apiService.get(
        '/api/medications',
        requireAuth: true,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.cast<Map<String, dynamic>>();
      } else {
        developer.log('Medication service not available, using fallback',
            name: 'PrescriptionService');
        return _getSimpleFallback();
      }
    } catch (e) {
      developer.log('Error fetching medications: $e',
          name: 'PrescriptionService');
      return _getSimpleFallback();
    }
  }

  /// Fallback simple si service médicament indisponible
  List<Map<String, dynamic>> _getSimpleFallback() {
    return [
      {'id': '1', 'name': 'Custom medication', 'category': 'Other'},
    ];
  }

  /// 🆕 HELPER: Format current time
  String _formatCurrentTime() {
    final now = DateTime.now();
    return '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
  }

  /// 🆕 NOUVELLE MÉTHODE: Vérifier si une consultation a une prescription
  Future<bool> hasConsultationPrescription(String consultationId) async {
    try {
      final prescriptions =
          await getPrescriptionsByConsultation(consultationId);
      return prescriptions.isNotEmpty;
    } catch (e) {
      developer.log('Error checking consultation prescription: $e',
          name: 'PrescriptionService');
      return false;
    }
  }
}
