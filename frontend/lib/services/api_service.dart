import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/customer.dart';
import '../models/prediction.dart';
import '../utils/constants.dart';

/// ── API Service ────────────────────────────────────────────────────────────
/// Handles all HTTP communication with the FastAPI backend
class ApiService {
  final String baseUrl;
  final http.Client _client;

  ApiService({String? baseUrl, http.Client? client})
      : baseUrl = baseUrl ?? AppConstants.apiBaseUrl,
        _client = client ?? http.Client();

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

  /// ── Health Check ─────────────────────────────────────────────────────────
  Future<HealthCheck> checkHealth() async {
    try {
      final response = await _client
          .get(
            Uri.parse('$baseUrl${AppConstants.healthEndpoint}'),
            headers: _headers,
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return HealthCheck.fromJson(jsonDecode(response.body));
      } else {
        throw ApiException(
          'Health check failed',
          statusCode: response.statusCode,
          body: response.body,
        );
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Cannot connect to API server: $e');
    }
  }

  /// ── Single Prediction ────────────────────────────────────────────────────
  Future<PredictionResult> predictCustomer(Customer customer) async {
    try {
      final response = await _client
          .post(
            Uri.parse('$baseUrl${AppConstants.predictEndpoint}'),
            headers: _headers,
            body: customer.toJsonString(),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        return PredictionResult.fromJson(jsonDecode(response.body));
      } else {
        final error = _parseError(response.body);
        throw ApiException(
          error,
          statusCode: response.statusCode,
          body: response.body,
        );
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Prediction request failed: $e');
    }
  }

  /// ── Batch Prediction ─────────────────────────────────────────────────────
  Future<BatchPredictionResult> predictBatch(List<Customer> customers) async {
    try {
      final body = jsonEncode({
        'customers': customers.map((c) => c.toJson()).toList(),
      });

      final response = await _client
          .post(
            Uri.parse('$baseUrl${AppConstants.predictBatchEndpoint}'),
            headers: _headers,
            body: body,
          )
          .timeout(const Duration(seconds: 120));

      if (response.statusCode == 200) {
        return BatchPredictionResult.fromJson(jsonDecode(response.body));
      } else {
        final error = _parseError(response.body);
        throw ApiException(
          error,
          statusCode: response.statusCode,
          body: response.body,
        );
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Batch prediction failed: $e');
    }
  }

  /// ── Model Metrics ────────────────────────────────────────────────────────
  Future<ModelMetrics> getMetrics() async {
    try {
      final response = await _client
          .get(
            Uri.parse('$baseUrl${AppConstants.metricsEndpoint}'),
            headers: _headers,
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return ModelMetrics.fromJson(jsonDecode(response.body));
      } else {
        throw ApiException(
          'Failed to fetch metrics',
          statusCode: response.statusCode,
          body: response.body,
        );
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Metrics request failed: $e');
    }
  }


  /// ── Prediction History ───────────────────────────────────────────────────
  Future<List<PredictionResult>> getHistory() async {
    try {
      final response = await _client
          .get(
            Uri.parse('$baseUrl${AppConstants.historyEndpoint}'),
            headers: _headers,
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final list = data['history'] as List? ?? [];
        return list.map((e) => PredictionResult.fromJson(e)).toList();
      } else {
        throw ApiException('Failed to fetch history', statusCode: response.statusCode);
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('History request failed: $e');
    }
  }

  /// ── Delete History Batch ──────────────────────────────────────────────────
  Future<void> deleteHistoryBatch(List<int> ids) async {
    try {
      final response = await _client.delete(
        Uri.parse('$baseUrl/history/batch'),
        headers: _headers,
        body: jsonEncode({'ids': ids}),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) {
        throw ApiException('Failed to delete history batch', statusCode: response.statusCode);
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Delete history batch request failed: $e');
    }
  }

  /// ── Delete Duplicate Predictions ──────────────────────────────────────────
  Future<void> deleteDuplicates() async {
    try {
      final response = await _client.delete(
        Uri.parse('$baseUrl/history/duplicates'),
        headers: _headers,
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) {
        throw ApiException('Failed to delete duplicate history', statusCode: response.statusCode);
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Delete duplicates request failed: $e');
    }
  }

  /// ── Auth: Log In ──────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await _client.post(
        Uri.parse('$baseUrl/api/auth/login'),
        headers: _headers,
        body: jsonEncode({
          'username': email,
          'password': password,
        }),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        final error = _parseError(response.body);
        throw ApiException(error, statusCode: response.statusCode);
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Login request failed: $e');
    }
  }

  /// ── Auth: Sign Up ─────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> signup(String email, String password, String name) async {
    try {
      final response = await _client.post(
        Uri.parse('$baseUrl/api/auth/signup'),
        headers: _headers,
        body: jsonEncode({
          'username': email,
          'password': password,
          'name': name,
        }),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        final error = _parseError(response.body);
        throw ApiException(error, statusCode: response.statusCode);
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Signup request failed: $e');
    }
  }

  /// ── Error Parser ─────────────────────────────────────────────────────────
  String _parseError(String body) {
    try {
      final json = jsonDecode(body);
      return json['detail'] ?? json['error'] ?? 'Unknown error';
    } catch (_) {
      return body;
    }
  }

  void dispose() {
    _client.close();
  }
}

/// ── API Exception ──────────────────────────────────────────────────────────
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final String? body;

  ApiException(this.message, {this.statusCode, this.body});

  @override
  String toString() {
    if (statusCode != null) {
      return 'ApiException($statusCode): $message';
    }
    return 'ApiException: $message';
  }
}
