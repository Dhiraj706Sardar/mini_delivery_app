import 'package:flutter_test/flutter_test.dart';
import 'package:deliery_app/data/models/menu_item.dart';

void main() {
  group('MenuItem Model', () {
    const testMenuItem = MenuItem(
      id: '1',
      itemName: 'Margherita Pizza',
      itemDescription: 'Classic pizza with tomato sauce and mozzarella',
      itemPrice: 12.99,
      imageUrl: 'https://example.com/pizza.jpg',
      category: 'Pizza',
    );

    const testJson = {
      'id': '1',
      'itemName': 'Margherita Pizza',
      'itemDescription': 'Classic pizza with tomato sauce and mozzarella',
      'itemPrice': 12.99,
      'imageUrl': 'https://example.com/pizza.jpg',
      'category': 'Pizza',
    };

    group('JSON Serialization', () {
      test('should create MenuItem from valid JSON', () {
        // Act
        final menuItem = MenuItem.fromJson(testJson);

        // Assert
        expect(menuItem.id, '1');
        expect(menuItem.itemName, 'Margherita Pizza');
        expect(menuItem.itemDescription, 'Classic pizza with tomato sauce and mozzarella');
        expect(menuItem.itemPrice, 12.99);
        expect(menuItem.imageUrl, 'https://example.com/pizza.jpg');
        expect(menuItem.category, 'Pizza');
      });

      test('should handle null values in JSON gracefully', () {
        // Arrange
        const nullJson = {
          'id': null,
          'itemName': null,
          'itemDescription': null,
          'itemPrice': null,
          'imageUrl': null,
          'category': null,
        };

        // Act
        final menuItem = MenuItem.fromJson(nullJson);

        // Assert
        expect(menuItem.id, '');
        expect(menuItem.itemName, '');
        expect(menuItem.itemDescription, '');
        expect(menuItem.itemPrice, 0.0);
        expect(menuItem.imageUrl, '');
        expect(menuItem.category, '');
      });

      test('should convert MenuItem to JSON correctly', () {
        // Act
        final json = testMenuItem.toJson();

        // Assert
        expect(json, testJson);
      });

      test('should handle integer price in JSON', () {
        // Arrange
        const jsonWithIntPrice = {
          'id': '1',
          'itemName': 'Margherita Pizza',
          'itemDescription': 'Classic pizza with tomato sauce and mozzarella',
          'itemPrice': 13,
          'imageUrl': 'https://example.com/pizza.jpg',
          'category': 'Pizza',
        };

        // Act
        final menuItem = MenuItem.fromJson(jsonWithIntPrice);

        // Assert
        expect(menuItem.itemPrice, 13.0);
      });
    });

    group('Validation', () {
      test('should return true for valid menu item', () {
        // Assert
        expect(testMenuItem.isValid, true);
      });

      test('should return false for menu item with empty id', () {
        // Arrange
        final invalidMenuItem = testMenuItem.copyWith(id: '');

        // Assert
        expect(invalidMenuItem.isValid, false);
      });

      test('should return false for menu item with empty name', () {
        // Arrange
        final invalidMenuItem = testMenuItem.copyWith(itemName: '');

        // Assert
        expect(invalidMenuItem.isValid, false);
      });

      test('should return false for menu item with empty description', () {
        // Arrange
        final invalidMenuItem = testMenuItem.copyWith(itemDescription: '');

        // Assert
        expect(invalidMenuItem.isValid, false);
      });

      test('should return false for menu item with invalid price', () {
        // Arrange
        final invalidMenuItem1 = testMenuItem.copyWith(itemPrice: 0.0);
        final invalidMenuItem2 = testMenuItem.copyWith(itemPrice: -5.0);

        // Assert
        expect(invalidMenuItem1.isValid, false);
        expect(invalidMenuItem2.isValid, false);
      });

      test('should return false for menu item with empty category', () {
        // Arrange
        final invalidMenuItem = testMenuItem.copyWith(category: '');

        // Assert
        expect(invalidMenuItem.isValid, false);
      });

      test('should return true for menu item with empty imageUrl', () {
        // Arrange
        final menuItemWithoutImage = testMenuItem.copyWith(imageUrl: '');

        // Assert
        expect(menuItemWithoutImage.isValid, true);
      });
    });

    group('Equality', () {
      test('should be equal when all properties are the same', () {
        // Arrange
        const menuItem1 = MenuItem(
          id: '1',
          itemName: 'Margherita Pizza',
          itemDescription: 'Classic pizza with tomato sauce and mozzarella',
          itemPrice: 12.99,
          imageUrl: 'https://example.com/pizza.jpg',
          category: 'Pizza',
        );

        const menuItem2 = MenuItem(
          id: '1',
          itemName: 'Margherita Pizza',
          itemDescription: 'Classic pizza with tomato sauce and mozzarella',
          itemPrice: 12.99,
          imageUrl: 'https://example.com/pizza.jpg',
          category: 'Pizza',
        );

        // Assert
        expect(menuItem1, menuItem2);
        expect(menuItem1.hashCode, menuItem2.hashCode);
      });

      test('should not be equal when properties differ', () {
        // Arrange
        final menuItem2 = testMenuItem.copyWith(itemName: 'Pepperoni Pizza');

        // Assert
        expect(testMenuItem, isNot(menuItem2));
      });
    });

    group('CopyWith', () {
      test('should create new instance with updated properties', () {
        // Act
        final updatedMenuItem = testMenuItem.copyWith(
          itemName: 'Pepperoni Pizza',
          itemPrice: 15.99,
        );

        // Assert
        expect(updatedMenuItem.itemName, 'Pepperoni Pizza');
        expect(updatedMenuItem.itemPrice, 15.99);
        expect(updatedMenuItem.id, testMenuItem.id);
        expect(updatedMenuItem.itemDescription, testMenuItem.itemDescription);
      });

      test('should keep original values when no parameters provided', () {
        // Act
        final copiedMenuItem = testMenuItem.copyWith();

        // Assert
        expect(copiedMenuItem, testMenuItem);
      });
    });

    group('ToString', () {
      test('should return formatted string representation', () {
        // Act
        final stringRepresentation = testMenuItem.toString();

        // Assert
        expect(stringRepresentation, contains('MenuItem('));
        expect(stringRepresentation, contains('id: 1'));
        expect(stringRepresentation, contains('itemName: Margherita Pizza'));
        expect(stringRepresentation, contains('itemPrice: 12.99'));
      });
    });
  });
}