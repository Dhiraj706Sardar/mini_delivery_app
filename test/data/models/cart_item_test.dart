import 'package:flutter_test/flutter_test.dart';
import 'package:deliery_app/data/models/cart_item.dart';
import 'package:deliery_app/data/models/menu_item.dart';

void main() {
  group('CartItem Model', () {
    const testMenuItem = MenuItem(
      id: '1',
      itemName: 'Margherita Pizza',
      itemDescription: 'Classic pizza with tomato sauce and mozzarella',
      itemPrice: 12.99,
      imageUrl: 'https://example.com/pizza.jpg',
      category: 'Pizza',
    );

    const testCartItem = CartItem(
      menuItem: testMenuItem,
      quantity: 2,
      restaurantId: 'restaurant_1',
    );

    final testJson = {
      'menuItem': testMenuItem.toJson(),
      'quantity': 2,
      'restaurantId': 'restaurant_1',
    };

    group('JSON Serialization', () {
      test('should create CartItem from valid JSON', () {
        // Act
        final cartItem = CartItem.fromJson(testJson);

        // Assert
        expect(cartItem.menuItem, testMenuItem);
        expect(cartItem.quantity, 2);
        expect(cartItem.restaurantId, 'restaurant_1');
      });

      test('should handle null values in JSON gracefully', () {
        // Arrange
        const nullJson = {
          'menuItem': null,
          'quantity': null,
          'restaurantId': null,
        };

        // Act
        final cartItem = CartItem.fromJson(nullJson);

        // Assert
        expect(cartItem.quantity, 1);
        expect(cartItem.restaurantId, '');
      });

      test('should convert CartItem to JSON correctly', () {
        // Act
        final json = testCartItem.toJson();

        // Assert
        expect(json, testJson);
      });
    });

    group('Price Calculations', () {
      test('should calculate total price correctly', () {
        // Act
        final totalPrice = testCartItem.totalPrice;

        // Assert
        expect(totalPrice, 25.98); // 12.99 * 2
      });

      test('should calculate total price for single item', () {
        // Arrange
        final singleCartItem = testCartItem.copyWith(quantity: 1);

        // Act
        final totalPrice = singleCartItem.totalPrice;

        // Assert
        expect(totalPrice, 12.99);
      });

      test('should calculate total price for multiple items', () {
        // Arrange
        final multipleCartItem = testCartItem.copyWith(quantity: 5);

        // Act
        final totalPrice = multipleCartItem.totalPrice;

        // Assert
        expect(totalPrice, 64.95); // 12.99 * 5
      });
    });

    group('Quantity Management', () {
      test('should increase quantity correctly', () {
        // Act
        final increasedCartItem = testCartItem.increaseQuantity();

        // Assert
        expect(increasedCartItem.quantity, 3);
        expect(increasedCartItem.menuItem, testCartItem.menuItem);
        expect(increasedCartItem.restaurantId, testCartItem.restaurantId);
      });

      test('should decrease quantity correctly', () {
        // Act
        final decreasedCartItem = testCartItem.decreaseQuantity();

        // Assert
        expect(decreasedCartItem.quantity, 1);
      });

      test('should not decrease quantity below 1', () {
        // Arrange
        final singleCartItem = testCartItem.copyWith(quantity: 1);

        // Act
        final decreasedCartItem = singleCartItem.decreaseQuantity();

        // Assert
        expect(decreasedCartItem.quantity, 1);
      });

      test('should update quantity to specific value', () {
        // Act
        final updatedCartItem = testCartItem.updateQuantity(5);

        // Assert
        expect(updatedCartItem.quantity, 5);
      });

      test('should not update quantity to zero or negative', () {
        // Act
        final updatedCartItem1 = testCartItem.updateQuantity(0);
        final updatedCartItem2 = testCartItem.updateQuantity(-1);

        // Assert
        expect(updatedCartItem1.quantity, testCartItem.quantity);
        expect(updatedCartItem2.quantity, testCartItem.quantity);
      });
    });

    group('Validation', () {
      test('should return true for valid cart item', () {
        // Assert
        expect(testCartItem.isValid, true);
      });

      test('should return false for cart item with invalid menu item', () {
        // Arrange
        const invalidMenuItem = MenuItem(
          id: '',
          itemName: '',
          itemDescription: '',
          itemPrice: 0.0,
          imageUrl: '',
          category: '',
        );
        final invalidCartItem = testCartItem.copyWith(menuItem: invalidMenuItem);

        // Assert
        expect(invalidCartItem.isValid, false);
      });

      test('should return false for cart item with zero quantity', () {
        // Arrange
        final invalidCartItem = CartItem(
          menuItem: testMenuItem,
          quantity: 0,
          restaurantId: 'restaurant_1',
        );

        // Assert
        expect(invalidCartItem.isValid, false);
      });

      test('should return false for cart item with empty restaurant ID', () {
        // Arrange
        final invalidCartItem = testCartItem.copyWith(restaurantId: '');

        // Assert
        expect(invalidCartItem.isValid, false);
      });
    });

    group('Equality', () {
      test('should be equal when all properties are the same', () {
        // Arrange
        const cartItem1 = CartItem(
          menuItem: testMenuItem,
          quantity: 2,
          restaurantId: 'restaurant_1',
        );

        const cartItem2 = CartItem(
          menuItem: testMenuItem,
          quantity: 2,
          restaurantId: 'restaurant_1',
        );

        // Assert
        expect(cartItem1, cartItem2);
        expect(cartItem1.hashCode, cartItem2.hashCode);
      });

      test('should not be equal when properties differ', () {
        // Arrange
        final cartItem2 = testCartItem.copyWith(quantity: 3);

        // Assert
        expect(testCartItem, isNot(cartItem2));
      });
    });

    group('CopyWith', () {
      test('should create new instance with updated properties', () {
        // Act
        final updatedCartItem = testCartItem.copyWith(
          quantity: 5,
          restaurantId: 'restaurant_2',
        );

        // Assert
        expect(updatedCartItem.quantity, 5);
        expect(updatedCartItem.restaurantId, 'restaurant_2');
        expect(updatedCartItem.menuItem, testCartItem.menuItem);
      });

      test('should keep original values when no parameters provided', () {
        // Act
        final copiedCartItem = testCartItem.copyWith();

        // Assert
        expect(copiedCartItem, testCartItem);
      });
    });

    group('ToString', () {
      test('should return formatted string representation', () {
        // Act
        final stringRepresentation = testCartItem.toString();

        // Assert
        expect(stringRepresentation, contains('CartItem('));
        expect(stringRepresentation, contains('quantity: 2'));
        expect(stringRepresentation, contains('restaurantId: restaurant_1'));
        expect(stringRepresentation, contains('totalPrice: 25.98'));
      });
    });
  });
}