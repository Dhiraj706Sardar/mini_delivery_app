import 'package:equatable/equatable.dart';
import '../../../data/models/order.dart';

/// Base class for all order states
abstract class OrderState extends Equatable {
  const OrderState();

  @override
  List<Object?> get props => [];
}

/// Initial state when no order operations have been performed
class OrderInitial extends OrderState {
  const OrderInitial();

  @override
  String toString() => 'OrderInitial()';
}

/// State when order is being processed
class OrderProcessing extends OrderState {
  final String? message;

  const OrderProcessing({this.message});

  @override
  List<Object?> get props => [message];

  @override
  String toString() => 'OrderProcessing(message: $message)';
}

/// State when order has been successfully placed
class OrderSuccess extends OrderState {
  final Order order;
  final String? message;

  const OrderSuccess({
    required this.order,
    this.message,
  });

  @override
  List<Object?> get props => [order, message];

  @override
  String toString() => 'OrderSuccess(order: ${order.id}, message: $message)';
}

/// State when order placement has failed
class OrderError extends OrderState {
  final String message;
  final String? errorCode;
  final bool canRetry;

  const OrderError({
    required this.message,
    this.errorCode,
    this.canRetry = true,
  });

  @override
  List<Object?> get props => [message, errorCode, canRetry];

  @override
  String toString() => 'OrderError(message: $message, errorCode: $errorCode, canRetry: $canRetry)';
}

/// State when order is being validated before placement
class OrderValidating extends OrderState {
  const OrderValidating();

  @override
  String toString() => 'OrderValidating()';
}

/// State when order has been confirmed and is awaiting processing
class OrderConfirmed extends OrderState {
  final Order order;
  final String? confirmationMessage;

  const OrderConfirmed({
    required this.order,
    this.confirmationMessage,
  });

  @override
  List<Object?> get props => [order, confirmationMessage];

  @override
  String toString() => 'OrderConfirmed(order: ${order.id}, confirmationMessage: $confirmationMessage)';
}