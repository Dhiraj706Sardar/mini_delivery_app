import 'dart:async';
import 'dart:math';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/models/order.dart';
import '../../../data/models/cart_item.dart';
import 'order_event.dart';
import 'order_state.dart';

/// BLoC for managing order-related state and business logic
class OrderBloc extends Bloc<OrderEvent, OrderState> {
  // Order configuration constants
  static const double _minOrderAmount = 5.0;
  static const double _maxOrderAmount = 10000.0; // Increased to allow larger orders
  static const int _maxItemsPerOrder = 50;
  static const Duration _orderProcessingDelay = Duration(milliseconds: 100);

  OrderBloc() : super(const OrderInitial()) {
    on<PlaceOrder>(_onPlaceOrder);
    on<ConfirmOrder>(_onConfirmOrder);
    on<RetryOrder>(_onRetryOrder);
    on<ResetOrder>(_onResetOrder);
  }

  /// Handles the PlaceOrder event
  Future<void> _onPlaceOrder(
    PlaceOrder event,
    Emitter<OrderState> emit,
  ) async {
    try {
      // Emit validating state
      emit(const OrderValidating());

      // Validate order
      final validationResult = _validateOrder(
        event.cartItems,
        event.restaurantId,
        event.deliveryFee,
        event.taxRate,
      );

      if (!validationResult.isValid) {
        emit(OrderError(
          message: validationResult.errorMessage!,
          canRetry: validationResult.canRetry,
        ));
        return;
      }

      // Emit processing state
      emit(const OrderProcessing(message: 'Processing your order...'));

      // Simulate order processing delay
      await Future.delayed(_orderProcessingDelay);

      // Create order
      final order = _createOrder(
        event.cartItems,
        event.restaurantId,
        event.deliveryFee,
        event.taxRate,
      );

      // Simulate order placement (in real app, this would be an API call)
      final success = await _simulateOrderPlacement(order);

      if (success) {
        emit(OrderSuccess(
          order: order,
          message: 'Order placed successfully!',
        ));
      } else {
        emit(const OrderError(
          message: 'Failed to place order. Please try again.',
          errorCode: 'ORDER_PLACEMENT_FAILED',
          canRetry: true,
        ));
      }
    } catch (error) {
      emit(OrderError(
        message: 'An unexpected error occurred: ${error.toString()}',
        errorCode: 'UNEXPECTED_ERROR',
        canRetry: true,
      ));
    }
  }

  /// Handles the ConfirmOrder event
  Future<void> _onConfirmOrder(
    ConfirmOrder event,
    Emitter<OrderState> emit,
  ) async {
    try {
      final currentState = state;
      
      if (currentState is! OrderSuccess) {
        emit(const OrderError(
          message: 'No order to confirm',
          canRetry: false,
        ));
        return;
      }

      // Emit processing state
      emit(const OrderProcessing(message: 'Confirming your order...'));

      // Simulate confirmation delay
      await Future.delayed(const Duration(milliseconds: 50));

      // Update order status to confirmed
      final confirmedOrder = currentState.order.copyWith(
        status: OrderStatus.confirmed,
      );

      emit(OrderConfirmed(
        order: confirmedOrder,
        confirmationMessage: 'Your order has been confirmed and is being prepared!',
      ));
    } catch (error) {
      emit(OrderError(
        message: 'Failed to confirm order: ${error.toString()}',
        errorCode: 'CONFIRMATION_FAILED',
        canRetry: true,
      ));
    }
  }

  /// Handles the RetryOrder event
  Future<void> _onRetryOrder(
    RetryOrder event,
    Emitter<OrderState> emit,
  ) async {
    // Retry by placing the order again
    add(PlaceOrder(
      cartItems: event.cartItems,
      restaurantId: event.restaurantId,
      deliveryFee: event.deliveryFee,
      taxRate: event.taxRate,
    ));
  }

  /// Handles the ResetOrder event
  void _onResetOrder(
    ResetOrder event,
    Emitter<OrderState> emit,
  ) {
    emit(const OrderInitial());
  }

  /// Validates order before placement
  OrderValidationResult _validateOrder(
    List<CartItem> cartItems,
    String restaurantId,
    double deliveryFee,
    double taxRate,
  ) {
    // Check if cart is empty
    if (cartItems.isEmpty) {
      return const OrderValidationResult(
        isValid: false,
        errorMessage: 'Cart is empty. Please add items before placing an order.',
        canRetry: false,
      );
    }

    // Check restaurant ID
    if (restaurantId.isEmpty) {
      return const OrderValidationResult(
        isValid: false,
        errorMessage: 'Invalid restaurant selection.',
        canRetry: false,
      );
    }

    // Validate all cart items
    for (final item in cartItems) {
      if (!item.isValid) {
        return const OrderValidationResult(
          isValid: false,
          errorMessage: 'Invalid item in cart. Please review your order.',
          canRetry: false,
        );
      }

      if (item.restaurantId != restaurantId) {
        return const OrderValidationResult(
          isValid: false,
          errorMessage: 'All items must be from the same restaurant.',
          canRetry: false,
        );
      }
    }

    // Check total items count
    final totalItems = cartItems.fold<int>(0, (sum, item) => sum + item.quantity);
    if (totalItems > _maxItemsPerOrder) {
      return OrderValidationResult(
        isValid: false,
        errorMessage: 'Maximum $_maxItemsPerOrder items allowed per order.',
        canRetry: false,
      );
    }

    // Calculate subtotal
    final subtotal = cartItems.fold<double>(0.0, (sum, item) => sum + item.totalPrice);

    // Check minimum order amount
    if (subtotal < _minOrderAmount) {
      return OrderValidationResult(
        isValid: false,
        errorMessage: 'Minimum order amount is \$${_minOrderAmount.toStringAsFixed(2)}.',
        canRetry: false,
      );
    }

    // Check maximum order amount
    if (subtotal > _maxOrderAmount) {
      return OrderValidationResult(
        isValid: false,
        errorMessage: 'Maximum order amount is \$${_maxOrderAmount.toStringAsFixed(2)}.',
        canRetry: false,
      );
    }

    // Validate delivery fee and tax rate
    if (deliveryFee < 0 || taxRate < 0 || taxRate > 1) {
      return const OrderValidationResult(
        isValid: false,
        errorMessage: 'Invalid pricing configuration.',
        canRetry: true,
      );
    }

    return const OrderValidationResult(isValid: true);
  }

  /// Creates an order from cart items
  Order _createOrder(
    List<CartItem> cartItems,
    String restaurantId,
    double deliveryFee,
    double taxRate,
  ) {
    // Generate unique order ID
    final orderId = _generateOrderId();

    return Order.fromCartItems(
      id: orderId,
      items: cartItems,
      restaurantId: restaurantId,
      deliveryFee: deliveryFee,
      taxRate: taxRate,
      orderTime: DateTime.now(),
      status: OrderStatus.pending,
    );
  }

  /// Simulates order placement (in real app, this would be an API call)
  Future<bool> _simulateOrderPlacement(Order order) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 100));

    // For testing purposes, always return success
    // In real implementation, this would be an actual API call
    return true;
  }

  /// Generates a unique order ID
  String _generateOrderId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = Random().nextInt(9999);
    return 'ORD-$timestamp-$random';
  }
}

/// Result of order validation
class OrderValidationResult {
  final bool isValid;
  final String? errorMessage;
  final bool canRetry;

  const OrderValidationResult({
    required this.isValid,
    this.errorMessage,
    this.canRetry = true,
  });
}