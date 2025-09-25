import 'package:equatable/equatable.dart';
import '../../../data/models/cart_item.dart';

/// Base class for all cart-related states
abstract class CartState extends Equatable {
  const CartState();

  @override
  List<Object?> get props => [];
}

/// Initial state when the bloc is first created
class CartInitial extends CartState {
  const CartInitial();
}

/// State when cart is being loaded from storage
class CartLoading extends CartState {
  const CartLoading();
}

/// State representing the current cart with items and calculations
class CartUpdated extends CartState {
  final List<CartItem> items;
  final double subtotal;
  final double deliveryFee;
  final double tax;
  final double total;
  final int totalItems;
  final String? currentRestaurantId;

  const CartUpdated({
    required this.items,
    required this.subtotal,
    required this.deliveryFee,
    required this.tax,
    required this.total,
    required this.totalItems,
    this.currentRestaurantId,
  });

  @override
  List<Object?> get props => [
        items,
        subtotal,
        deliveryFee,
        tax,
        total,
        totalItems,
        currentRestaurantId,
      ];

  /// Create a copy of this state with updated values
  CartUpdated copyWith({
    List<CartItem>? items,
    double? subtotal,
    double? deliveryFee,
    double? tax,
    double? total,
    int? totalItems,
    String? currentRestaurantId,
  }) {
    return CartUpdated(
      items: items ?? this.items,
      subtotal: subtotal ?? this.subtotal,
      deliveryFee: deliveryFee ?? this.deliveryFee,
      tax: tax ?? this.tax,
      total: total ?? this.total,
      totalItems: totalItems ?? this.totalItems,
      currentRestaurantId: currentRestaurantId ?? this.currentRestaurantId,
    );
  }

  /// Check if cart is empty
  bool get isEmpty => items.isEmpty;

  /// Check if cart has items
  bool get hasItems => items.isNotEmpty;

  /// Get cart item by menu item ID
  CartItem? getCartItem(String menuItemId) {
    try {
      return items.firstWhere((item) => item.menuItem.id == menuItemId);
    } catch (e) {
      return null;
    }
  }

  /// Check if a menu item is in the cart
  bool containsItem(String menuItemId) {
    return items.any((item) => item.menuItem.id == menuItemId);
  }

  /// Get quantity of a specific menu item in cart
  int getItemQuantity(String menuItemId) {
    final cartItem = getCartItem(menuItemId);
    return cartItem?.quantity ?? 0;
  }

  /// Check if cart contains items from multiple restaurants
  bool get hasMultipleRestaurants {
    if (items.isEmpty) return false;
    final firstRestaurantId = items.first.restaurantId;
    return items.any((item) => item.restaurantId != firstRestaurantId);
  }

  /// Get all unique restaurant IDs in the cart
  Set<String> get restaurantIds {
    return items.map((item) => item.restaurantId).toSet();
  }
}

/// State when an error occurs during cart operations
class CartError extends CartState {
  final String message;
  final List<CartItem> items;

  const CartError({
    required this.message,
    this.items = const [],
  });

  @override
  List<Object?> get props => [message, items];
}