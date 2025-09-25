import 'package:flutter/material.dart';
import 'app_router.dart';
import '../../data/models/restaurant.dart';
import '../../data/models/order.dart';
import '../../data/models/cart_item.dart';

/// Global navigation service
class NavigationService {
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  
  static NavigatorState? get navigator => navigatorKey.currentState;
  static BuildContext? get context => navigatorKey.currentContext;
  
  /// Navigate to restaurant list screen
  static Future<void> goToRestaurants({bool clearStack = false}) async {
    if (clearStack) {
      await navigator?.pushNamedAndRemoveUntil(AppRoutes.restaurants, (route) => false);
    } else {
      await navigator?.pushReplacementNamed(AppRoutes.restaurants);
    }
  }
  
  /// Navigate to menu screen
  static Future<void> goToMenu(Restaurant restaurant) async {
    await navigator?.pushNamed(
      AppRoutes.menu,
      arguments: MenuScreenArguments(restaurant: restaurant),
    );
  }
  
  /// Navigate to cart screen
  static Future<void> goToCart() async {
    await navigator?.pushNamed(AppRoutes.cart);
  }
  
  /// Navigate to checkout screen
  static Future<void> goToCheckout() async {
    await navigator?.pushNamed(AppRoutes.checkout);
  }
  
  /// Navigate to order confirmation screen
  static Future<void> goToOrderConfirmation(Order order) async {
    await navigator?.pushReplacementNamed(
      AppRoutes.orderConfirmation,
      arguments: OrderConfirmationArguments(order: order),
    );
  }
  
  /// Navigate to order failure screen
  static Future<void> goToOrderFailure({
    required String errorMessage,
    String? errorCode,
    required bool canRetry,
    required List<CartItem> cartItems,
    required String restaurantId,
  }) async {
    await navigator?.pushNamed(
      AppRoutes.orderFailure,
      arguments: OrderFailureArguments(
        errorMessage: errorMessage,
        errorCode: errorCode,
        canRetry: canRetry,
        cartItems: cartItems,
        restaurantId: restaurantId,
      ),
    );
  }
  
  /// Go back to previous screen
  static void goBack([dynamic result]) {
    navigator?.pop(result);
  }
  
  /// Check if we can go back
  static bool canGoBack() {
    return navigator?.canPop() ?? false;
  }
}

