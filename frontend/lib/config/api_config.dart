// lib/config/api_config.dart
class ApiConfig {
  // 🌐 URL du Gateway Express
  static const String baseUrl = 'http://localhost:8080';

  // 🔐 Endpoints d'authentification
  static const String authBaseUrl = '$baseUrl/api/auth';

  static const String loginEndpoint = '$authBaseUrl/login';
  static const String verify2FAEndpoint = '$authBaseUrl/2fa/verify';
  static const String send2FAEndpoint = '$authBaseUrl/2fa/send';
  static const String refreshTokenEndpoint = '$authBaseUrl/refresh-token';
  static const String logoutEndpoint = '$authBaseUrl/logout';
  static const String forgetPasswordEndpoint = '$authBaseUrl/forget-password';
  static const String changePasswordEndpoint = '$authBaseUrl/change-password';

  // Patient endpoints
  static const String patientsEndpoint = '/api/patients/';
  static const String patientByIdEndpoint = '/api/patients';
  static const String searchPatientsEndpoint = '/api/patients/search';
  static const String patientMedicalHistoryEndpoint = '/api/patients';

  // Consultation endpoints
  static const String consultationsEndpoint = '/api/consultations';
  static const String consultationByIdEndpoint = '/api/consultations';
  static const String consultationsByPatientEndpoint =
      '/api/consultations/patient';

  // Appointment endpoints
  static const String appointmentsEndpoint = '/api/appointments';

  // Prescription endpoints
  static const String prescriptionsEndpoint = '/api/prescriptions';
  static const String prescriptionByIdEndpoint = '/api/prescriptions';
  static const String exportPrescriptionEndpoint = '/api/prescriptions';

  // Medication endpoints
  static const String medicationsEndpoint = '/api/medications';
  static const String searchMedicationsEndpoint = '/api/medications/search';

  // ⏱️ Timeouts
  static const int connectionTimeout = 30000; // 30 secondes
  static const int receiveTimeout = 30000; // 30 secondes

  // 🔑 Headers par défaut
  static Map<String, String> get defaultHeaders => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

  // 🔒 Headers avec authentification
  static Map<String, String> getAuthHeaders(String token) => {
        ...defaultHeaders,
        'Authorization': 'Bearer $token',
      };
}
