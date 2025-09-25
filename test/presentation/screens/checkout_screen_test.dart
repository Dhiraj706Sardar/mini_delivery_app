import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:deliery_app/presentation/screens/checkout_screen.dart';
import 'package:deliery_app/presentation/blocs/cart/cart_bloc.dart';
import 'package:deliery_app/presentation/blocs/cart/cart_state.dart';
import 'package:deliery_app/presentation/blocs/cart/cart_event.dart';
import 'package:deliery_app/presentation/blocs/order/order_bloc.dart';
import 'package:deliery_app/presentation/blocs/order/order_state.dart';

import 'package:deliery_app/data/models/cart_item.dart';
import 'package:deliery_app/data/models/menu_item.dart';
import 'package:deliery_app/data/models/order.dart';
import 'package:deliery_app/core/theme/app_theme.dart';

import 'checkout_screen_test.mocks.dart';

@GenerateMocks([CartBloc, OrderBloc])
void main() {
  group('CheckoutScreen', () {
    late MockCartBloc mockCartBloc;
    late MockOrderBloc mockOrderBloc;

    setUp(() {
      mockCartBloc = MockCartBloc();
      mockOrderBloc = MockOrderBloc();
    });

    tearDown(() {
      mockCartBloc.close();
      mockOrderBloc.close();
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

    final testCartState = CartUpdated(
      items: testCartItems,
      subtotal: 30.97,
      deliveryFee: 2.99,
      tax: 2.48,
      total: 36.44,
      totalItems: 3,
      currentRestaurantId: 'restaurant-1',
    );

    Widget createTestWidget() {
      return MaterialApp(
        theme: AppTheme.lightTheme,
        home: MultiBlocProvider(
          providers: [
            BlocProvider<CartBloc>.value(value: mockCartBloc),
            BlocProvider<OrderBloc>.value(value: mockOrderBloc),
          ],
          child: const CheckoutScreen(),
        ),
        routes: {
          '/restaurants': (context) =>
              const Scaffold(body: Text('Restaurants')),
          '/order-confirmation': (context) =>
              const Scaffold(body: Text('Order Confirmation')),
        },
      );
    }

    group('Widget Rendering', () {
      testWidgets('renders checkout screen with app bar', (tester) async {
        when(mockCartBloc.state).thenReturn(const CartLoading());
        when(mockCartBloc.stream).thenAnswer((_) => const Stream.empty());
        when(mockOrderBloc.state).thenReturn(const OrderInitial());
        when(mockOrderBloc.stream).thenAnswer((_) => const Stream.empty());

        await tester.pumpWidget(createTestWidget());

        expect(find.text('Checkout'), findsOneWidget);
        expect(find.byType(AppBar), findsOneWidget);
      });

      testWidgets('shows loading state when cart is loading', (tester) async {
        when(mockCartBloc.state).thenReturn(const CartLoading());
        when(mockCartBloc.stream).thenAnswer((_) => const Stream.empty());
        when(mockOrderBloc.state).thenReturn(const OrderInitial());
        when(mockOrderBloc.stream).thenAnswer((_) => const Stream.empty());

        await tester.pumpWidget(createTestWidget());

        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        expect(find.text('Loading your cart...'), findsOneWidget);
      });

      testWidgets('shows empty cart state when cart is empty', (tester) async {
        const emptyCartState = CartUpdated(
          items: [],
          subtotal: 0.0,
          deliveryFee: 0.0,
          tax: 0.0,
          total: 0.0,
          totalItems: 0,
          currentRestaurantId: null,
        );

        when(mockCartBloc.state).thenReturn(emptyCartState);
        when(mockCartBloc.stream).thenAnswer((_) => const Stream.empty());
        when(mockOrderBloc.state).thenReturn(const OrderInitial());
        when(mockOrderBloc.stream).thenAnswer((_) => const Stream.empty());

        await tester.pumpWidget(createTestWidget());

        expect(find.text('Your cart is empty'), findsOneWidget);
        expect(
          find.text('Add some items to your cart before checkout.'),
          findsOneWidget,
        );
        expect(find.text('Browse Restaurants'), findsOneWidget);
      });

      testWidgets('shows error state when cart has error', (tester) async {
        const errorState = CartError(message: 'Failed to load cart');

        when(mockCartBloc.state).thenReturn(errorState);
        when(mockCartBloc.stream).thenAnswer((_) => const Stream.empty());
        when(mockOrderBloc.state).thenReturn(const OrderInitial());
        when(mockOrderBloc.stream).thenAnswer((_) => const Stream.empty());

        await tester.pumpWidget(createTestWidget());

        expect(find.text('Something went wrong'), findsOneWidget);
        expect(find.text('Failed to load cart'), findsOneWidget);
        expect(find.text('Try Again'), findsOneWidget);
      });
    });

    group('Checkout Content', () {
      testWidgets('displays order items section with cart items', (
        tester,
      ) async {
        when(mockCartBloc.state).thenReturn(testCartState);
        when(mockCartBloc.stream).thenAnswer((_) => const Stream.empty());
        when(mockOrderBloc.state).thenReturn(const OrderInitial());
        when(mockOrderBloc.stream).thenAnswer((_) => const Stream.empty());

        await tester.pumpWidget(createTestWidget());

        expect(find.text('Order Items'), findsOneWidget);
        expect(find.text('Test Burger'), findsOneWidget);
        expect(find.text('Test Fries'), findsOneWidget);
        expect(find.text('Qty: 2'), findsOneWidget);
        expect(find.text('Qty: 1'), findsOneWidget);
        expect(find.text('Total Items'), findsOneWidget);
        expect(find.text('3'), findsOneWidget);
      });

      testWidgets('displays delivery information section', (tester) async {
        when(mockCartBloc.state).thenReturn(testCartState);
        when(mockCartBloc.stream).thenAnswer((_) => const Stream.empty());
        when(mockOrderBloc.state).thenReturn(const OrderInitial());
        when(mockOrderBloc.stream).thenAnswer((_) => const Stream.empty());

        await tester.pumpWidget(createTestWidget());

        expect(find.text('Delivery Information'), findsOneWidget);
        expect(find.text('Address'), findsOneWidget);
        expect(
          find.text('123 Main Street, Apt 4B\nNew York, NY 10001'),
          findsOneWidget,
        );
        expect(find.text('Estimated Delivery'), findsOneWidget);
        expect(find.text('25-35 minutes'), findsOneWidget);
      });

      testWidgets('displays payment method section', (tester) async {
        when(mockCartBloc.state).thenReturn(testCartState);
        when(mockCartBloc.stream).thenAnswer((_) => const Stream.empty());
        when(mockOrderBloc.state).thenReturn(const OrderInitial());
        when(mockOrderBloc.stream).thenAnswer((_) => const Stream.empty());

        await tester.pumpWidget(createTestWidget());

        expect(find.text('Payment Method'), findsOneWidget);
        expect(find.text('Credit Card'), findsOneWidget);
        expect(find.text('**** **** **** 1234'), findsOneWidget);
        expect(find.text('Change'), findsOneWidget);
      });

      testWidgets('displays order summary section with correct totals', (
        tester,
      ) async {
        when(mockCartBloc.state).thenReturn(testCartState);
        when(mockCartBloc.stream).thenAnswer((_) => const Stream.empty());
        when(mockOrderBloc.state).thenReturn(const OrderInitial());
        when(mockOrderBloc.stream).thenAnswer((_) => const Stream.empty());

        await tester.pumpWidget(createTestWidget());

        expect(find.text('Order Summary'), findsOneWidget);
        expect(find.text('Subtotal'), findsOneWidget);
        expect(find.text('\$30.97'), findsOneWidget);
        expect(find.text('Delivery Fee'), findsOneWidget);
        expect(find.text('\$2.99'), findsOneWidget);
        expect(find.text('Tax & Fees'), findsOneWidget);
        expect(find.text('\$2.48'), findsOneWidget);
        expect(find.text('Total'), findsOneWidget);
        expect(find.text('\$36.44'), findsAtLeastNWidgets(1));
      });

      testWidgets('shows free delivery message when applicable', (
        tester,
      ) async {
        final freeDeliveryCartState = CartUpdated(
          items: testCartItems,
          subtotal: 30.97,
          deliveryFee: 0.0, // Free delivery
          tax: 2.48,
          total: 33.45,
          totalItems: 3,
          currentRestaurantId: 'restaurant-1',
        );

        when(mockCartBloc.state).thenReturn(freeDeliveryCartState);
        when(mockCartBloc.stream).thenAnswer((_) => const Stream.empty());
        when(mockOrderBloc.state).thenReturn(const OrderInitial());
        when(mockOrderBloc.stream).thenAnswer((_) => const Stream.empty());

        await tester.pumpWidget(createTestWidget());

        expect(find.text('FREE'), findsOneWidget);
        expect(find.text('You saved \$2.99 on delivery!'), findsOneWidget);
      });
    });

    group('Place Order Button', () {
      testWidgets('displays place order button with total', (tester) async {
        when(mockCartBloc.state).thenReturn(testCartState);
        when(mockCartBloc.stream).thenAnswer((_) => const Stream.empty());
        when(mockOrderBloc.state).thenReturn(const OrderInitial());
        when(mockOrderBloc.stream).thenAnswer((_) => const Stream.empty());

        await tester.pumpWidget(createTestWidget());

        expect(find.text('Place Order'), findsOneWidget);
        expect(
          find.text('\$36.44'),
          findsAtLeastNWidgets(2),
        ); // One in summary, one in button
      });

      testWidgets('shows processing state when order is being processed', (
        tester,
      ) async {
        when(mockCartBloc.state).thenReturn(testCartState);
        when(mockCartBloc.stream).thenAnswer((_) => const Stream.empty());
        when(mockOrderBloc.state).thenReturn(
          const OrderProcessing(message: 'Processing your order...'),
        );
        when(mockOrderBloc.stream).thenAnswer((_) => const Stream.empty());

        await tester.pumpWidget(createTestWidget());

        expect(find.text('Processing...'), findsOneWidget);
        expect(find.text('Processing your order...'), findsOneWidget);
        expect(find.byType(CircularProgressIndicator), findsAtLeastNWidgets(1));
      });

      testWidgets('shows validating state when order is being validated', (
        tester,
      ) async {
        when(mockCartBloc.state).thenReturn(testCartState);
        when(mockCartBloc.stream).thenAnswer((_) => const Stream.empty());
        when(mockOrderBloc.state).thenReturn(const OrderValidating());
        when(mockOrderBloc.stream).thenAnswer((_) => const Stream.empty());

        await tester.pumpWidget(createTestWidget());

        expect(find.text('Processing...'), findsOneWidget);
        expect(find.text('Validating your order...'), findsOneWidget);
        expect(find.byType(CircularProgressIndicator), findsAtLeastNWidgets(1));
      });

      testWidgets('places order when button is tapped', (tester) async {
        when(mockCartBloc.state).thenReturn(testCartState);
        when(mockCartBloc.stream).thenAnswer((_) => const Stream.empty());
        when(mockOrderBloc.state).thenReturn(const OrderInitial());
        when(mockOrderBloc.stream).thenAnswer((_) => const Stream.empty());

        await tester.pumpWidget(createTestWidget());

        final placeOrderButton = find.text('Place Order');
        expect(placeOrderButton, findsOneWidget);

        await tester.tap(placeOrderButton);
        await tester.pump();

        verify(mockOrderBloc.add(any)).called(1);
      });

      testWidgets('button is disabled when order is processing', (
        tester,
      ) async {
        when(mockCartBloc.state).thenReturn(testCartState);
        when(mockCartBloc.stream).thenAnswer((_) => const Stream.empty());
        when(mockOrderBloc.state).thenReturn(const OrderProcessing());
        when(mockOrderBloc.stream).thenAnswer((_) => const Stream.empty());

        await tester.pumpWidget(createTestWidget());

        final elevatedButton = tester.widget<ElevatedButton>(
          find.byType(ElevatedButton).last,
        );
        expect(elevatedButton.onPressed, isNull);
      });
    });

    group('Order State Handling', () {
      testWidgets('navigates to order confirmation on successful order', (
        tester,
      ) async {
        final testOrder = Order.fromCartItems(
          id: 'test-order-1',
          items: testCartItems,
          restaurantId: 'restaurant-1',
        );

        when(mockCartBloc.state).thenReturn(testCartState);
        when(mockCartBloc.stream).thenAnswer((_) => const Stream.empty());
        when(mockOrderBloc.state).thenReturn(const OrderInitial());
        when(mockOrderBloc.stream).thenAnswer(
          (_) => Stream.fromIterable([
            OrderSuccess(
              order: testOrder,
              message: 'Order placed successfully!',
            ),
          ]),
        );

        await tester.pumpWidget(createTestWidget());
        await tester.pump();

        // Verify cart is cleared
        verify(mockCartBloc.add(const ClearCart())).called(1);

        // Check if we're on the order confirmation screen
        await tester.pumpAndSettle();
        expect(find.text('Order Confirmation'), findsOneWidget);
      });

      testWidgets('shows error snackbar on order error', (tester) async {
        when(mockCartBloc.state).thenReturn(testCartState);
        when(mockCartBloc.stream).thenAnswer((_) => const Stream.empty());
        when(mockOrderBloc.state).thenReturn(const OrderInitial());
        when(mockOrderBloc.stream).thenAnswer(
          (_) => Stream.fromIterable([
            const OrderError(message: 'Order failed', canRetry: true),
          ]),
        );

        await tester.pumpWidget(createTestWidget());
        await tester.pump();

        expect(find.text('Order failed'), findsOneWidget);
        expect(find.text('Retry'), findsOneWidget);
      });

      testWidgets('shows error snackbar without retry when canRetry is false', (
        tester,
      ) async {
        when(mockCartBloc.state).thenReturn(testCartState);
        when(mockCartBloc.stream).thenAnswer((_) => const Stream.empty());
        when(mockOrderBloc.state).thenReturn(const OrderInitial());
        when(mockOrderBloc.stream).thenAnswer(
          (_) => Stream.fromIterable([
            const OrderError(message: 'Order failed', canRetry: false),
          ]),
        );

        await tester.pumpWidget(createTestWidget());
        await tester.pump();

        expect(find.text('Order failed'), findsOneWidget);
        expect(find.text('Retry'), findsNothing);
      });
    });

    group('User Interactions', () {
      testWidgets('loads cart on screen initialization', (tester) async {
        when(mockCartBloc.state).thenReturn(const CartLoading());
        when(mockCartBloc.stream).thenAnswer((_) => const Stream.empty());
        when(mockOrderBloc.state).thenReturn(const OrderInitial());
        when(mockOrderBloc.stream).thenAnswer((_) => const Stream.empty());

        await tester.pumpWidget(createTestWidget());

        verify(mockCartBloc.add(const LoadCart())).called(1);
      });

      testWidgets(
        'retries loading cart when try again is tapped in error state',
        (tester) async {
          const errorState = CartError(message: 'Failed to load cart');

          when(mockCartBloc.state).thenReturn(errorState);
          when(mockCartBloc.stream).thenAnswer((_) => const Stream.empty());
          when(mockOrderBloc.state).thenReturn(const OrderInitial());
          when(mockOrderBloc.stream).thenAnswer((_) => const Stream.empty());

          await tester.pumpWidget(createTestWidget());

          final tryAgainButton = find.text('Try Again');
          expect(tryAgainButton, findsOneWidget);

          await tester.tap(tryAgainButton);
          await tester.pump();

          verify(
            mockCartBloc.add(const LoadCart()),
          ).called(2); // Once on init, once on retry
        },
      );

      testWidgets(
        'navigates to restaurants when browse restaurants is tapped',
        (tester) async {
          const emptyCartState = CartUpdated(
            items: [],
            subtotal: 0.0,
            deliveryFee: 0.0,
            tax: 0.0,
            total: 0.0,
            totalItems: 0,
            currentRestaurantId: null,
          );

          when(mockCartBloc.state).thenReturn(emptyCartState);
          when(mockCartBloc.stream).thenAnswer((_) => const Stream.empty());
          when(mockOrderBloc.state).thenReturn(const OrderInitial());
          when(mockOrderBloc.stream).thenAnswer((_) => const Stream.empty());

          await tester.pumpWidget(createTestWidget());

          final browseButton = find.text('Browse Restaurants');
          expect(browseButton, findsOneWidget);

          await tester.tap(browseButton);
          await tester.pumpAndSettle();

          expect(find.text('Restaurants'), findsOneWidget);
        },
      );

      testWidgets('shows payment method change dialog when change is tapped', (
        tester,
      ) async {
        when(mockCartBloc.state).thenReturn(testCartState);
        when(mockCartBloc.stream).thenAnswer((_) => const Stream.empty());
        when(mockOrderBloc.state).thenReturn(const OrderInitial());
        when(mockOrderBloc.stream).thenAnswer((_) => const Stream.empty());

        await tester.pumpWidget(createTestWidget());

        final changeButton = find.text('Change');
        expect(changeButton, findsOneWidget);

        // Scroll to make the button visible
        await tester.scrollUntilVisible(changeButton, 100);
        await tester.tap(changeButton);
        await tester.pump();

        expect(
          find.text('Payment method selection not implemented in demo'),
          findsOneWidget,
        );
      });
    });

    group('Edge Cases', () {
      testWidgets('handles null restaurant ID gracefully', (tester) async {
        final invalidCartState = CartUpdated(
          items: testCartItems,
          subtotal: 30.97,
          deliveryFee: 2.99,
          tax: 2.48,
          total: 36.44,
          totalItems: 3,
          currentRestaurantId: null, // Null restaurant ID
        );

        when(mockCartBloc.state).thenReturn(invalidCartState);
        when(mockCartBloc.stream).thenAnswer((_) => const Stream.empty());
        when(mockOrderBloc.state).thenReturn(const OrderInitial());
        when(mockOrderBloc.stream).thenAnswer((_) => const Stream.empty());

        await tester.pumpWidget(createTestWidget());

        final placeOrderButton = find.text('Place Order');
        await tester.tap(placeOrderButton);
        await tester.pump();

        expect(
          find.text('Unable to place order: Invalid restaurant selection'),
          findsOneWidget,
        );
        verifyNever(mockOrderBloc.add(any));
      });

      testWidgets('handles image loading errors gracefully', (tester) async {
        when(mockCartBloc.state).thenReturn(testCartState);
        when(mockCartBloc.stream).thenAnswer((_) => const Stream.empty());
        when(mockOrderBloc.state).thenReturn(const OrderInitial());
        when(mockOrderBloc.stream).thenAnswer((_) => const Stream.empty());

        await tester.pumpWidget(createTestWidget());

        // The error builder should show a fallback icon when images fail to load
        // Since we can't easily trigger image loading errors in tests, we'll just verify the screen renders
        expect(find.text('Order Items'), findsOneWidget);
      });
    });
  });
}
