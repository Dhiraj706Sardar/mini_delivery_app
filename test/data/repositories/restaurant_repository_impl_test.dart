import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

import 'package:deliery_app/core/errors/failures.dart';
import 'package:deliery_app/core/network/api_client.dart';
import 'package:deliery_app/data/repositories/restaurant_repository_impl.dart';
import 'package:deliery_app/data/models/restaurant.dart';
import 'package:deliery_app/data/models/menu_item.dart';
import 'package:deliery_app/data/datasources/menu_cache_datasource.dart';

import 'restaurant_repository_impl_test.mocks.dart';

@GenerateMocks([ApiClient, MenuCacheDataSource])
void main() {
  late RestaurantRepositoryImpl repository;
  late MockApiClient mockApiClient;
  late MockMenuCacheDataSource mockMenuCache;

  setUp(() {
    mockApiClient = MockApiClient();
    mockMenuCache = MockMenuCacheDataSource();
    repository = RestaurantRepositoryImpl(
      apiClient: mockApiClient,
      menuCache: mockMenuCache,
    );
  });

  group('RestaurantRepositoryImpl', () {
    group('getRestaurants', () {
      test('should return list of restaurants when API call succeeds', () async {
        // Arrange
        final mockResponse = {
          'data': [
            {
              'id': '1',
              'name': 'Test Restaurant',
              'rating': 4.5,
              'address': '123 Test St',
              'cuisineType': 'Italian',
              'imageUrl': 'https://example.com/image.jpg',
              'description': 'A great restaurant',
            },
            {
              'id': '2',
              'name': 'Another Restaurant',
              'rating': 4.0,
              'address': '456 Another St',
              'cuisineType': 'Chinese',
              'imageUrl': 'https://example.com/image2.jpg',
              'description': 'Another great restaurant',
            },
          ]
        };

        when(mockApiClient.get('/Restaurant'))
            .thenAnswer((_) async => mockResponse);

        // Act
        final result = await repository.getRestaurants();

        // Assert
        expect(result, isA<List<Restaurant>>());
        expect(result.length, equals(2));
        expect(result[0].name, equals('Test Restaurant'));
        expect(result[0].rating, equals(4.5));
        expect(result[1].name, equals('Another Restaurant'));
        expect(result[1].rating, equals(4.0));
        verify(mockApiClient.get('/Restaurant')).called(1);
      });

      test('should handle response without data wrapper', () async {
        // Arrange
        final mockResponse = {
          'id': '1',
          'name': 'Test Restaurant',
          'rating': 4.5,
          'address': '123 Test St',
          'cuisineType': 'Italian',
          'imageUrl': 'https://example.com/image.jpg',
          'description': 'A great restaurant',
        };

        when(mockApiClient.get('/Restaurant'))
            .thenAnswer((_) async => mockResponse);

        // Act
        final result = await repository.getRestaurants();

        // Assert
        expect(result, isA<List<Restaurant>>());
        expect(result.length, equals(1));
        expect(result[0].name, equals('Test Restaurant'));
      });

      test('should filter out invalid restaurants', () async {
        // Arrange
        final mockResponse = {
          'data': [
            {
              'id': '1',
              'name': 'Valid Restaurant',
              'rating': 4.5,
              'address': '123 Test St',
              'cuisineType': 'Italian',
              'imageUrl': 'https://example.com/image.jpg',
              'description': 'A great restaurant',
            },
            {
              'id': '', // Invalid - empty ID
              'name': 'Invalid Restaurant',
              'rating': 4.0,
              'address': '456 Another St',
              'cuisineType': 'Chinese',
              'imageUrl': 'https://example.com/image2.jpg',
              'description': 'Invalid restaurant',
            },
            {
              'id': '3',
              'name': '', // Invalid - empty name
              'rating': 3.5,
              'address': '789 Third St',
              'cuisineType': 'Mexican',
              'imageUrl': 'https://example.com/image3.jpg',
              'description': 'Another invalid restaurant',
            },
          ]
        };

        when(mockApiClient.get('/Restaurant'))
            .thenAnswer((_) async => mockResponse);

        // Act
        final result = await repository.getRestaurants();

        // Assert
        expect(result, isA<List<Restaurant>>());
        expect(result.length, equals(1));
        expect(result[0].name, equals('Valid Restaurant'));
      });

      test('should throw ServerFailure when all restaurants are invalid', () async {
        // Arrange
        final mockResponse = {
          'data': [
            {
              'id': '', // Invalid
              'name': '',
              'rating': -1.0,
              'address': '',
              'cuisineType': '',
              'imageUrl': '',
              'description': '',
            }
          ]
        };

        when(mockApiClient.get('/Restaurant'))
            .thenAnswer((_) async => mockResponse);

        // Act & Assert
        expect(
          () => repository.getRestaurants(),
          throwsA(isA<ServerFailure>().having(
            (e) => e.message,
            'message',
            contains('Invalid restaurant data format received'),
          )),
        );
      });

      test('should rethrow NetworkFailure from API client', () async {
        // Arrange
        when(mockApiClient.get('/Restaurant'))
            .thenThrow(const NetworkFailure('No internet connection'));

        // Act & Assert
        expect(
          () => repository.getRestaurants(),
          throwsA(isA<NetworkFailure>().having(
            (e) => e.message,
            'message',
            equals('No internet connection'),
          )),
        );
      });

      test('should rethrow ServerFailure from API client', () async {
        // Arrange
        when(mockApiClient.get('/Restaurant'))
            .thenThrow(const ServerFailure('Internal server error'));

        // Act & Assert
        expect(
          () => repository.getRestaurants(),
          throwsA(isA<ServerFailure>().having(
            (e) => e.message,
            'message',
            equals('Internal server error'),
          )),
        );
      });

      test('should throw UnknownFailure for unexpected errors', () async {
        // Arrange
        when(mockApiClient.get('/Restaurant'))
            .thenThrow(Exception('Unexpected error'));

        // Act & Assert
        expect(
          () => repository.getRestaurants(),
          throwsA(isA<UnknownFailure>().having(
            (e) => e.message,
            'message',
            contains('Failed to fetch restaurants'),
          )),
        );
      });
    });

    group('getMenuItems', () {
      const restaurantId = 'restaurant123';
      final menuItems = [
        const MenuItem(
          id: '1',
          itemName: 'Pizza Margherita',
          itemDescription: 'Classic pizza with tomato and mozzarella',
          itemPrice: 12.99,
          imageUrl: 'https://example.com/pizza.jpg',
          category: 'Pizza',
        ),
        const MenuItem(
          id: '2',
          itemName: 'Pasta Carbonara',
          itemDescription: 'Creamy pasta with bacon and eggs',
          itemPrice: 14.99,
          imageUrl: 'https://example.com/pasta.jpg',
          category: 'Pasta',
        ),
      ];

      test('should return cached menu items when available', () async {
        // Arrange
        when(mockMenuCache.getCachedMenuItems(restaurantId))
            .thenAnswer((_) async => menuItems);

        // Act
        final result = await repository.getMenuItems(restaurantId);

        // Assert
        expect(result, isA<List<MenuItem>>());
        expect(result.length, equals(2));
        expect(result[0].itemName, equals('Pizza Margherita'));
        expect(result[1].itemName, equals('Pasta Carbonara'));
        
        // Verify cache was checked but API was not called
        verify(mockMenuCache.getCachedMenuItems(restaurantId)).called(1);
        verifyNever(mockApiClient.get(any));
      });

      test('should fetch from API and cache when no cached data available', () async {
        // Arrange
        final mockResponse = {
          'data': [
            {
              'id': '1',
              'itemName': 'Pizza Margherita',
              'itemDescription': 'Classic pizza with tomato and mozzarella',
              'itemPrice': 12.99,
              'imageUrl': 'https://example.com/pizza.jpg',
              'category': 'Pizza',
            },
            {
              'id': '2',
              'itemName': 'Pasta Carbonara',
              'itemDescription': 'Creamy pasta with bacon and eggs',
              'itemPrice': 14.99,
              'imageUrl': 'https://example.com/pasta.jpg',
              'category': 'Pasta',
            },
          ]
        };

        when(mockMenuCache.getCachedMenuItems(restaurantId))
            .thenAnswer((_) async => null);
        when(mockApiClient.get('/Restaurant/$restaurantId/menu'))
            .thenAnswer((_) async => mockResponse);
        when(mockMenuCache.cacheMenuItems(restaurantId, any))
            .thenAnswer((_) async {});

        // Act
        final result = await repository.getMenuItems(restaurantId);

        // Assert
        expect(result, isA<List<MenuItem>>());
        expect(result.length, equals(2));
        expect(result[0].itemName, equals('Pizza Margherita'));
        expect(result[0].itemPrice, equals(12.99));
        expect(result[1].itemName, equals('Pasta Carbonara'));
        expect(result[1].itemPrice, equals(14.99));
        
        // Verify the flow: check cache -> API call -> cache result
        verify(mockMenuCache.getCachedMenuItems(restaurantId)).called(1);
        verify(mockApiClient.get('/Restaurant/$restaurantId/menu')).called(1);
        verify(mockMenuCache.cacheMenuItems(restaurantId, any)).called(1);
      });

      test('should return cached data on network failure', () async {
        // Arrange
        when(mockMenuCache.getCachedMenuItems(restaurantId))
            .thenAnswer((_) async => null);
        when(mockApiClient.get('/Restaurant/$restaurantId/menu'))
            .thenThrow(const NetworkFailure('No internet connection'));
        when(mockMenuCache.getCachedMenuItemsIgnoreExpiry(restaurantId))
            .thenAnswer((_) async => menuItems);

        // Act
        final result = await repository.getMenuItems(restaurantId);

        // Assert
        expect(result, isA<List<MenuItem>>());
        expect(result.length, equals(2));
        expect(result[0].itemName, equals('Pizza Margherita'));
        
        // Verify fallback to expired cache was used
        verify(mockMenuCache.getCachedMenuItems(restaurantId)).called(1);
        verify(mockApiClient.get('/Restaurant/$restaurantId/menu')).called(1);
        verify(mockMenuCache.getCachedMenuItemsIgnoreExpiry(restaurantId)).called(1);
      });

      test('should throw NetworkFailure when no cached data available on network failure', () async {
        // Arrange
        when(mockMenuCache.getCachedMenuItems(restaurantId))
            .thenAnswer((_) async => null);
        when(mockApiClient.get('/Restaurant/$restaurantId/menu'))
            .thenThrow(const NetworkFailure('No internet connection'));
        when(mockMenuCache.getCachedMenuItemsIgnoreExpiry(restaurantId))
            .thenAnswer((_) async => null);

        // Act & Assert
        expect(
          () => repository.getMenuItems(restaurantId),
          throwsA(isA<NetworkFailure>().having(
            (e) => e.message,
            'message',
            equals('No internet connection'),
          )),
        );
      });

      test('should return empty list when no menu items available', () async {
        // Arrange
        final mockResponse = {'data': <dynamic>[]};

        when(mockMenuCache.getCachedMenuItems(restaurantId))
            .thenAnswer((_) async => null);
        when(mockApiClient.get('/Restaurant/$restaurantId/menu'))
            .thenAnswer((_) async => mockResponse);
        when(mockMenuCache.cacheMenuItems(restaurantId, any))
            .thenAnswer((_) async {});

        // Act
        final result = await repository.getMenuItems(restaurantId);

        // Assert
        expect(result, isA<List<MenuItem>>());
        expect(result.length, equals(0));
      });

      test('should filter out invalid menu items', () async {
        // Arrange
        final mockResponse = {
          'data': [
            {
              'id': '1',
              'itemName': 'Valid Item',
              'itemDescription': 'A valid menu item',
              'itemPrice': 12.99,
              'imageUrl': 'https://example.com/item.jpg',
              'category': 'Main',
            },
            {
              'id': '', // Invalid - empty ID
              'itemName': 'Invalid Item',
              'itemDescription': 'Invalid item',
              'itemPrice': 10.99,
              'imageUrl': 'https://example.com/invalid.jpg',
              'category': 'Main',
            },
            {
              'id': '3',
              'itemName': 'Another Invalid',
              'itemDescription': 'Another invalid item',
              'itemPrice': -5.0, // Invalid - negative price
              'imageUrl': 'https://example.com/invalid2.jpg',
              'category': 'Main',
            },
          ]
        };

        when(mockMenuCache.getCachedMenuItems(restaurantId))
            .thenAnswer((_) async => null);
        when(mockApiClient.get('/Restaurant/$restaurantId/menu'))
            .thenAnswer((_) async => mockResponse);
        when(mockMenuCache.cacheMenuItems(restaurantId, any))
            .thenAnswer((_) async {});

        // Act
        final result = await repository.getMenuItems(restaurantId);

        // Assert
        expect(result, isA<List<MenuItem>>());
        expect(result.length, equals(1));
        expect(result[0].itemName, equals('Valid Item'));
      });

      test('should throw ServerFailure when restaurant ID is empty', () async {
        // Act & Assert
        expect(
          () => repository.getMenuItems(''),
          throwsA(isA<ServerFailure>().having(
            (e) => e.message,
            'message',
            equals('Restaurant ID cannot be empty'),
          )),
        );
      });

      test('should rethrow NetworkFailure from API client when no cache available', () async {
        // Arrange
        when(mockMenuCache.getCachedMenuItems(restaurantId))
            .thenAnswer((_) async => null);
        when(mockApiClient.get('/Restaurant/$restaurantId/menu'))
            .thenThrow(const NetworkFailure('No internet connection'));
        when(mockMenuCache.getCachedMenuItemsIgnoreExpiry(restaurantId))
            .thenAnswer((_) async => null);

        // Act & Assert
        expect(
          () => repository.getMenuItems(restaurantId),
          throwsA(isA<NetworkFailure>().having(
            (e) => e.message,
            'message',
            equals('No internet connection'),
          )),
        );
      });

      test('should throw UnknownFailure for unexpected errors', () async {
        // Arrange
        when(mockMenuCache.getCachedMenuItems(restaurantId))
            .thenAnswer((_) async => null);
        when(mockApiClient.get('/Restaurant/$restaurantId/menu'))
            .thenThrow(Exception('Unexpected error'));

        // Act & Assert
        expect(
          () => repository.getMenuItems(restaurantId),
          throwsA(isA<UnknownFailure>().having(
            (e) => e.message,
            'message',
            contains('Failed to fetch menu items'),
          )),
        );
      });
    });

    group('getRestaurantById', () {
      const restaurantId = 'restaurant123';

      test('should return restaurant when API call succeeds', () async {
        // Arrange
        final mockResponse = {
          'id': restaurantId,
          'name': 'Test Restaurant',
          'rating': 4.5,
          'address': '123 Test St',
          'cuisineType': 'Italian',
          'imageUrl': 'https://example.com/image.jpg',
          'description': 'A great restaurant',
        };

        when(mockApiClient.get('/Restaurant/$restaurantId'))
            .thenAnswer((_) async => mockResponse);

        // Act
        final result = await repository.getRestaurantById(restaurantId);

        // Assert
        expect(result, isA<Restaurant>());
        expect(result.id, equals(restaurantId));
        expect(result.name, equals('Test Restaurant'));
        expect(result.rating, equals(4.5));
        verify(mockApiClient.get('/Restaurant/$restaurantId')).called(1);
      });

      test('should throw ServerFailure when restaurant ID is empty', () async {
        // Act & Assert
        expect(
          () => repository.getRestaurantById(''),
          throwsA(isA<ServerFailure>().having(
            (e) => e.message,
            'message',
            equals('Restaurant ID cannot be empty'),
          )),
        );
      });

      test('should throw ServerFailure when restaurant data is invalid', () async {
        // Arrange
        final mockResponse = {
          'id': '', // Invalid
          'name': '',
          'rating': -1.0,
          'address': '',
          'cuisineType': '',
          'imageUrl': '',
          'description': '',
        };

        when(mockApiClient.get('/Restaurant/$restaurantId'))
            .thenAnswer((_) async => mockResponse);

        // Act & Assert
        expect(
          () => repository.getRestaurantById(restaurantId),
          throwsA(isA<ServerFailure>().having(
            (e) => e.message,
            'message',
            equals('Invalid restaurant data format received'),
          )),
        );
      });

      test('should rethrow NetworkFailure from API client', () async {
        // Arrange
        when(mockApiClient.get('/Restaurant/$restaurantId'))
            .thenThrow(const NetworkFailure('No internet connection'));

        // Act & Assert
        expect(
          () => repository.getRestaurantById(restaurantId),
          throwsA(isA<NetworkFailure>().having(
            (e) => e.message,
            'message',
            equals('No internet connection'),
          )),
        );
      });

      test('should throw UnknownFailure for unexpected errors', () async {
        // Arrange
        when(mockApiClient.get('/Restaurant/$restaurantId'))
            .thenThrow(Exception('Unexpected error'));

        // Act & Assert
        expect(
          () => repository.getRestaurantById(restaurantId),
          throwsA(isA<UnknownFailure>().having(
            (e) => e.message,
            'message',
            contains('Failed to fetch restaurant'),
          )),
        );
      });
    });

    group('additional cache methods', () {
      const restaurantId = 'restaurant123';

      test('refreshMenuItems should clear cache and fetch fresh data', () async {
        // Arrange
        final mockResponse = {
          'data': [
            {
              'id': '1',
              'itemName': 'Fresh Pizza',
              'itemDescription': 'Freshly fetched pizza',
              'itemPrice': 15.99,
              'imageUrl': 'https://example.com/fresh-pizza.jpg',
              'category': 'Pizza',
            },
          ]
        };

        when(mockMenuCache.clearMenuCache(restaurantId))
            .thenAnswer((_) async {});
        when(mockMenuCache.getCachedMenuItems(restaurantId))
            .thenAnswer((_) async => null);
        when(mockApiClient.get('/Restaurant/$restaurantId/menu'))
            .thenAnswer((_) async => mockResponse);
        when(mockMenuCache.cacheMenuItems(restaurantId, any))
            .thenAnswer((_) async {});

        // Act
        final result = await repository.refreshMenuItems(restaurantId);

        // Assert
        expect(result, isA<List<MenuItem>>());
        expect(result.length, equals(1));
        expect(result[0].itemName, equals('Fresh Pizza'));
        
        // Verify cache was cleared first
        verify(mockMenuCache.clearMenuCache(restaurantId)).called(1);
        verify(mockApiClient.get('/Restaurant/$restaurantId/menu')).called(1);
      });

      test('clearMenuCache should clear all cached menu data', () async {
        // Arrange
        when(mockMenuCache.clearAllMenuCache())
            .thenAnswer((_) async {});

        // Act
        await repository.clearMenuCache();

        // Assert
        verify(mockMenuCache.clearAllMenuCache()).called(1);
      });

      test('hasMenuCache should return cache availability status', () async {
        // Arrange
        when(mockMenuCache.hasMenuCache(restaurantId))
            .thenAnswer((_) async => true);

        // Act
        final result = await repository.hasMenuCache(restaurantId);

        // Assert
        expect(result, isTrue);
        verify(mockMenuCache.hasMenuCache(restaurantId)).called(1);
      });
    });
  });
}