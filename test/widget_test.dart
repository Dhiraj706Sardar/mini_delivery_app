import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:deliery_app/main.dart';

void main() {
  testWidgets('Food Delivery App smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const FoodDeliveryApp());
    await tester.pumpAndSettle();

    // Verify that the app starts and shows the restaurant screen
    expect(find.text('Restaurants'), findsOneWidget);
    
    // Verify that the initial state is shown
    expect(find.text('Welcome to Food Delivery'), findsOneWidget);
    expect(find.text('Discover amazing restaurants near you'), findsOneWidget);
    
    // Verify that the restaurant icon is displayed
    expect(find.byIcon(Icons.restaurant), findsOneWidget);
  });
}
