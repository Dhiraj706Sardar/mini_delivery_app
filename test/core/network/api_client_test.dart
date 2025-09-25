import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:deliery_app/core/network/api_client.dart';
import 'package:deliery_app/core/errors/failures.dart';

import 'api_client_test.mocks.dart';

@GenerateMocks([http.Client])
void main() {
  group('ApiClient', () {
    late ApiClient apiClient;
    late MockClient mockHttpClient;

    setUp(() {
      mockHttpClient = MockClient();
      apiClient = ApiClient(client: mockHttpClient, enableLogging: false);
    });

    tearDown(() {
      apiClient.dispose();
    });

    group('GET Requests', () {
      test('should return data when GET request is successful', () async {
        // Arrange
        const endpoint = '/test';
        final responseData = {'message': 'success', 'data': []};
        when(mockHttpClient.get(any, headers: anyNamed('headers')))
            .thenAnswer((_) async => http.Response(json.encode(responseData), 200));

        // Act
        final result = await apiClient.get(endpoint);

        // Assert
        expect(result, responseData);
        verify(mockHttpClient.get(
          Uri.parse('https://fakerestaurantapi.runasp.net/api$endpoint'),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            'User-Agent': 'FoodDeliveryApp/1.0.0',
          },
        )).called(1);
      });

      test('should handle empty response body', () async {
        // Arrange
        const endpoint = '/test';
        when(mockHttpClient.get(any, headers: anyNamed('headers')))
            .thenAnswer((_) async => http.Response('', 200));

        // Act
        final result = await apiClient.get(endpoint);

        // Assert
        expect(result, <String, dynamic>{});
      });

      test('should handle list response', () async {
        // Arrange
        const endpoint = '/test';
        final responseData = [{'id': 1}, {'id': 2}];
        when(mockHttpClient.get(any, headers: anyNamed('headers')))
            .thenAnswer((_) async => http.Response(json.encode(responseData), 200));

        // Act
        final result = await apiClient.get(endpoint);

        // Assert
        expect(result, {'data': responseData});
      });

      test('should handle primitive response', () async {
        // Arrange
        const endpoint = '/test';
        const responseData = 'success';
        when(mockHttpClient.get(any, headers: anyNamed('headers')))
            .thenAnswer((_) async => http.Response(json.encode(responseData), 200));

        // Act
        final result = await apiClient.get(endpoint);

        // Assert
        expect(result, {'result': responseData});
      });

      test('should throw NetworkFailure on SocketException', () async {
        // Arrange
        const endpoint = '/test';
        when(mockHttpClient.get(any, headers: anyNamed('headers')))
            .thenThrow(const SocketException('No internet connection'));

        // Act & Assert
        expect(
          () => apiClient.get(endpoint),
          throwsA(isA<NetworkFailure>().having(
            (f) => f.message,
            'message',
            'No internet connection',
          )),
        );
      });

      test('should throw NetworkFailure on TimeoutException', () async {
        // Arrange
        const endpoint = '/test';
        when(mockHttpClient.get(any, headers: anyNamed('headers')))
            .thenThrow(TimeoutException('Request timeout', const Duration(seconds: 30)));

        // Act & Assert
        expect(
          () => apiClient.get(endpoint),
          throwsA(isA<NetworkFailure>().having(
            (f) => f.message,
            'message',
            'Request timeout',
          )),
        );
      });

      test('should throw ServerFailure on 404 response', () async {
        // Arrange
        const endpoint = '/test';
        when(mockHttpClient.get(any, headers: anyNamed('headers')))
            .thenAnswer((_) async => http.Response('Not Found', 404));

        // Act & Assert
        expect(
          () => apiClient.get(endpoint),
          throwsA(isA<ServerFailure>().having(
            (f) => f.message,
            'message',
            'Resource not found',
          )),
        );
      });

      test('should throw ServerFailure on 500 response', () async {
        // Arrange
        const endpoint = '/test';
        when(mockHttpClient.get(any, headers: anyNamed('headers')))
            .thenAnswer((_) async => http.Response('Internal Server Error', 500));

        // Act & Assert
        expect(
          () => apiClient.get(endpoint),
          throwsA(isA<ServerFailure>().having(
            (f) => f.message,
            'message',
            'Internal server error',
          )),
        );
      });

      test('should throw ServerFailure on invalid JSON response', () async {
        // Arrange
        const endpoint = '/test';
        when(mockHttpClient.get(any, headers: anyNamed('headers')))
            .thenAnswer((_) async => http.Response('invalid json', 200));

        // Act & Assert
        expect(
          () => apiClient.get(endpoint),
          throwsA(isA<ServerFailure>().having(
            (f) => f.message,
            'message',
            'Invalid JSON response format',
          )),
        );
      });
    });

    group('POST Requests', () {
      test('should return data when POST request is successful', () async {
        // Arrange
        const endpoint = '/test';
        final requestData = {'name': 'test'};
        final responseData = {'id': 1, 'name': 'test'};
        when(mockHttpClient.post(
          any,
          headers: anyNamed('headers'),
          body: anyNamed('body'),
        )).thenAnswer((_) async => http.Response(json.encode(responseData), 201));

        // Act
        final result = await apiClient.post(endpoint, requestData);

        // Assert
        expect(result, responseData);
        verify(mockHttpClient.post(
          Uri.parse('https://fakerestaurantapi.runasp.net/api$endpoint'),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            'User-Agent': 'FoodDeliveryApp/1.0.0',
          },
          body: json.encode(requestData),
        )).called(1);
      });

      test('should throw ServerFailure on 400 response with error message', () async {
        // Arrange
        const endpoint = '/test';
        final requestData = {'name': 'test'};
        final errorResponse = {'message': 'Validation failed'};
        when(mockHttpClient.post(
          any,
          headers: anyNamed('headers'),
          body: anyNamed('body'),
        )).thenAnswer((_) async => http.Response(json.encode(errorResponse), 400));

        // Act & Assert
        expect(
          () => apiClient.post(endpoint, requestData),
          throwsA(isA<ServerFailure>().having(
            (f) => f.message,
            'message',
            'Bad request: Validation failed',
          )),
        );
      });
    });

    group('PUT Requests', () {
      test('should return data when PUT request is successful', () async {
        // Arrange
        const endpoint = '/test/1';
        final requestData = {'name': 'updated'};
        final responseData = {'id': 1, 'name': 'updated'};
        when(mockHttpClient.put(
          any,
          headers: anyNamed('headers'),
          body: anyNamed('body'),
        )).thenAnswer((_) async => http.Response(json.encode(responseData), 200));

        // Act
        final result = await apiClient.put(endpoint, requestData);

        // Assert
        expect(result, responseData);
      });
    });

    group('DELETE Requests', () {
      test('should return empty data when DELETE request is successful', () async {
        // Arrange
        const endpoint = '/test/1';
        when(mockHttpClient.delete(any, headers: anyNamed('headers')))
            .thenAnswer((_) async => http.Response('', 204));

        // Act
        final result = await apiClient.delete(endpoint);

        // Assert
        expect(result, <String, dynamic>{});
      });
    });

    group('Retry Mechanism', () {
      test('should retry on NetworkFailure and succeed on second attempt', () async {
        // Arrange
        const endpoint = '/test';
        final responseData = {'message': 'success'};
        var callCount = 0;
        when(mockHttpClient.get(any, headers: anyNamed('headers')))
            .thenAnswer((_) async {
          callCount++;
          if (callCount == 1) {
            throw const SocketException('No internet connection');
          }
          return http.Response(json.encode(responseData), 200);
        });

        // Act
        final result = await apiClient.get(endpoint);

        // Assert
        expect(result, responseData);
        verify(mockHttpClient.get(any, headers: anyNamed('headers'))).called(2);
      });

      test('should not retry on ServerFailure', () async {
        // Arrange
        const endpoint = '/test';
        when(mockHttpClient.get(any, headers: anyNamed('headers')))
            .thenAnswer((_) async => http.Response('Bad Request', 400));

        // Act & Assert
        expect(
          () => apiClient.get(endpoint),
          throwsA(isA<ServerFailure>()),
        );
        verify(mockHttpClient.get(any, headers: anyNamed('headers'))).called(1);
      });

      test('should throw NetworkFailure after max retries exceeded', () async {
        // Arrange
        const endpoint = '/test';
        when(mockHttpClient.get(any, headers: anyNamed('headers')))
            .thenAnswer((_) async {
          throw const SocketException('No internet connection');
        });

        // Act & Assert
        expect(
          () => apiClient.get(endpoint),
          throwsA(isA<NetworkFailure>()),
        );
        verify(mockHttpClient.get(any, headers: anyNamed('headers'))).called(4); // 1 + 3 retries
      });
    });

    group('Error Message Extraction', () {
      test('should extract error message from JSON response', () async {
        // Arrange
        const endpoint = '/test';
        final errorResponse = {'message': 'Custom error message'};
        when(mockHttpClient.get(any, headers: anyNamed('headers')))
            .thenAnswer((_) async => http.Response(json.encode(errorResponse), 400));

        // Act & Assert
        expect(
          () => apiClient.get(endpoint),
          throwsA(isA<ServerFailure>().having(
            (f) => f.message,
            'message',
            'Bad request: Custom error message',
          )),
        );
      });

      test('should extract error from error field when message not available', () async {
        // Arrange
        const endpoint = '/test';
        final errorResponse = {'error': 'Another error message'};
        when(mockHttpClient.get(any, headers: anyNamed('headers')))
            .thenAnswer((_) async => http.Response(json.encode(errorResponse), 400));

        // Act & Assert
        expect(
          () => apiClient.get(endpoint),
          throwsA(isA<ServerFailure>().having(
            (f) => f.message,
            'message',
            'Bad request: Another error message',
          )),
        );
      });

      test('should use response body when JSON parsing fails', () async {
        // Arrange
        const endpoint = '/test';
        when(mockHttpClient.get(any, headers: anyNamed('headers')))
            .thenAnswer((_) async => http.Response('Plain text error', 400));

        // Act & Assert
        expect(
          () => apiClient.get(endpoint),
          throwsA(isA<ServerFailure>().having(
            (f) => f.message,
            'message',
            'Bad request: Plain text error',
          )),
        );
      });
    });

    group('HTTP Status Codes', () {
      test('should handle 202 Accepted', () async {
        // Arrange
        const endpoint = '/test';
        final responseData = {'status': 'accepted'};
        when(mockHttpClient.get(any, headers: anyNamed('headers')))
            .thenAnswer((_) async => http.Response(json.encode(responseData), 202));

        // Act
        final result = await apiClient.get(endpoint);

        // Assert
        expect(result, responseData);
      });

      test('should handle 401 Unauthorized', () async {
        // Arrange
        const endpoint = '/test';
        when(mockHttpClient.get(any, headers: anyNamed('headers')))
            .thenAnswer((_) async => http.Response('Unauthorized', 401));

        // Act & Assert
        expect(
          () => apiClient.get(endpoint),
          throwsA(isA<ServerFailure>().having(
            (f) => f.message,
            'message',
            'Unauthorized access',
          )),
        );
      });

      test('should handle 403 Forbidden', () async {
        // Arrange
        const endpoint = '/test';
        when(mockHttpClient.get(any, headers: anyNamed('headers')))
            .thenAnswer((_) async => http.Response('Forbidden', 403));

        // Act & Assert
        expect(
          () => apiClient.get(endpoint),
          throwsA(isA<ServerFailure>().having(
            (f) => f.message,
            'message',
            'Access forbidden',
          )),
        );
      });

      test('should handle 408 Request Timeout', () async {
        // Arrange
        const endpoint = '/test';
        when(mockHttpClient.get(any, headers: anyNamed('headers')))
            .thenAnswer((_) async => http.Response('Request Timeout', 408));

        // Act & Assert
        expect(
          () => apiClient.get(endpoint),
          throwsA(isA<NetworkFailure>().having(
            (f) => f.message,
            'message',
            'Request timeout',
          )),
        );
      });

      test('should handle 429 Too Many Requests', () async {
        // Arrange
        const endpoint = '/test';
        when(mockHttpClient.get(any, headers: anyNamed('headers')))
            .thenAnswer((_) async => http.Response('Too Many Requests', 429));

        // Act & Assert
        expect(
          () => apiClient.get(endpoint),
          throwsA(isA<ServerFailure>().having(
            (f) => f.message,
            'message',
            'Too many requests',
          )),
        );
      });

      test('should handle 502 Bad Gateway', () async {
        // Arrange
        const endpoint = '/test';
        when(mockHttpClient.get(any, headers: anyNamed('headers')))
            .thenAnswer((_) async => http.Response('Bad Gateway', 502));

        // Act & Assert
        expect(
          () => apiClient.get(endpoint),
          throwsA(isA<ServerFailure>().having(
            (f) => f.message,
            'message',
            'Bad gateway',
          )),
        );
      });

      test('should handle 503 Service Unavailable', () async {
        // Arrange
        const endpoint = '/test';
        when(mockHttpClient.get(any, headers: anyNamed('headers')))
            .thenAnswer((_) async => http.Response('Service Unavailable', 503));

        // Act & Assert
        expect(
          () => apiClient.get(endpoint),
          throwsA(isA<ServerFailure>().having(
            (f) => f.message,
            'message',
            'Service unavailable',
          )),
        );
      });

      test('should handle 504 Gateway Timeout', () async {
        // Arrange
        const endpoint = '/test';
        when(mockHttpClient.get(any, headers: anyNamed('headers')))
            .thenAnswer((_) async => http.Response('Gateway Timeout', 504));

        // Act & Assert
        expect(
          () => apiClient.get(endpoint),
          throwsA(isA<ServerFailure>().having(
            (f) => f.message,
            'message',
            'Gateway timeout',
          )),
        );
      });

      test('should handle unknown status codes', () async {
        // Arrange
        const endpoint = '/test';
        when(mockHttpClient.get(any, headers: anyNamed('headers')))
            .thenAnswer((_) async => http.Response('Unknown Error', 418));

        // Act & Assert
        expect(
          () => apiClient.get(endpoint),
          throwsA(isA<ServerFailure>().having(
            (f) => f.message,
            'message',
            'HTTP error 418: I\'m a teapot',
          )),
        );
      });
    });
  });
}