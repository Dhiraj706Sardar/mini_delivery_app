import 'package:equatable/equatable.dart';
import '../../../data/models/cart_item.dart';

/// Base class for all order events
abstract class OrderEvent extends Equatable {
  const OrderEvent();

  @override
  List<Object?> get props => [];
}

/// Event to place an order with cart items
class PlaceOrder extends OrderEvent {
  final List<CartItem> cartItems;
  final String restaurantId;
  final double deliveryFee;
  final double taxRate;

  const PlaceOrder({
    required this.cartItems,
    required this.restaurantId,
    this.deliveryFee = 2.99,
    this.taxRate = 0.08,
  });

  @override
  List<Object?> get props => [cartItems, restaurantId, deliveryFee, taxRate];

  @override
  String toString() {
    return 'PlaceOrder(cartItems: ${cartItems.length}, restaurantId: $restaurantId, deliveryFee: $deliveryFee, taxRate: $taxRate)';
  }
}

/// Event to confirm an order after validation
class ConfirmOrder extends OrderEvent {
  final String orderId;

  const ConfirmOrder({
    required this.orderId,
  });

  @override
  List<Object?> get props => [orderId];

  @override
  String toString() {
    return 'ConfirmOrder(orderId: $orderId)';
  }
}

/// Event to retry a failed order
class RetryOrder extends OrderEvent {
  final List<CartItem> cartItems;
  final String restaurantId;
  final double deliveryFee;
  final double taxRate;

  const RetryOrder({
    required this.cartItems,
    required this.restaurantId,
    this.deliveryFee = 2.99,
    this.taxRate = 0.08,
  });

  @override
  List<Object?> get props => [cartItems, restaurantId, deliveryFee, taxRate];

  @override
  String toString() {
    return 'RetryOrder(cartItems: ${cartItems.length}, restaurantId: $restaurantId, deliveryFee: $deliveryFee, taxRate: $taxRate)';
  }
}

/// Event to reset order state
class ResetOrder extends OrderEvent {
  const ResetOrder();

  @override
  String toString() {
    return 'ResetOrder()';
  }
}