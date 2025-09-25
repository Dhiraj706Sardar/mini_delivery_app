import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:deliery_app/data/datasources/cart_persistence_datasource.dart';
import 'package:deliery_app/data/models/cart_item.dart';
import 'package:deliery_app/data/models/menu_item.dart';

import 'cart_persistence_datasource_test.mocks.dart';

@GenerateMocks([SharedPreferences])
void main() {
  group('CartPersistenceDataSourceImpl', () {
    late CartPersistenceDataSourceImpl dataSource;
    late MockSharedPreferences mockPrefs;

    // Test data
    const testRestaurantId = 'restaurant_1';
    
    const testMenuItem1 = MenuItem(
      id: 'item_1',
      itemName: 'Pizza',
      itemDescription: 'Delicious pizza',
      itemPrice: 12.99,
      imageUrl: 'https://example.com/pizza.jpg',
      category: 'Main Course',
    );

    const testMenuItem2 = MenuItem(
      id: 'item_2',
      itemName: 'Burger',
      itemDescription: 'Tasty burger',
      itemPrice: 8.99,
      imageUrl: 'https://example.com/burger.jpg',
      category: 'Main Course',
    );

    const testCartItem1 = CartItem(
      menuItem: testMenuItem1,
      quantity: 2,
      restaurantId: testRestaurantId,
    );

    const testCartItem2 = CartItem(
      menuItem: testMenuItem2,
      quantity: 1,
      restaurantId: testRestaurantId,
    );

    setUp(() {
      mockPrefs = MockSharedPreferences();
      dataSource = CartPersistenceDataSourceImpl(prefs: mockPrefs);
    });

    group('loadCartItems', () {
      test('returns empty list when no data stored', () async {
        // Arrange
        when(mockPrefs.getString('cart_items')).thenReturn(null);

        // Act
        final result = await dataSource.loadCartItems();

        // Assert
        expect(result, isEmpty);
        verify(mockPrefs.getString('cart_items')).called(1);
      });

      test('returns empty list when stored data is empty string', () async {
        // Arrange
        when(mockPrefs.getString('cart_items')).thenReturn('');

        // Act
        final result = await dataSource.loadCartItems();

        // Assert
        expect(result, isEmpty);
        verify(mockPrefs.getString('cart_items')).called(1);
      });

      test('loads cart items successfully from valid JSON', () async {
        // Arrange
        final cartItemsJson = json.encode([
          testCartItem1.toJson(),
          testCartItem2.toJson(),
        ]);
        when(mockPrefs.getString('cart_items')).thenReturn(cartItemsJson);

        // Act
        final result = await dataSource.loadCartItems();

        // Assert
        expect(result, hasLength(2));
        expect(result[0].menuItem.id, testCartItem1.menuItem.id);
        expect(result[0].quantity, testCartItem1.quantity);
        expect(result[1].menuItem.id, testCartItem2.menuItem.id);
        expect(result[1].quantity, testCartItem2.quantity);
        verify(mockPrefs.getString('cart_items')).called(1);
      });

      test('filters out invalid items and returns valid ones', () async {
        // Arrange
        final invalidCartItem = const CartItem(
          menuItem: MenuItem(
            id: '',
            itemName: '',
            itemDescription: '',
            itemPrice: -1.0,
            imageUrl: '',
            category: '',
          ),
          quantity: 0,
          restaurantId: '',
        );
        
        final cartItemsJson = json.encode([
          testCartItem1.toJson(),
          invalidCartItem.toJson(),
          testCartItem2.toJson(),
        ]);
        when(mockPrefs.getString('cart_items')).thenReturn(cartItemsJson);

        // Act
        final result = await dataSource.loadCartItems();

        // Assert
        expect(result, hasLength(2)); // Only valid items
        expect(result[0].menuItem.id, testCartItem1.menuItem.id);
        expect(result[1].menuItem.id, testCartItem2.menuItem.id);
      });

      test('returns empty list and clears data when JSON is corrupted', () async {
        // Arrange
        when(mockPrefs.getString('cart_items')).thenReturn('invalid json');
        when(mockPrefs.remove('cart_items')).thenAnswer((_) async => true);
        when(mockPrefs.remove('current_restaurant_id')).thenAnswer((_) async => true);

        // Act
        final result = await dataSource.loadCartItems();

        // Assert
        expect(result, isEmpty);
        verify(mockPrefs.remove('cart_items')).called(1);
        verify(mockPrefs.remove('current_restaurant_id')).called(1);
      });
    });

    group('saveCartItems', () {
      test('saves cart items successfully', () async {
        // Arrange
        final cartItems = [testCartItem1, testCartItem2];
        when(mockPrefs.setString(any, any)).thenAnswer((_) async => true);

        // Act
        await dataSource.saveCartItems(cartItems);

        // Assert
        final capturedJson = verify(mockPrefs.setString('cart_items', captureAny))
            .captured.single as String;
        final decodedItems = json.decode(capturedJson) as List;
        expect(decodedItems, hasLength(2));
      });

      test('filters out invalid items before saving', () async {
        // Arrange
        final invalidCartItem = const CartItem(
          menuItem: MenuItem(
            id: '',
            itemName: '',
            itemDescription: '',
            itemPrice: -1.0,
            imageUrl: '',
            category: '',
          ),
          quantity: 0,
          restaurantId: '',
        );
        
        final cartItems = [testCartItem1, invalidCartItem, testCartItem2];
        when(mockPrefs.setString(any, any)).thenAnswer((_) async => true);

        // Act
        await dataSource.saveCartItems(cartItems);

        // Assert
        final capturedJson = verify(mockPrefs.setString('cart_items', captureAny))
            .captured.single as String;
        final decodedItems = json.decode(capturedJson) as List;
        expect(decodedItems, hasLength(2)); // Only valid items saved
      });

      test('clears cart when save fails', () async {
        // Arrange
        final cartItems = [testCartItem1];
        when(mockPrefs.setString(any, any)).thenThrow(Exception('Save failed'));
        when(mockPrefs.remove(any)).thenAnswer((_) async => true);

        // Act & Assert
        try {
          await dataSource.saveCartItems(cartItems);
          fail('Expected exception to be thrown');
        } catch (e) {
          expect(e, isA<Exception>());
        }
        
        verify(mockPrefs.remove('cart_items')).called(1);
        verify(mockPrefs.remove('current_restaurant_id')).called(1);
      });
    });

    group('clearCart', () {
      test('removes both cart items and restaurant ID', () async {
        // Arrange
        when(mockPrefs.remove('cart_items')).thenAnswer((_) async => true);
        when(mockPrefs.remove('current_restaurant_id')).thenAnswer((_) async => true);

        // Act
        await dataSource.clearCart();

        // Assert
        verify(mockPrefs.remove('cart_items')).called(1);
        verify(mockPrefs.remove('current_restaurant_id')).called(1);
      });

      test('does not throw when removal fails', () async {
        // Arrange
        when(mockPrefs.remove(any)).thenThrow(Exception('Remove failed'));

        // Act & Assert
        expect(() => dataSource.clearCart(), returnsNormally);
      });
    });

    group('getCurrentRestaurantId', () {
      test('returns restaurant ID when stored', () async {
        // Arrange
        when(mockPrefs.getString('current_restaurant_id')).thenReturn(testRestaurantId);

        // Act
        final result = await dataSource.getCurrentRestaurantId();

        // Assert
        expect(result, testRestaurantId);
        verify(mockPrefs.getString('current_restaurant_id')).called(1);
      });

      test('returns null when no restaurant ID stored', () async {
        // Arrange
        when(mockPrefs.getString('current_restaurant_id')).thenReturn(null);

        // Act
        final result = await dataSource.getCurrentRestaurantId();

        // Assert
        expect(result, isNull);
        verify(mockPrefs.getString('current_restaurant_id')).called(1);
      });

      test('returns null when get fails', () async {
        // Arrange
        when(mockPrefs.getString('current_restaurant_id')).thenThrow(Exception('Get failed'));

        // Act
        final result = await dataSource.getCurrentRestaurantId();

        // Assert
        expect(result, isNull);
      });
    });

    group('saveCurrentRestaurantId', () {
      test('saves restaurant ID when provided', () async {
        // Arrange
        when(mockPrefs.setString('current_restaurant_id', testRestaurantId))
            .thenAnswer((_) async => true);

        // Act
        await dataSource.saveCurrentRestaurantId(testRestaurantId);

        // Assert
        verify(mockPrefs.setString('current_restaurant_id', testRestaurantId)).called(1);
      });

      test('removes restaurant ID when null provided', () async {
        // Arrange
        when(mockPrefs.remove('current_restaurant_id')).thenAnswer((_) async => true);

        // Act
        await dataSource.saveCurrentRestaurantId(null);

        // Assert
        verify(mockPrefs.remove('current_restaurant_id')).called(1);
      });

      test('does not throw when save fails', () async {
        // Arrange
        when(mockPrefs.setString(any, any)).thenThrow(Exception('Save failed'));

        // Act & Assert
        expect(
          () => dataSource.saveCurrentRestaurantId(testRestaurantId),
          returnsNormally,
        );
      });
    });
  });
}