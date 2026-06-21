// lib/features/prescription/services/medication_service.dart
import 'dart:convert';
import 'dart:developer' as developer;
import '../../../core/services/api_service.dart';
import '../models/medication.dart';

class MedicationService {
  final ApiService _apiService = ApiService();

  // Base URL pour le service de médicaments
  static const String _baseUrl = '/api/medications';

  /// Récupérer tous les médicaments
  Future<List<Medication>> getAllMedications() async {
    try {
      developer.log('Fetching all medications', name: 'MedicationService');

      final response = await _apiService.get(
        '$_baseUrl/',
        requireAuth: true,
      );

      developer.log('Response status: ${response.statusCode}',
          name: 'MedicationService');
      developer.log('Response body: ${response.body}',
          name: 'MedicationService');

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => Medication.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load medications: ${response.statusCode}');
      }
    } catch (e) {
      developer.log('Error fetching medications: $e',
          name: 'MedicationService');
      throw Exception('Error fetching medications: $e');
    }
  }

  /// Rechercher des médicaments
  Future<List<Medication>> searchMedications(String query) async {
    try {
      developer.log('Searching medications with query: $query',
          name: 'MedicationService');

      final response = await _apiService.get(
        '$_baseUrl/search',
        queryParams: {'q': query},
        requireAuth: true,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => Medication.fromJson(json)).toList();
      } else {
        throw Exception('Failed to search medications: ${response.statusCode}');
      }
    } catch (e) {
      developer.log('Error searching medications: $e',
          name: 'MedicationService');
      throw Exception('Error searching medications: $e');
    }
  }

  /// Créer un nouveau médicament
  Future<Medication> createMedication(
      Map<String, dynamic> medicationData) async {
    try {
      developer.log('Creating medication with data: $medicationData',
          name: 'MedicationService');

      final response = await _apiService.post(
        '$_baseUrl/',
        medicationData,
        requireAuth: true,
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return Medication.fromJson(data);
      } else {
        final errorBody = response.body;
        throw Exception(
            'Failed to create medication: ${response.statusCode} - $errorBody');
      }
    } catch (e) {
      developer.log('Error creating medication: $e', name: 'MedicationService');
      throw Exception('Error creating medication: $e');
    }
  }

  /// Mettre à jour un médicament
  Future<Medication> updateMedication(
      String id, Map<String, dynamic> medicationData) async {
    try {
      developer.log('Updating medication $id with data: $medicationData',
          name: 'MedicationService');

      final response = await _apiService.put(
        '$_baseUrl/$id',
        medicationData,
        requireAuth: true,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return Medication.fromJson(data);
      } else {
        throw Exception('Failed to update medication: ${response.statusCode}');
      }
    } catch (e) {
      developer.log('Error updating medication: $e', name: 'MedicationService');
      throw Exception('Error updating medication: $e');
    }
  }

  /// Supprimer un médicament
  Future<bool> deleteMedication(String id) async {
    try {
      developer.log('Deleting medication: $id', name: 'MedicationService');

      final response = await _apiService.delete(
        '$_baseUrl/$id',
        requireAuth: true,
      );

      return response.statusCode == 200;
    } catch (e) {
      developer.log('Error deleting medication: $e', name: 'MedicationService');
      throw Exception('Error deleting medication: $e');
    }
  }

  /// Obtenir un médicament par ID
  Future<Medication> getMedicationById(String id) async {
    try {
      developer.log('Fetching medication by ID: $id',
          name: 'MedicationService');

      final response = await _apiService.get(
        '$_baseUrl/$id',
        requireAuth: true,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return Medication.fromJson(data);
      } else {
        throw Exception('Failed to load medication: ${response.statusCode}');
      }
    } catch (e) {
      developer.log('Error fetching medication by ID: $e',
          name: 'MedicationService');
      throw Exception('Error fetching medication: $e');
    }
  }
}
