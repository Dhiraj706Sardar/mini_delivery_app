class AppConstants {
  // API Configuration
  static const String baseUrl = 'https://fakerestaurantapi.runasp.net/api';
  static const String restaurantEndpoint = '/Restaurant';
  static const String menuEndpoint = '/Restaurant/{id}/menu';
  
  // App Configuration
  static const String appName = 'Food Delivery';
  static const String appVersion = '1.0.0';
  
  // Network Configuration
  static const int connectionTimeout = 30000; // 30 seconds
  static const int receiveTimeout = 30000; // 30 seconds
  static const int maxRetries = 3;
  
  // UI Constants
  static const double defaultPadding = 16.0;
  static const double smallPadding = 8.0;
  static const double largePadding = 24.0;
  static const double borderRadius = 12.0;
  static const double smallBorderRadius = 8.0;
  
  // Cart Configuration
  static const double deliveryFee = 2.99;
  static const double taxRate = 0.08; // 8% tax
  static const double minimumOrderAmount = 10.0;
  
  // Error Messages
  static const String networkErrorMessage = 'Please check your internet connection and try again.';
  static const String serverErrorMessage = 'Something went wrong. Please try again later.';
  static const String unknownErrorMessage = 'An unexpected error occurred.';
  static const String emptyCartMessage = 'Your cart is empty. Add some delicious items!';
  static const String noRestaurantsMessage = 'No restaurants available at the moment.';
  static const String noMenuItemsMessage = 'No menu items available for this restaurant.';
}