import '../../core/errors/failures.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_endpoints.dart';
import '../../domain/repositories/restaurant_repository.dart';
import '../models/restaurant.dart';
import '../models/menu_item.dart';
import '../datasources/menu_cache_datasource.dart';

/// Concrete implementation of [RestaurantRepository]
///
/// This class handles all restaurant-related API calls and data transformation.
/// It uses the [ApiClient] for network operations and implements proper error
/// handling and data validation. It also includes caching for menu items to
/// improve performance and reduce API calls.
class RestaurantRepositoryImpl implements RestaurantRepository {
  final ApiClient _apiClient;
  final MenuCacheDataSource _menuCache;

  const RestaurantRepositoryImpl({
    required ApiClient apiClient,
    required MenuCacheDataSource menuCache,
  }) : _apiClient = apiClient,
       _menuCache = menuCache;

  @override
  Future<List<Restaurant>> getRestaurants() async {
    try {
      final response = await _apiClient.get(ApiEndpoints.restaurants);

      // Handle different response formats
      List<dynamic> restaurantData;
      if (response.containsKey('data') && response['data'] is List) {
        restaurantData = response['data'] as List<dynamic>;
      } else if (response.containsKey('data')) {
        // If data is not a list, wrap it in a list
        restaurantData = [response['data']];
      } else {
        // If response doesn't have data key, assume the response itself is the data
        restaurantData = [response];
      }

      // Transform JSON data to Restaurant objects
      final restaurants = restaurantData
          .map((json) => _parseRestaurant(json))
          .where((restaurant) => restaurant != null)
          .cast<Restaurant>()
          .toList();

      // Validate that we have at least some valid restaurants
      if (restaurants.isEmpty && restaurantData.isNotEmpty) {
        throw const ServerFailure('Invalid restaurant data format received');
      }

      return restaurants;
    } on NetworkFailure {
      rethrow;
    } on ServerFailure {
      rethrow;
    } catch (e) {
      throw UnknownFailure('Failed to fetch restaurants: ${e.toString()}');
    }
  }

  @override
  Future<List<MenuItem>> getMenuItems(String restaurantId) async {
    if (restaurantId.isEmpty) {
      throw const ServerFailure('Restaurant ID cannot be empty');
    }

    try {
      // First, try to get menu items from cache
      final cachedMenuItems = await _menuCache.getCachedMenuItems(restaurantId);
      if (cachedMenuItems != null) {
        return cachedMenuItems;
      }

      // If not in cache or cache expired, fetch from API
      final endpoint = ApiEndpoints.getRestaurantMenu(restaurantId);
      final response = await _apiClient.get(endpoint);

      // Handle different response formats
      List<dynamic> menuData;
      if (response.containsKey('data') && response['data'] is List) {
        menuData = response['data'] as List<dynamic>;
      } else if (response.containsKey('data')) {
        // If data is not a list, wrap it in a list
        menuData = [response['data']];
      } else {
        // If response doesn't have data key, assume the response itself is the data
        menuData = [response];
      }

      // Transform JSON data to MenuItem objects
      final menuItems = menuData
          .map((json) => _parseMenuItem(json))
          .where((menuItem) => menuItem != null)
          .cast<MenuItem>()
          .toList();

      // Cache the fetched menu items
      await _menuCache.cacheMenuItems(restaurantId, menuItems);

      // Note: Empty menu is valid, so we don't throw an error for empty lists
      return menuItems;
    } on NetworkFailure {
      // If network fails, try to return cached data even if expired
      final cachedMenuItems = await _getCachedMenuItemsIgnoreExpiry(
        restaurantId,
      );
      if (cachedMenuItems != null) {
        return cachedMenuItems;
      }
      rethrow;
    } on ServerFailure {
      rethrow;
    } catch (e) {
      throw UnknownFailure('Failed to fetch menu items: ${e.toString()}');
    }
  }

  @override
  Future<Restaurant> getRestaurantById(String restaurantId) async {
    if (restaurantId.isEmpty) {
      throw const ServerFailure('Restaurant ID cannot be empty');
    }

    try {
      final endpoint = ApiEndpoints.getRestaurantById(restaurantId);
      final response = await _apiClient.get(endpoint);

      // Parse the restaurant data
      final restaurant = _parseRestaurant(response);
      if (restaurant == null) {
        throw const ServerFailure('Invalid restaurant data format received');
      }

      return restaurant;
    } on NetworkFailure {
      rethrow;
    } on ServerFailure {
      rethrow;
    } catch (e) {
      throw UnknownFailure('Failed to fetch restaurant: ${e.toString()}');
    }
  }

  /// Parse JSON data into a Restaurant object
  ///
  /// Returns null if the data is invalid or cannot be parsed
  Restaurant? _parseRestaurant(dynamic json) {
    try {
      if (json is! Map<String, dynamic>) {
        return null;
      }

      final restaurant = Restaurant.fromJson(json);

      // Validate the parsed restaurant
      if (!restaurant.isValid) {
        return null;
      }

      return restaurant;
    } catch (e) {
      // Log parsing error but don't throw - return null to filter out invalid data
      return null;
    }
  }

  /// Parse JSON data into a MenuItem object
  ///
  /// Returns null if the data is invalid or cannot be parsed
  MenuItem? _parseMenuItem(dynamic json) {
    try {
      if (json is! Map<String, dynamic>) {
        return null;
      }

      final menuItem = MenuItem.fromJson(json);

      // Validate the parsed menu item
      if (!menuItem.isValid) {
        return null;
      }

      return menuItem;
    } catch (e) {
      // Log parsing error but don't throw - return null to filter out invalid data
      return null;
    }
  }

  /// Get cached menu items ignoring expiry (for offline fallback)
  Future<List<MenuItem>?> _getCachedMenuItemsIgnoreExpiry(
    String restaurantId,
  ) async {
    return await _menuCache.getCachedMenuItemsIgnoreExpiry(restaurantId);
  }

  /// Refresh menu items for a restaurant (bypass cache)
  Future<List<MenuItem>> refreshMenuItems(String restaurantId) async {
    if (restaurantId.isEmpty) {
      throw const ServerFailure('Restaurant ID cannot be empty');
    }

    try {
      // Clear existing cache first
      await _menuCache.clearMenuCache(restaurantId);

      // Fetch fresh data from API
      return await getMenuItems(restaurantId);
    } catch (e) {
      rethrow;
    }
  }

  /// Clear all cached menu data
  Future<void> clearMenuCache() async {
    await _menuCache.clearAllMenuCache();
  }

  /// Check if menu items are cached for a restaurant
  Future<bool> hasMenuCache(String restaurantId) async {
    return await _menuCache.hasMenuCache(restaurantId);
  }
}
