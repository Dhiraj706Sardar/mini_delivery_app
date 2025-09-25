import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

import 'package:deliery_app/presentation/widgets/cart_item_card.dart';
import 'package:deliery_app/presentation/blocs/cart/cart_bloc.dart';
import 'package:deliery_app/presentation/blocs/cart/cart_event.dart';
import 'package:deliery_app/presentation/blocs/cart/cart_state.dart';
import 'package:deliery_app/data/models/cart_item.dart';
import 'package:deliery_app/data/models/menu_item.dart';
import 'package:deliery_app/core/theme/app_theme.dart';

import 'cart_item_card_test.mocks.dart';

@GenerateMocks([CartBloc])
void main() {
  group('CartItemCard Widget Tests', () {
    late MockCartBloc mockCartBloc;
    late CartItem testCartItem;
    late MenuItem testMenuItem;

    setUp(() {
      mockCartBloc = MockCartBloc();
      
      testMenuItem = const MenuItem(
        id: 'menu_1',
        itemName: 'Delicious Burger',
        itemDescription: 'A juicy beef burger with fresh vegetables',
        itemPrice: 12.99,
        imageUrl: 'https://example.com/burger.jpg',
        category: 'Main Course',
      );
      
      testCartItem = CartItem(
        menuItem: testMenuItem,
        quantity: 2,
        restaurantId: 'restaurant_1',
      );

      // Setup default mock behavior
      when(mockCartBloc.state).thenReturn(const CartInitial());
      when(mockCartBloc.stream).thenAnswer((_) => const Stream.empty());
    });

    Widget createTestWidget({
      CartItem? cartItem,
      VoidCallback? onRemove,
    }) {
      return MaterialApp(
        theme: AppTheme.lightTheme,
        home: BlocProvider<CartBloc>.value(
          value: mockCartBloc,
          child: Scaffold(
            body: CartItemCard(
              cartItem: cartItem ?? testCartItem,
              onRemove: onRemove,
            ),
          ),
        ),
      );
    }

    testWidgets('displays cart item information correctly', (tester) async {
      await tester.pumpWidget(createTestWidget());

      // Verify item name is displayed
      expect(find.text('Delicious Burger'), findsOneWidget);
      
      // Verify item description is displayed
      expect(find.text('A juicy beef burger with fresh vegetables'), findsOneWidget);
      
      // Verify unit price is displayed
      expect(find.text('\$12.99 each'), findsOneWidget);
      
      // Verify total price is displayed
      expect(find.text('\$25.98'), findsOneWidget);
      
      // Verify quantity is displayed
      expect(find.text('2'), findsOneWidget);
    });

    testWidgets('displays item image with proper fallback', (tester) async {
      await tester.pumpWidget(createTestWidget());

      // Should find the image container
      expect(find.byType(ClipRRect), findsOneWidget);
      
      // Test with empty image URL
      final itemWithoutImage = CartItem(
        menuItem: testMenuItem.copyWith(imageUrl: ''),
        quantity: 1,
        restaurantId: 'restaurant_1',
      );
      
      await tester.pumpWidget(createTestWidget(cartItem: itemWithoutImage));
      
      // Should show fallback icon
      expect(find.byIcon(Icons.restaurant), findsOneWidget);
    });

    testWidgets('quantity controls work correctly', (tester) async {
      await tester.pumpWidget(createTestWidget());

      // Find quantity control buttons
      final decreaseButton = find.byIcon(Icons.remove);
      final increaseButton = find.byIcon(Icons.add);
      
      expect(decreaseButton, findsOneWidget);
      expect(increaseButton, findsOneWidget);

      // Test increase quantity
      await tester.tap(increaseButton);
      await tester.pump();

      verify(mockCartBloc.add(const UpdateQuantity(
        menuItemId: 'menu_1',
        quantity: 3,
      ))).called(1);

      // Test decrease quantity
      await tester.tap(decreaseButton);
      await tester.pump();

      verify(mockCartBloc.add(const UpdateQuantity(
        menuItemId: 'menu_1',
        quantity: 1,
      ))).called(1);
    });

    testWidgets('decrease button is disabled when quantity is 1', (tester) async {
      final singleItemCart = CartItem(
        menuItem: testMenuItem,
        quantity: 1,
        restaurantId: 'restaurant_1',
      );
      
      await tester.pumpWidget(createTestWidget(cartItem: singleItemCart));

      final decreaseButton = find.byIcon(Icons.remove);
      expect(decreaseButton, findsOneWidget);

      // The button should be present but disabled (grey color)
      final iconWidget = tester.widget<Icon>(decreaseButton);
      expect(iconWidget.color, equals(Colors.grey));
    });

    testWidgets('increase button is disabled when quantity is at max (10)', (tester) async {
      final maxQuantityCart = CartItem(
        menuItem: testMenuItem,
        quantity: 10,
        restaurantId: 'restaurant_1',
      );
      
      await tester.pumpWidget(createTestWidget(cartItem: maxQuantityCart));

      final increaseButton = find.byIcon(Icons.add);
      expect(increaseButton, findsOneWidget);

      // The button should be present but disabled (grey color)
      final iconWidget = tester.widget<Icon>(increaseButton);
      expect(iconWidget.color, equals(Colors.grey));
    });

    testWidgets('remove button shows confirmation dialog', (tester) async {
      await tester.pumpWidget(createTestWidget());

      // Find and tap the remove button
      final removeButton = find.byIcon(Icons.close);
      expect(removeButton, findsOneWidget);
      
      await tester.tap(removeButton);
      await tester.pump();

      // Verify confirmation dialog is shown
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('Remove Item'), findsOneWidget);
      expect(find.text('Are you sure you want to remove "Delicious Burger" from your cart?'), findsOneWidget);
      
      // Find dialog buttons
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Remove'), findsOneWidget);
    });

    testWidgets('confirmation dialog cancel button works', (tester) async {
      await tester.pumpWidget(createTestWidget());

      // Tap remove button to show dialog
      await tester.tap(find.byIcon(Icons.close));
      await tester.pump();

      // Tap cancel button
      await tester.tap(find.text('Cancel'));
      await tester.pump();

      // Dialog should be dismissed
      expect(find.byType(AlertDialog), findsNothing);
      
      // No remove event should be sent
      verifyNever(mockCartBloc.add(any));
    });

    testWidgets('confirmation dialog remove button removes item', (tester) async {
      await tester.pumpWidget(createTestWidget());

      // Tap remove button to show dialog
      await tester.tap(find.byIcon(Icons.close));
      await tester.pump();

      // Tap remove button in dialog
      await tester.tap(find.text('Remove'));
      await tester.pump();

      // Verify remove event is sent
      verify(mockCartBloc.add(const RemoveFromCart('menu_1'))).called(1);
    });

    testWidgets('remove item shows snackbar with undo option', (tester) async {
      await tester.pumpWidget(createTestWidget());

      // Tap remove button and confirm
      await tester.tap(find.byIcon(Icons.close));
      await tester.pump();
      await tester.tap(find.text('Remove'));
      await tester.pump();

      // Verify snackbar is shown
      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.text('Delicious Burger removed from cart'), findsOneWidget);
      expect(find.text('Undo'), findsOneWidget);
    });

    testWidgets('undo action is available in snackbar', (tester) async {
      await tester.pumpWidget(createTestWidget());

      // Remove item
      await tester.tap(find.byIcon(Icons.close));
      await tester.pump();
      await tester.tap(find.text('Remove'));
      await tester.pump();

      // Verify snackbar with undo action is shown
      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.byType(SnackBarAction), findsOneWidget);
      expect(find.text('Undo'), findsOneWidget);
    });

    testWidgets('onRemove callback is called when item is removed', (tester) async {
      bool callbackCalled = false;
      
      await tester.pumpWidget(createTestWidget(
        onRemove: () => callbackCalled = true,
      ));

      // Remove item
      await tester.tap(find.byIcon(Icons.close));
      await tester.pump();
      await tester.tap(find.text('Remove'));
      await tester.pump();

      expect(callbackCalled, isTrue);
    });

    testWidgets('handles long item names with ellipsis', (tester) async {
      final longNameItem = CartItem(
        menuItem: testMenuItem.copyWith(
          itemName: 'This is a very long menu item name that should be truncated with ellipsis',
        ),
        quantity: 1,
        restaurantId: 'restaurant_1',
      );
      
      await tester.pumpWidget(createTestWidget(cartItem: longNameItem));

      final textWidget = tester.widget<Text>(
        find.text('This is a very long menu item name that should be truncated with ellipsis'),
      );
      
      expect(textWidget.maxLines, equals(2));
      expect(textWidget.overflow, equals(TextOverflow.ellipsis));
    });

    testWidgets('handles long descriptions with ellipsis', (tester) async {
      final longDescriptionItem = CartItem(
        menuItem: testMenuItem.copyWith(
          itemDescription: 'This is a very long description that should be truncated with ellipsis when it exceeds the maximum number of lines allowed',
        ),
        quantity: 1,
        restaurantId: 'restaurant_1',
      );
      
      await tester.pumpWidget(createTestWidget(cartItem: longDescriptionItem));

      final descriptionFinder = find.text('This is a very long description that should be truncated with ellipsis when it exceeds the maximum number of lines allowed');
      expect(descriptionFinder, findsOneWidget);
      
      final textWidget = tester.widget<Text>(descriptionFinder);
      expect(textWidget.maxLines, equals(2));
      expect(textWidget.overflow, equals(TextOverflow.ellipsis));
    });

    testWidgets('handles empty description gracefully', (tester) async {
      final noDescriptionItem = CartItem(
        menuItem: testMenuItem.copyWith(itemDescription: ''),
        quantity: 1,
        restaurantId: 'restaurant_1',
      );
      
      await tester.pumpWidget(createTestWidget(cartItem: noDescriptionItem));

      // Should not show description text when empty
      expect(find.text(''), findsNothing);
      
      // But should still show other elements
      expect(find.text('Delicious Burger'), findsOneWidget);
      expect(find.text('\$12.99 each'), findsOneWidget);
    });

    testWidgets('displays correct price formatting', (tester) async {
      final expensiveItem = CartItem(
        menuItem: testMenuItem.copyWith(itemPrice: 123.456),
        quantity: 3,
        restaurantId: 'restaurant_1',
      );
      
      await tester.pumpWidget(createTestWidget(cartItem: expensiveItem));

      // Unit price should be formatted to 2 decimal places
      expect(find.text('\$123.46 each'), findsOneWidget);
      
      // Total price should be calculated and formatted correctly
      expect(find.text('\$370.37'), findsOneWidget); // 123.456 * 3 = 370.368 -> 370.37
    });

    testWidgets('tooltip is shown on remove button', (tester) async {
      await tester.pumpWidget(createTestWidget());

      final removeButton = find.byIcon(Icons.close);
      expect(removeButton, findsOneWidget);

      // Long press to show tooltip
      await tester.longPress(removeButton);
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Remove item'), findsOneWidget);
    });
  });
}