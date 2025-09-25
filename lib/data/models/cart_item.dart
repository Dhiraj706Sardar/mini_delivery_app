import 'package:equatable/equatable.dart';
import 'menu_item.dart';

class CartItem extends Equatable {
  final MenuItem menuItem;
  final int quantity;
  final String restaurantId;

  const CartItem({
    required this.menuItem,
    required this.quantity,
    required this.restaurantId,
  });

  // JSON serialization
  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      menuItem: MenuItem.fromJson(json['menuItem'] ?? {}),
      quantity: (json['quantity'] as num?)?.toInt() ?? 1,
      restaurantId: json['restaurantId']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'menuItem': menuItem.toJson(),
      'quantity': quantity,
      'restaurantId': restaurantId,
    };
  }

  // Calculate total price for this cart item
  double get totalPrice => menuItem.itemPrice * quantity;

  // Validation
  bool get isValid {
    return menuItem.isValid &&
        quantity > 0 &&
        restaurantId.isNotEmpty;
  }

  // Quantity management methods
  CartItem increaseQuantity() {
    return copyWith(quantity: quantity + 1);
  }

  CartItem decreaseQuantity() {
    if (quantity <= 1) {
      return this; // Don't allow quantity to go below 1
    }
    return copyWith(quantity: quantity - 1);
  }

  CartItem updateQuantity(int newQuantity) {
    if (newQuantity <= 0) {
      return this; // Don't allow quantity to go below 1
    }
    return copyWith(quantity: newQuantity);
  }

  // Copy with method for immutability
  CartItem copyWith({
    MenuItem? menuItem,
    int? quantity,
    String? restaurantId,
  }) {
    return CartItem(
      menuItem: menuItem ?? this.menuItem,
      quantity: quantity ?? this.quantity,
      restaurantId: restaurantId ?? this.restaurantId,
    );
  }

  @override
  List<Object?> get props => [
        menuItem,
        quantity,
        restaurantId,
      ];

  @override
  String toString() {
    return 'CartItem(menuItem: $menuItem, quantity: $quantity, restaurantId: $restaurantId, totalPrice: $totalPrice)';
  }
}