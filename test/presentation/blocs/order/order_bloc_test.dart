import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:deliery_app/presentation/blocs/order/order_bloc.dart';
import 'package:deliery_app/presentation/blocs/order/order_event.dart';
import 'package:deliery_app/presentation/blocs/order/order_state.dart';
import 'package:deliery_app/data/models/order.dart';
import 'package:deliery_app/data/models/cart_item.dart';
import 'package:deliery_app/data/models/menu_item.dart';

void main() {
  group('OrderBloc', () {
    late OrderBloc orderBloc;

    setUp(() {
      orderBloc = OrderBloc();
    });

    tearDown(() {
      orderBloc.close();
    });

    // Test data
    final testMenuItem1 = MenuItem(
      id: '1',
      itemName: 'Test Burger',
      itemDescription: 'Delicious test burger',
      itemPrice: 12.99,
      imageUrl: 'https://example.com/burger.jpg',
      category: 'Main Course',
    );

    final testMenuItem2 = MenuItem(
      id: '2',
      itemName: 'Test Fries',
      itemDescription: 'Crispy test fries',
      itemPrice: 4.99,
      imageUrl: 'https://example.com/fries.jpg',
      category: 'Sides',
    );

    final testCartItems = [
      CartItem(
        menuItem: testMenuItem1,
        quantity: 2,
        restaurantId: 'restaurant-1',
      ),
      CartItem(
        menuItem: testMenuItem2,
        quantity: 1,
        restaurantId: 'restaurant-1',
      ),
    ];

    const testRestaurantId = 'restaurant-1';
    const testDeliveryFee = 2.99;
    const testTaxRate = 0.08;

    test('initial state is OrderInitial', () {
      expect(orderBloc.state, equals(const OrderInitial()));
    });

    group('PlaceOrder', () {
      blocTest<OrderBloc, OrderState>(
        'emits [OrderValidating, OrderProcessing, OrderSuccess] when order is placed successfully',
        build: () => orderBloc,
        act: (bloc) => bloc.add(PlaceOrder(
          cartItems: testCartItems,
          restaurantId: testRestaurantId,
          deliveryFee: testDeliveryFee,
          taxRate: testTaxRate,
        )),
        wait: const Duration(milliseconds: 300),
        expect: () => [
          const OrderValidating(),
          const OrderProcessing(message: 'Processing your order...'),
          isA<OrderSuccess>(),
        ],
        verify: (bloc) {
          final state = bloc.state as OrderSuccess;
          expect(state.order.items, equals(testCartItems));
          expect(state.order.restaurantId, equals(testRestaurantId));
          expect(state.order.deliveryFee, equals(testDeliveryFee));
          expect(state.order.status, equals(OrderStatus.pending));
          expect(state.order.isValid, isTrue);
        },
      );

      blocTest<OrderBloc, OrderState>(
        'emits [OrderValidating, OrderError] when cart is empty',
        build: () => orderBloc,
        act: (bloc) => bloc.add(const PlaceOrder(
          cartItems: [],
          restaurantId: testRestaurantId,
          deliveryFee: testDeliveryFee,
          taxRate: testTaxRate,
        )),
        expect: () => [
          const OrderValidating(),
          const OrderError(
            message: 'Cart is empty. Please add items before placing an order.',
            canRetry: false,
          ),
        ],
      );

      blocTest<OrderBloc, OrderState>(
        'emits [OrderValidating, OrderError] when restaurant ID is empty',
        build: () => orderBloc,
        act: (bloc) => bloc.add(PlaceOrder(
          cartItems: testCartItems,
          restaurantId: '',
          deliveryFee: testDeliveryFee,
          taxRate: testTaxRate,
        )),
        expect: () => [
          const OrderValidating(),
          const OrderError(
            message: 'Invalid restaurant selection.',
            canRetry: false,
          ),
        ],
      );

      blocTest<OrderBloc, OrderState>(
        'emits [OrderValidating, OrderError] when items are from different restaurants',
        build: () => orderBloc,
        act: (bloc) {
          final mixedCartItems = [
            CartItem(
              menuItem: testMenuItem1,
              quantity: 1,
              restaurantId: 'restaurant-1',
            ),
            CartItem(
              menuItem: testMenuItem2,
              quantity: 1,
              restaurantId: 'restaurant-2', // Different restaurant
            ),
          ];
          
          return bloc.add(PlaceOrder(
            cartItems: mixedCartItems,
            restaurantId: testRestaurantId,
            deliveryFee: testDeliveryFee,
            taxRate: testTaxRate,
          ));
        },
        expect: () => [
          const OrderValidating(),
          const OrderError(
            message: 'All items must be from the same restaurant.',
            canRetry: false,
          ),
        ],
      );

      blocTest<OrderBloc, OrderState>(
        'emits [OrderValidating, OrderError] when order amount is below minimum',
        build: () => orderBloc,
        act: (bloc) {
          final lowValueItem = MenuItem(
            id: '3',
            itemName: 'Cheap Item',
            itemDescription: 'Very cheap item',
            itemPrice: 1.0,
            imageUrl: 'https://example.com/cheap.jpg',
            category: 'Snacks',
          );
          
          final lowValueCartItems = [
            CartItem(
              menuItem: lowValueItem,
              quantity: 1,
              restaurantId: testRestaurantId,
            ),
          ];
          
          return bloc.add(PlaceOrder(
            cartItems: lowValueCartItems,
            restaurantId: testRestaurantId,
            deliveryFee: testDeliveryFee,
            taxRate: testTaxRate,
          ));
        },
        expect: () => [
          const OrderValidating(),
          const OrderError(
            message: 'Minimum order amount is \$5.00.',
            canRetry: false,
          ),
        ],
      );

      blocTest<OrderBloc, OrderState>(
        'emits [OrderValidating, OrderError] when too many items in order',
        build: () => orderBloc,
        act: (bloc) {
          final manyItems = List.generate(
            51, // Exceeds max of 50
            (index) => CartItem(
              menuItem: testMenuItem1,
              quantity: 1,
              restaurantId: testRestaurantId,
            ),
          );
          
          return bloc.add(PlaceOrder(
            cartItems: manyItems,
            restaurantId: testRestaurantId,
            deliveryFee: testDeliveryFee,
            taxRate: testTaxRate,
          ));
        },
        expect: () => [
          const OrderValidating(),
          const OrderError(
            message: 'Maximum 50 items allowed per order.',
            canRetry: false,
          ),
        ],
      );

      blocTest<OrderBloc, OrderState>(
        'emits [OrderValidating, OrderError] when delivery fee is negative',
        build: () => orderBloc,
        act: (bloc) => bloc.add(PlaceOrder(
          cartItems: testCartItems,
          restaurantId: testRestaurantId,
          deliveryFee: -1.0, // Negative delivery fee
          taxRate: testTaxRate,
        )),
        expect: () => [
          const OrderValidating(),
          const OrderError(
            message: 'Invalid pricing configuration.',
            canRetry: true,
          ),
        ],
      );

      blocTest<OrderBloc, OrderState>(
        'emits [OrderValidating, OrderError] when tax rate is invalid',
        build: () => orderBloc,
        act: (bloc) => bloc.add(PlaceOrder(
          cartItems: testCartItems,
          restaurantId: testRestaurantId,
          deliveryFee: testDeliveryFee,
          taxRate: 1.5, // Invalid tax rate > 1
        )),
        expect: () => [
          const OrderValidating(),
          const OrderError(
            message: 'Invalid pricing configuration.',
            canRetry: true,
          ),
        ],
      );
    });

    group('ConfirmOrder', () {
      blocTest<OrderBloc, OrderState>(
        'emits [OrderProcessing, OrderConfirmed] when confirming successful order',
        build: () => orderBloc,
        seed: () {
          final order = Order.fromCartItems(
            id: 'test-order-1',
            items: testCartItems,
            restaurantId: testRestaurantId,
            deliveryFee: testDeliveryFee,
            taxRate: testTaxRate,
          );
          return OrderSuccess(order: order, message: 'Order placed successfully!');
        },
        act: (bloc) => bloc.add(const ConfirmOrder(orderId: 'test-order-1')),
        wait: const Duration(milliseconds: 100),
        expect: () => [
          const OrderProcessing(message: 'Confirming your order...'),
          isA<OrderConfirmed>(),
        ],
        verify: (bloc) {
          final state = bloc.state as OrderConfirmed;
          expect(state.order.status, equals(OrderStatus.confirmed));
          expect(state.confirmationMessage, isNotNull);
        },
      );

      blocTest<OrderBloc, OrderState>(
        'emits [OrderError] when trying to confirm without successful order',
        build: () => orderBloc,
        act: (bloc) => bloc.add(const ConfirmOrder(orderId: 'test-order-1')),
        expect: () => [
          const OrderError(
            message: 'No order to confirm',
            canRetry: false,
          ),
        ],
      );
    });

    group('RetryOrder', () {
      blocTest<OrderBloc, OrderState>(
        'triggers PlaceOrder when retrying',
        build: () => orderBloc,
        act: (bloc) => bloc.add(RetryOrder(
          cartItems: testCartItems,
          restaurantId: testRestaurantId,
          deliveryFee: testDeliveryFee,
          taxRate: testTaxRate,
        )),
        wait: const Duration(milliseconds: 300),
        expect: () => [
          const OrderValidating(),
          const OrderProcessing(message: 'Processing your order...'),
          isA<OrderSuccess>(),
        ],
      );
    });

    group('ResetOrder', () {
      blocTest<OrderBloc, OrderState>(
        'emits [OrderInitial] when resetting order',
        build: () => orderBloc,
        seed: () => const OrderError(message: 'Some error'),
        act: (bloc) => bloc.add(const ResetOrder()),
        expect: () => [const OrderInitial()],
      );
    });

    group('Order Calculations', () {
      test('order totals are calculated correctly', () async {
        // Place order and wait for completion
        orderBloc.add(PlaceOrder(
          cartItems: testCartItems,
          restaurantId: testRestaurantId,
          deliveryFee: testDeliveryFee,
          taxRate: testTaxRate,
        ));

        await expectLater(
          orderBloc.stream,
          emitsInOrder([
            const OrderValidating(),
            const OrderProcessing(message: 'Processing your order...'),
            isA<OrderSuccess>(),
          ]),
        );

        final state = orderBloc.state as OrderSuccess;
        final order = state.order;

        // Calculate expected values
        final expectedSubtotal = (testMenuItem1.itemPrice * 2) + (testMenuItem2.itemPrice * 1);
        final expectedTax = expectedSubtotal * testTaxRate;
        final expectedTotal = expectedSubtotal + testDeliveryFee + expectedTax;

        expect(order.subtotal, closeTo(expectedSubtotal, 0.01));
        expect(order.tax, closeTo(expectedTax, 0.01));
        expect(order.deliveryFee, equals(testDeliveryFee));
        expect(order.total, closeTo(expectedTotal, 0.01));
      });

      test('order ID is generated correctly', () async {
        orderBloc.add(PlaceOrder(
          cartItems: testCartItems,
          restaurantId: testRestaurantId,
          deliveryFee: testDeliveryFee,
          taxRate: testTaxRate,
        ));

        await expectLater(
          orderBloc.stream,
          emitsInOrder([
            const OrderValidating(),
            const OrderProcessing(message: 'Processing your order...'),
            isA<OrderSuccess>(),
          ]),
        );

        final state = orderBloc.state as OrderSuccess;
        final order = state.order;

        expect(order.id, isNotEmpty);
        expect(order.id, startsWith('ORD-'));
        expect(order.id.split('-'), hasLength(3));
      });
    });

    group('Edge Cases', () {
      blocTest<OrderBloc, OrderState>(
        'handles invalid cart items gracefully',
        build: () => orderBloc,
        act: (bloc) {
          final invalidMenuItem = MenuItem(
            id: '', // Invalid empty ID
            itemName: 'Invalid Item',
            itemDescription: 'Invalid item description',
            itemPrice: -5.0, // Invalid negative price
            imageUrl: 'invalid-url',
            category: 'Test',
          );
          
          final invalidCartItems = [
            CartItem(
              menuItem: invalidMenuItem,
              quantity: 1,
              restaurantId: testRestaurantId,
            ),
          ];
          
          return bloc.add(PlaceOrder(
            cartItems: invalidCartItems,
            restaurantId: testRestaurantId,
            deliveryFee: testDeliveryFee,
            taxRate: testTaxRate,
          ));
        },
        expect: () => [
          const OrderValidating(),
          const OrderError(
            message: 'Invalid item in cart. Please review your order.',
            canRetry: false,
          ),
        ],
      );

      blocTest<OrderBloc, OrderState>(
        'handles zero quantity cart items',
        build: () => orderBloc,
        act: (bloc) {
          final zeroQuantityCartItems = [
            CartItem(
              menuItem: testMenuItem1,
              quantity: 0, // Invalid zero quantity
              restaurantId: testRestaurantId,
            ),
          ];
          
          return bloc.add(PlaceOrder(
            cartItems: zeroQuantityCartItems,
            restaurantId: testRestaurantId,
            deliveryFee: testDeliveryFee,
            taxRate: testTaxRate,
          ));
        },
        expect: () => [
          const OrderValidating(),
          const OrderError(
            message: 'Invalid item in cart. Please review your order.',
            canRetry: false,
          ),
        ],
      );
    });
  });
}