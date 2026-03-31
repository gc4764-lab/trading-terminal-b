import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:stock_trading_app/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('end-to-end test', () {
    testWidgets('navigate through all screens', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Test watchlist screen
      await tester.tap(find.byIcon(Icons.list));
      await tester.pumpAndSettle();
      expect(find.text('Watchlist'), findsOneWidget);

      // Test charts screen
      await tester.tap(find.byIcon(Icons.show_chart));
      await tester.pumpAndSettle();
      expect(find.text('Chart Grid'), findsOneWidget);

      // Test risk management screen
      await tester.tap(find.byIcon(Icons.security));
      await tester.pumpAndSettle();
      expect(find.text('Risk Management'), findsOneWidget);

      // Test orders screen
      await tester.tap(find.byIcon(Icons.shopping_cart));
      await tester.pumpAndSettle();
      expect(find.text('Orders & Trades'), findsOneWidget);

      // Test positions screen
      await tester.tap(find.byIcon(Icons.account_balance));
      await tester.pumpAndSettle();
      expect(find.text('Positions & Holdings'), findsOneWidget);

      // Test alerts screen
      await tester.tap(find.byIcon(Icons.notifications));
      await tester.pumpAndSettle();
      expect(find.text('Alerts'), findsOneWidget);

      // Test news screen
      await tester.tap(find.byIcon(Icons.newspaper));
      await tester.pumpAndSettle();
      expect(find.text('Market News'), findsOneWidget);

      // Test settings screen
      await tester.tap(find.byIcon(Icons.settings));
      await tester.pumpAndSettle();
      expect(find.text('Settings'), findsOneWidget);
    });
  });
}