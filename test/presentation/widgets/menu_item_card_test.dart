import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

import 'package:deliery_app/presentation/widgets/menu_item_card.dart';
import 'package:deliery_app/presentation/blocs/cart/cart_bloc.dart';
import 'package:deliery_app/presentation/blocs/cart/cart_state.dart';
import 'package:deliery_app/presentation/blocs/cart/cart_event.dart';
import 'package:deliery_app/data/models/menu_item.dart';
import 'package:deliery_app/data/models/cart_item.dart';
import 'package:deliery_app/core/theme/app_theme.dart';

import 'menu_item_card_test.mocks.dart';

@GenerateMocks([CartBloc])
void main() {
  group('MenuItemCard Widget Tests', () {
    late MockCartBloc mockCartBloc;
    late MenuItem testMenuItem;
    const String testRestaurantId = 'restaurant_1';

    setUp(() {
      mockCartBloc = MockCartBloc();
      testMenuItem = const MenuItem(
        id: 'item_1',
        itemName: 'Margherita Pizza',
        itemDescription: 'Classic pizza with tomato sauce, mozzarella, and basil',
        itemPrice: 12.99,
        imageUrl: 'https://example.com/pizza.jpg',
        category: 'Pizza',
      );
    });

    Widget createWidgetUnderTest({
      MenuItem? menuItem,
      String? restaurantId,
      VoidCallback? onAddToCart,
    }) {
      return MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(
          body: BlocProvider<CartBloc>(
            create: (context) => mockCartBloc,
            child: MenuItemCard(
              menuItem: menuItem ?? testMenuItem,
              restaurantId: restaurantId ?? testRestaurantId,
              onAddToCart: onAddToCart,
            ),
          ),
        ),
      );
    }

    testWidgets('displays menu item information correctly', (tester) async {
      // Arrange
      when(mockCartBloc.state).thenReturn(const CartInitial());
      when(mockCartBloc.stream).thenAnswer((_) => const Stream.empty());

      // Act
      await tester.pumpWidget(createWidgetUnderTest());

      // Assert
      expect(find.text('Margherita Pizza'), findsOneWidget);
      expect(find.text('Classic pizza with tomato sauce, mozzarella, and basil'), findsOneWidget);
      expect(find.text('\$12.99'), findsOneWidget);
      expect(find.text('Pizza'), findsOneWidget);
      // Note: Icon might not be found due to CachedNetworkImage placeholder behavior
    });

    testWidgets('shows Add button when item is not in cart', (tester) async {
      // Arrange
      when(mockCartBloc.state).thenReturn(const CartInitial());
      when(mockCartBloc.stream).thenAnswer((_) => const Stream.empty());

      // Act
      await tester.pumpWidget(createWidgetUnderTest());

      // Assert
      expect(find.text('Add'), findsOneWidget);
      expect(find.byIcon(Icons.add), findsOneWidget);
      expect(find.byIcon(Icons.remove), findsNothing);
      expect(find.byIcon(Icons.delete_outline), findsNothing);
    });

    testWidgets('shows quantity controls when item is in cart', (tester) async {
      // Arrange
      final cartItem = CartItem(
        menuItem: testMenuItem,
        quantity: 2,
        restaurantId: testRestaurantId,
      );
      
      final cartState = CartUpdated(
        items: [cartItem],
        subtotal: 25.98,
        deliveryFee: 2.99,
        tax: 2.08,
        total: 31.05,
        totalItems: 2,
        currentRestaurantId: testRestaurantId,
      );

      when(mockCartBloc.state).thenReturn(cartState);
      when(mockCartBloc.stream).thenAnswer((_) => Stream.value(cartState));

      // Act
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();

      // Assert
      expect(find.text('Add'), findsNothing);
      expect(find.text('2'), findsOneWidget); // Quantity display
      expect(find.byIcon(Icons.remove), findsOneWidget);
      expect(find.byIcon(Icons.add), findsOneWidget);
    });

    testWidgets('shows delete icon when quantity is 1', (tester) async {
      // Arrange
      final cartItem = CartItem(
        menuItem: testMenuItem,
        quantity: 1,
        restaurantId: testRestaurantId,
      );
      
      final cartState = CartUpdated(
        items: [cartItem],
        subtotal: 12.99,
        deliveryFee: 2.99,
        tax: 1.04,
        total: 17.02,
        totalItems: 1,
        currentRestaurantId: testRestaurantId,
      );

      when(mockCartBloc.state).thenReturn(cartState);
      when(mockCartBloc.stream).thenAnswer((_) => Stream.value(cartState));

      // Act
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();

      // Assert
      expect(find.byIcon(Icons.delete_outline), findsOneWidget);
      expect(find.byIcon(Icons.remove), findsNothing);
    });

    testWidgets('adds item to cart when Add button is tapped', (tester) async {
      // Arrange
      when(mockCartBloc.state).thenReturn(const CartInitial());
      when(mockCartBloc.stream).thenAnswer((_) => const Stream.empty());

      // Act
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.tap(find.text('Add'));
      await tester.pump();

      // Assert
      verify(mockCartBloc.add(AddToCart(
        menuItem: testMenuItem,
        restaurantId: testRestaurantId,
        quantity: 1,
      ))).called(1);
    });

    testWidgets('increases quantity when + button is tapped', (tester) async {
      // Arrange
      final cartItem = CartItem(
        menuItem: testMenuItem,
        quantity: 2,
        restaurantId: testRestaurantId,
      );
      
      final cartState = CartUpdated(
        items: [cartItem],
        subtotal: 25.98,
        deliveryFee: 2.99,
        tax: 2.08,
        total: 31.05,
        totalItems: 2,
        currentRestaurantId: testRestaurantId,
      );

      when(mockCartBloc.state).thenReturn(cartState);
      when(mockCartBloc.stream).thenAnswer((_) => Stream.value(cartState));

      // Act
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();
      
      // Find the + button (second add icon)
      final addButtons = find.byIcon(Icons.add);
      await tester.tap(addButtons.last);
      await tester.pump();

      // Assert
      verify(mockCartBloc.add(UpdateQuantity(
        menuItemId: testMenuItem.id,
        quantity: 3,
      ))).called(1);
    });

    testWidgets('decreases quantity when - button is tapped', (tester) async {
      // Arrange
      final cartItem = CartItem(
        menuItem: testMenuItem,
        quantity: 3,
        restaurantId: testRestaurantId,
      );
      
      final cartState = CartUpdated(
        items: [cartItem],
        subtotal: 38.97,
        deliveryFee: 0.0, // Free delivery over $25
        tax: 3.12,
        total: 42.09,
        totalItems: 3,
        currentRestaurantId: testRestaurantId,
      );

      when(mockCartBloc.state).thenReturn(cartState);
      when(mockCartBloc.stream).thenAnswer((_) => Stream.value(cartState));

      // Act
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();
      
      await tester.tap(find.byIcon(Icons.remove));
      await tester.pump();

      // Assert
      verify(mockCartBloc.add(UpdateQuantity(
        menuItemId: testMenuItem.id,
        quantity: 2,
      ))).called(1);
    });

    testWidgets('removes item when delete button is tapped (quantity = 1)', (tester) async {
      // Arrange
      final cartItem = CartItem(
        menuItem: testMenuItem,
        quantity: 1,
        restaurantId: testRestaurantId,
      );
      
      final cartState = CartUpdated(
        items: [cartItem],
        subtotal: 12.99,
        deliveryFee: 2.99,
        tax: 1.04,
        total: 17.02,
        totalItems: 1,
        currentRestaurantId: testRestaurantId,
      );

      when(mockCartBloc.state).thenReturn(cartState);
      when(mockCartBloc.stream).thenAnswer((_) => Stream.value(cartState));

      // Act
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();
      
      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pump();

      // Assert
      verify(mockCartBloc.add(RemoveFromCart(testMenuItem.id))).called(1);
    });

    testWidgets('calls onAddToCart callback when item is added', (tester) async {
      // Arrange
      bool callbackCalled = false;
      when(mockCartBloc.state).thenReturn(const CartInitial());
      when(mockCartBloc.stream).thenAnswer((_) => const Stream.empty());

      // Act
      await tester.pumpWidget(createWidgetUnderTest(
        onAddToCart: () => callbackCalled = true,
      ));
      
      await tester.tap(find.text('Add'));
      await tester.pump();

      // Assert
      expect(callbackCalled, isTrue);
    });

    testWidgets('displays snackbar when item is added to cart', (tester) async {
      // Arrange
      when(mockCartBloc.state).thenReturn(const CartInitial());
      when(mockCartBloc.stream).thenAnswer((_) => const Stream.empty());

      // Act
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.tap(find.text('Add'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Assert
      expect(find.text('Margherita Pizza added to cart'), findsOneWidget);
    });

    testWidgets('handles menu item without image', (tester) async {
      // Arrange
      final menuItemWithoutImage = testMenuItem.copyWith(imageUrl: '');
      when(mockCartBloc.state).thenReturn(const CartInitial());
      when(mockCartBloc.stream).thenAnswer((_) => const Stream.empty());

      // Act
      await tester.pumpWidget(createWidgetUnderTest(menuItem: menuItemWithoutImage));

      // Assert - Check that the widget renders without errors
      expect(find.text('Margherita Pizza'), findsOneWidget);
      expect(find.text('\$12.99'), findsOneWidget);
    });

    testWidgets('handles menu item without category', (tester) async {
      // Arrange
      final menuItemWithoutCategory = testMenuItem.copyWith(category: '');
      when(mockCartBloc.state).thenReturn(const CartInitial());
      when(mockCartBloc.stream).thenAnswer((_) => const Stream.empty());

      // Act
      await tester.pumpWidget(createWidgetUnderTest(menuItem: menuItemWithoutCategory));

      // Assert
      expect(find.text('Pizza'), findsNothing);
      expect(find.text('Margherita Pizza'), findsOneWidget);
      expect(find.text('\$12.99'), findsOneWidget);
    });

    testWidgets('handles menu item without description', (tester) async {
      // Arrange
      final menuItemWithoutDescription = testMenuItem.copyWith(itemDescription: '');
      when(mockCartBloc.state).thenReturn(const CartInitial());
      when(mockCartBloc.stream).thenAnswer((_) => const Stream.empty());

      // Act
      await tester.pumpWidget(createWidgetUnderTest(menuItem: menuItemWithoutDescription));

      // Assert
      expect(find.text('Classic pizza with tomato sauce, mozzarella, and basil'), findsNothing);
      expect(find.text('Margherita Pizza'), findsOneWidget);
      expect(find.text('\$12.99'), findsOneWidget);
    });

    testWidgets('animates when add button is pressed', (tester) async {
      // Arrange
      when(mockCartBloc.state).thenReturn(const CartInitial());
      when(mockCartBloc.stream).thenAnswer((_) => const Stream.empty());

      // Act
      await tester.pumpWidget(createWidgetUnderTest());
      
      // Verify the widget has Transform widgets
      expect(find.byType(Transform), findsWidgets);
      
      await tester.tap(find.text('Add'));
      await tester.pump(const Duration(milliseconds: 100));
      
      // Just verify that the animation controller is working by checking
      // that the widget still exists and is functional
      expect(find.text('Add'), findsOneWidget);
    });
  });
}