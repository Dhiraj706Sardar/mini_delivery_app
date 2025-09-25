/// API endpoints configuration for the food delivery app
class ApiEndpoints {
  // Base configuration
  static const String baseUrl = 'https://fakerestaurantapi.runasp.net/api';
  
  // Restaurant endpoints
  static const String restaurants = '/Restaurant';
  static const String restaurantById = '/Restaurant/{id}';
  static const String restaurantMenu = '/Restaurant/{id}/menu';
  
  // Order endpoints (for future use)
  static const String orders = '/Order';
  static const String orderById = '/Order/{id}';
  static const String createOrder = '/Order';
  static const String updateOrder = '/Order/{id}';
  static const String cancelOrder = '/Order/{id}/cancel';
  
  // User endpoints (for future use)
  static const String users = '/User';
  static const String userById = '/User/{id}';
  static const String userOrders = '/User/{id}/orders';
  
  // Search endpoints (for future use)
  static const String searchRestaurants = '/Restaurant/search';
  static const String searchMenuItems = '/MenuItem/search';
  
  /// Helper method to replace path parameters in endpoints
  static String replacePathParams(String endpoint, Map<String, String> params) {
    String result = endpoint;
    params.forEach((key, value) {
      result = result.replaceAll('{$key}', value);
    });
    return result;
  }
  
  /// Get restaurant by ID endpoint with parameter replacement
  static String getRestaurantById(String restaurantId) {
    return replacePathParams(restaurantById, {'id': restaurantId});
  }
  
  /// Get restaurant menu endpoint with parameter replacement
  static String getRestaurantMenu(String restaurantId) {
    return replacePathParams(restaurantMenu, {'id': restaurantId});
  }
  
  /// Get order by ID endpoint with parameter replacement
  static String getOrderById(String orderId) {
    return replacePathParams(orderById, {'id': orderId});
  }
  
  /// Update order endpoint with parameter replacement
  static String getUpdateOrder(String orderId) {
    return replacePathParams(updateOrder, {'id': orderId});
  }
  
  /// Cancel order endpoint with parameter replacement
  static String getCancelOrder(String orderId) {
    return replacePathParams(cancelOrder, {'id': orderId});
  }
  
  /// Get user by ID endpoint with parameter replacement
  static String getUserById(String userId) {
    return replacePathParams(userById, {'id': userId});
  }
  
  /// Get user orders endpoint with parameter replacement
  static String getUserOrders(String userId) {
    return replacePathParams(userOrders, {'id': userId});
  }
  
  /// Build query string from parameters
  static String buildQueryString(Map<String, dynamic> params) {
    if (params.isEmpty) return '';
    
    final queryParams = params.entries
        .where((entry) => entry.value != null)
        .map((entry) => '${Uri.encodeComponent(entry.key)}=${Uri.encodeComponent(entry.value.toString())}')
        .join('&');
    
    return queryParams.isNotEmpty ? '?$queryParams' : '';
  }
  
  /// Search restaurants with query parameters
  static String getSearchRestaurants({
    String? query,
    String? cuisine,
    double? minRating,
    double? maxDistance,
    int? limit,
    int? offset,
  }) {
    final params = <String, dynamic>{};
    if (query != null) params['q'] = query;
    if (cuisine != null) params['cuisine'] = cuisine;
    if (minRating != null) params['minRating'] = minRating;
    if (maxDistance != null) params['maxDistance'] = maxDistance;
    if (limit != null) params['limit'] = limit;
    if (offset != null) params['offset'] = offset;
    
    return searchRestaurants + buildQueryString(params);
  }
  
  /// Search menu items with query parameters
  static String getSearchMenuItems({
    String? query,
    String? category,
    double? minPrice,
    double? maxPrice,
    int? limit,
    int? offset,
  }) {
    final params = <String, dynamic>{};
    if (query != null) params['q'] = query;
    if (category != null) params['category'] = category;
    if (minPrice != null) params['minPrice'] = minPrice;
    if (maxPrice != null) params['maxPrice'] = maxPrice;
    if (limit != null) params['limit'] = limit;
    if (offset != null) params['offset'] = offset;
    
    return searchMenuItems + buildQueryString(params);
  }
}