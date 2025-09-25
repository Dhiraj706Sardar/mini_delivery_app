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
import 'package:deliery_app/data/models/restaurant.dart';
import 'package:deliery_app/data/models/order.dart';
import 'package:deliery_app/data/models/cart_item.dart';
import 'package:deliery_app/data/models/menu_item.dart';
import 'package:deliery_app/data/datasources/mock_cart_persistence_datasource.dart';

void main() {
  group('NavigationService Tests', () {
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

    Widget createTestApp() {
      return BlocProvider<CartBloc>(
        create: (context) => CartBloc(persistenceDataSource: mockCartDataSource),
        child: MaterialApp(
          navigatorKey: NavigationService.navigatorKey,
          initialRoute: AppRoutes.restaurants,
          onGenerateRoute: AppRouter.generateRoute,
        ),
      );
    }

    group('Service Properties', () {
      testWidgets('should have valid navigator key', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        expect(NavigationService.navigatorKey, isNotNull);
        expect(NavigationService.navigatorKey, isA<GlobalKey<NavigatorState>>());
      });

      testWidgets('should have valid navigator state', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        expect(NavigationService.navigator, isNotNull);
        expect(NavigationService.navigator, isA<NavigatorState>());
      });

      testWidgets('should have valid context', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        expect(NavigationService.context, isNotNull);
        expect(NavigationService.context, isA<BuildContext>());
      });
    });

    group('Navigation Methods', () {
      testWidgets('goToRestaurants should navigate to restaurant list', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        // Navigate away first
        await NavigationService.goToCart();
        await tester.pumpAndSettle();
        expect(find.byType(CartScreen), findsOneWidget);

        // Navigate back to restaurants
        await NavigationService.goToRestaurants();
        await tester.pumpAndSettle();

        expect(find.byType(RestaurantListScreen), findsOneWidget);
        expect(find.text('Restaurants'), findsOneWidget);
      });

      testWidgets('goToRestaurants with clearStack should clear navigation stack', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        // Navigate to multiple screens
        await NavigationService.goToCart();
        await tester.pumpAndSettle();
        await NavigationService.goToCheckout();
        await tester.pumpAndSettle();

        // Clear stack and go to restaurants
        await NavigationService.goToRestaurants(clearStack: true);
        await tester.pumpAndSettle();

        expect(find.byType(RestaurantListScreen), findsOneWidget);
        expect(NavigationService.canGoBack(), isFalse);
      });

      testWidgets('goToMenu should navigate to menu screen', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        await NavigationService.goToMenu(testRestaurant);
        await tester.pumpAndSettle();

        expect(find.byType(MenuScreen), findsOneWidget);
        expect(find.text('Test Restaurant'), findsOneWidget);
      });

      testWidgets('goToCart should navigate to cart screen', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        await NavigationService.goToCart();
        await tester.pumpAndSettle();

        expect(find.byType(CartScreen), findsOneWidget);
        expect(find.text('Your Cart'), findsOneWidget);
      });

      testWidgets('goToCheckout should navigate to checkout screen', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        await NavigationService.goToCheckout();
        await tester.pumpAndSettle();

        expect(find.byType(CheckoutScreen), findsOneWidget);
        expect(find.text('Checkout'), findsOneWidget);
      });

      testWidgets('goToOrderConfirmation should navigate to order confirmation', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        await NavigationService.goToOrderConfirmation(testOrder);
        await tester.pumpAndSettle();

        expect(find.text('Order Confirmed!'), findsOneWidget);
      });

      testWidgets('goToOrderFailure should navigate to order failure screen', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        await NavigationService.goToOrderFailure(
          errorMessage: 'Payment failed',
          errorCode: 'PAYMENT_ERROR',
          canRetry: true,
          cartItems: testCartItems,
          restaurantId: '1',
        );
        await tester.pumpAndSettle();

        expect(find.text('Order Failed'), findsOneWidget);
        expect(find.text('Payment failed'), findsOneWidget);
      });
    });

    group('Navigation Control', () {
      testWidgets('goBack should navigate to previous screen', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        // Navigate to cart
        await NavigationService.goToCart();
        await tester.pumpAndSettle();
        expect(find.byType(CartScreen), findsOneWidget);

        // Go back
        NavigationService.goBack();
        await tester.pumpAndSettle();

        expect(find.byType(RestaurantListScreen), findsOneWidget);
      });

      testWidgets('goBack with result should pass result', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        // Navigate to cart
        final future = NavigationService.navigator?.pushNamed(AppRoutes.cart);
        await tester.pumpAndSettle();

        // Go back with result
        NavigationService.goBack('test_result');
        await tester.pumpAndSettle();

        final result = await future;
        expect(result, equals('test_result'));
      });

      testWidgets('canGoBack should return correct boolean', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        // Initially should not be able to go back (on initial route)
        expect(NavigationService.canGoBack(), isFalse);

        // Navigate to cart
        await NavigationService.goToCart();
        await tester.pumpAndSettle();

        // Now should be able to go back
        expect(NavigationService.canGoBack(), isTrue);

        // Go back
        NavigationService.goBack();
        await tester.pumpAndSettle();

        // Should not be able to go back again
        expect(NavigationService.canGoBack(), isFalse);
      });
    });

    group('Multiple Navigation Calls', () {
      testWidgets('should handle rapid navigation calls', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        // Rapid navigation calls
        await NavigationService.goToCart();
        await NavigationService.goToRestaurants();
        await NavigationService.goToCart();
        await tester.pumpAndSettle();

        expect(find.byType(CartScreen), findsOneWidget);
      });

      testWidgets('should handle navigation with different arguments', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        final restaurant1 = testRestaurant;
        final restaurant2 = const Restaurant(
          id: '2',
          name: 'Another Restaurant',
          rating: 4.0,
          address: '456 Another Street',
          cuisineType: 'Chinese',
          imageUrl: 'https://example.com/image2.jpg',
          description: 'Another test restaurant',
        );

        // Navigate to first restaurant menu
        await NavigationService.goToMenu(restaurant1);
        await tester.pumpAndSettle();
        expect(find.text('Test Restaurant'), findsOneWidget);

        // Navigate to second restaurant menu
        await NavigationService.goToMenu(restaurant2);
        await tester.pumpAndSettle();
        expect(find.text('Another Restaurant'), findsOneWidget);
      });
    });

    group('Error Scenarios', () {
      testWidgets('should handle navigation when navigator is null', (tester) async {
        // Don't pump widget, so navigator will be null
        expect(NavigationService.navigator, isNull);
        expect(NavigationService.context, isNull);
        expect(NavigationService.canGoBack(), isFalse);

        // These should not throw errors
        await NavigationService.goToRestaurants();
        await NavigationService.goToCart();
        NavigationService.goBack();
      });

      testWidgets('should handle navigation after widget disposal', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        // Verify navigation works
        expect(NavigationService.navigator, isNotNull);

        // Remove widget
        await tester.pumpWidget(const SizedBox());
        await tester.pumpAndSettle();

        // Navigation should handle gracefully
        await NavigationService.goToCart();
        NavigationService.goBack();
      });
    });

    group('Integration with App Router', () {
      testWidgets('should work seamlessly with AppRouter', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        // Use NavigationService methods
        await NavigationService.goToMenu(testRestaurant);
        await tester.pumpAndSettle();
        expect(find.byType(MenuScreen), findsOneWidget);

        // Use Navigator directly
        NavigationService.navigator?.pushNamed(AppRoutes.cart);
        await tester.pumpAndSettle();
        expect(find.byType(CartScreen), findsOneWidget);

        // Mix both approaches
        NavigationService.goBack();
        await tester.pumpAndSettle();
        expect(find.byType(MenuScreen), findsOneWidget);

        await NavigationService.goToRestaurants();
        await tester.pumpAndSettle();
        expect(find.byType(RestaurantListScreen), findsOneWidget);
      });
    });
  });
}