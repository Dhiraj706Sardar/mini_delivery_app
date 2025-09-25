import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:deliery_app/presentation/blocs/cart/cart_bloc.dart';
import 'package:deliery_app/presentation/blocs/cart/cart_event.dart';
import 'package:deliery_app/presentation/blocs/cart/cart_state.dart';
import 'package:deliery_app/data/models/menu_item.dart';
import 'package:deliery_app/data/models/cart_item.dart';
import 'package:deliery_app/data/datasources/cart_persistence_datasource.dart';

import 'cart_bloc_persistence_test.mocks.dart';

@GenerateMocks([CartPersistenceDataSource])
void main() {
  group('CartBloc Persistence Tests', () {
    late CartBloc cartBloc;
    late MockCartPersistenceDataSource mockPersistenceDataSource;

    // Test data
    const testRestaurantId = 'restaurant_1';
    const testRestaurantId2 = 'restaurant_2';
    
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
      mockPersistenceDataSource = MockCartPersistenceDataSource();
      cartBloc = CartBloc(persistenceDataSource: mockPersistenceDataSource);
    });

    tearDown(() {
      cartBloc.close();
    });

    group('LoadCart', () {
      blocTest<CartBloc, CartState>(
        'loads cart items from persistence successfully',
        build: () {
          when(mockPersistenceDataSource.loadCartItems())
              .thenAnswer((_) async => [testCartItem1, testCartItem2]);
          when(mockPersistenceDataSource.getCurrentRestaurantId())
              .thenAnswer((_) async => testRestaurantId);
          return cartBloc;
        },
        act: (bloc) => bloc.add(const LoadCart()),
        expect: () => [
          const CartLoading(),
          predicate<CartUpdated>((state) {
            return state.items.length == 2 &&
                state.currentRestaurantId == testRestaurantId &&
                state.totalItems == 3; // 2 + 1
          }),
        ],
        verify: (_) {
          verify(mockPersistenceDataSource.loadCartItems()).called(1);
          verify(mockPersistenceDataSource.getCurrentRestaurantId()).called(1);
        },
      );

      blocTest<CartBloc, CartState>(
        'loads empty cart when no persisted data',
        build: () {
          when(mockPersistenceDataSource.loadCartItems())
              .thenAnswer((_) async => []);
          when(mockPersistenceDataSource.getCurrentRestaurantId())
              .thenAnswer((_) async => null);
          return cartBloc;
        },
        act: (bloc) => bloc.add(const LoadCart()),
        expect: () => [
          const CartLoading(),
          predicate<CartUpdated>((state) {
            return state.items.isEmpty &&
                state.currentRestaurantId == null &&
                state.totalItems == 0;
          }),
        ],
      );

      blocTest<CartBloc, CartState>(
        'clears cart when items are from multiple restaurants',
        build: () {
          final mixedItems = [
            testCartItem1,
            const CartItem(
              menuItem: testMenuItem2,
              quantity: 1,
              restaurantId: testRestaurantId2, // Different restaurant
            ),
          ];
          when(mockPersistenceDataSource.loadCartItems())
              .thenAnswer((_) async => mixedItems);
          when(mockPersistenceDataSource.getCurrentRestaurantId())
              .thenAnswer((_) async => testRestaurantId);
          when(mockPersistenceDataSource.clearCart())
              .thenAnswer((_) async {});
          return cartBloc;
        },
        act: (bloc) => bloc.add(const LoadCart()),
        expect: () => [
          const CartLoading(),
          predicate<CartUpdated>((state) {
            return state.items.isEmpty &&
                state.currentRestaurantId == null;
          }),
        ],
        verify: (_) {
          verify(mockPersistenceDataSource.clearCart()).called(1);
        },
      );

      blocTest<CartBloc, CartState>(
        'handles persistence loading error gracefully',
        build: () {
          when(mockPersistenceDataSource.loadCartItems())
              .thenThrow(Exception('Storage error'));
          when(mockPersistenceDataSource.getCurrentRestaurantId())
              .thenAnswer((_) async => null);
          return cartBloc;
        },
        act: (bloc) => bloc.add(const LoadCart()),
        expect: () => [
          const CartLoading(),
          predicate<CartUpdated>((state) {
            return state.items.isEmpty &&
                state.currentRestaurantId == null;
          }),
        ],
      );
    });

    group('SaveCart', () {
      blocTest<CartBloc, CartState>(
        'saves cart to persistence when cart has items',
        build: () {
          when(mockPersistenceDataSource.saveCartItems(any))
              .thenAnswer((_) async {});
          when(mockPersistenceDataSource.saveCurrentRestaurantId(any))
              .thenAnswer((_) async {});
          return cartBloc;
        },
        seed: () => const CartUpdated(
          items: [testCartItem1],
          subtotal: 25.98,
          deliveryFee: 0.0,
          tax: 2.08,
          total: 28.06,
          totalItems: 2,
          currentRestaurantId: testRestaurantId,
        ),
        act: (bloc) => bloc.add(const SaveCart()),
        verify: (_) {
          verify(mockPersistenceDataSource.saveCartItems([testCartItem1])).called(1);
          verify(mockPersistenceDataSource.saveCurrentRestaurantId(testRestaurantId)).called(1);
        },
      );

      blocTest<CartBloc, CartState>(
        'handles save error gracefully without breaking app',
        build: () {
          when(mockPersistenceDataSource.saveCartItems(any))
              .thenThrow(Exception('Storage error'));
          when(mockPersistenceDataSource.saveCurrentRestaurantId(any))
              .thenAnswer((_) async {});
          return cartBloc;
        },
        seed: () => const CartUpdated(
          items: [testCartItem1],
          subtotal: 25.98,
          deliveryFee: 0.0,
          tax: 2.08,
          total: 28.06,
          totalItems: 2,
          currentRestaurantId: testRestaurantId,
        ),
        act: (bloc) => bloc.add(const SaveCart()),
        expect: () => [], // No state change expected - error is handled silently
        verify: (_) {
          verify(mockPersistenceDataSource.saveCartItems([testCartItem1])).called(1);
        },
      );
    });

    group('AddToCart with Persistence', () {
      blocTest<CartBloc, CartState>(
        'saves cart after adding item',
        build: () {
          when(mockPersistenceDataSource.saveCartItems(any))
              .thenAnswer((_) async {});
          when(mockPersistenceDataSource.saveCurrentRestaurantId(any))
              .thenAnswer((_) async {});
          return cartBloc;
        },
        act: (bloc) => bloc.add(const AddToCart(
          menuItem: testMenuItem1,
          restaurantId: testRestaurantId,
          quantity: 1,
        )),
        verify: (_) {
          verify(mockPersistenceDataSource.saveCartItems(any)).called(1);
          verify(mockPersistenceDataSource.saveCurrentRestaurantId(testRestaurantId)).called(1);
        },
      );
    });

    group('RemoveFromCart with Persistence', () {
      blocTest<CartBloc, CartState>(
        'saves cart after removing item',
        build: () {
          when(mockPersistenceDataSource.saveCartItems(any))
              .thenAnswer((_) async {});
          when(mockPersistenceDataSource.saveCurrentRestaurantId(any))
              .thenAnswer((_) async {});
          return cartBloc;
        },
        seed: () => const CartUpdated(
          items: [testCartItem1, testCartItem2],
          subtotal: 34.97,
          deliveryFee: 0.0,
          tax: 2.80,
          total: 37.77,
          totalItems: 3,
          currentRestaurantId: testRestaurantId,
        ),
        act: (bloc) => bloc.add(const RemoveFromCart('item_1')),
        verify: (_) {
          verify(mockPersistenceDataSource.saveCartItems(any)).called(1);
          verify(mockPersistenceDataSource.saveCurrentRestaurantId(testRestaurantId)).called(1);
        },
      );
    });

    group('UpdateQuantity with Persistence', () {
      blocTest<CartBloc, CartState>(
        'saves cart after updating quantity',
        build: () {
          when(mockPersistenceDataSource.saveCartItems(any))
              .thenAnswer((_) async {});
          when(mockPersistenceDataSource.saveCurrentRestaurantId(any))
              .thenAnswer((_) async {});
          return cartBloc;
        },
        seed: () => const CartUpdated(
          items: [testCartItem1],
          subtotal: 25.98,
          deliveryFee: 0.0,
          tax: 2.08,
          total: 28.06,
          totalItems: 2,
          currentRestaurantId: testRestaurantId,
        ),
        act: (bloc) => bloc.add(const UpdateQuantity(
          menuItemId: 'item_1',
          quantity: 3,
        )),
        verify: (_) {
          verify(mockPersistenceDataSource.saveCartItems(any)).called(1);
          verify(mockPersistenceDataSource.saveCurrentRestaurantId(testRestaurantId)).called(1);
        },
      );
    });

    group('ClearCart with Persistence', () {
      blocTest<CartBloc, CartState>(
        'clears persistence when clearing cart',
        build: () {
          when(mockPersistenceDataSource.clearCart())
              .thenAnswer((_) async {});
          return cartBloc;
        },
        seed: () => const CartUpdated(
          items: [testCartItem1],
          subtotal: 25.98,
          deliveryFee: 0.0,
          tax: 2.08,
          total: 28.06,
          totalItems: 2,
          currentRestaurantId: testRestaurantId,
        ),
        act: (bloc) => bloc.add(const ClearCart()),
        verify: (_) {
          verify(mockPersistenceDataSource.clearCart()).called(1);
        },
      );
    });

    group('Validation Tests', () {
      blocTest<CartBloc, CartState>(
        'rejects adding item with quantity exceeding maximum',
        build: () => cartBloc,
        act: (bloc) => bloc.add(const AddToCart(
          menuItem: testMenuItem1,
          restaurantId: testRestaurantId,
          quantity: 15, // Exceeds max of 10
        )),
        expect: () => [
          predicate<CartError>((state) => 
            state.message.contains('Maximum quantity per item is 10')),
        ],
      );

      blocTest<CartBloc, CartState>(
        'rejects updating quantity exceeding maximum',
        build: () => cartBloc,
        seed: () => const CartUpdated(
          items: [testCartItem1],
          subtotal: 25.98,
          deliveryFee: 0.0,
          tax: 2.08,
          total: 28.06,
          totalItems: 2,
          currentRestaurantId: testRestaurantId,
        ),
        act: (bloc) => bloc.add(const UpdateQuantity(
          menuItemId: 'item_1',
          quantity: 15, // Exceeds max of 10
        )),
        expect: () => [
          predicate<CartError>((state) => 
            state.message.contains('Maximum quantity per item is 10')),
        ],
      );
    });
  });
}