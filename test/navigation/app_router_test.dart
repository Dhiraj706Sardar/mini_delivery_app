import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:deliery_app/core/navigation/app_router.dart';
import 'package:deliery_app/core/navigation/navigation_service.dart';
import 'package:deliery_app/presentation/blocs/cart/cart_bloc.dart';
import 'package:deliery_app/presentation/screens/restaurant_list_screen.dart';
import 'package:deliery_app/presentation/screens/menu_screen.dart';
import 'package:deliery_app/presentation/screens/cart_screen.dart';
import 'package:deliery_app/presentation/screens/checkout_screen.dart';
import 'package:deliery_app/presentation/screens/order_confirmation_screen.dart';
import 'package:deliery_app/presentation/screens/order_failure_screen.dart';
import 'package:deliery_app/data/models/restaurant.dart';
import 'package:deliery_app/data/models/order.dart';
import 'package:deliery_app/data/models/cart_item.dart';
import 'package:deliery_app/data/models/menu_item.dart';
import 'package:deliery_app/data/datasources/mock_cart_persistence_datasource.dart';

void main() {
  group('AppRouter Tests', () {
    late MockCartPersistenceDataSource mockCartDataSource;
    late Restaurant testRestaurant;
    late Order testOrder;
    late List<CartItem> testCartItems;

    setUp(() {
      mockCartDataSource = MockCartPersistenceDataSource();
      
      testRestaurant = const Restaurant(
        id: '1',
        name: 'Test Restaurant',
        rating: 4.5,
        address: '123 Test Street',
        cuisineType: 'Italian',
        imageUrl: 'https://example.com/image.jpg',
        description: 'A test restaurant',
      );

      testOrder = Order(
        id: 'order_1',
        restaurantId: '1',
        items: const [],
        subtotal: 20.00,
        deliveryFee: 2.99,
        tax: 1.60,
        total: 24.59,
        orderTime: DateTime.now(),
        status: OrderStatus.confirmed,
      );

      testCartItems = [
        CartItem(
          menuItem: const MenuItem(
            id: '1',
            itemName: 'Pizza',
            itemDescription: 'Delicious pizza',
            itemPrice: 12.99,
            imageUrl: 'pizza.jpg',
            category: 'Main',
          ),
          quantity: 2,
          restaurantId: '1',
        ),
      ];
    });

    Widget createTestApp({String? initialRoute}) {
      return BlocProvider<CartBloc>(
        create: (context) => CartBloc(persistenceDataSource: mockCartDataSource),
        child: MaterialApp(
          navigatorKey: NavigationService.navigatorKey,
          initialRoute: initialRoute ?? AppRoutes.restaurants,
          onGenerateRoute: AppRouter.generateRoute,
        ),
      );
    }

    group('Route Constants', () {
      test('should have correct route paths', () {
        expect(AppRoutes.restaurants, equals('/restaurants'));
        expect(AppRoutes.menu, equals('/menu'));
        expect(AppRoutes.cart, equals('/cart'));
        expect(AppRoutes.checkout, equals('/checkout'));
        expect(AppRoutes.orderConfirmation, equals('/order-confirmation'));
        expect(AppRoutes.orderFailure, equals('/order-failure'));
        expect(AppRoutes.initial, equals(AppRoutes.restaurants));
      });
    });

    group('Route Arguments', () {
      test('MenuScreenArguments should work correctly', () {
        final args = MenuScreenArguments(restaurant: testRestaurant);
        expect(args.restaurant, equals(testRestaurant));
        expect(args.restaurant.name, equals('Test Restaurant'));
      });

      test('OrderConfirmationArguments should work correctly', () {
        final args = OrderConfirmationArguments(order: testOrder);
        expect(args.order, equals(testOrder));
        expect(args.order.id, equals('order_1'));
      });

      test('OrderFailureArguments should work correctly', () {
        final args = OrderFailureArguments(
          errorMessage: 'Payment failed',
          errorCode: 'PAYMENT_ERROR',
          canRetry: true,
          cartItems: testCartItems,
          restaurantId: '1',
        );
        
        expect(args.errorMessage, equals('Payment failed'));
        expect(args.errorCode, equals('PAYMENT_ERROR'));
        expect(args.canRetry, isTrue);
        expect(args.cartItems, equals(testCartItems));
        expect(args.restaurantId, equals('1'));
      });
    });

    group('Route Generation', () {
      testWidgets('should generate restaurant list route', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        expect(find.byType(RestaurantListScreen), findsOneWidget);
        expect(find.text('Restaurants'), findsOneWidget);
      });

      testWidgets('should generate menu route with valid arguments', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        NavigationService.navigator?.pushNamed(
          AppRoutes.menu,
          arguments: MenuScreenArguments(restaurant: testRestaurant),
        );
        await tester.pumpAndSettle();

        expect(find.byType(MenuScreen), findsOneWidget);
        expect(find.text('Test Restaurant'), findsOneWidget);
      });

      testWidgets('should generate cart route', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        NavigationService.navigator?.pushNamed(AppRoutes.cart);
        await tester.pumpAndSettle();

        expect(find.byType(CartScreen), findsOneWidget);
        expect(find.text('Your Cart'), findsOneWidget);
      });

      testWidgets('should generate checkout route', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        NavigationService.navigator?.pushNamed(AppRoutes.checkout);
        await tester.pumpAndSettle();

        expect(find.byType(CheckoutScreen), findsOneWidget);
        expect(find.text('Checkout'), findsOneWidget);
      });

      testWidgets('should generate order confirmation route with valid arguments', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        NavigationService.navigator?.pushNamed(
          AppRoutes.orderConfirmation,
          arguments: OrderConfirmationArguments(order: testOrder),
        );
        await tester.pumpAndSettle();

        expect(find.byType(OrderConfirmationScreen), findsOneWidget);
        expect(find.text('Order Confirmed!'), findsOneWidget);
      });

      testWidgets('should generate order failure route with valid arguments', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        NavigationService.navigator?.pushNamed(
          AppRoutes.orderFailure,
          arguments: OrderFailureArguments(
            errorMessage: 'Payment failed',
            canRetry: true,
            cartItems: testCartItems,
            restaurantId: '1',
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(OrderFailureScreen), findsOneWidget);
        expect(find.text('Order Failed'), findsOneWidget);
      });
    });

    group('Error Handling', () {
      testWidgets('should show error route for unknown paths', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        NavigationService.navigator?.pushNamed('/unknown-route');
        await tester.pumpAndSettle();

        expect(find.text('Route not found: /unknown-route'), findsOneWidget);
        expect(find.text('Go to Home'), findsOneWidget);
        expect(find.byIcon(Icons.error_outline), findsOneWidget);
      });

      testWidgets('should show error route for menu without arguments', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        NavigationService.navigator?.pushNamed(AppRoutes.menu);
        await tester.pumpAndSettle();

        expect(find.text('Route not found'), findsOneWidget);
        expect(find.text('Go to Home'), findsOneWidget);
      });

      testWidgets('should show error route for order confirmation without arguments', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        NavigationService.navigator?.pushNamed(AppRoutes.orderConfirmation);
        await tester.pumpAndSettle();

        expect(find.text('Route not found'), findsOneWidget);
      });

      testWidgets('should show error route for order failure without arguments', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        NavigationService.navigator?.pushNamed(AppRoutes.orderFailure);
        await tester.pumpAndSettle();

        expect(find.text('Route not found'), findsOneWidget);
      });

      testWidgets('error route home button should navigate back', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        NavigationService.navigator?.pushNamed('/unknown-route');
        await tester.pumpAndSettle();

        await tester.tap(find.text('Go to Home'));
        await tester.pumpAndSettle();

        expect(find.text('Restaurants'), findsOneWidget);
        expect(find.byType(RestaurantListScreen), findsOneWidget);
      });
    });

    group('Route Settings', () {
      testWidgets('should preserve route settings', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        const customSettings = RouteSettings(
          name: AppRoutes.cart,
          arguments: {'custom': 'data'},
        );

        final route = AppRouter.generateRoute(customSettings);
        expect(route.settings, equals(customSettings));
      });

      testWidgets('should handle null route settings', (tester) async {
        const settings = RouteSettings(name: null);
        final route = AppRouter.generateRoute(settings);
        
        expect(route, isA<MaterialPageRoute>());
        expect(route.settings, equals(settings));
      });
    });

    group('Navigation Flow', () {
      testWidgets('should support complete navigation flow', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        // Start at restaurants
        expect(find.text('Restaurants'), findsOneWidget);

        // Navigate to menu
        NavigationService.navigator?.pushNamed(
          AppRoutes.menu,
          arguments: MenuScreenArguments(restaurant: testRestaurant),
        );
        await tester.pumpAndSettle();
        expect(find.text('Test Restaurant'), findsOneWidget);

        // Navigate to cart
        NavigationService.navigator?.pushNamed(AppRoutes.cart);
        await tester.pumpAndSettle();
        expect(find.text('Your Cart'), findsOneWidget);

        // Navigate to checkout
        NavigationService.navigator?.pushNamed(AppRoutes.checkout);
        await tester.pumpAndSettle();
        expect(find.text('Checkout'), findsOneWidget);

        // Go back to cart
        NavigationService.goBack();
        await tester.pumpAndSettle();
        expect(find.text('Your Cart'), findsOneWidget);
      });
    });
  });
}