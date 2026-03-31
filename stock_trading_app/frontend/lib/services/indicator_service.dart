import 'dart:math';
import 'package:stock_trading_app/models/chart_data.dart';

class IndicatorService {
  // Moving Averages
  static List<double> calculateSMA(List<double> prices, int period) {
    if (prices.length < period) return [];
    
    List<double> sma = [];
    for (int i = period - 1; i < prices.length; i++) {
      double sum = 0;
      for (int j = i - period + 1; j <= i; j++) {
        sum += prices[j];
      }
      sma.add(sum / period);
    }
    return sma;
  }
  
  static List<double> calculateEMA(List<double> prices, int period) {
    if (prices.length < period) return [];
    
    List<double> ema = [];
    double multiplier = 2 / (period + 1);
    
    // Initial SMA
    double sum = 0;
    for (int i = 0; i < period; i++) {
      sum += prices[i];
    }
    double previousEMA = sum / period;
    ema.add(previousEMA);
    
    // Calculate EMA
    for (int i = period; i < prices.length; i++) {
      double currentEMA = (prices[i] - previousEMA) * multiplier + previousEMA;
      ema.add(currentEMA);
      previousEMA = currentEMA;
    }
    return ema;
  }
  
  // Bollinger Bands
  static Map<String, List<double>> calculateBollingerBands(
    List<double> prices, 
    int period, 
    double stdDevMultiplier
  ) {
    List<double> middle = calculateSMA(prices, period);
    List<double> upper = [];
    List<double> lower = [];
    
    for (int i = period - 1; i < prices.length; i++) {
      double sum = 0;
      for (int j = i - period + 1; j <= i; j++) {
        sum += pow(prices[j] - middle[i - (period - 1)], 2);
      }
      double stdDev = sqrt(sum / period);
      upper.add(middle[i - (period - 1)] + stdDevMultiplier * stdDev);
      lower.add(middle[i - (period - 1)] - stdDevMultiplier * stdDev);
    }
    
    return {
      'upper': upper,
      'middle': middle,
      'lower': lower,
    };
  }
  
  // RSI (Relative Strength Index)
  static List<double> calculateRSI(List<double> prices, int period) {
    if (prices.length < period + 1) return [];
    
    List<double> rsi = [];
    List<double> gains = [];
    List<double> losses = [];
    
    // Calculate gains and losses
    for (int i = 1; i < prices.length; i++) {
      double change = prices[i] - prices[i - 1];
      gains.add(max(change, 0));
      losses.add(max(-change, 0));
    }
    
    // Calculate average gains and losses
    for (int i = period - 1; i < gains.length; i++) {
      double avgGain = 0;
      double avgLoss = 0;
      
      for (int j = i - period + 1; j <= i; j++) {
        avgGain += gains[j];
        avgLoss += losses[j];
      }
      
      avgGain /= period;
      avgLoss /= period;
      
      if (avgLoss == 0) {
        rsi.add(100);
      } else {
        double rs = avgGain / avgLoss;
        rsi.add(100 - (100 / (1 + rs)));
      }
    }
    
    return rsi;
  }
  
  // MACD (Moving Average Convergence Divergence)
  static Map<String, List<double>> calculateMACD(
    List<double> prices, 
    int fastPeriod, 
    int slowPeriod, 
    int signalPeriod
  ) {
    List<double> fastEMA = calculateEMA(prices, fastPeriod);
    List<double> slowEMA = calculateEMA(prices, slowPeriod);
    
    // Align lengths
    int offset = slowPeriod - fastPeriod;
    List<double> macdLine = [];
    for (int i = offset; i < fastEMA.length; i++) {
      macdLine.add(fastEMA[i] - slowEMA[i - offset]);
    }
    
    // Calculate signal line
    List<double> signalLine = calculateEMA(macdLine, signalPeriod);
    
    // Calculate histogram
    List<double> histogram = [];
    for (int i = 0; i < signalLine.length; i++) {
      histogram.add(macdLine[i + (macdLine.length - signalLine.length)] - signalLine[i]);
    }
    
    return {
      'macd': macdLine,
      'signal': signalLine,
      'histogram': histogram,
    };
  }
  
