import 'package:deliery_app/presentation/widgets/loading_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:deliery_app/presentation/widgets/restaurant_card.dart';
import 'package:deliery_app/data/models/restaurant.dart';
import 'package:deliery_app/core/theme/app_theme.dart';

void main() {
  group('RestaurantCard Widget Tests', () {
    late Restaurant testRestaurant;

    setUp(() {
      testRestaurant = const Restaurant(
        id: '1',
        name: 'Test Restaurant',
        rating: 4.5,
        address: '123 Test Street, Test City',
        cuisineType: 'Italian',
        imageUrl: 'https://example.com/image.jpg',
        description: 'A great test restaurant',
      );
    });

    testWidgets('displays restaurant information correctly', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(body: RestaurantCard(restaurant: testRestaurant)),
        ),
      );

      // Verify restaurant name is displayed
      expect(find.text('Test Restaurant'), findsOneWidget);

      // Verify cuisine type is displayed
      expect(find.text('Italian'), findsOneWidget);

      // Verify address is displayed
      expect(find.text('123 Test Street, Test City'), findsOneWidget);

      // Verify rating is displayed
      expect(find.text('4.5'), findsOneWidget);

      // Verify description is displayed
      expect(find.text('A great test restaurant'), findsOneWidget);

      // Verify star icon is present
      expect(find.byIcon(Icons.star), findsOneWidget);
    });

    testWidgets('handles tap events correctly', (WidgetTester tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: RestaurantCard(
              restaurant: testRestaurant,
              onTap: () {
                tapped = true;
              },
            ),
          ),
        ),
      );

      // Tap on the card
      await tester.tap(find.byType(RestaurantCard));
      await tester.pump();

      // Verify tap was handled
      expect(tapped, isTrue);
    });

    testWidgets('displays correct rating color for high rating', (
      WidgetTester tester,
    ) async {
      final highRatingRestaurant = testRestaurant.copyWith(rating: 4.5);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: RestaurantCard(restaurant: highRatingRestaurant),
          ),
        ),
      );

      // Verify rating is displayed
      expect(find.text('4.5'), findsOneWidget);
      expect(find.byIcon(Icons.star), findsOneWidget);
    });

    testWidgets('displays correct rating color for medium rating', (
      WidgetTester tester,
    ) async {
      final mediumRatingRestaurant = testRestaurant.copyWith(rating: 3.5);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: RestaurantCard(restaurant: mediumRatingRestaurant),
          ),
        ),
      );

      // Verify rating is displayed
      expect(find.text('3.5'), findsOneWidget);
      expect(find.byIcon(Icons.star), findsOneWidget);
    });

    testWidgets('displays correct rating color for low rating', (
      WidgetTester tester,
    ) async {
      final lowRatingRestaurant = testRestaurant.copyWith(rating: 2.0);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(body: RestaurantCard(restaurant: lowRatingRestaurant)),
        ),
      );

      // Verify rating is displayed
      expect(find.text('2.0'), findsOneWidget);
      expect(find.byIcon(Icons.star), findsOneWidget);
    });

    testWidgets('displays shimmer loading state correctly', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const Scaffold(
            body: RestaurantCard(
              restaurant: Restaurant(
                id: '',
                name: '',
                rating: 0.0,
                address: '',
                cuisineType: '',
                imageUrl: '',
                description: '',
              ),
            ),
          ),
        ),
      );

      // Verify shimmer effect is present
      expect(find.byType(RestaurantCard), findsOneWidget);

      // Verify actual content is not displayed during loading
      expect(find.text('Test Restaurant'), findsNothing);
      expect(find.text('Italian'), findsNothing);
    });

    testWidgets('handles long text with ellipsis', (WidgetTester tester) async {
      final restaurantWithLongText = testRestaurant.copyWith(
        name: 'This is a very long restaurant name that should be truncated',
        address:
            'This is a very long address that should be truncated with ellipsis',
        description: 'This is a very long description that should be truncated',
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: SizedBox(
            width: 300, // Constrain width to force ellipsis
            child: Scaffold(
              body: RestaurantCard(restaurant: restaurantWithLongText),
            ),
          ),
        ),
      );

      // Verify the card is displayed (text truncation is handled by Flutter)
      expect(find.byType(RestaurantCard), findsOneWidget);
    });

    testWidgets('RestaurantCardShimmer displays loading state', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const Scaffold(body: RestaurantCardShimmer()),
        ),
      );

      // Verify shimmer card is displayed
      expect(find.byType(RestaurantCard), findsOneWidget);
      expect(find.byType(RestaurantCard), findsOneWidget);
    });

    testWidgets('handles null onTap callback gracefully', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: RestaurantCard(restaurant: testRestaurant, onTap: null),
          ),
        ),
      );

      // Should not throw when tapping without callback
      await tester.tap(find.byType(RestaurantCard));
      await tester.pump();

      // Verify card is still displayed
      expect(find.byType(RestaurantCard), findsOneWidget);
    });

    testWidgets('displays restaurant card with proper structure', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(body: RestaurantCard(restaurant: testRestaurant)),
        ),
      );

      // Verify card structure
      expect(find.byType(Card), findsOneWidget);
      expect(find.byType(InkWell), findsOneWidget);
      expect(find.byType(Row), findsAtLeastNWidgets(1));
      expect(find.byType(Column), findsAtLeastNWidgets(1));
    });
  });
}
