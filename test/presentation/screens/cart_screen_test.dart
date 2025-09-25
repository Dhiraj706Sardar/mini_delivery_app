import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

import 'package:deliery_app/presentation/screens/cart_screen.dart';
import 'package:deliery_app/presentation/blocs/cart/cart_bloc.dart';
import 'package:deliery_app/presentation/blocs/cart/cart_event.dart';
import 'package:deliery_app/presentation/blocs/cart/cart_state.dart';
import 'package:deliery_app/presentation/widgets/cart_item_card.dart';
import 'package:deliery_app/data/models/cart_item.dart';
import 'package:deliery_app/data/models/menu_item.dart';
import 'package:deliery_app/core/theme/app_theme.dart';

import 'cart_screen_test.mocks.dart';

@GenerateMocks([CartBloc])
void main() {
  group('CartScreen Widget Tests', () {
    late MockCartBloc mockCartBloc;
    late List<CartItem> testCartItems;
    late CartUpdated testCartState;

    setUp(() {
      mockCartBloc = MockCartBloc();
      
      // Create test cart items
      testCartItems = [
        CartItem(
          menuItem: const MenuItem(
            id: 'menu_1',
            itemName: 'Burger',
            itemDescription: 'Delicious beef burger',
            itemPrice: 12.99,
            imageUrl: 'https://example.com/burger.jpg',
            category: 'Main Course',
          ),
          quantity: 2,
          restaurantId: 'restaurant_1',
        ),
        CartItem(
          menuItem: const MenuItem(
            id: 'menu_2',
            itemName: 'Pizza',
            itemDescription: 'Margherita pizza',
            itemPrice: 15.99,
            imageUrl: 'https://example.com/pizza.jpg',
            category: 'Main Course',
          ),
          quantity: 1,
          restaurantId: 'restaurant_1',
        ),
      ];

      testCartState = CartUpdated(
        items: testCartItems,
        subtotal: 41.97, // (12.99 * 2) + 15.99
        deliveryFee: 2.99,
        tax: 3.36, // 8% of subtotal
        total: 48.32,
        totalItems: 3,
        currentRestaurantId: 'restaurant_1',
      );

      // Setup default mock behavior
      when(mockCartBloc.state).thenReturn(const CartInitial());
      when(mockCartBloc.stream).thenAnswer((_) => const Stream.empty());
    });

    Widget createTestWidget({CartState? initialState}) {
      when(mockCartBloc.state).thenReturn(initialState ?? const CartInitial());
      
      return MaterialApp(
        theme: AppTheme.lightTheme,
        home: BlocProvider<CartBloc>.value(
          value: mockCartBloc,
          child: const CartScreen(),
        ),
        routes: {
          '/restaurants': (context) => const Scaffold(body: Text('Restaurants')),
          '/checkout': (context) => const Scaffold(body: Text('Checkout')),
        },
      );
    }

    testWidgets('loads cart on initialization', (tester) async {
      await tester.pumpWidget(createTestWidget());

      // Verify LoadCart event is sent on initialization
      verify(mockCartBloc.add(const LoadCart())).called(1);
    });

    testWidgets('displays loading state correctly', (tester) async {
      await tester.pumpWidget(createTestWidget(initialState: const CartLoading()));

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Loading your cart...'), findsOneWidget);
    });

    testWidgets('displays empty cart state correctly', (tester) async {
      const emptyCartState = CartUpdated(
        items: [],
        subtotal: 0.0,
        deliveryFee: 0.0,
        tax: 0.0,
        total: 0.0,
        totalItems: 0,
      );

      await tester.pumpWidget(createTestWidget(initialState: emptyCartState));

      expect(find.byIcon(Icons.shopping_cart_outlined), findsOneWidget);
      expect(find.text('Your cart is empty'), findsOneWidget);
      expect(find.text('Add some delicious items from our restaurants to get started!'), findsOneWidget);
      expect(find.text('Browse Restaurants'), findsOneWidget);
    });

    testWidgets('displays cart items correctly', (tester) async {
      await tester.pumpWidget(createTestWidget(initialState: testCartState));

      // Verify cart items are displayed
      expect(find.byType(CartItemCard), findsNWidgets(2));
      expect(find.text('Burger'), findsOneWidget);
      expect(find.text('Pizza'), findsOneWidget);
    });

    testWidgets('displays order summary correctly', (tester) async {
      await tester.pumpWidget(createTestWidget(initialState: testCartState));

      // Verify order summary section
      expect(find.text('Order Summary'), findsOneWidget);
      expect(find.text('Subtotal (3 items)'), findsOneWidget);
      expect(find.text('\$41.97'), findsOneWidget);
      expect(find.text('Delivery Fee'), findsOneWidget);
      expect(find.text('\$2.99'), findsOneWidget);
      expect(find.text('Tax & Fees'), findsOneWidget);
      expect(find.text('\$3.36'), findsOneWidget);
      expect(find.text('Total'), findsOneWidget);
      expect(find.text('\$48.32'), findsAtLeastNWidgets(1));
    });

    testWidgets('displays free delivery message when applicable', (tester) async {
      final freeDeliveryState = CartUpdated(
        items: testCartItems,
        subtotal: 30.0, // Above free delivery threshold
        deliveryFee: 0.0,
        tax: 2.40,
        total: 32.40,
        totalItems: 3,
        currentRestaurantId: 'restaurant_1',
      );

      await tester.pumpWidget(createTestWidget(initialState: freeDeliveryState));

      expect(find.text('FREE'), findsOneWidget);
      expect(find.text('You saved \$2.99 on delivery!'), findsOneWidget);
      expect(find.byIcon(Icons.local_shipping), findsOneWidget);
    });

    testWidgets('displays checkout bottom bar when cart has items', (tester) async {
      await tester.pumpWidget(createTestWidget(initialState: testCartState));

      // Verify checkout bottom bar
      expect(find.text('Estimated delivery: 25-35 min'), findsOneWidget);
      expect(find.text('Proceed to Checkout'), findsOneWidget);
      expect(find.byIcon(Icons.access_time), findsOneWidget);
      
      // Verify total is displayed in both summary and checkout button
      final totalTexts = find.text('\$48.32');
      expect(totalTexts, findsNWidgets(2)); // One in summary, one in button
    });

    testWidgets('hides checkout bottom bar when cart is empty', (tester) async {
      const emptyCartState = CartUpdated(
        items: [],
        subtotal: 0.0,
        deliveryFee: 0.0,
        tax: 0.0,
        total: 0.0,
        totalItems: 0,
      );

      await tester.pumpWidget(createTestWidget(initialState: emptyCartState));

      expect(find.text('Proceed to Checkout'), findsNothing);
      expect(find.text('Estimated delivery: 25-35 min'), findsNothing);
    });

    testWidgets('shows clear cart button when cart has items', (tester) async {
      await tester.pumpWidget(createTestWidget(initialState: testCartState));

      expect(find.byIcon(Icons.delete_outline), findsOneWidget);
    });

    testWidgets('hides clear cart button when cart is empty', (tester) async {
      const emptyCartState = CartUpdated(
        items: [],
        subtotal: 0.0,
        deliveryFee: 0.0,
        tax: 0.0,
        total: 0.0,
        totalItems: 0,
      );

      await tester.pumpWidget(createTestWidget(initialState: emptyCartState));

      expect(find.byIcon(Icons.delete_outline), findsNothing);
    });

    testWidgets('clear cart dialog works correctly', (tester) async {
      await tester.pumpWidget(createTestWidget(initialState: testCartState));

      // Tap clear cart button
      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pump();

      // Verify dialog is shown
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('Clear Cart'), findsNWidgets(2)); // Title and button
      expect(find.text('Are you sure you want to remove all items from your cart? This action cannot be undone.'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
    });

    testWidgets('clear cart dialog cancel works', (tester) async {
      await tester.pumpWidget(createTestWidget(initialState: testCartState));

      // Show dialog and cancel
      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pump();
      await tester.tap(find.text('Cancel'));
      await tester.pump();

      // Dialog should be dismissed
      expect(find.byType(AlertDialog), findsNothing);
      
      // No clear event should be sent
      verifyNever(mockCartBloc.add(const ClearCart()));
    });

    testWidgets('clear cart dialog confirm works', (tester) async {
      await tester.pumpWidget(createTestWidget(initialState: testCartState));

      // Show dialog and confirm
      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pump();
      await tester.tap(find.text('Clear Cart').last); // Get the button, not the title
      await tester.pump();

      // Verify clear event is sent
      verify(mockCartBloc.add(const ClearCart())).called(1);
    });

    testWidgets('browse restaurants button navigates correctly', (tester) async {
      const emptyCartState = CartUpdated(
        items: [],
        subtotal: 0.0,
        deliveryFee: 0.0,
        tax: 0.0,
        total: 0.0,
        totalItems: 0,
      );

      await tester.pumpWidget(createTestWidget(initialState: emptyCartState));

      // Tap browse restaurants button
      await tester.tap(find.text('Browse Restaurants'));
      await tester.pumpAndSettle();

      // Verify navigation to restaurants screen
      expect(find.text('Restaurants'), findsOneWidget);
    });

    testWidgets('proceed to checkout button navigates correctly', (tester) async {
      await tester.pumpWidget(createTestWidget(initialState: testCartState));

      // Tap proceed to checkout button
      await tester.tap(find.text('Proceed to Checkout'));
      await tester.pumpAndSettle();

      // Verify navigation to checkout screen
      expect(find.text('Checkout'), findsOneWidget);
    });

    testWidgets('displays error state correctly', (tester) async {
      const errorState = CartError(message: 'Failed to load cart');

      await tester.pumpWidget(createTestWidget(initialState: errorState));

      expect(find.byIcon(Icons.error_outline), findsOneWidget);
      expect(find.text('Something went wrong'), findsOneWidget);
      expect(find.text('Failed to load cart'), findsOneWidget);
      expect(find.text('Try Again'), findsOneWidget);
    });

    testWidgets('error state retry button works', (tester) async {
      const errorState = CartError(message: 'Failed to load cart');

      await tester.pumpWidget(createTestWidget(initialState: errorState));

      // Tap retry button
      await tester.tap(find.text('Try Again'));
      await tester.pump();

      // Verify LoadCart event is sent
      verify(mockCartBloc.add(const LoadCart())).called(2); // Once on init, once on retry
    });

    testWidgets('displays initial state correctly', (tester) async {
      await tester.pumpWidget(createTestWidget(initialState: const CartInitial()));

      expect(find.byIcon(Icons.shopping_cart), findsOneWidget);
      expect(find.text('Loading your cart items...'), findsOneWidget);
      expect(find.text('Load Cart'), findsOneWidget);
      
      // Title may appear in both app bar and body
      expect(find.text('Your Cart'), findsAtLeastNWidgets(1));
    });

    testWidgets('initial state load cart button works', (tester) async {
      await tester.pumpWidget(createTestWidget(initialState: const CartInitial()));

      // Tap load cart button
      await tester.tap(find.text('Load Cart'));
      await tester.pump();

      // Verify LoadCart event is sent
      verify(mockCartBloc.add(const LoadCart())).called(2); // Once on init, once on button tap
    });

    testWidgets('displays correct item count in summary', (tester) async {
      final singleItemState = CartUpdated(
        items: [testCartItems.first],
        subtotal: 25.98,
        deliveryFee: 2.99,
        tax: 2.08,
        total: 31.05,
        totalItems: 2, // 2 quantity of 1 item
        currentRestaurantId: 'restaurant_1',
      );

      await tester.pumpWidget(createTestWidget(initialState: singleItemState));

      expect(find.text('Subtotal (2 items)'), findsOneWidget);
    });

    testWidgets('handles different cart states correctly', (tester) async {
      // Test with empty cart
      const emptyState = CartUpdated(
        items: [],
        subtotal: 0.0,
        deliveryFee: 0.0,
        tax: 0.0,
        total: 0.0,
        totalItems: 0,
      );

      await tester.pumpWidget(createTestWidget(initialState: emptyState));
      expect(find.text('Your cart is empty'), findsOneWidget);
      expect(find.text('Browse Restaurants'), findsOneWidget);
    });

    testWidgets('displays app bar title correctly', (tester) async {
      await tester.pumpWidget(createTestWidget());

      // Find app bar title specifically
      final appBar = find.byType(AppBar);
      expect(appBar, findsOneWidget);
      
      // Verify app bar styling
      final appBarWidget = tester.widget<AppBar>(appBar);
      expect(appBarWidget.backgroundColor, equals(AppTheme.primaryColor));
      expect(appBarWidget.foregroundColor, equals(Colors.white));
      
      // Verify title exists (may appear multiple times in different contexts)
      expect(find.text('Your Cart'), findsAtLeastNWidgets(1));
    });

    testWidgets('checkout button is disabled when cart is empty', (tester) async {
      const emptyCartState = CartUpdated(
        items: [],
        subtotal: 0.0,
        deliveryFee: 0.0,
        tax: 0.0,
        total: 0.0,
        totalItems: 0,
      );

      await tester.pumpWidget(createTestWidget(initialState: emptyCartState));

      // Checkout button should not be visible for empty cart
      expect(find.text('Proceed to Checkout'), findsNothing);
    });

    testWidgets('displays delivery time estimate', (tester) async {
      await tester.pumpWidget(createTestWidget(initialState: testCartState));

      expect(find.text('Estimated delivery: 25-35 min'), findsOneWidget);
      expect(find.byIcon(Icons.access_time), findsOneWidget);
    });
  });
}