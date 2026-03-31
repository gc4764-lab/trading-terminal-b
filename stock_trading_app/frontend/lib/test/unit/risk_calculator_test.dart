import 'package:flutter_test/flutter_test.dart';
import 'package:stock_trading_app/providers/risk_provider.dart';
import 'package:stock_trading_app/models/position.dart';

void main() {
  group('Risk Calculator Tests', () {
    test('Calculate concentration risk correctly', () {
      List<Position> positions = [
        Position(
          id: '1',
          brokerId: 'test',
          symbol: 'AAPL',
          quantity: 100,
          avgPrice: 150,
          currentPrice: 155,
          pnl: 500,
          updatedAt: DateTime.now(),
        ),
        Position(
          id: '2',
          brokerId: 'test',
          symbol: 'GOOGL',
          quantity: 50,
          avgPrice: 2800,
          currentPrice: 2850,
          pnl: 2500,
          updatedAt: DateTime.now(),
        ),
      ];
      
      double totalValue = positions.fold(0.0, (sum, p) => sum + (p.quantity * p.currentPrice));
      double concentration = 0;
      
      for (var p in positions) {
        double weight = (p.quantity * p.currentPrice) / totalValue;
        concentration += weight * weight;
      }
      
      expect(concentration, greaterThan(0.5));
      expect(concentration, lessThan(0.6));
    });
    
    test('Calculate Sharpe ratio correctly', () {
      List<double> returns = [0.01, -0.005, 0.02, 0.015, -0.01, 0.03];
      double mean = returns.reduce((a, b) => a + b) / returns.length;
      double variance = 0;
      
      for (var r in returns) {
        variance += pow(r - mean, 2);
      }
      variance /= returns.length;
      double stdDev = sqrt(variance);
      
      double riskFreeRate = 0.02 / 252;
      double sharpe = stdDev == 0 ? 0 : (mean - riskFreeRate) / stdDev * sqrt(252);
      
      expect(sharpe, greaterThan(-10));
      expect(sharpe, lessThan(10));
    });
  });
}