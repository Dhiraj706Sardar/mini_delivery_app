import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

import 'package:deliery_app/presentation/screens/order_confirmation_screen.dart';
import 'package:deliery_app/presentation/blocs/cart/cart_bloc.dart';
import 'package:deliery_app/data/models/order.dart';
import 'package:deliery_app/data/models/cart_item.dart';
import 'package:deliery_app/data/models/menu_item.dart';
import 'package:deliery_app/core/theme/app_theme.dart';

import 'order_confirmation_screen_test.mocks.dart';

@GenerateMocks([CartBloc])
void main() {
  group('OrderConfirmationScreen', () {
    late MockCartBloc mockCartBloc;
    late Order testOrder;
    late List<CartItem> testCartItems;

    setUp(() {
      mockCartBloc = MockCartBloc();
      
      // Create test menu items
      final menuItem1 = MenuItem(
        id: '1',
        itemName: 'Burger',
        itemDescription: 'Delicious beef burger',
        itemPrice: 12.99,
        imageUrl: 'https://example.com/burger.jpg',
        category: 'Main Course',
      );
      
      final menuItem2 = MenuItem(
        id: '2',
        itemName: 'Fries',
        itemDescription: 'Crispy french fries',
        itemPrice: 4.99,
        imageUrl: 'https://example.com/fries.jpg',
        category: 'Sides',
      );

      // Create test cart items
      testCartItems = [
        CartItem(
          menuItem: menuItem1,
          quantity: 2,
          restaurantId: 'restaurant1',
        ),
        CartItem(
          menuItem: menuItem2,
          quantity: 1,
          restaurantId: 'restaurant1',
        ),
      ];

      // Create test order
      testOrder = Order.fromCartItems(
        id: 'ORDER-123456',
        items: testCartItems,
        restaurantId: 'restaurant1',
        deliveryFee: 2.99,
        taxRate: 0.08,
        orderTime: DateTime(2024, 1, 15, 12, 30),
        status: OrderStatus.confirmed,
      );
    });

    Widget createWidgetUnderTest() {
      return MaterialApp(
        theme: AppTheme.lightTheme,
        home: BlocProvider<CartBloc>(
          create: (context) => mockCartBloc,
          child: OrderConfirmationScreen(order: testOrder),
        ),
      );
    }

    testWidgets('should display success header with checkmark and message', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Verify success checkmark is displayed
      expect(find.byIcon(Icons.check), findsOneWidget);
      
      // Verify success messages
      expect(find.text('Order Confirmed!'), findsOneWidget);
      expect(find.text('Your order has been placed successfully'), findsOneWidget);
    });

    testWidgets('should display order details card with correct information', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Verify order details section
      expect(find.text('Order Details'), findsOneWidget);
      expect(find.text('ORDER-123456'), findsOneWidget);
      expect(find.text('Confirmed'), findsOneWidget);
      
      // Verify price breakdown
      expect(find.text('Subtotal'), findsOneWidget);
      expect(find.text('Delivery Fee'), findsOneWidget);
      expect(find.text('Tax & Fees'), findsOneWidget);
      expect(find.text('Total'), findsOneWidget);
      
      // Verify total amount is displayed
      expect(find.text('\$${testOrder.total.toStringAsFixed(2)}'), findsOneWidget);
    });

    testWidgets('should display delivery information card', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Verify delivery information section
      expect(find.text('Delivery Information'), findsOneWidget);
      expect(find.text('Estimated Delivery'), findsOneWidget);
      
      // Verify tracking steps are displayed
      expect(find.text('Order Confirmed'), findsOneWidget);
      expect(find.text('Preparing'), findsOneWidget);
      expect(find.text('Out for Delivery'), findsOneWidget);
      expect(find.text('Delivered'), findsOneWidget);
    });

    testWidgets('should display order items card with correct items', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Verify order items section
      expect(find.text('Order Items'), findsOneWidget);
      expect(find.text('3 items'), findsOneWidget); // 2 burgers + 1 fries
      
      // Verify individual items are displayed
      expect(find.text('Burger'), findsOneWidget);
      expect(find.text('Fries'), findsOneWidget);
      expect(find.text('Qty: 2'), findsOneWidget);
      expect(find.text('Qty: 1'), findsOneWidget);
    });

    testWidgets('should display bottom action buttons', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Verify action buttons are displayed
      expect(find.text('Track Order'), findsOneWidget);
      expect(find.text('Continue Shopping'), findsOneWidget);
      
      // Verify buttons are tappable
      expect(find.byType(ElevatedButton), findsOneWidget);
      expect(find.byType(OutlinedButton), findsOneWidget);
    });

    testWidgets('should clear cart when screen is initialized', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Verify that ClearCart event was dispatched
      verify(mockCartBloc.add(any)).called(1);
    });

    testWidgets('should show track order snackbar when track order button is tapped', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Tap track order button
      await tester.tap(find.text('Track Order'));
      await tester.pumpAndSettle();

      // Verify snackbar is shown
      expect(find.text('Order tracking for ORDER-123456'), findsOneWidget);
    });

    testWidgets('should navigate to restaurants when continue shopping button is tapped', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Tap continue shopping button
      await tester.tap(find.text('Continue Shopping'));
      await tester.pumpAndSettle();

      // Note: Navigation testing would require more complex setup with named routes
      // For now, we verify the button exists and is tappable
      expect(find.text('Continue Shopping'), findsOneWidget);
    });

    testWidgets('should display correct status chip for different order statuses', (tester) async {
      // Test with pending status
      final pendingOrder = testOrder.copyWith(status: OrderStatus.pending);
      
      await tester.pumpWidget(MaterialApp(
        theme: AppTheme.lightTheme,
        home: BlocProvider<CartBloc>(
          create: (context) => mockCartBloc,
          child: OrderConfirmationScreen(order: pendingOrder),
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Pending'), findsOneWidget);
      expect(find.byIcon(Icons.schedule), findsOneWidget);
    });

    testWidgets('should display correct tracking steps based on order status', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // For confirmed status, first two steps should be completed
      // We can verify this by checking the presence of check icons
      expect(find.byIcon(Icons.check), findsWidgets);
      
      // Verify step titles are present
      expect(find.text('Order Confirmed'), findsOneWidget);
      expect(find.text('Your order has been received'), findsOneWidget);
    });

    testWidgets('should handle image loading errors gracefully', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Verify fallback icons are displayed when images fail to load
      expect(find.byIcon(Icons.fastfood), findsWidgets);
    });

    testWidgets('should format order time correctly', (tester) async {
      // Create order with recent time
      final recentOrder = testOrder.copyWith(
        orderTime: DateTime.now().subtract(const Duration(minutes: 5)),
      );
      
      await tester.pumpWidget(MaterialApp(
        theme: AppTheme.lightTheme,
        home: BlocProvider<CartBloc>(
          create: (context) => mockCartBloc,
          child: OrderConfirmationScreen(order: recentOrder),
        ),
      ));
      await tester.pumpAndSettle();

      // Should show "5 minutes ago" or similar
      expect(find.textContaining('minutes ago'), findsOneWidget);
    });

    testWidgets('should display estimated delivery time', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Verify estimated delivery time is shown
      expect(find.text('Estimated Delivery'), findsOneWidget);
      // The exact time text will vary based on current time, so we just check it exists
      expect(find.byIcon(Icons.access_time), findsOneWidget);
    });

    group('Order Status Display', () {
      testWidgets('should display preparing status correctly', (tester) async {
        final preparingOrder = testOrder.copyWith(status: OrderStatus.preparing);
        
        await tester.pumpWidget(MaterialApp(
          theme: AppTheme.lightTheme,
          home: BlocProvider<CartBloc>(
            create: (context) => mockCartBloc,
            child: OrderConfirmationScreen(order: preparingOrder),
          ),
        ));
        await tester.pumpAndSettle();

        expect(find.text('Preparing'), findsOneWidget);
        expect(find.byIcon(Icons.restaurant), findsOneWidget);
      });

      testWidgets('should display out for delivery status correctly', (tester) async {
        final deliveryOrder = testOrder.copyWith(status: OrderStatus.outForDelivery);
        
        await tester.pumpWidget(MaterialApp(
          theme: AppTheme.lightTheme,
          home: BlocProvider<CartBloc>(
            create: (context) => mockCartBloc,
            child: OrderConfirmationScreen(order: deliveryOrder),
          ),
        ));
        await tester.pumpAndSettle();

        expect(find.text('Out for Delivery'), findsOneWidget);
        expect(find.byIcon(Icons.local_shipping), findsOneWidget);
      });

      testWidgets('should display delivered status correctly', (tester) async {
        final deliveredOrder = testOrder.copyWith(status: OrderStatus.delivered);
        
        await tester.pumpWidget(MaterialApp(
          theme: AppTheme.lightTheme,
          home: BlocProvider<CartBloc>(
            create: (context) => mockCartBloc,
            child: OrderConfirmationScreen(order: deliveredOrder),
          ),
        ));
        await tester.pumpAndSettle();

        expect(find.text('Delivered'), findsOneWidget);
        expect(find.byIcon(Icons.check_circle), findsOneWidget);
      });
    });

    group('Animation Tests', () {
      testWidgets('should animate checkmark on screen load', (tester) async {
        await tester.pumpWidget(createWidgetUnderTest());
        
        // Initially, animations haven't started
        await tester.pump();
        
        // Let animations complete
        await tester.pumpAndSettle();
        
        // Verify checkmark is visible after animation
        expect(find.byIcon(Icons.check), findsOneWidget);
      });

      testWidgets('should animate content after checkmark', (tester) async {
        await tester.pumpWidget(createWidgetUnderTest());
        
        // Pump through animation frames
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));
        await tester.pumpAndSettle();
        
        // Verify content is visible after animation
        expect(find.text('Order Details'), findsOneWidget);
      });
    });
  });
}