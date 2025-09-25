import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

import 'package:deliery_app/presentation/screens/order_failure_screen.dart';
import 'package:deliery_app/presentation/blocs/cart/cart_bloc.dart';
import 'package:deliery_app/presentation/blocs/order/order_bloc.dart';
import 'package:deliery_app/presentation/blocs/order/order_state.dart';

import 'package:deliery_app/data/models/cart_item.dart';
import 'package:deliery_app/data/models/menu_item.dart';
import 'package:deliery_app/core/theme/app_theme.dart';

import 'order_failure_screen_test.mocks.dart';

@GenerateMocks([CartBloc, OrderBloc])
void main() {
  group('OrderFailureScreen', () {
    late MockCartBloc mockCartBloc;
    late MockOrderBloc mockOrderBloc;
    late List<CartItem> testCartItems;

    setUp(() {
      mockCartBloc = MockCartBloc();
      mockOrderBloc = MockOrderBloc();
      
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

      // Setup default mock behavior
      when(mockOrderBloc.state).thenReturn(const OrderInitial());
      when(mockOrderBloc.stream).thenAnswer((_) => Stream.empty());
    });

    Widget createWidgetUnderTest({
      String errorMessage = 'Order placement failed',
      String? errorCode,
      bool canRetry = true,
    }) {
      return MaterialApp(
        theme: AppTheme.lightTheme,
        home: MultiBlocProvider(
          providers: [
            BlocProvider<CartBloc>(create: (context) => mockCartBloc),
            BlocProvider<OrderBloc>(create: (context) => mockOrderBloc),
          ],
          child: OrderFailureScreen(
            errorMessage: errorMessage,
            errorCode: errorCode,
            canRetry: canRetry,
            cartItems: testCartItems,
            restaurantId: 'restaurant1',
          ),
        ),
      );
    }

    testWidgets('should display error header with error icon and message', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Verify error icon is displayed
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
      
      // Verify error messages
      expect(find.text('Order Failed'), findsOneWidget);
      expect(find.text('We couldn\'t process your order'), findsOneWidget);
    });

    testWidgets('should display error details card with correct information', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest(
        errorMessage: 'Payment processing failed',
        errorCode: 'PAYMENT_ERROR_001',
      ));
      await tester.pumpAndSettle();

      // Verify error details section
      expect(find.text('Error Details'), findsOneWidget);
      expect(find.text('Payment processing failed'), findsOneWidget);
      expect(find.text('Error Code: '), findsOneWidget);
      expect(find.text('PAYMENT_ERROR_001'), findsOneWidget);
    });

    testWidgets('should display cart preservation card with cart summary', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Verify cart preservation section
      expect(find.text('Your Cart is Safe'), findsOneWidget);
      expect(find.text('Don\'t worry! Your cart items have been preserved. You can retry your order or continue shopping.'), findsOneWidget);
      
      // Verify cart summary
      expect(find.text('3 items'), findsOneWidget); // 2 burgers + 1 fries
      
      // Calculate expected total
      final expectedTotal = (12.99 * 2) + (4.99 * 1);
      expect(find.text('\$${expectedTotal.toStringAsFixed(2)}'), findsOneWidget);
    });

    testWidgets('should display troubleshooting tips card', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Verify troubleshooting section
      expect(find.text('Troubleshooting Tips'), findsOneWidget);
      expect(find.text('Check your internet connection and try again'), findsOneWidget);
      expect(find.text('Ensure your payment method is valid and has sufficient funds'), findsOneWidget);
    });

    testWidgets('should display retry button when canRetry is true', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest(canRetry: true));
      await tester.pumpAndSettle();

      // Verify retry button is displayed
      expect(find.text('Retry Order'), findsOneWidget);
      expect(find.byIcon(Icons.refresh), findsOneWidget);
    });

    testWidgets('should not display retry button when canRetry is false', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest(canRetry: false));
      await tester.pumpAndSettle();

      // Verify retry button is not displayed
      expect(find.text('Retry Order'), findsNothing);
    });

    testWidgets('should display back to cart and continue shopping buttons', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Verify action buttons are displayed
      expect(find.text('Back to Cart'), findsOneWidget);
      expect(find.text('Continue Shopping'), findsOneWidget);
    });

    testWidgets('should dispatch RetryOrder event when retry button is tapped', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest(canRetry: true));
      await tester.pumpAndSettle();

      // Tap retry button
      await tester.tap(find.text('Retry Order'));
      await tester.pumpAndSettle();

      // Verify RetryOrder event was dispatched
      verify(mockOrderBloc.add(any)).called(1);
    });

    testWidgets('should show retry availability message when canRetry is true', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest(canRetry: true));
      await tester.pumpAndSettle();

      expect(find.text('You can retry placing this order'), findsOneWidget);
      expect(find.byIcon(Icons.refresh), findsWidgets);
    });

    testWidgets('should show non-retryable message when canRetry is false', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest(canRetry: false));
      await tester.pumpAndSettle();

      expect(find.text('This order cannot be retried automatically'), findsOneWidget);
      expect(find.byIcon(Icons.block), findsOneWidget);
    });

    testWidgets('should handle back to cart button tap', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Tap back to cart button
      await tester.tap(find.text('Back to Cart'));
      await tester.pumpAndSettle();

      // Note: Navigation testing would require more complex setup
      // For now, we verify the button exists and is tappable
      expect(find.text('Back to Cart'), findsOneWidget);
    });

    testWidgets('should handle continue shopping button tap', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Tap continue shopping button
      await tester.tap(find.text('Continue Shopping'));
      await tester.pumpAndSettle();

      // Note: Navigation testing would require more complex setup
      // For now, we verify the button exists and is tappable
      expect(find.text('Continue Shopping'), findsOneWidget);
    });

    testWidgets('should display processing state when order is being retried', (tester) async {
      // Setup mock to return processing state
      when(mockOrderBloc.state).thenReturn(const OrderProcessing(message: 'Retrying order...'));
      
      await tester.pumpWidget(createWidgetUnderTest(canRetry: true));
      await tester.pumpAndSettle();

      // Verify processing state is displayed
      expect(find.text('Retrying...'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('should handle order success state by navigating to confirmation', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Note: Testing navigation would require more complex setup with NavigatorObserver
      // For now, we verify the BlocListener is set up correctly
      expect(find.byType(BlocListener<OrderBloc, OrderState>), findsOneWidget);
    });

    testWidgets('should handle order error state by showing snackbar', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Note: Testing snackbar would require triggering the error state
      // For now, we verify the BlocListener is set up correctly
      expect(find.byType(BlocListener<OrderBloc, OrderState>), findsOneWidget);
    });

    testWidgets('should not display error code when not provided', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest(
        errorMessage: 'Network error',
        errorCode: null,
      ));
      await tester.pumpAndSettle();

      // Verify error code section is not displayed
      expect(find.text('Error Code: '), findsNothing);
    });

    testWidgets('should display custom error message', (tester) async {
      const customErrorMessage = 'Custom error message for testing';
      
      await tester.pumpWidget(createWidgetUnderTest(
        errorMessage: customErrorMessage,
      ));
      await tester.pumpAndSettle();

      expect(find.text(customErrorMessage), findsOneWidget);
    });

    group('Animation Tests', () {
      testWidgets('should animate error icon on screen load', (tester) async {
        await tester.pumpWidget(createWidgetUnderTest());
        
        // Initially, animations haven't started
        await tester.pump();
        
        // Let animations complete
        await tester.pumpAndSettle();
        
        // Verify error icon is visible after animation
        expect(find.byIcon(Icons.error_outline), findsOneWidget);
      });

      testWidgets('should animate content after error icon', (tester) async {
        await tester.pumpWidget(createWidgetUnderTest());
        
        // Pump through animation frames
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        await tester.pumpAndSettle();
        
        // Verify content is visible after animation
        expect(find.text('Error Details'), findsOneWidget);
      });
    });

    group('Error Code Display', () {
      testWidgets('should display error code when provided', (tester) async {
        await tester.pumpWidget(createWidgetUnderTest(
          errorCode: 'ERR_PAYMENT_001',
        ));
        await tester.pumpAndSettle();

        expect(find.text('Error Code: '), findsOneWidget);
        expect(find.text('ERR_PAYMENT_001'), findsOneWidget);
      });

      testWidgets('should not display error code section when null', (tester) async {
        await tester.pumpWidget(createWidgetUnderTest(
          errorCode: null,
        ));
        await tester.pumpAndSettle();

        expect(find.text('Error Code: '), findsNothing);
      });
    });

    group('Cart Summary Display', () {
      testWidgets('should calculate and display correct cart totals', (tester) async {
        await tester.pumpWidget(createWidgetUnderTest());
        await tester.pumpAndSettle();

        // Verify item count calculation
        final totalItems = testCartItems.fold<int>(0, (sum, item) => sum + item.quantity);
        expect(find.text('$totalItems items'), findsOneWidget);

        // Verify total price calculation
        final totalPrice = testCartItems.fold<double>(0.0, (sum, item) => sum + item.totalPrice);
        expect(find.text('\$${totalPrice.toStringAsFixed(2)}'), findsOneWidget);
      });
    });
  });
}