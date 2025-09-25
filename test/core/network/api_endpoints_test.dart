import 'package:flutter_test/flutter_test.dart';
import 'package:deliery_app/core/network/api_endpoints.dart';

void main() {
  group('ApiEndpoints', () {
    group('Path Parameter Replacement', () {
      test('should replace single path parameter correctly', () {
        // Arrange
        const endpoint = '/Restaurant/{id}';
        const params = {'id': '123'};

        // Act
        final result = ApiEndpoints.replacePathParams(endpoint, params);

        // Assert
        expect(result, '/Restaurant/123');
      });

      test('should replace multiple path parameters correctly', () {
        // Arrange
        const endpoint = '/User/{userId}/orders/{orderId}';
        const params = {'userId': '456', 'orderId': '789'};

        // Act
        final result = ApiEndpoints.replacePathParams(endpoint, params);

        // Assert
        expect(result, '/User/456/orders/789');
      });

      test('should handle empty parameters map', () {
        // Arrange
        const endpoint = '/Restaurant';
        const params = <String, String>{};

        // Act
        final result = ApiEndpoints.replacePathParams(endpoint, params);

        // Assert
        expect(result, '/Restaurant');
      });

      test('should not modify endpoint when no matching parameters', () {
        // Arrange
        const endpoint = '/Restaurant/{id}';
        const params = {'otherId': '123'};

        // Act
        final result = ApiEndpoints.replacePathParams(endpoint, params);

        // Assert
        expect(result, '/Restaurant/{id}');
      });
    });

    group('Helper Methods', () {
      test('getRestaurantById should return correct endpoint', () {
        // Act
        final result = ApiEndpoints.getRestaurantById('123');

        // Assert
        expect(result, '/Restaurant/123');
      });

      test('getRestaurantMenu should return correct endpoint', () {
        // Act
        final result = ApiEndpoints.getRestaurantMenu('456');

        // Assert
        expect(result, '/Restaurant/456/menu');
      });

      test('getOrderById should return correct endpoint', () {
        // Act
        final result = ApiEndpoints.getOrderById('789');

        // Assert
        expect(result, '/Order/789');
      });

      test('getUpdateOrder should return correct endpoint', () {
        // Act
        final result = ApiEndpoints.getUpdateOrder('789');

        // Assert
        expect(result, '/Order/789');
      });

      test('getCancelOrder should return correct endpoint', () {
        // Act
        final result = ApiEndpoints.getCancelOrder('789');

        // Assert
        expect(result, '/Order/789/cancel');
      });

      test('getUserById should return correct endpoint', () {
        // Act
        final result = ApiEndpoints.getUserById('user123');

        // Assert
        expect(result, '/User/user123');
      });

      test('getUserOrders should return correct endpoint', () {
        // Act
        final result = ApiEndpoints.getUserOrders('user123');

        // Assert
        expect(result, '/User/user123/orders');
      });
    });

    group('Query String Building', () {
      test('should build query string from parameters', () {
        // Arrange
        const params = {
          'query': 'pizza',
          'limit': 10,
          'offset': 0,
        };

        // Act
        final result = ApiEndpoints.buildQueryString(params);

        // Assert
        expect(result, '?query=pizza&limit=10&offset=0');
      });

      test('should handle empty parameters', () {
        // Arrange
        const params = <String, dynamic>{};

        // Act
        final result = ApiEndpoints.buildQueryString(params);

        // Assert
        expect(result, '');
      });

      test('should skip null parameters', () {
        // Arrange
        const params = {
          'query': 'pizza',
          'limit': null,
          'offset': 0,
        };

        // Act
        final result = ApiEndpoints.buildQueryString(params);

        // Assert
        expect(result, '?query=pizza&offset=0');
      });

      test('should URL encode parameters', () {
        // Arrange
        const params = {
          'query': 'pizza & pasta',
          'category': 'fast food',
        };

        // Act
        final result = ApiEndpoints.buildQueryString(params);

        // Assert
        expect(result, contains('pizza%20%26%20pasta'));
        expect(result, contains('fast%20food'));
      });
    });

    group('Search Endpoints', () {
      test('getSearchRestaurants should build correct endpoint with all parameters', () {
        // Act
        final result = ApiEndpoints.getSearchRestaurants(
          query: 'pizza',
          cuisine: 'Italian',
          minRating: 4.0,
          maxDistance: 5.0,
          limit: 20,
          offset: 0,
        );

        // Assert
        expect(result, startsWith('/Restaurant/search?'));
        expect(result, contains('q=pizza'));
        expect(result, contains('cuisine=Italian'));
        expect(result, contains('minRating=4.0'));
        expect(result, contains('maxDistance=5.0'));
        expect(result, contains('limit=20'));
        expect(result, contains('offset=0'));
      });

      test('getSearchRestaurants should build correct endpoint with partial parameters', () {
        // Act
        final result = ApiEndpoints.getSearchRestaurants(
          query: 'burger',
          limit: 10,
        );

        // Assert
        expect(result, '/Restaurant/search?q=burger&limit=10');
      });

      test('getSearchRestaurants should return base endpoint when no parameters', () {
        // Act
        final result = ApiEndpoints.getSearchRestaurants();

        // Assert
        expect(result, '/Restaurant/search');
      });

      test('getSearchMenuItems should build correct endpoint with all parameters', () {
        // Act
        final result = ApiEndpoints.getSearchMenuItems(
          query: 'salad',
          category: 'Healthy',
          minPrice: 5.0,
          maxPrice: 15.0,
          limit: 15,
          offset: 5,
        );

        // Assert
        expect(result, startsWith('/MenuItem/search?'));
        expect(result, contains('q=salad'));
        expect(result, contains('category=Healthy'));
        expect(result, contains('minPrice=5.0'));
        expect(result, contains('maxPrice=15.0'));
        expect(result, contains('limit=15'));
        expect(result, contains('offset=5'));
      });

      test('getSearchMenuItems should build correct endpoint with partial parameters', () {
        // Act
        final result = ApiEndpoints.getSearchMenuItems(
          category: 'Dessert',
          maxPrice: 10.0,
        );

        // Assert
        expect(result, '/MenuItem/search?category=Dessert&maxPrice=10.0');
      });

      test('getSearchMenuItems should return base endpoint when no parameters', () {
        // Act
        final result = ApiEndpoints.getSearchMenuItems();

        // Assert
        expect(result, '/MenuItem/search');
      });
    });

    group('Constants', () {
      test('should have correct base URL', () {
        expect(ApiEndpoints.baseUrl, 'https://fakerestaurantapi.runasp.net/api');
      });

      test('should have correct restaurant endpoints', () {
        expect(ApiEndpoints.restaurants, '/Restaurant');
        expect(ApiEndpoints.restaurantById, '/Restaurant/{id}');
        expect(ApiEndpoints.restaurantMenu, '/Restaurant/{id}/menu');
      });

      test('should have correct order endpoints', () {
        expect(ApiEndpoints.orders, '/Order');
        expect(ApiEndpoints.orderById, '/Order/{id}');
        expect(ApiEndpoints.createOrder, '/Order');
        expect(ApiEndpoints.updateOrder, '/Order/{id}');
        expect(ApiEndpoints.cancelOrder, '/Order/{id}/cancel');
      });

      test('should have correct user endpoints', () {
        expect(ApiEndpoints.users, '/User');
        expect(ApiEndpoints.userById, '/User/{id}');
        expect(ApiEndpoints.userOrders, '/User/{id}/orders');
      });

      test('should have correct search endpoints', () {
        expect(ApiEndpoints.searchRestaurants, '/Restaurant/search');
        expect(ApiEndpoints.searchMenuItems, '/MenuItem/search');
      });
    });
  });
}