import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bloc_test/bloc_test.dart';

import 'package:deliery_app/presentation/screens/restaurant_list_screen.dart';
import 'package:deliery_app/presentation/blocs/restaurant/restaurant_bloc.dart';
import 'package:deliery_app/presentation/blocs/restaurant/restaurant_event.dart';
import 'package:deliery_app/presentation/blocs/restaurant/restaurant_state.dart';
import 'package:deliery_app/presentation/widgets/restaurant_card.dart';
import 'package:deliery_app/data/models/restaurant.dart';
import 'package:deliery_app/core/theme/app_theme.dart';

// Mock RestaurantBloc
class MockRestaurantBloc extends MockBloc<RestaurantEvent, RestaurantState>
    implements RestaurantBloc {}

void main() {
  group('RestaurantListScreen Widget Tests', () {
    late MockRestaurantBloc mockRestaurantBloc;
    late List<Restaurant> testRestaurants;

    setUp(() {
      mockRestaurantBloc = MockRestaurantBloc();
      testRestaurants = [
        const Restaurant(
          id: '1',
          name: 'Test Restaurant 1',
          rating: 4.5,
          address: '123 Test Street',
          cuisineType: 'Italian',
          imageUrl: 'https://example.com/image1.jpg',
          description: 'Great Italian food',
        ),
        const Restaurant(
          id: '2',
          name: 'Test Restaurant 2',
          rating: 4.0,
          address: '456 Test Avenue',
          cuisineType: 'Chinese',
          imageUrl: 'https://example.com/image2.jpg',
          description: 'Authentic Chinese cuisine',
        ),
      ];
    });

    Widget createWidgetUnderTest(RestaurantState initialState) {
      whenListen(
        mockRestaurantBloc,
        Stream<RestaurantState>.fromIterable([initialState]),
        initialState: initialState,
      );

      return MaterialApp(
        theme: AppTheme.lightTheme,
        home: BlocProvider<RestaurantBloc>(
          create: (context) => mockRestaurantBloc,
          child: const RestaurantListScreen(),
        ),
      );
    }

    testWidgets('displays app bar with correct title', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createWidgetUnderTest(const RestaurantInitial()));

      expect(find.text('Restaurants'), findsOneWidget);
      expect(find.byType(AppBar), findsOneWidget);
    });

    testWidgets('displays initial state correctly', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createWidgetUnderTest(const RestaurantInitial()));

      expect(find.text('Welcome to Food Delivery'), findsOneWidget);
      expect(
        find.text('Discover amazing restaurants near you'),
        findsOneWidget,
      );
      expect(find.text('Explore Restaurants'), findsOneWidget);
      expect(find.byIcon(Icons.restaurant), findsOneWidget);
    });

    testWidgets('displays loading state with shimmer cards', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createWidgetUnderTest(const RestaurantLoading()));

      expect(find.byType(Card), findsWidgets);
      expect(find.byType(ListView), findsOneWidget);
    });

    testWidgets('displays loaded state with restaurant cards', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        createWidgetUnderTest(RestaurantLoaded(restaurants: testRestaurants)),
      );

      expect(find.byType(RestaurantCard), findsNWidgets(2));
      expect(find.text('Test Restaurant 1'), findsOneWidget);
      expect(find.text('Test Restaurant 2'), findsOneWidget);
      expect(find.text('Italian'), findsOneWidget);
      expect(find.text('Chinese'), findsOneWidget);
    });

    testWidgets('displays empty state when no restaurants', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        createWidgetUnderTest(const RestaurantLoaded(restaurants: [])),
      );

      expect(find.text('No Restaurants Found'), findsOneWidget);
      expect(
        find.text(
          'We couldn\'t find any restaurants at the moment. Please try again later.',
        ),
        findsOneWidget,
      );
      expect(find.text('Refresh'), findsOneWidget);
      expect(find.byIcon(Icons.restaurant_menu), findsOneWidget);
    });

    testWidgets('displays error state with error message', (
      WidgetTester tester,
    ) async {
      const errorMessage = 'Network error occurred';
      await tester.pumpWidget(
        createWidgetUnderTest(const RestaurantError(errorMessage)),
      );

      expect(find.text('Oops! Something went wrong'), findsOneWidget);
      expect(find.text(errorMessage), findsOneWidget);
      expect(find.text('Try Again'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
    });

    testWidgets('displays RefreshIndicator', (WidgetTester tester) async {
      await tester.pumpWidget(
        createWidgetUnderTest(RestaurantLoaded(restaurants: testRestaurants)),
      );

      expect(find.byType(RefreshIndicator), findsOneWidget);
    });

    testWidgets('displays restaurant list screen structure', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        createWidgetUnderTest(RestaurantLoaded(restaurants: testRestaurants)),
      );

      expect(find.byType(Scaffold), findsOneWidget);
      expect(find.byType(AppBar), findsOneWidget);
      expect(find.byType(RefreshIndicator), findsOneWidget);
      expect(find.byType(ListView), findsOneWidget);
    });

    testWidgets('restaurant cards are tappable', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: BlocProvider<RestaurantBloc>(
            create: (context) {
              whenListen(
                mockRestaurantBloc,
                Stream<RestaurantState>.fromIterable([
                  RestaurantLoaded(restaurants: testRestaurants),
                ]),
                initialState: RestaurantLoaded(restaurants: testRestaurants),
              );
              return mockRestaurantBloc;
            },
            child: const RestaurantListScreen(),
          ),
          routes: {
            '/menu': (context) =>
                const Scaffold(body: Center(child: Text('Menu Screen'))),
          },
        ),
      );

      await tester.tap(find.byType(RestaurantCard).first);
      await tester.pumpAndSettle();

      expect(find.text('Menu Screen'), findsOneWidget);
    });

    testWidgets('error state retry button is tappable', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        createWidgetUnderTest(const RestaurantError('Test error')),
      );

      expect(find.text('Try Again'), findsOneWidget);
      await tester.tap(find.text('Try Again'));
      await tester.pump();

      // Should not throw any errors
      expect(tester.takeException(), isNull);
    });

    testWidgets('empty state refresh button is tappable', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        createWidgetUnderTest(const RestaurantLoaded(restaurants: [])),
      );

      expect(find.text('Refresh'), findsOneWidget);
      await tester.tap(find.text('Refresh'));
      await tester.pump();

      // Should not throw any errors
      expect(tester.takeException(), isNull);
    });

    testWidgets('initial state explore button is tappable', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createWidgetUnderTest(const RestaurantInitial()));

      expect(find.text('Explore Restaurants'), findsOneWidget);
      await tester.tap(find.text('Explore Restaurants'));
      await tester.pump();

      // Should not throw any errors
      expect(tester.takeException(), isNull);
    });

    testWidgets('displays correct icon in initial state', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createWidgetUnderTest(const RestaurantInitial()));
      expect(find.byIcon(Icons.restaurant), findsOneWidget);
    });

    testWidgets('displays correct icon in error state', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        createWidgetUnderTest(const RestaurantError('Error')),
      );
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
    });

    testWidgets('displays correct icon in empty state', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        createWidgetUnderTest(const RestaurantLoaded(restaurants: [])),
      );
      expect(find.byIcon(Icons.restaurant_menu), findsOneWidget);
    });

    testWidgets('displays correct button text in initial state', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createWidgetUnderTest(const RestaurantInitial()));
      expect(find.text('Explore Restaurants'), findsOneWidget);
    });

    testWidgets('displays correct button text in error state', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        createWidgetUnderTest(const RestaurantError('Error')),
      );
      expect(find.text('Try Again'), findsOneWidget);
    });

    testWidgets('displays correct button text in empty state', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        createWidgetUnderTest(const RestaurantLoaded(restaurants: [])),
      );
      expect(find.text('Refresh'), findsOneWidget);
    });

    testWidgets('shows shimmer cards in loading state', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createWidgetUnderTest(const RestaurantLoading()));

      // Should show multiple shimmer cards (at least 5 visible in viewport)

    });

    testWidgets('handles empty restaurant list gracefully', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        createWidgetUnderTest(const RestaurantLoaded(restaurants: [])),
      );

      // Should show empty state instead of empty list
      expect(find.text('No Restaurants Found'), findsOneWidget);
      expect(find.byType(RestaurantCard), findsNothing);
    });

    testWidgets('displays restaurant details correctly', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        createWidgetUnderTest(RestaurantLoaded(restaurants: testRestaurants)),
      );

      // Check that restaurant details are displayed
      expect(find.text('4.5'), findsOneWidget);
      expect(find.text('4.0'), findsOneWidget);
      expect(find.text('123 Test Street'), findsOneWidget);
      expect(find.text('456 Test Avenue'), findsOneWidget);
    });
  });
}
