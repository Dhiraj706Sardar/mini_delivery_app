import 'package:flutter_test/flutter_test.dart';
import 'package:deliery_app/data/datasources/menu_cache_datasource.dart';
import 'package:deliery_app/data/models/menu_item.dart';

void main() {
  late MenuCacheDataSourceImpl cacheDataSource;

  setUp(() {
    cacheDataSource = MenuCacheDataSourceImpl(
      cacheExpiration: const Duration(minutes: 30),
    );
  });

  group('MenuCacheDataSourceImpl', () {
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

    group('cacheMenuItems and getCachedMenuItems', () {
      test('should cache and retrieve menu items successfully', () async {
        // Act
        await cacheDataSource.cacheMenuItems(restaurantId, menuItems);
        final result = await cacheDataSource.getCachedMenuItems(restaurantId);

        // Assert
        expect(result, isNotNull);
        expect(result!.length, equals(2));
        expect(result[0].itemName, equals('Pizza Margherita'));
        expect(result[1].itemName, equals('Pasta Carbonara'));
      });

      test('should return null for non-existent cache', () async {
        // Act
        final result = await cacheDataSource.getCachedMenuItems('nonexistent');

        // Assert
        expect(result, isNull);
      });

      test('should return null for expired cache', () async {
        // Arrange - Create cache with very short expiration
        final shortCacheDataSource = MenuCacheDataSourceImpl(
          cacheExpiration: const Duration(milliseconds: 1),
        );

        // Act
        await shortCacheDataSource.cacheMenuItems(restaurantId, menuItems);
        
        // Wait for cache to expire
        await Future.delayed(const Duration(milliseconds: 10));
        
        final result = await shortCacheDataSource.getCachedMenuItems(restaurantId);

        // Assert
        expect(result, isNull);
      });
    });

    group('hasMenuCache', () {
      test('should return true for valid cached items', () async {
        // Arrange
        await cacheDataSource.cacheMenuItems(restaurantId, menuItems);

        // Act
        final result = await cacheDataSource.hasMenuCache(restaurantId);

        // Assert
        expect(result, isTrue);
      });

      test('should return false for non-existent cache', () async {
        // Act
        final result = await cacheDataSource.hasMenuCache('nonexistent');

        // Assert
        expect(result, isFalse);
      });

      test('should return false for expired cache', () async {
        // Arrange - Create cache with very short expiration
        final shortCacheDataSource = MenuCacheDataSourceImpl(
          cacheExpiration: const Duration(milliseconds: 1),
        );

        await shortCacheDataSource.cacheMenuItems(restaurantId, menuItems);
        
        // Wait for cache to expire
        await Future.delayed(const Duration(milliseconds: 10));

        // Act
        final result = await shortCacheDataSource.hasMenuCache(restaurantId);

        // Assert
        expect(result, isFalse);
      });
    });

    group('isCacheValid', () {
      test('should return true for valid cache', () async {
        // Arrange
        await cacheDataSource.cacheMenuItems(restaurantId, menuItems);

        // Act
        final result = await cacheDataSource.isCacheValid(restaurantId);

        // Assert
        expect(result, isTrue);
      });

      test('should return false for expired cache', () async {
        // Arrange - Create cache with very short expiration
        final shortCacheDataSource = MenuCacheDataSourceImpl(
          cacheExpiration: const Duration(milliseconds: 1),
        );

        await shortCacheDataSource.cacheMenuItems(restaurantId, menuItems);
        
        // Wait for cache to expire
        await Future.delayed(const Duration(milliseconds: 10));

        // Act
        final result = await shortCacheDataSource.isCacheValid(restaurantId);

        // Assert
        expect(result, isFalse);
      });

      test('should return false for non-existent cache', () async {
        // Act
        final result = await cacheDataSource.isCacheValid('nonexistent');

        // Assert
        expect(result, isFalse);
      });
    });

    group('clearMenuCache', () {
      test('should clear specific restaurant cache', () async {
        // Arrange
        await cacheDataSource.cacheMenuItems(restaurantId, menuItems);
        await cacheDataSource.cacheMenuItems('restaurant456', menuItems);

        // Act
        await cacheDataSource.clearMenuCache(restaurantId);

        // Assert
        final result1 = await cacheDataSource.getCachedMenuItems(restaurantId);
        final result2 = await cacheDataSource.getCachedMenuItems('restaurant456');
        
        expect(result1, isNull);
        expect(result2, isNotNull);
      });
    });

    group('clearAllMenuCache', () {
      test('should clear all cached menu items', () async {
        // Arrange
        await cacheDataSource.cacheMenuItems(restaurantId, menuItems);
        await cacheDataSource.cacheMenuItems('restaurant456', menuItems);

        // Act
        await cacheDataSource.clearAllMenuCache();

        // Assert
        final result1 = await cacheDataSource.getCachedMenuItems(restaurantId);
        final result2 = await cacheDataSource.getCachedMenuItems('restaurant456');
        
        expect(result1, isNull);
        expect(result2, isNull);
      });
    });

    group('getCachedMenuItemsIgnoreExpiry', () {
      test('should return cached items even when expired', () async {
        // Arrange - Create cache with very short expiration
        final shortCacheDataSource = MenuCacheDataSourceImpl(
          cacheExpiration: const Duration(milliseconds: 1),
        );

        await shortCacheDataSource.cacheMenuItems(restaurantId, menuItems);
        
        // Wait for cache to expire
        await Future.delayed(const Duration(milliseconds: 10));

        // Act
        final normalResult = await shortCacheDataSource.getCachedMenuItems(restaurantId);
        final ignoreExpiryResult = await shortCacheDataSource.getCachedMenuItemsIgnoreExpiry(restaurantId);

        // Assert
        expect(normalResult, isNull); // Should be null due to expiry
        expect(ignoreExpiryResult, isNotNull); // Should return data ignoring expiry
        expect(ignoreExpiryResult!.length, equals(2));
      });

      test('should return null for non-existent cache', () async {
        // Act
        final result = await cacheDataSource.getCachedMenuItemsIgnoreExpiry('nonexistent');

        // Assert
        expect(result, isNull);
      });
    });

    group('getCacheStats', () {
      test('should return correct cache statistics', () async {
        // Arrange
        await cacheDataSource.cacheMenuItems('restaurant1', menuItems);
        await cacheDataSource.cacheMenuItems('restaurant2', menuItems);

        // Act
        final stats = cacheDataSource.getCacheStats();

        // Assert
        expect(stats['totalEntries'], equals(2));
        expect(stats['validEntries'], equals(2));
        expect(stats['expiredEntries'], equals(0));
        expect(stats['cacheExpirationMinutes'], equals(30));
      });

      test('should correctly count expired entries', () async {
        // Arrange - Create cache with very short expiration
        final shortCacheDataSource = MenuCacheDataSourceImpl(
          cacheExpiration: const Duration(milliseconds: 1),
        );

        await shortCacheDataSource.cacheMenuItems('restaurant1', menuItems);
        await shortCacheDataSource.cacheMenuItems('restaurant2', menuItems);
        
        // Wait for cache to expire
        await Future.delayed(const Duration(milliseconds: 10));

        // Act
        final stats = shortCacheDataSource.getCacheStats();

        // Assert
        expect(stats['totalEntries'], equals(2));
        expect(stats['validEntries'], equals(0));
        expect(stats['expiredEntries'], equals(2));
      });
    });
  });
}