import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:http/http.dart' as http;
import '../constants/app_constants.dart';
import '../errors/failures.dart';

class ApiClient {
  final http.Client client;
  final bool enableLogging;

  ApiClient({http.Client? client, this.enableLogging = true})
    : client = client ?? http.Client();

  /// GET request with retry mechanism and error handling
  Future<Map<String, dynamic>> get(String endpoint) async {
    return _executeWithRetry(() => _performGet(endpoint));
  }

  /// POST request with retry mechanism and error handling
  Future<Map<String, dynamic>> post(
    String endpoint,
    Map<String, dynamic> data,
  ) async {
    return _executeWithRetry(() => _performPost(endpoint, data));
  }

  /// PUT request with retry mechanism and error handling
  Future<Map<String, dynamic>> put(
    String endpoint,
    Map<String, dynamic> data,
  ) async {
    return _executeWithRetry(() => _performPut(endpoint, data));
  }

  /// DELETE request with retry mechanism and error handling
  Future<Map<String, dynamic>> delete(String endpoint) async {
    return _executeWithRetry(() => _performDelete(endpoint));
  }

  /// Execute request with retry mechanism
  Future<Map<String, dynamic>> _executeWithRetry(
    Future<Map<String, dynamic>> Function() request,
  ) async {
    int retryCount = 0;

    while (retryCount <= AppConstants.maxRetries) {
      try {
        return await request();
      } catch (e) {
        retryCount++;

        if (retryCount > AppConstants.maxRetries) {
          rethrow;
        }

        // Only retry on specific network errors, not on client/server errors
        if (e is NetworkFailure &&
            (e.message.contains('No internet connection') ||
                e.message.contains('Network error'))) {
          _log(
            'Retrying request (attempt $retryCount/${AppConstants.maxRetries})',
          );
          await Future.delayed(
            Duration(milliseconds: _getRetryDelay(retryCount)),
          );
        } else {
          rethrow;
        }
      }
    }

    throw const NetworkFailure('Max retry attempts exceeded');
  }

  /// Calculate exponential backoff delay
  int _getRetryDelay(int retryCount) {
    return (1000 * retryCount * retryCount).clamp(1000, 10000);
  }

  /// Perform GET request
  Future<Map<String, dynamic>> _performGet(String endpoint) async {
    final uri = Uri.parse('${AppConstants.baseUrl}$endpoint');
    _log('GET: $uri');

    try {
      final response = await client
          .get(uri, headers: _getHeaders())
          .timeout(
            const Duration(milliseconds: AppConstants.connectionTimeout),
          );

      _logResponse(response);
      return _handleResponse(response);
    } on SocketException {
      throw const NetworkFailure('No internet connection');
    } on TimeoutException {
      throw const NetworkFailure('Request timeout');
    } on FormatException {
      throw const NetworkFailure('Invalid URL format');
    } on ServerFailure {
      rethrow; // Re-throw ServerFailure as-is
    } catch (e) {
      throw NetworkFailure('Network error: ${e.toString()}');
    }
  }

  /// Perform POST request
  Future<Map<String, dynamic>> _performPost(
    String endpoint,
    Map<String, dynamic> data,
  ) async {
    final uri = Uri.parse('${AppConstants.baseUrl}$endpoint');
    final body = json.encode(data);
    _log('POST: $uri');
    _log('Body: $body');

    try {
      final response = await client
          .post(uri, headers: _getHeaders(), body: body)
          .timeout(
            const Duration(milliseconds: AppConstants.connectionTimeout),
          );

      _logResponse(response);
      return _handleResponse(response);
    } on SocketException {
      throw const NetworkFailure('No internet connection');
    } on TimeoutException {
      throw const NetworkFailure('Request timeout');
    } on FormatException {
      throw const NetworkFailure('Invalid URL format');
    } on ServerFailure {
      rethrow; // Re-throw ServerFailure as-is
    } catch (e) {
      throw NetworkFailure('Network error: ${e.toString()}');
    }
  }

