import 'package:flutter_test/flutter_test.dart';
import 'package:stock_trading_app/services/indicator_service.dart';

void main() {
  group('IndicatorService Tests', () {
    List<double> samplePrices = [100, 102, 101, 105, 108, 107, 110, 112, 111, 115];
    
    test('Calculate SMA correctly', () {
      List<double> sma = IndicatorService.calculateSMA(samplePrices, 5);
      
      expect(sma.length, 6);
      expect(sma[0], (100 + 102 + 101 + 105 + 108) / 5);
      expect(sma.last, (108 + 107 + 110 + 112 + 111) / 5);
    });
    
    test('Calculate EMA correctly', () {
      List<double> ema = IndicatorService.calculateEMA(samplePrices, 5);
      
      expect(ema.length, 6);
      expect(ema[0], (100 + 102 + 101 + 105 + 108) / 5);
      expect(ema.last, greaterThan(0));
    });
    
    test('Calculate RSI correctly', () {
      List<double> rsi = IndicatorService.calculateRSI(samplePrices, 5);
      
      expect(rsi.length, 5);
      expect(rsi[0], between(0, 100));
      expect(rsi.last, between(0, 100));
    });
    
    test('Calculate Bollinger Bands correctly', () {
      var bands = IndicatorService.calculateBollingerBands(samplePrices, 5, 2);
      
      expect(bands['upper']!.length, 6);
      expect(bands['middle']!.length, 6);
      expect(bands['lower']!.length, 6);
      expect(bands['upper']![0], greaterThan(bands['middle']![0]));
      expect(bands['lower']![0], lessThan(bands['middle']![0]));
    });
    
    test('Calculate MACD correctly', () {
      var macd = IndicatorService.calculateMACD(samplePrices, 12, 26, 9);
      
      expect(macd['macd']!.length, greaterThan(0));
      expect(macd['signal']!.length, greaterThan(0));
      expect(macd['histogram']!.length, greaterThan(0));
    });
    
    test('Calculate Fibonacci Retracement correctly', () {
      var fib = IndicatorService.calculateFibonacciRetracement(115, 100);
      
      expect(fib[0.0], 115);
      expect(fib[0.236], closeTo(111.46, 0.01));
      expect(fib[0.382], closeTo(109.27, 0.01));
      expect(fib[0.5], closeTo(107.5, 0.01));
      expect(fib[0.618], closeTo(105.73, 0.01));
      expect(fib[0.786], closeTo(103.21, 0.01));
      expect(fib[1.0], 100);
    });
  });
}