  // Fibonacci Retracement
  static Map<double, double> calculateFibonacciRetracement(
    double high, 
    double low
  ) {
    double diff = high - low;
    return {
      0.0: high,
      0.236: high - diff * 0.236,
      0.382: high - diff * 0.382,
      0.5: high - diff * 0.5,
      0.618: high - diff * 0.618,
      0.786: high - diff * 0.786,
      1.0: low,
    };
  }
  
  // Ichimoku Cloud
  static Map<String, List<double>> calculateIchimoku(
    List<double> highs,
    List<double> lows,
    List<double> closes,
    int tenkanPeriod,
    int kijunPeriod,
    int senkouBPeriod
  ) {
    List<double> tenkanSen = [];
    List<double> kijunSen = [];
    List<double> senkouSpanA = [];
    List<double> senkouSpanB = [];
    
    // Tenkan-sen (Conversion Line)
    for (int i = tenkanPeriod - 1; i < highs.length; i++) {
      double maxHigh = highs[i - tenkanPeriod + 1];
      double minLow = lows[i - tenkanPeriod + 1];
      for (int j = i - tenkanPeriod + 2; j <= i; j++) {
        maxHigh = max(maxHigh, highs[j]);
        minLow = min(minLow, lows[j]);
      }
      tenkanSen.add((maxHigh + minLow) / 2);
    }
    
    // Kijun-sen (Base Line)
    for (int i = kijunPeriod - 1; i < highs.length; i++) {
      double maxHigh = highs[i - kijunPeriod + 1];
      double minLow = lows[i - kijunPeriod + 1];
      for (int j = i - kijunPeriod + 2; j <= i; j++) {
        maxHigh = max(maxHigh, highs[j]);
        minLow = min(minLow, lows[j]);
      }
      kijunSen.add((maxHigh + minLow) / 2);
    }
    
    // Senkou Span A (Leading Span A)
    for (int i = 0; i < min(tenkanSen.length, kijunSen.length); i++) {
      senkouSpanA.add((tenkanSen[i] + kijunSen[i]) / 2);
    }
    
    // Senkou Span B (Leading Span B)
    for (int i = senkouBPeriod - 1; i < highs.length; i++) {
      double maxHigh = highs[i - senkouBPeriod + 1];
      double minLow = lows[i - senkouBPeriod + 1];
      for (int j = i - senkouBPeriod + 2; j <= i; j++) {
        maxHigh = max(maxHigh, highs[j]);
        minLow = min(minLow, lows[j]);
      }
      senkouSpanB.add((maxHigh + minLow) / 2);
    }
    
    return {
      'tenkan': tenkanSen,
      'kijun': kijunSen,
      'senkouA': senkouSpanA,
      'senkouB': senkouSpanB,
    };
  }
  
  // ATR (Average True Range)
  static List<double> calculateATR(
    List<double> highs,
    List<double> lows,
    List<double> closes,
    int period
  ) {
    if (highs.length < period + 1) return [];
    
    List<double> trueRanges = [];
    List<double> atr = [];
    
    // Calculate True Range
    for (int i = 1; i < highs.length; i++) {
      double highLow = highs[i] - lows[i];
      double highClose = (highs[i] - closes[i - 1]).abs();
      double lowClose = (lows[i] - closes[i - 1]).abs();
      trueRanges.add(max(highLow, max(highClose, lowClose)));
    }
    
    // Calculate initial ATR
    double sum = 0;
    for (int i = 0; i < period; i++) {
      sum += trueRanges[i];
    }
    atr.add(sum / period);
    
    // Calculate subsequent ATR
    for (int i = period; i < trueRanges.length; i++) {
      atr.add((atr.last * (period - 1) + trueRanges[i]) / period);
    }
    
    return atr;
  }
}