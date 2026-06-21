// lib/features/patient/services/patient_service.dart - VERSION CORRIGÉE
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/services/api_service.dart';
import '../../../config/api_config.dart';
import '../models/patient.dart';
import '../models/medical_history.dart';

class PatientService {
  final ApiService _apiService = ApiService();

  // Get all patients
  Future<List<Patient>> getAllPatients() async {
    try {
      final response =
          await _apiService.get('/api/patients/', requireAuth: true);

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => Patient.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load patients: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching patients: $e');
    }
  }

  // Get patient by ID
  Future<Patient> getPatientById(String id) async {
    try {
      final response =
          await _apiService.get('${ApiConfig.patientByIdEndpoint}/$id');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return Patient.fromJson(data);
      } else {
        throw Exception('Failed to load patient: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching patient: $e');
    }
  }

  // Create patient
  Future<Patient> createPatient(Patient patient) async {
    try {
      final response = await _apiService.post(
        ApiConfig.patientsEndpoint,
        patient.toJson(),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return Patient.fromJson(data);
      } else if (response.statusCode == 500) {
        final error = jsonDecode(response.body);
        if (error['error']?.contains('E11000') == true &&
            error['error']?.contains('email') == true) {
          throw Exception(
              'This email is already registered. Please use a different email.');
        }
        throw Exception('Failed to create patient: ${response.statusCode}');
      } else {
        throw Exception('Failed to create patient: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error creating patient: $e');
    }
  }

  // Update patient
  Future<Patient> updatePatient(String id, Patient patient) async {
    try {
      final response = await _apiService.put(
        '${ApiConfig.patientByIdEndpoint}/$id',
        patient.toJson(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return Patient.fromJson(data);
      } else {
        throw Exception('Failed to update patient: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error updating patient: $e');
    }
  }

  // Delete patient
  Future<bool> deletePatient(String id) async {
    try {
      final response =
          await _apiService.delete('${ApiConfig.patientByIdEndpoint}/$id');
      return response.statusCode == 200;
    } catch (e) {
      throw Exception('Error deleting patient: $e');
    }
  }

  // Search patients
  Future<List<Patient>> searchPatients({
    String? firstName,
    String? lastName,
    String? email,
  }) async {
    try {
      final queryParams = <String, String>{};
      if (firstName != null) queryParams['firstname'] = firstName;
      if (lastName != null) queryParams['lastname'] = lastName;
      if (email != null) queryParams['email'] = email;

      final response = await _apiService.get(
        ApiConfig.searchPatientsEndpoint,
        queryParams: queryParams,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => Patient.fromJson(json)).toList();
      } else {
        throw Exception('Failed to search patients: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error searching patients: $e');
    }
  }

  // Add medical history
  Future<MedicalHistory> addMedicalHistory(
    String patientId,
    MedicalHistory medicalHistory,
  ) async {
    try {
      final response = await _apiService.post(
        '${ApiConfig.patientMedicalHistoryEndpoint}/$patientId/medical-history',
        medicalHistory.toJson(),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return MedicalHistory.fromJson(data);
      } else {
        throw Exception(
            'Failed to add medical history: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error adding medical history: $e');
    }
  }

  // Get medical history by patient ID
  Future<List<MedicalHistory>> getMedicalHistoryByPatientId(
    String patientId,
  ) async {
    try {
      final response = await _apiService.get(
        '${ApiConfig.patientMedicalHistoryEndpoint}/$patientId/medical-history',
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => MedicalHistory.fromJson(json)).toList();
      } else {
        throw Exception(
            'Failed to load medical history: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching medical history: $e');
    }
  }

  // 🆕 Update medical history - MÉTHODE MANQUANTE AJOUTÉE
  Future<MedicalHistory> updateMedicalHistory(
    String id,
    MedicalHistory medicalHistory,
  ) async {
    try {
      final response = await _apiService.put(
        '/api/patients/medical-history/$id', // Endpoint pour update medical history
        medicalHistory.toJson(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return MedicalHistory.fromJson(data);
      } else {
        throw Exception(
            'Failed to update medical history: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error updating medical history: $e');
    }
  }

  // 🆕 Delete medical history
  Future<bool> deleteMedicalHistory(String id) async {
    try {
      final response =
          await _apiService.delete('/api/patients/medical-history/$id');
      return response.statusCode == 200;
    } catch (e) {
      throw Exception('Error deleting medical history: $e');
    }
  }

  // 🆕 Filter patients
  Future<List<Patient>> filterPatients({
    String? gender,
    DateTime? dateOfBirth,
    String? civilStatus,
  }) async {
    try {
      final queryParams = <String, String>{};
      if (gender != null) queryParams['gender'] = gender;
      if (dateOfBirth != null)
        queryParams['dob'] = dateOfBirth.toIso8601String();
      if (civilStatus != null) queryParams['civilStatus'] = civilStatus;

      final response = await _apiService.get(
        '/api/patients/filter',
        queryParams: queryParams,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => Patient.fromJson(json)).toList();
      } else {
        throw Exception('Failed to filter patients: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error filtering patients: $e');
    }
  }

  // 🆕 Get current month patient count
  Future<int> getCurrentMonthPatientCount() async {
    try {
      final response =
          await _apiService.get('/api/patients/stats/current-month');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['count'] ?? 0;
      } else {
        throw Exception('Failed to get patient count: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error getting patient count: $e');
    }
  }

  // 🆕 Search medical history
  Future<List<MedicalHistory>> searchMedicalHistory(
    String patientId, {
    String? vitals,
    DateTime? date,
  }) async {
    try {
      final queryParams = <String, String>{
        'patientId': patientId,
      };
      if (vitals != null) queryParams['vitals'] = vitals;
      if (date != null) queryParams['date'] = date.toIso8601String();

      final response = await _apiService.get(
        '/api/patients/medical-history/search',
        queryParams: queryParams,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => MedicalHistory.fromJson(json)).toList();
      } else {
        throw Exception(
            'Failed to search medical history: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error searching medical history: $e');
    }
  }

  // 🆕 Sync all patients (for testing/admin purposes)
  Future<void> syncAllPatients() async {
    try {
      final response = await _apiService.post('/api/patients/sync', {});

      if (response.statusCode != 200) {
        throw Exception('Failed to sync patients: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error syncing patients: $e');
    }
  }
}
