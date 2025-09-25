import 'package:flutter_test/flutter_test.dart';
import 'package:deliery_app/data/models/order.dart';
import 'package:deliery_app/data/models/cart_item.dart';
import 'package:deliery_app/data/models/menu_item.dart';

void main() {
  group('Order Model', () {
    const testMenuItem1 = MenuItem(
      id: '1',
      itemName: 'Margherita Pizza',
      itemDescription: 'Classic pizza with tomato sauce and mozzarella',
      itemPrice: 12.99,
      imageUrl: 'https://example.com/pizza.jpg',
      category: 'Pizza',
    );

    const testMenuItem2 = MenuItem(
      id: '2',
      itemName: 'Caesar Salad',
      itemDescription: 'Fresh romaine lettuce with caesar dressing',
      itemPrice: 8.99,
      imageUrl: 'https://example.com/salad.jpg',
      category: 'Salad',
    );

    const testCartItem1 = CartItem(
      menuItem: testMenuItem1,
      quantity: 2,
      restaurantId: 'restaurant_1',
    );

    const testCartItem2 = CartItem(
      menuItem: testMenuItem2,
      quantity: 1,
      restaurantId: 'restaurant_1',
    );

    final testOrderTime = DateTime(2024, 1, 15, 12, 30);

    final testOrder = Order(
      id: 'order_1',
      items: [testCartItem1, testCartItem2],
      subtotal: 34.97, // (12.99 * 2) + (8.99 * 1)
      deliveryFee: 2.99,
      tax: 2.80, // 8% of subtotal
      total: 40.76, // subtotal + deliveryFee + tax
      orderTime: testOrderTime,
      status: OrderStatus.pending,
      restaurantId: 'restaurant_1',
    );

    group('Factory Constructor', () {
      test('should create order from cart items with correct calculations', () {
        // Act
        final order = Order.fromCartItems(
          id: 'order_1',
          items: [testCartItem1, testCartItem2],
          restaurantId: 'restaurant_1',
          deliveryFee: 2.99,
          taxRate: 0.08,
          orderTime: testOrderTime,
        );

        // Assert
        expect(order.id, 'order_1');
        expect(order.items, [testCartItem1, testCartItem2]);
        expect(order.subtotal, 34.97);
        expect(order.deliveryFee, 2.99);
        expect(order.tax, closeTo(2.80, 0.01)); // Allow for floating point precision
        expect(order.total, closeTo(40.76, 0.01));
        expect(order.orderTime, testOrderTime);
        expect(order.status, OrderStatus.pending);
        expect(order.restaurantId, 'restaurant_1');
      });

      test('should use default values when not provided', () {
        // Act
        final order = Order.fromCartItems(
          id: 'order_1',
          items: [testCartItem1],
          restaurantId: 'restaurant_1',
        );

        // Assert
        expect(order.deliveryFee, 2.99);
        expect(order.tax, closeTo(2.08, 0.01)); // 8% of 25.98
        expect(order.status, OrderStatus.pending);
        expect(order.orderTime, isA<DateTime>());
      });
    });

    group('JSON Serialization', () {
      test('should create Order from valid JSON', () {
        // Arrange
        final json = {
          'id': 'order_1',
          'items': [testCartItem1.toJson(), testCartItem2.toJson()],
          'subtotal': 34.97,
          'deliveryFee': 2.99,
          'tax': 2.80,
          'total': 40.76,
          'orderTime': testOrderTime.toIso8601String(),
          'status': 'pending',
          'restaurantId': 'restaurant_1',
        };

        // Act
        final order = Order.fromJson(json);

        // Assert
        expect(order.id, 'order_1');
        expect(order.items.length, 2);
        expect(order.subtotal, 34.97);
        expect(order.deliveryFee, 2.99);
        expect(order.tax, 2.80);
        expect(order.total, 40.76);
        expect(order.orderTime, testOrderTime);
        expect(order.status, OrderStatus.pending);
        expect(order.restaurantId, 'restaurant_1');
      });

      test('should handle null values in JSON gracefully', () {
        // Arrange
        const nullJson = {
          'id': null,
          'items': null,
          'subtotal': null,
          'deliveryFee': null,
          'tax': null,
          'total': null,
          'orderTime': null,
          'status': null,
          'restaurantId': null,
        };

        // Act
        final order = Order.fromJson(nullJson);

        // Assert
        expect(order.id, '');
        expect(order.items, []);
        expect(order.subtotal, 0.0);
        expect(order.deliveryFee, 0.0);
        expect(order.tax, 0.0);
        expect(order.total, 0.0);
        expect(order.status, OrderStatus.pending);
        expect(order.restaurantId, '');
      });

      test('should convert Order to JSON correctly', () {
        // Act
        final json = testOrder.toJson();

        // Assert
        expect(json['id'], 'order_1');
        expect(json['items'], isA<List>());
        expect(json['subtotal'], 34.97);
        expect(json['deliveryFee'], 2.99);
        expect(json['tax'], 2.80);
        expect(json['total'], 40.76);
        expect(json['orderTime'], testOrderTime.toIso8601String());
        expect(json['status'], 'pending');
        expect(json['restaurantId'], 'restaurant_1');
      });
    });

    group('Order Status Parsing', () {
      test('should parse valid order status strings', () {
        // Arrange & Act
        final pendingOrder = Order.fromJson({'status': 'pending'});
        final confirmedOrder = Order.fromJson({'status': 'confirmed'});
        final preparingOrder = Order.fromJson({'status': 'preparing'});
        final deliveryOrder = Order.fromJson({'status': 'outForDelivery'});
        final deliveredOrder = Order.fromJson({'status': 'delivered'});
        final cancelledOrder = Order.fromJson({'status': 'cancelled'});

        // Assert
        expect(pendingOrder.status, OrderStatus.pending);
        expect(confirmedOrder.status, OrderStatus.confirmed);
        expect(preparingOrder.status, OrderStatus.preparing);
        expect(deliveryOrder.status, OrderStatus.outForDelivery);
        expect(deliveredOrder.status, OrderStatus.delivered);
        expect(cancelledOrder.status, OrderStatus.cancelled);
      });

      test('should default to pending for invalid status', () {
        // Arrange & Act
        final invalidOrder = Order.fromJson({'status': 'invalid_status'});

        // Assert
        expect(invalidOrder.status, OrderStatus.pending);
      });
    });

    group('Price Calculations', () {
      test('should calculate subtotal correctly', () {
        // Act
        final calculatedSubtotal = testOrder.calculateSubtotal();

        // Assert
        expect(calculatedSubtotal, 34.97);
      });

      test('should calculate tax correctly', () {
        // Act
        final calculatedTax = testOrder.calculateTax(0.08);

        // Assert
        expect(calculatedTax, closeTo(2.80, 0.01));
      });

      test('should calculate total with custom values', () {
        // Act
        final calculatedTotal = testOrder.calculateTotal(
          customDeliveryFee: 5.00,
          customTaxRate: 0.10,
        );

        // Assert
        expect(calculatedTotal, closeTo(43.47, 0.01)); // 34.97 + 5.00 + 3.50
      });

      test('should calculate total with existing values when no custom values provided', () {
        // Act
        final calculatedTotal = testOrder.calculateTotal();

        // Assert
        expect(calculatedTotal, closeTo(40.76, 0.01));
      });
    });

    group('Order Properties', () {
      test('should calculate total item count correctly', () {
        // Act
        final totalItemCount = testOrder.totalItemCount;

        // Assert
        expect(totalItemCount, 3); // 2 + 1
      });

      test('should return restaurant IDs correctly', () {
        // Act
        final restaurantIds = testOrder.restaurantIds;

        // Assert
        expect(restaurantIds, {'restaurant_1'});
      });

      test('should detect multiple restaurant IDs', () {
        // Arrange
        const mixedCartItem = CartItem(
          menuItem: testMenuItem1,
          quantity: 1,
          restaurantId: 'restaurant_2',
        );
        final mixedOrder = testOrder.copyWith(items: [testCartItem1, mixedCartItem]);

        // Act
        final restaurantIds = mixedOrder.restaurantIds;

        // Assert
        expect(restaurantIds, {'restaurant_1', 'restaurant_2'});
      });
    });

    group('Order Status Checks', () {
      test('should identify cancellable orders', () {
        // Arrange
        final pendingOrder = testOrder.copyWith(status: OrderStatus.pending);
        final confirmedOrder = testOrder.copyWith(status: OrderStatus.confirmed);
        final preparingOrder = testOrder.copyWith(status: OrderStatus.preparing);

        // Assert
        expect(pendingOrder.canBeCancelled, true);
        expect(confirmedOrder.canBeCancelled, true);
        expect(preparingOrder.canBeCancelled, false);
      });

      test('should identify completed orders', () {
        // Arrange
        final deliveredOrder = testOrder.copyWith(status: OrderStatus.delivered);
        final cancelledOrder = testOrder.copyWith(status: OrderStatus.cancelled);
        final pendingOrder = testOrder.copyWith(status: OrderStatus.pending);

        // Assert
        expect(deliveredOrder.isCompleted, true);
        expect(cancelledOrder.isCompleted, true);
        expect(pendingOrder.isCompleted, false);
      });
    });

    group('Validation', () {
      test('should return true for valid order', () {
        // Assert
        expect(testOrder.isValid, true);
      });

      test('should return false for order with empty id', () {
        // Arrange
        final invalidOrder = testOrder.copyWith(id: '');

        // Assert
        expect(invalidOrder.isValid, false);
      });

      test('should return false for order with empty items', () {
        // Arrange
        final invalidOrder = testOrder.copyWith(items: []);

        // Assert
        expect(invalidOrder.isValid, false);
      });

      test('should return false for order with empty restaurant ID', () {
        // Arrange
        final invalidOrder = testOrder.copyWith(restaurantId: '');

        // Assert
        expect(invalidOrder.isValid, false);
      });

      test('should return false for order with items from different restaurants', () {
        // Arrange
        const mixedCartItem = CartItem(
          menuItem: testMenuItem1,
          quantity: 1,
          restaurantId: 'restaurant_2',
        );
        final invalidOrder = testOrder.copyWith(items: [testCartItem1, mixedCartItem]);

        // Assert
        expect(invalidOrder.isValid, false);
      });

      test('should return false for order with negative prices', () {
        // Arrange
        final invalidOrder1 = testOrder.copyWith(subtotal: -10.0);
        final invalidOrder2 = testOrder.copyWith(deliveryFee: -5.0);
        final invalidOrder3 = testOrder.copyWith(tax: -2.0);
        final invalidOrder4 = testOrder.copyWith(total: -20.0);

        // Assert
        expect(invalidOrder1.isValid, false);
        expect(invalidOrder2.isValid, false);
        expect(invalidOrder3.isValid, false);
        expect(invalidOrder4.isValid, false);
      });
    });

    group('Equality', () {
      test('should be equal when all properties are the same', () {
        // Arrange
        final order1 = Order(
          id: 'order_1',
          items: [testCartItem1, testCartItem2],
          subtotal: 34.97,
          deliveryFee: 2.99,
          tax: 2.80,
          total: 40.76,
          orderTime: testOrderTime,
          status: OrderStatus.pending,
          restaurantId: 'restaurant_1',
        );

        final order2 = Order(
          id: 'order_1',
          items: [testCartItem1, testCartItem2],
          subtotal: 34.97,
          deliveryFee: 2.99,
          tax: 2.80,
          total: 40.76,
          orderTime: testOrderTime,
          status: OrderStatus.pending,
          restaurantId: 'restaurant_1',
        );

        // Assert
        expect(order1, order2);
        expect(order1.hashCode, order2.hashCode);
      });

      test('should not be equal when properties differ', () {
        // Arrange
        final order2 = testOrder.copyWith(status: OrderStatus.confirmed);

        // Assert
        expect(testOrder, isNot(order2));
      });
    });

    group('CopyWith', () {
      test('should create new instance with updated properties', () {
        // Act
        final updatedOrder = testOrder.copyWith(
          status: OrderStatus.confirmed,
          total: 45.00,
        );

        // Assert
        expect(updatedOrder.status, OrderStatus.confirmed);
        expect(updatedOrder.total, 45.00);
        expect(updatedOrder.id, testOrder.id);
        expect(updatedOrder.items, testOrder.items);
      });

      test('should keep original values when no parameters provided', () {
        // Act
        final copiedOrder = testOrder.copyWith();

        // Assert
        expect(copiedOrder, testOrder);
      });
    });

    group('ToString', () {
      test('should return formatted string representation', () {
        // Act
        final stringRepresentation = testOrder.toString();

        // Assert
        expect(stringRepresentation, contains('Order('));
        expect(stringRepresentation, contains('id: order_1'));
        expect(stringRepresentation, contains('items: 2'));
        expect(stringRepresentation, contains('total: 40.76'));
        expect(stringRepresentation, contains('status: OrderStatus.pending'));
      });
    });
  });
}