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
}
