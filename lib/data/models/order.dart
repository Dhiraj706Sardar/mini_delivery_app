import 'package:equatable/equatable.dart';
import 'cart_item.dart';

enum OrderStatus {
  pending,
  confirmed,
  preparing,
  outForDelivery,
  delivered,
  cancelled,
}

class Order extends Equatable {
  final String id;
  final List<CartItem> items;
  final double subtotal;
  final double deliveryFee;
  final double tax;
  final double total;
  final DateTime orderTime;
  final OrderStatus status;
  final String restaurantId;

  const Order({
    required this.id,
    required this.items,
    required this.subtotal,
    required this.deliveryFee,
    required this.tax,
    required this.total,
    required this.orderTime,
    required this.status,
    required this.restaurantId,
  });

  // Factory constructor to create order from cart items
  factory Order.fromCartItems({
    required String id,
    required List<CartItem> items,
    required String restaurantId,
    double deliveryFee = 2.99,
    double taxRate = 0.08, // 8% tax rate
    DateTime? orderTime,
    OrderStatus status = OrderStatus.pending,
  }) {
    final subtotal = _calculateSubtotal(items);
    final tax = subtotal * taxRate;
    final total = subtotal + deliveryFee + tax;

    return Order(
      id: id,
      items: items,
      subtotal: subtotal,
      deliveryFee: deliveryFee,
      tax: tax,
      total: total,
      orderTime: orderTime ?? DateTime.now(),
      status: status,
      restaurantId: restaurantId,
    );
  }

  // JSON serialization
  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id']?.toString() ?? '',
      items: (json['items'] as List<dynamic>?)
              ?.map((item) => CartItem.fromJson(item))
              .toList() ??
          [],
      subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0.0,
      deliveryFee: (json['deliveryFee'] as num?)?.toDouble() ?? 0.0,
      tax: (json['tax'] as num?)?.toDouble() ?? 0.0,
      total: (json['total'] as num?)?.toDouble() ?? 0.0,
      orderTime: DateTime.tryParse(json['orderTime']?.toString() ?? '') ?? DateTime.now(),
      status: _parseOrderStatus(json['status']?.toString()),
      restaurantId: json['restaurantId']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'items': items.map((item) => item.toJson()).toList(),
      'subtotal': subtotal,
      'deliveryFee': deliveryFee,
      'tax': tax,
      'total': total,
      'orderTime': orderTime.toIso8601String(),
      'status': status.name,
      'restaurantId': restaurantId,
    };
  }

  // Static method to calculate subtotal from cart items
  static double _calculateSubtotal(List<CartItem> items) {
    return items.fold(0.0, (sum, item) => sum + item.totalPrice);
  }

  // Static method to parse order status from string
  static OrderStatus _parseOrderStatus(String? statusString) {
    if (statusString == null) return OrderStatus.pending;
    
    try {
      return OrderStatus.values.firstWhere(
        (status) => status.name.toLowerCase() == statusString.toLowerCase(),
        orElse: () => OrderStatus.pending,
      );
    } catch (e) {
      return OrderStatus.pending;
    }
  }

  // Calculate total number of items in the order
  int get totalItemCount {
    return items.fold(0, (sum, item) => sum + item.quantity);
  }

  // Get all unique restaurant IDs (should be one for a valid order)
  Set<String> get restaurantIds {
    return items.map((item) => item.restaurantId).toSet();
  }

  // Validation
  bool get isValid {
    return id.isNotEmpty &&
        items.isNotEmpty &&
        restaurantId.isNotEmpty &&
        items.every((item) => item.isValid) &&
        items.every((item) => item.restaurantId == restaurantId) && // All items from same restaurant
        subtotal >= 0 &&
        deliveryFee >= 0 &&
        tax >= 0 &&
        total >= 0;
  }

  // Check if order can be cancelled
  bool get canBeCancelled {
    return status == OrderStatus.pending || status == OrderStatus.confirmed;
  }

  // Check if order is completed
  bool get isCompleted {
    return status == OrderStatus.delivered || status == OrderStatus.cancelled;
  }

  // Price calculation methods
  double calculateSubtotal() => _calculateSubtotal(items);
  
  double calculateTax(double taxRate) => subtotal * taxRate;
  
  double calculateTotal({double? customDeliveryFee, double? customTaxRate}) {
    final delivery = customDeliveryFee ?? deliveryFee;
    final taxAmount = customTaxRate != null ? subtotal * customTaxRate : tax;
    return subtotal + delivery + taxAmount;
  }

  // Copy with method for immutability
  Order copyWith({
    String? id,
    List<CartItem>? items,
    double? subtotal,
    double? deliveryFee,
    double? tax,
    double? total,
    DateTime? orderTime,
    OrderStatus? status,
    String? restaurantId,
  }) {
    return Order(
      id: id ?? this.id,
      items: items ?? this.items,
      subtotal: subtotal ?? this.subtotal,
      deliveryFee: deliveryFee ?? this.deliveryFee,
      tax: tax ?? this.tax,
      total: total ?? this.total,
      orderTime: orderTime ?? this.orderTime,
      status: status ?? this.status,
      restaurantId: restaurantId ?? this.restaurantId,
    );
  }

  @override
  List<Object?> get props => [
        id,
        items,
        subtotal,
        deliveryFee,
        tax,
        total,
        orderTime,
        status,
        restaurantId,
      ];

  @override
  String toString() {
    return 'Order(id: $id, items: ${items.length}, subtotal: $subtotal, deliveryFee: $deliveryFee, tax: $tax, total: $total, orderTime: $orderTime, status: $status, restaurantId: $restaurantId)';
  }
}