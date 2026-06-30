// lib/core/services/api_service.dart - CORRIGÉ
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class ApiService {
  static const String _fallbackBaseUrl = 'http://localhost:8090';
  static const Duration _timeout = Duration(seconds: 30);

  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  String? _accessToken;
  // ignore: unused_field
  String? _refreshToken;

  void setTokens(String accessToken, String refreshToken) {
    _accessToken = accessToken;
    _refreshToken = refreshToken;
  }

  void clearTokens() {
    _accessToken = null;
    _refreshToken = null;
  }

  Map<String, String> get _baseHeaders => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

  Map<String, String> get _authHeaders => {
        ..._baseHeaders,
        if (_accessToken != null) 'Authorization': 'Bearer $_accessToken',
      };

  Uri _buildUri(String endpoint) {
    final parsedEndpoint = Uri.parse(endpoint);
    if (parsedEndpoint.hasScheme) {
      return parsedEndpoint;
    }

    if (kIsWeb) {
      return Uri.base.resolve(endpoint);
    }

    return Uri.parse('$_fallbackBaseUrl$endpoint');
  }

  // GET request générique
  Future<http.Response> get(
    String endpoint, {
    bool requireAuth = true,
    Map<String, String>? queryParams,
  }) async {
    var uri = _buildUri(endpoint);
    if (queryParams != null) {
      uri = uri.replace(queryParameters: queryParams);
    }

    try {
      final response = await http
          .get(
            uri,
            headers: requireAuth ? _authHeaders : _baseHeaders,
          )
          .timeout(_timeout);

      return response;
    } catch (e) {
      debugPrint('GET Error: $e');
      rethrow;
    }
  }

  // POST request générique
  Future<http.Response> post(String endpoint, Map<String, dynamic> data,
      {bool requireAuth = true}) async {
    final url = _buildUri(endpoint);

    try {
      final response = await http
          .post(
            url,
            headers: requireAuth ? _authHeaders : _baseHeaders,
            body: jsonEncode(data),
          )
          .timeout(_timeout);

      return response;
    } catch (e) {
      debugPrint('POST Error: $e');
      rethrow;
    }
  }

  // PUT request générique
  Future<http.Response> put(String endpoint, Map<String, dynamic> data,
      {bool requireAuth = true}) async {
    final url = _buildUri(endpoint);

    try {
      final response = await http
          .put(
            url,
            headers: requireAuth ? _authHeaders : _baseHeaders,
            body: jsonEncode(data),
          )
          .timeout(_timeout);

      return response;
    } catch (e) {
      debugPrint('PUT Error: $e');
      rethrow;
    }
  }

  // DELETE request générique
  Future<http.Response> delete(String endpoint,
      {bool requireAuth = true}) async {
    final url = _buildUri(endpoint);

    try {
      final response = await http
          .delete(
            url,
            headers: requireAuth ? _authHeaders : _baseHeaders,
          )
          .timeout(_timeout);

      return response;
    } catch (e) {
      debugPrint('DELETE Error: $e');
      rethrow;
    }
  }
}
