import 'package:flutter/material.dart';
import '../../presentation/screens/restaurant_list_screen.dart';
import '../../presentation/screens/menu_screen.dart';
import '../../presentation/screens/cart_screen.dart';
import '../../presentation/screens/checkout_screen.dart';
import '../../presentation/screens/order_confirmation_screen.dart';
import '../../presentation/screens/order_failure_screen.dart';
import '../../data/models/restaurant.dart';
import '../../data/models/order.dart';
import '../../data/models/cart_item.dart';

/// Application routes
class AppRoutes {
  static const String restaurants = '/restaurants';
  static const String menu = '/menu';
  static const String cart = '/cart';
  static const String checkout = '/checkout';
  static const String orderConfirmation = '/order-confirmation';
  static const String orderFailure = '/order-failure';
  
  static const String initial = restaurants;
}

/// Route arguments
class MenuScreenArguments {
  final Restaurant restaurant;
  const MenuScreenArguments({required this.restaurant});
}

class OrderConfirmationArguments {
  final Order order;
  const OrderConfirmationArguments({required this.order});
}

class OrderFailureArguments {
  final String errorMessage;
  final String? errorCode;
  final bool canRetry;
  final List<CartItem> cartItems;
  final String restaurantId;
  
  const OrderFailureArguments({
    required this.errorMessage,
    this.errorCode,
    required this.canRetry,
    required this.cartItems,
    required this.restaurantId,
  });
}

/// Main router class handling all navigation logic
class AppRouter {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.restaurants:
        return _buildRoute(const RestaurantListScreen(), settings);
        
      case AppRoutes.menu:
        final args = settings.arguments as MenuScreenArguments?;
        if (args != null) {
          return _buildRoute(MenuScreen(restaurant: args.restaurant), settings);
        }
        return _errorRoute(settings);
        
      case AppRoutes.cart:
        return _buildRoute(const CartScreen(), settings);
        
      case AppRoutes.checkout:
        return _buildRoute(const CheckoutScreen(), settings);
        
      case AppRoutes.orderConfirmation:
        final args = settings.arguments as OrderConfirmationArguments?;
        if (args != null) {
          return _buildRoute(OrderConfirmationScreen(order: args.order), settings);
        }
        return _errorRoute(settings);
        
      case AppRoutes.orderFailure:
        final args = settings.arguments as OrderFailureArguments?;
        if (args != null) {
          return _buildRoute(
            OrderFailureScreen(
              errorMessage: args.errorMessage,
              errorCode: args.errorCode,
              canRetry: args.canRetry,
              cartItems: args.cartItems,
              restaurantId: args.restaurantId,
            ),
            settings,
          );
        }
        return _errorRoute(settings);
        
      default:
        return _errorRoute(settings);
    }
  }
  
  static MaterialPageRoute<T> _buildRoute<T>(Widget page, RouteSettings settings) {
    return MaterialPageRoute<T>(
      builder: (_) => page,
      settings: settings,
    );
  }
  
  static Route<dynamic> _errorRoute(RouteSettings settings) {
    return MaterialPageRoute(
      builder: (context) => Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                'Route not found: ${settings.name}',
                style: const TextStyle(fontSize: 18),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pushReplacementNamed(AppRoutes.restaurants),
                child: const Text('Go to Home'),
              ),
            ],
          ),
        ),
      ),
      settings: settings,
    );
  }
}