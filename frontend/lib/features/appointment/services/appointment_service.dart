import 'dart:convert';
import 'package:frontend/core/services/api_service.dart';
import '../../../config/api_config.dart';
import '../models/appointment.dart';

class AppointmentService {
  final ApiService _apiService = ApiService();

  Future<List<Appointment>> getAllAppointments({
    String? search,
    String? status,
    String? type,
  }) async {
    try {
      final queryParams = <String, String>{};
      if (search != null && search.isNotEmpty) {
        queryParams['patientName'] = search;
      }
      if (status != null && status.isNotEmpty) {
        queryParams['status'] = status;
      }
      if (type != null && type.isNotEmpty) {
        queryParams['type'] = type;
      }

      final response = await _apiService.get(
        ApiConfig.appointmentsEndpoint,
        requireAuth: true,
        queryParams: queryParams.isEmpty ? null : queryParams,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final appointmentList = data['appointments'] ?? data;
        if (appointmentList is List) {
          return appointmentList
              .map((json) => Appointment.fromJson(json))
              .toList();
        }
        return [];
      }

      throw Exception('Failed to load appointments: ${response.statusCode}');
    } catch (e) {
      throw Exception('Error fetching appointments: $e');
    }
  }

  Future<Appointment> createAppointment(Appointment appointment) async {
    try {
      final response = await _apiService.post(
        ApiConfig.appointmentsEndpoint,
        appointment.toJson(),
        requireAuth: true,
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final record = data['appointment'] ?? data;
        return Appointment.fromJson(record);
      }

      final errorBody = response.body;
      throw Exception(
          'Failed to create appointment: ${response.statusCode} - $errorBody');
    } catch (e) {
      throw Exception('Error creating appointment: $e');
    }
  }

  /// Update an existing appointment (status, notes, etc.)
  Future<Appointment> updateAppointment(String id, Map<String, dynamic> data) async {
    try {
      final response = await _apiService.put(
        '${ApiConfig.appointmentsEndpoint}/$id',
        data,
        requireAuth: true,
      );

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        final record = result['appointment'] ?? result;
        return Appointment.fromJson(record);
      }

      throw Exception('Failed to update appointment: ${response.statusCode}');
    } catch (e) {
      throw Exception('Error updating appointment: $e');
    }
  }

  /// Check-in a patient (Secretary / Receptionist)
  Future<bool> checkInPatient(String appointmentId, {String? notes, String priority = 'Normal'}) async {
    try {
      final response = await _apiService.post(
        '/api/waiting-room/checkin/$appointmentId',
        {
          'priority': priority,
          if (notes != null) 'notes': notes,
        },
        requireAuth: true,
      );
      return response.statusCode == 200;
    } catch (e) {
      throw Exception('Error checking in patient: $e');
    }
  }

  /// Start consultation (Doctor)  — sets appointment to In-progress & auto-creates consultation
  Future<bool> startConsultation(String appointmentId) async {
    try {
      final response = await _apiService.post(
        '/api/waiting-room/start-consultation/$appointmentId',
        {},
        requireAuth: true,
      );
      return response.statusCode == 200;
    } catch (e) {
      throw Exception('Error starting consultation: $e');
    }
  }

  /// Complete consultation (Doctor)
  Future<bool> completeConsultation(String appointmentId, {String? notes, int? actualDuration}) async {
    try {
      final response = await _apiService.post(
        '/api/waiting-room/complete-consultation/$appointmentId',
        {
          if (notes != null) 'notes': notes,
          if (actualDuration != null) 'actualDuration': actualDuration,
        },
        requireAuth: true,
      );
      return response.statusCode == 200;
    } catch (e) {
      throw Exception('Error completing consultation: $e');
    }
  }

  /// Cancel an appointment
  Future<bool> cancelAppointment(String appointmentId, String reason) async {
    try {
      final response = await _apiService.post(
        '${ApiConfig.appointmentsEndpoint}/$appointmentId/cancel',
        {'cancellationReason': reason},
        requireAuth: true,
      );
      return response.statusCode == 200;
    } catch (e) {
      throw Exception('Error cancelling appointment: $e');
    }
  }
}
