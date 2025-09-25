import '../models/menu_item.dart';

/// Abstract interface for menu caching operations
abstract class MenuCacheDataSource {
  /// Cache menu items for a specific restaurant
  Future<void> cacheMenuItems(String restaurantId, List<MenuItem> menuItems);

  /// Retrieve cached menu items for a specific restaurant
  Future<List<MenuItem>?> getCachedMenuItems(String restaurantId);

  /// Clear cached menu items for a specific restaurant
  Future<void> clearMenuCache(String restaurantId);

  /// Clear all cached menu items
  Future<void> clearAllMenuCache();

  /// Check if menu items are cached for a specific restaurant
  Future<bool> hasMenuCache(String restaurantId);

  /// Check if cached menu items are still valid (not expired)
  Future<bool> isCacheValid(String restaurantId);

  /// Get cached menu items ignoring expiry (for offline fallback)
  Future<List<MenuItem>?> getCachedMenuItemsIgnoreExpiry(String restaurantId);
}

/// In-memory implementation of menu cache
///
/// This implementation stores menu items in memory with expiration times.
/// For production apps, consider using shared_preferences, hive, or sqflite
/// for persistent caching.
class MenuCacheDataSourceImpl implements MenuCacheDataSource {
  final Map<String, _CacheEntry> _cache = {};
  final Duration _cacheExpiration;

  MenuCacheDataSourceImpl({
    Duration cacheExpiration = const Duration(minutes: 30),
  }) : _cacheExpiration = cacheExpiration;

  @override
  Future<void> cacheMenuItems(
    String restaurantId,
    List<MenuItem> menuItems,
  ) async {
    _cache[restaurantId] = _CacheEntry(
      menuItems: menuItems,
      timestamp: DateTime.now(),
    );
  }

  @override
  Future<List<MenuItem>?> getCachedMenuItems(String restaurantId) async {
    final entry = _cache[restaurantId];
    if (entry == null) {
      return null;
    }

    // Check if cache is still valid
    if (_isCacheExpired(entry)) {
      // Don't remove expired entries here - let them be cleaned up elsewhere
      // This allows getCachedMenuItemsIgnoreExpiry to still access them
      return null;
    }

    return entry.menuItems;
  }

  @override
  Future<void> clearMenuCache(String restaurantId) async {
    _cache.remove(restaurantId);
  }

  @override
  Future<void> clearAllMenuCache() async {
    _cache.clear();
  }

  @override
  Future<bool> hasMenuCache(String restaurantId) async {
    final entry = _cache[restaurantId];
    if (entry == null) {
      return false;
    }

    // Check if cache is still valid
    if (_isCacheExpired(entry)) {
      return false;
    }

    return true;
  }

  @override
  Future<bool> isCacheValid(String restaurantId) async {
    final entry = _cache[restaurantId];
    if (entry == null) {
      return false;
    }

    return !_isCacheExpired(entry);
  }

  /// Check if a cache entry has expired
  bool _isCacheExpired(_CacheEntry entry) {
    final now = DateTime.now();
    final expirationTime = entry.timestamp.add(_cacheExpiration);
    return now.isAfter(expirationTime);
  }

  /// Get cached menu items ignoring expiry (for offline fallback)
  Future<List<MenuItem>?> getCachedMenuItemsIgnoreExpiry(
    String restaurantId,
  ) async {
    final entry = _cache[restaurantId];
    return entry?.menuItems;
  }

  /// Clean up expired cache entries
  Future<void> cleanupExpiredEntries() async {
    final expiredKeys = _cache.entries
        .where((entry) => _isCacheExpired(entry.value))
        .map((entry) => entry.key)
        .toList();

    for (final key in expiredKeys) {
      _cache.remove(key);
    }
  }

  /// Get cache statistics for debugging
  Map<String, dynamic> getCacheStats() {
    final validEntries = _cache.entries
        .where((entry) => !_isCacheExpired(entry.value))
        .length;

    return {
      'totalEntries': _cache.length,
      'validEntries': validEntries,
      'expiredEntries': _cache.length - validEntries,
      'cacheExpirationMinutes': _cacheExpiration.inMinutes,
    };
  }
}

/// Internal cache entry class
class _CacheEntry {
  final List<MenuItem> menuItems;
  final DateTime timestamp;

  _CacheEntry({required this.menuItems, required this.timestamp});
}
