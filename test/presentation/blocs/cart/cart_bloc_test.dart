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

import 'cart_bloc_test.mocks.dart';

@GenerateMocks([CartPersistenceDataSource])
void main() {
  group('CartBloc', () {
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

    // Removed unused testMenuItem3

    setUp(() {
      mockPersistenceDataSource = MockCartPersistenceDataSource();

      // Set up default mock behavior
      when(
        mockPersistenceDataSource.saveCartItems(any),
      ).thenAnswer((_) async {});
      when(
        mockPersistenceDataSource.saveCurrentRestaurantId(any),
      ).thenAnswer((_) async {});
      when(
        mockPersistenceDataSource.loadCartItems(),
      ).thenAnswer((_) async => []);
      when(
        mockPersistenceDataSource.getCurrentRestaurantId(),
      ).thenAnswer((_) async => null);
      when(mockPersistenceDataSource.clearCart()).thenAnswer((_) async {});

      cartBloc = CartBloc(persistenceDataSource: mockPersistenceDataSource);
    });

    tearDown(() {
      cartBloc.close();
    });

    test('initial state is CartInitial', () {
      expect(cartBloc.state, equals(const CartInitial()));
    });

    group('LoadCart', () {
      blocTest<CartBloc, CartState>(
        'emits [CartLoading, CartUpdated] with empty cart when LoadCart is added',
        build: () => cartBloc,
        act: (bloc) => bloc.add(const LoadCart()),
        expect: () => [
          const CartLoading(),
          const CartUpdated(
            items: [],
            subtotal: 0.0,
            deliveryFee: 2.99,
            tax: 0.0,
            total: 2.99,
            totalItems: 0,
            currentRestaurantId: null,
          ),
        ],
      );
    });

    group('AddToCart', () {
      blocTest<CartBloc, CartState>(
        'emits [CartUpdated] when valid item is added to empty cart',
        build: () => cartBloc,
        act: (bloc) => bloc.add(
          const AddToCart(
            menuItem: testMenuItem1,
            restaurantId: testRestaurantId,
            quantity: 1,
          ),
        ),
        verify: (bloc) {
          final state = bloc.state as CartUpdated;
          expect(state.items.length, 1);
          expect(state.subtotal, closeTo(12.99, 0.01));
          expect(state.deliveryFee, closeTo(2.99, 0.01));
          expect(state.tax, closeTo(1.04, 0.01)); // 8% of 12.99
          expect(state.total, closeTo(17.02, 0.01));
          expect(state.totalItems, 1);
          expect(state.currentRestaurantId, testRestaurantId);
        },
      );

      blocTest<CartBloc, CartState>(
        'emits [CartUpdated] with free delivery when subtotal exceeds threshold',
        build: () => cartBloc,
        act: (bloc) => bloc.add(
          const AddToCart(
            menuItem: testMenuItem1,
            restaurantId: testRestaurantId,
            quantity: 3, // 3 * 12.99 = 38.97 > 25.0
          ),
        ),
        verify: (bloc) {
          final state = bloc.state as CartUpdated;
          expect(state.items.length, 1);
          expect(state.subtotal, closeTo(38.97, 0.01));
          expect(state.deliveryFee, closeTo(0.0, 0.01)); // Free delivery
          expect(state.tax, closeTo(3.12, 0.01)); // 8% of 38.97
          expect(state.total, closeTo(42.09, 0.01));
          expect(state.totalItems, 3);
          expect(state.currentRestaurantId, testRestaurantId);
        },
      );

      blocTest<CartBloc, CartState>(
        'updates quantity when same item is added again',
        build: () => cartBloc,
        seed: () => const CartUpdated(
          items: [
            CartItem(
              menuItem: testMenuItem1,
              quantity: 1,
              restaurantId: testRestaurantId,
            ),
          ],
          subtotal: 12.99,
          deliveryFee: 2.99,
          tax: 1.04,
          total: 17.02,
          totalItems: 1,
          currentRestaurantId: testRestaurantId,
        ),
        act: (bloc) => bloc.add(
          const AddToCart(
            menuItem: testMenuItem1,
            restaurantId: testRestaurantId,
            quantity: 2,
          ),
        ),
        verify: (bloc) {
          final state = bloc.state as CartUpdated;
          expect(state.items.length, 1);
          expect(state.items.first.quantity, 3); // 1 + 2
          expect(state.subtotal, closeTo(38.97, 0.01)); // 3 * 12.99
          expect(state.deliveryFee, closeTo(0.0, 0.01)); // Free delivery
          expect(state.tax, closeTo(3.12, 0.01));
          expect(state.total, closeTo(42.09, 0.01));
          expect(state.totalItems, 3);
          expect(state.currentRestaurantId, testRestaurantId);
        },
      );

      blocTest<CartBloc, CartState>(
        'emits [CartError] when trying to add item from different restaurant',
        build: () => cartBloc,
        seed: () => const CartUpdated(
          items: [
            CartItem(
              menuItem: testMenuItem1,
              quantity: 1,
              restaurantId: testRestaurantId,
            ),
          ],
          subtotal: 12.99,
          deliveryFee: 2.99,
          tax: 1.04,
          total: 17.02,
          totalItems: 1,
          currentRestaurantId: testRestaurantId,
        ),
        act: (bloc) => bloc.add(
          const AddToCart(
            menuItem: testMenuItem2,
            restaurantId: testRestaurantId2, // Different restaurant
            quantity: 1,
          ),
        ),
        expect: () => [
          const CartError(
            message:
                'Cannot add items from different restaurants. Please clear your cart first.',
          ),
        ],
      );

      blocTest<CartBloc, CartState>(
        'emits [CartError] when quantity is zero or negative',
        build: () => cartBloc,
        act: (bloc) => bloc.add(
          const AddToCart(
            menuItem: testMenuItem1,
            restaurantId: testRestaurantId,
            quantity: 0,
          ),
        ),
        expect: () => [
          const CartError(message: 'Quantity must be greater than 0'),
        ],
      );

      blocTest<CartBloc, CartState>(
        'emits [CartError] when restaurant ID is empty',
        build: () => cartBloc,
        act: (bloc) => bloc.add(
          const AddToCart(
            menuItem: testMenuItem1,
            restaurantId: '',
            quantity: 1,
          ),
        ),
        expect: () => [
          const CartError(message: 'Restaurant ID cannot be empty'),
        ],
      );
    });

    group('RemoveFromCart', () {
      blocTest<CartBloc, CartState>(
        'removes item from cart successfully',
        build: () => cartBloc,
        seed: () => const CartUpdated(
          items: [
            CartItem(
              menuItem: testMenuItem1,
              quantity: 1,
              restaurantId: testRestaurantId,
            ),
            CartItem(
              menuItem: testMenuItem2,
              quantity: 2,
              restaurantId: testRestaurantId,
            ),
          ],
          subtotal: 30.97, // 12.99 + (8.99 * 2)
          deliveryFee: 0.0,
          tax: 2.48,
          total: 33.45,
          totalItems: 3,
          currentRestaurantId: testRestaurantId,
        ),
        act: (bloc) => bloc.add(const RemoveFromCart('item_1')),
        verify: (bloc) {
          final state = bloc.state as CartUpdated;
          expect(state.items.length, 1);
          expect(state.items.first.menuItem.id, 'item_2');
          expect(state.subtotal, closeTo(17.98, 0.01)); // 8.99 * 2
          expect(
            state.deliveryFee,
            closeTo(2.99, 0.01),
          ); // Below threshold again
          expect(state.tax, closeTo(1.44, 0.01)); // 8% of 17.98
          expect(state.total, closeTo(22.41, 0.01));
          expect(state.totalItems, 2);
          expect(state.currentRestaurantId, testRestaurantId);
        },
      );

      blocTest<CartBloc, CartState>(
        'clears restaurant ID when last item is removed',
        build: () => cartBloc,
        seed: () => const CartUpdated(
          items: [
            CartItem(
              menuItem: testMenuItem1,
              quantity: 1,
              restaurantId: testRestaurantId,
            ),
          ],
          subtotal: 12.99,
          deliveryFee: 2.99,
          tax: 1.04,
          total: 17.02,
          totalItems: 1,
          currentRestaurantId: testRestaurantId,
        ),
        act: (bloc) => bloc.add(const RemoveFromCart('item_1')),
        expect: () => [
          const CartUpdated(
            items: [],
            subtotal: 0.0,
            deliveryFee: 2.99,
            tax: 0.0,
            total: 2.99,
            totalItems: 0,
            currentRestaurantId: null,
          ),
        ],
      );

      blocTest<CartBloc, CartState>(
        'emits [CartError] when cart is not in valid state',
        build: () => cartBloc,
        seed: () => const CartInitial(),
        act: (bloc) => bloc.add(const RemoveFromCart('item_1')),
        expect: () => [
          const CartError(message: 'Cart is not in a valid state'),
        ],
      );
    });

    group('UpdateQuantity', () {
      blocTest<CartBloc, CartState>(
        'updates item quantity successfully',
        build: () => cartBloc,
        seed: () => const CartUpdated(
          items: [
            CartItem(
              menuItem: testMenuItem1,
              quantity: 1,
              restaurantId: testRestaurantId,
            ),
          ],
          subtotal: 12.99,
          deliveryFee: 2.99,
          tax: 1.04,
          total: 17.02,
          totalItems: 1,
          currentRestaurantId: testRestaurantId,
        ),
        act: (bloc) =>
            bloc.add(const UpdateQuantity(menuItemId: 'item_1', quantity: 3)),
        verify: (bloc) {
          final state = bloc.state as CartUpdated;
          expect(state.items.length, 1);
          expect(state.items.first.quantity, 3);
          expect(state.subtotal, closeTo(38.97, 0.01)); // 12.99 * 3
          expect(state.deliveryFee, closeTo(0.0, 0.01)); // Free delivery
          expect(state.tax, closeTo(3.12, 0.01));
          expect(state.total, closeTo(42.09, 0.01));
          expect(state.totalItems, 3);
          expect(state.currentRestaurantId, testRestaurantId);
        },
      );

      blocTest<CartBloc, CartState>(
        'removes item when quantity is set to zero',
        build: () => cartBloc,
        seed: () => const CartUpdated(
          items: [
            CartItem(
              menuItem: testMenuItem1,
              quantity: 2,
              restaurantId: testRestaurantId,
            ),
          ],
          subtotal: 25.98,
          deliveryFee: 0.0,
          tax: 2.08,
          total: 28.06,
          totalItems: 2,
          currentRestaurantId: testRestaurantId,
        ),
        act: (bloc) =>
            bloc.add(const UpdateQuantity(menuItemId: 'item_1', quantity: 0)),
        expect: () => [
          const CartUpdated(
            items: [],
            subtotal: 0.0,
            deliveryFee: 2.99,
            tax: 0.0,
            total: 2.99,
            totalItems: 0,
            currentRestaurantId: null,
          ),
        ],
      );

      blocTest<CartBloc, CartState>(
        'emits [CartError] when item not found',
        build: () => cartBloc,
        seed: () => const CartUpdated(
          items: [
            CartItem(
              menuItem: testMenuItem1,
              quantity: 1,
              restaurantId: testRestaurantId,
            ),
          ],
          subtotal: 12.99,
          deliveryFee: 2.99,
          tax: 1.04,
          total: 17.02,
          totalItems: 1,
          currentRestaurantId: testRestaurantId,
        ),
        act: (bloc) => bloc.add(
          const UpdateQuantity(menuItemId: 'nonexistent_item', quantity: 2),
        ),
        expect: () => [const CartError(message: 'Item not found in cart')],
      );
    });

    group('ClearCart', () {
      blocTest<CartBloc, CartState>(
        'clears all items from cart',
        build: () => cartBloc,
        seed: () => const CartUpdated(
          items: [
            CartItem(
              menuItem: testMenuItem1,
              quantity: 1,
              restaurantId: testRestaurantId,
            ),
            CartItem(
              menuItem: testMenuItem2,
              quantity: 2,
              restaurantId: testRestaurantId,
            ),
          ],
          subtotal: 30.97,
          deliveryFee: 0.0,
          tax: 2.48,
          total: 33.45,
          totalItems: 3,
          currentRestaurantId: testRestaurantId,
        ),
        act: (bloc) => bloc.add(const ClearCart()),
        expect: () => [
          const CartUpdated(
            items: [],
            subtotal: 0.0,
            deliveryFee: 2.99,
            tax: 0.0,
            total: 2.99,
            totalItems: 0,
            currentRestaurantId: null,
          ),
        ],
      );
    });

    group('Cart calculations', () {
      test('delivery fee is free when subtotal >= 25.0', () {
        cartBloc.add(
          const AddToCart(
            menuItem: testMenuItem1,
            restaurantId: testRestaurantId,
            quantity: 2, // 2 * 12.99 = 25.98
          ),
        );

        expectLater(
          cartBloc.stream,
          emits(predicate<CartUpdated>((state) => state.deliveryFee == 0.0)),
        );
      });

      test('delivery fee is 2.99 when subtotal < 25.0', () {
        cartBloc.add(
          const AddToCart(
            menuItem: testMenuItem1,
            restaurantId: testRestaurantId,
            quantity: 1, // 1 * 12.99 = 12.99
          ),
        );

        expectLater(
          cartBloc.stream,
          emits(predicate<CartUpdated>((state) => state.deliveryFee == 2.99)),
        );
      });

      test('tax is calculated as 8% of subtotal', () {
        cartBloc.add(
          const AddToCart(
            menuItem: testMenuItem1,
            restaurantId: testRestaurantId,
            quantity: 1,
          ),
        );

        expectLater(
          cartBloc.stream,
          emits(
            predicate<CartUpdated>(
              (state) => (state.tax - (state.subtotal * 0.08)).abs() < 0.01,
            ),
          ),
        );
      });
    });

    group('CartUpdated state methods', () {
      const cartState = CartUpdated(
        items: [
          CartItem(
            menuItem: testMenuItem1,
            quantity: 2,
            restaurantId: testRestaurantId,
          ),
          CartItem(
            menuItem: testMenuItem2,
            quantity: 1,
            restaurantId: testRestaurantId,
          ),
        ],
        subtotal: 30.97,
        deliveryFee: 0.0,
        tax: 2.48,
        total: 33.45,
        totalItems: 3,
        currentRestaurantId: testRestaurantId,
      );

      test('isEmpty returns false when cart has items', () {
        expect(cartState.isEmpty, false);
      });

      test('hasItems returns true when cart has items', () {
        expect(cartState.hasItems, true);
      });

      test('getCartItem returns correct item', () {
        final item = cartState.getCartItem('item_1');
        expect(item?.menuItem.id, 'item_1');
        expect(item?.quantity, 2);
      });

      test('getCartItem returns null for non-existent item', () {
        final item = cartState.getCartItem('nonexistent');
        expect(item, null);
      });

      test('containsItem returns true for existing item', () {
        expect(cartState.containsItem('item_1'), true);
      });

      test('containsItem returns false for non-existing item', () {
        expect(cartState.containsItem('nonexistent'), false);
      });

      test('getItemQuantity returns correct quantity', () {
        expect(cartState.getItemQuantity('item_1'), 2);
        expect(cartState.getItemQuantity('item_2'), 1);
        expect(cartState.getItemQuantity('nonexistent'), 0);
      });

      test('hasMultipleRestaurants returns false for single restaurant', () {
        expect(cartState.hasMultipleRestaurants, false);
      });

      test('restaurantIds returns correct set', () {
        expect(cartState.restaurantIds, {testRestaurantId});
      });
    });
  });
}
