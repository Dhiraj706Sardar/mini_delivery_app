import '../models/menu_item.dart';
import 'menu_cache_datasource.dart';

/// Mock implementation of MenuCacheDataSource for development/testing
class MockMenuCacheDataSource implements MenuCacheDataSource {
  final Map<String, List<MenuItem>> _cache = {};
  final Map<String, DateTime> _cacheTimestamps = {};
  final Duration _cacheExpiration = const Duration(minutes: 5);

  @override
  Future<List<MenuItem>?> getCachedMenuItems(String restaurantId) async {
    final items = _cache[restaurantId];
    final timestamp = _cacheTimestamps[restaurantId];

    if (items != null && timestamp != null) {
      // Check if cache is still valid
      final now = DateTime.now();
      final cacheAge = now.difference(timestamp);

      if (cacheAge.inMinutes < _cacheExpiration.inMinutes) {
        return List.from(items);
      } else {
        // Cache expired, but don't remove it here for offline fallback
        return null;
      }
    }

    return null;
  }

  @override
  Future<void> cacheMenuItems(String restaurantId, List<MenuItem> items) async {
    _cache[restaurantId] = List.from(items);
    _cacheTimestamps[restaurantId] = DateTime.now();
  }

  @override
  Future<void> clearMenuCache(String restaurantId) async {
    _cache.remove(restaurantId);
    _cacheTimestamps.remove(restaurantId);
  }

  @override
  Future<void> clearAllMenuCache() async {
    _cache.clear();
    _cacheTimestamps.clear();
  }

  @override
  Future<bool> hasMenuCache(String restaurantId) async {
    final items = _cache[restaurantId];
    final timestamp = _cacheTimestamps[restaurantId];

    if (items != null && timestamp != null) {
      // Check if cache is still valid
      final now = DateTime.now();
      final cacheAge = now.difference(timestamp);
      return cacheAge.inMinutes < _cacheExpiration.inMinutes;
    }

    return false;
  }

  @override
  Future<bool> isCacheValid(String restaurantId) async {
    final timestamp = _cacheTimestamps[restaurantId];

    if (timestamp != null) {
      final now = DateTime.now();
      final cacheAge = now.difference(timestamp);
      return cacheAge.inMinutes < _cacheExpiration.inMinutes;
    }

    return false;
  }

  @override
  Future<List<MenuItem>?> getCachedMenuItemsIgnoreExpiry(
    String restaurantId,
  ) async {
    final items = _cache[restaurantId];
    return items != null ? List.from(items) : null;
  }
}