  /// Perform PUT request
  Future<Map<String, dynamic>> _performPut(
    String endpoint,
    Map<String, dynamic> data,
  ) async {
    final uri = Uri.parse('${AppConstants.baseUrl}$endpoint');
    final body = json.encode(data);
    _log('PUT: $uri');
    _log('Body: $body');

    try {
      final response = await client
          .put(uri, headers: _getHeaders(), body: body)
          .timeout(
            const Duration(milliseconds: AppConstants.connectionTimeout),
          );

      _logResponse(response);
      return _handleResponse(response);
    } on SocketException {
      throw const NetworkFailure('No internet connection');
    } on TimeoutException {
      throw const NetworkFailure('Request timeout');
    } on FormatException {
      throw const NetworkFailure('Invalid URL format');
    } on ServerFailure {
      rethrow; // Re-throw ServerFailure as-is
    } catch (e) {
      throw NetworkFailure('Network error: ${e.toString()}');
    }
  }

  /// Perform DELETE request
  Future<Map<String, dynamic>> _performDelete(String endpoint) async {
    final uri = Uri.parse('${AppConstants.baseUrl}$endpoint');
    _log('DELETE: $uri');

    try {
      final response = await client
          .delete(uri, headers: _getHeaders())
          .timeout(
            const Duration(milliseconds: AppConstants.connectionTimeout),
          );

      _logResponse(response);
      return _handleResponse(response);
    } on SocketException {
      throw const NetworkFailure('No internet connection');
    } on TimeoutException {
      throw const NetworkFailure('Request timeout');
    } on FormatException {
      throw const NetworkFailure('Invalid URL format');
    } on ServerFailure {
      rethrow; // Re-throw ServerFailure as-is
    } catch (e) {
      throw NetworkFailure('Network error: ${e.toString()}');
    }
  }

  /// Get default headers for requests
  Map<String, String> _getHeaders() {
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'User-Agent': 'FoodDeliveryApp/${AppConstants.appVersion}',
    };
  }

  /// Handle HTTP response and convert to appropriate format or throw error
  Map<String, dynamic> _handleResponse(http.Response response) {
    switch (response.statusCode) {
      case 200:
      case 201:
      case 202:
        try {
          if (response.body.isEmpty) {
            return <String, dynamic>{};
          }
          final decoded = json.decode(response.body);
          if (decoded is Map<String, dynamic>) {
            return decoded;
          } else if (decoded is List) {
            return {'data': decoded};
          } else {
            return {'result': decoded};
          }
        } catch (e) {
          throw const ServerFailure('Invalid JSON response format');
        }
      case 204:
        return <String, dynamic>{}; // No content
      case 400:
        throw ServerFailure('Bad request: ${_extractErrorMessage(response)}');
      case 401:
        throw const ServerFailure('Unauthorized access');
      case 403:
        throw const ServerFailure('Access forbidden');
      case 404:
        throw const ServerFailure('Resource not found');
      case 408:
        throw const NetworkFailure('Request timeout');
      case 429:
        throw const ServerFailure('Too many requests');
      case 500:
        throw const ServerFailure('Internal server error');
      case 502:
        throw const ServerFailure('Bad gateway');
      case 503:
        throw const ServerFailure('Service unavailable');
      case 504:
        throw const ServerFailure('Gateway timeout');
      default:
        throw ServerFailure(
          'HTTP error ${response.statusCode}: ${response.reasonPhrase}',
        );
    }
  }

  /// Extract error message from response body
  String _extractErrorMessage(http.Response response) {
    try {
      final body = json.decode(response.body);
      if (body is Map<String, dynamic>) {
        return body['message'] ?? body['error'] ?? 'Unknown error';
      }
      return response.body;
    } catch (e) {
      return response.reasonPhrase ?? 'Unknown error';
    }
  }

  /// Log request/response information
  void _log(String message) {
    if (enableLogging) {
      print('[ApiClient] $message');
    }
  }

  /// Log response information
  void _logResponse(http.Response response) {
    if (enableLogging) {
      _log('Response: ${response.statusCode} ${response.reasonPhrase}');
      if (response.body.isNotEmpty && response.body.length < 1000) {
        _log('Response Body: ${response.body}');
      } else if (response.body.length >= 1000) {
        _log(
          'Response Body: ${response.body.substring(0, 1000)}... (truncated)',
        );
      }
    }
  }

  /// Dispose of the client
  void dispose() {
    client.close();
  }
}
