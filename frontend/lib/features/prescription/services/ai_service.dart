import 'dart:convert';
import 'dart:developer' as developer;
import '../../../core/services/api_service.dart';
import '../models/ai_suggestion.dart';

class AIService {
  final ApiService _apiService = ApiService();
  static const String _baseUrl = '/api/prescriptions';

  /// Obtenir les suggestions IA pour une consultation
  Future<AISuggestionsResponse> getAISuggestions(String consultationId) async {
    try {
      developer.log('Getting AI suggestions for consultation: $consultationId',
          name: 'AIService');

      final response = await _apiService.get(
        '$_baseUrl/ai-suggestions/$consultationId',
        requireAuth: true,
      );

      developer.log('AI suggestions response: ${response.statusCode}',
          name: 'AIService');
      developer.log('AI suggestions body: ${response.body}', name: 'AIService');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return AISuggestionsResponse.fromJson(data);
      } else {
        throw Exception('Failed to get AI suggestions: ${response.statusCode}');
      }
    } catch (e) {
      developer.log('Error getting AI suggestions: $e', name: 'AIService');

      // Retourner une réponse d'erreur
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

  /// Vérifier si le service IA est disponible
  Future<bool> isAIServiceAvailable() async {
    try {
      // Test d'un endpoint simple pour vérifier la disponibilité
      final testResponse = await _apiService.get(
        '$_baseUrl/ai-suggestions/test',
        requireAuth: true,
      );
      return testResponse.statusCode != 500;
    } catch (e) {
      return false;
    }
  }
}
