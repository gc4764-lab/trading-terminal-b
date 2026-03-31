import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stock_trading_app/main.dart';
import 'package:stock_trading_app/screens/watchlist_screen.dart';
import 'package:stock_trading_app/models/watchlist.dart';

void main() {
  testWidgets('Watchlist screen test', (WidgetTester tester) async {
    // Build our app and trigger a frame
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: WatchlistScreen(),
        ),
      ),
    );

    // Verify that watchlist screen is loaded
    expect(find.text('Watchlist'), findsOneWidget);
    expect(find.byIcon(Icons.add), findsOneWidget);
  });

  testWidgets('Add stock to watchlist', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: WatchlistScreen(),
        ),
      ),
    );

    // Tap add button
    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();

    // Verify dialog appears
    expect(find.text('Add Stock'), findsOneWidget);
    expect(find.text('Symbol'), findsOneWidget);
    expect(find.text('Company Name'), findsOneWidget);
    expect(find.text('Exchange'), findsOneWidget);

    // Fill form
    await tester.enterText(find.widgetWithText(TextFormField, 'Symbol'), 'AAPL');
    await tester.enterText(find.widgetWithText(TextFormField, 'Company Name'), 'Apple Inc.');
    await tester.enterText(find.widgetWithText(TextFormField, 'Exchange'), 'NASDAQ');

    // Submit
    await tester.tap(find.text('Add'));
    await tester.pumpAndSettle();

    // Verify stock was added (you may need to mock API)
    expect(find.text('AAPL'), findsOneWidget);
  });
}