import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:tflite_flutter/tflite_flutter.dart';

class AIService {
  Interpreter? _pricePredictor;
  Interpreter? _sentimentAnalyzer;
  
  Future<void> initialize() async {
    // Load TensorFlow Lite models
    try {
      _pricePredictor = await Interpreter.fromAsset('models/price_predictor.tflite');
      _sentimentAnalyzer = await Interpreter.fromAsset('models/sentiment_analyzer.tflite');
    } catch (e) {
      print('Error loading AI models: $e');
    }
  }
  
  // Price Prediction
  Future<Map<String, dynamic>> predictPrice({
    required String symbol,
    required List<double> historicalPrices,
    required List<double> volumes,
    required List<Map<String, double>> technicalIndicators,
  }) async {
    if (_pricePredictor == null) {
      return _fallbackPrediction(historicalPrices);
    }
    
    // Prepare input features
    List<double> features = [];
    
    // Add historical prices (last 30 days)
    features.addAll(historicalPrices.takeLast(30));
    
    // Add volumes
    features.addAll(volumes.takeLast(30).map((v) => v / 1000000)); // Normalize
    
    // Add technical indicators
    features.add(technicalIndicators.last['rsi'] ?? 50);
    features.add(technicalIndicators.last['macd'] ?? 0);
    features.add(technicalIndicators.last['sma'] ?? 0);
    features.add(technicalIndicators.last['ema'] ?? 0);
    features.add(technicalIndicators.last['bollinger_upper'] ?? 0);
    features.add(technicalIndicators.last['bollinger_lower'] ?? 0);
    
    // Reshape to [1, feature_count]
    var input = [features];
    var output = List.filled(1, 0.0).reshape([1, 1]);
    
    // Run inference
    _pricePredictor!.run(input, output);
    
    double predictedPrice = output[0][0];
    double confidence = _calculateConfidence(predictedPrice, historicalPrices);
    
    return {
      'predicted_price': predictedPrice,
      'confidence': confidence,
      'direction': predictedPrice > historicalPrices.last ? 'up' : 'down',
      'percentage_change': ((predictedPrice - historicalPrices.last) / historicalPrices.last) * 100,
    };
  }
  
  // Sentiment Analysis on News
  Future<Map<String, dynamic>> analyzeSentiment(String newsText) async {
    if (_sentimentAnalyzer == null) {
      return _fallbackSentiment(newsText);
    }
    
    // Tokenize and prepare input
    List<String> tokens = _tokenize(newsText);
    var input = _encodeTokens(tokens);
    var output = List.filled(3, 0.0).reshape([1, 3]);
    
    _sentimentAnalyzer!.run(input, output);
    
    double positive = output[0][0];
    double neutral = output[0][1];
    double negative = output[0][2];
    
    String sentiment = positive > negative ? 'positive' : (negative > positive ? 'negative' : 'neutral');
    double score = positive > negative ? positive : (negative > positive ? negative : neutral);
    
    return {
      'sentiment': sentiment,
      'score': score,
      'positive': positive,
      'neutral': neutral,
      'negative': negative,
    };
  }
  
  // Pattern Recognition
  Future<List<Map<String, dynamic>>> detectPatterns(List<ChartData> data) async {
    List<Map<String, dynamic>> patterns = [];
    
    // Check for common candlestick patterns
    if (_isBullishEngulfing(data)) {
      patterns.add({
        'type': 'bullish_engulfing',
        'confidence': 0.85,
        'description': 'Bullish reversal pattern',
        'timestamp': data.last.date,
      });
    }
    
    if (_isBearishEngulfing(data)) {
      patterns.add({
        'type': 'bearish_engulfing',
        'confidence': 0.85,
        'description': 'Bearish reversal pattern',
        'timestamp': data.last.date,
      });
    }
    
    if (_isDoji(data)) {
      patterns.add({
        'type': 'doji',
        'confidence': 0.70,
        'description': 'Indecision pattern',
        'timestamp': data.last.date,
      });
    }
    
    if (_isHammer(data)) {
      patterns.add({
        'type': 'hammer',
        'confidence': 0.80,
        'description': 'Bullish reversal pattern',
        'timestamp': data.last.date,
      });
    }
    
    if (_isShootingStar(data)) {
      patterns.add({
        'type': 'shooting_star',
        'confidence': 0.80,
        'description': 'Bearish reversal pattern',
        'timestamp': data.last.date,
      });
    }
    
    // Check chart patterns
    if (_isHeadAndShoulders(data)) {
      patterns.add({
        'type': 'head_and_shoulders',
        'confidence': 0.75,
        'description': 'Bearish reversal pattern',
        'timestamp': data.last.date,
      });
    }
    
    if (_isDoubleTop(data)) {
      patterns.add({
        'type': 'double_top',
        'confidence': 0.78,
        'description': 'Bearish reversal pattern',
        'timestamp': data.last.date,
      });
    }
    
    if (_isDoubleBottom(data)) {
      patterns.add({
        'type': 'double_bottom',
        'confidence': 0.78,
        'description': 'Bullish reversal pattern',
        'timestamp': data.last.date,
      });
    }
    
    return patterns;
  }
  
  // Pattern detection helpers
  bool _isBullishEngulfing(List<ChartData> data) {
    if (data.length < 2) return false;
    
    ChartData today = data[data.length - 1];
    ChartData yesterday = data[data.length - 2];
    
    return yesterday.open > yesterday.close && // Previous candle is bearish
           today.open < yesterday.close && // Gap down
           today.close > yesterday.open && // Engulf previous candle
           today.close > today.open; // Current candle is bullish
  }
  
  bool _isBearishEngulfing(List<ChartData> data) {
    if (data.length < 2) return false;
    
    ChartData today = data[data.length - 1];
    ChartData yesterday = data[data.length - 2];
    
    return yesterday.open < yesterday.close && // Previous candle is bullish
           today.open > yesterday.close && // Gap up
           today.close < yesterday.open && // Engulf previous candle
           today.close < today.open; // Current candle is bearish
  }
  
  bool _isDoji(List<ChartData> data) {
    if (data.isEmpty) return false;
    
    ChartData candle = data.last;
    double bodySize = (candle.close - candle.open).abs();
    double totalRange = candle.high - candle.low;
    
    return bodySize / totalRange < 0.1; // Body is less than 10% of total range
  }
  
  bool _isHammer(List<ChartData> data) {
    if (data.isEmpty) return false;
    
    ChartData candle = data.last;
    double bodySize = (candle.close - candle.open).abs();
    double lowerWick = (candle.open < candle.close ? candle.open : candle.close) - candle.low;
    double upperWick = candle.high - (candle.open > candle.close ? candle.open : candle.close);
    
    return lowerWick > bodySize * 2 && // Lower wick at least 2x body
           upperWick < bodySize; // Small upper wick
  }
  
  bool _isShootingStar(List<ChartData> data) {
    if (data.isEmpty) return false;
    
    ChartData candle = data.last;
    double bodySize = (candle.close - candle.open).abs();
    double upperWick = candle.high - (candle.open > candle.close ? candle.open : candle.close);
    double lowerWick = (candle.open < candle.close ? candle.open : candle.close) - candle.low;
    
    return upperWick > bodySize * 2 && // Upper wick at least 2x body
           lowerWick < bodySize; // Small lower wick
  }
  
  bool _isHeadAndShoulders(List<ChartData> data) {
    if (data.length < 5) return false;
    
    List<double> highs = data.map((d) => d.high).toList();
    int n = highs.length;
    
    // Find peaks
    List<int> peaks = [];
    for (int i = 2; i < n - 2; i++) {
      if (highs[i] > highs[i-1] && highs[i] > highs[i-2] &&
          highs[i] > highs[i+1] && highs[i] > highs[i+2]) {
        peaks.add(i);
      }
    }
    
    if (peaks.length >= 3) {
      int left = peaks[peaks.length - 3];
      int head = peaks[peaks.length - 2];
      int right = peaks[peaks.length - 1];
      
      return highs[head] > highs[left] && 
             highs[head] > highs[right] &&
             (highs[left] - highs[right]).abs() / highs[left] < 0.05; // Similar height
    }
    
    return false;
  }
  
  bool _isDoubleTop(List<ChartData> data) {
    if (data.length < 4) return false;
    
    List<double> highs = data.map((d) => d.high).toList();
    int n = highs.length;
    
    // Find two peaks
    int peak1 = -1, peak2 = -1;
    for (int i = 1; i < n - 1; i++) {
      if (highs[i] > highs[i-1] && highs[i] > highs[i+1]) {
        if (peak1 == -1) {
          peak1 = i;
        } else if (peak2 == -1 && i > peak1 + 5) {
          peak2 = i;
          break;
        }
      }
    }
    
    if (peak1 != -1 && peak2 != -1) {
      double diff = (highs[peak1] - highs[peak2]).abs();
      return diff / highs[peak1] < 0.03; // Within 3%
    }
    
    return false;
  }
  
  bool _isDoubleBottom(List<ChartData> data) {
    if (data.length < 4) return false;
    
    List<double> lows = data.map((d) => d.low).toList();
    int n = lows.length;
    
    // Find two troughs
    int trough1 = -1, trough2 = -1;
    for (int i = 1; i < n - 1; i++) {
      if (lows[i] < lows[i-1] && lows[i] < lows[i+1]) {
        if (trough1 == -1) {
          trough1 = i;
        } else if (trough2 == -1 && i > trough1 + 5) {
          trough2 = i;
          break;
        }
      }
    }
    
    if (trough1 != -1 && trough2 != -1) {
      double diff = (lows[trough1] - lows[trough2]).abs();
      return diff / lows[trough1] < 0.03; // Within 3%
    }
    
    return false;
  }
  
  Map<String, dynamic> _fallbackPrediction(List<double> historicalPrices) {
    // Simple moving average as fallback
    double sma = historicalPrices.takeLast(20).reduce((a, b) => a + b) / 20;
    double lastPrice = historicalPrices.last;
    double direction = sma > lastPrice ? 0.5 : -0.5;
    
    return {
      'predicted_price': sma,
      'confidence': 0.5,
      'direction': sma > lastPrice ? 'up' : 'down',
      'percentage_change': ((sma - lastPrice) / lastPrice) * 100,
    };
  }
  
  Map<String, dynamic> _fallbackSentiment(String newsText) {
    // Simple keyword-based sentiment as fallback
    List<String> positiveWords = ['up', 'gain', 'profit', 'growth', 'bullish', 'positive'];
    List<String> negativeWords = ['down', 'loss', 'risk', 'bearish', 'negative', 'crisis'];
    
    int positiveCount = 0;
    int negativeCount = 0;
    
    for (var word in newsText.toLowerCase().split(' ')) {
      if (positiveWords.contains(word)) positiveCount++;
      if (negativeWords.contains(word)) negativeCount++;
    }
    
    if (positiveCount > negativeCount) {
      return {
        'sentiment': 'positive',
        'score': positiveCount / (positiveCount + negativeCount),
        'positive': 0.7,
        'neutral': 0.2,
        'negative': 0.1,
      };
    } else if (negativeCount > positiveCount) {
      return {
        'sentiment': 'negative',
        'score': negativeCount / (positiveCount + negativeCount),
        'positive': 0.1,
        'neutral': 0.2,
        'negative': 0.7,
      };
    } else {
      return {
        'sentiment': 'neutral',
        'score': 0.5,
        'positive': 0.3,
        'neutral': 0.4,
        'negative': 0.3,
      };
    }
  }
  
  List<String> _tokenize(String text) {
    // Simple tokenization
    return text.toLowerCase()
        .replaceAll(RegExp(r'[^\w\s]'), '')
        .split(' ')
        .where((w) => w.length > 2)
        .toList();
  }
  
  List<List<double>> _encodeTokens(List<String> tokens) {
    // Simple one-hot encoding (would use proper embedding in production)
    // This is a placeholder
    return [List.filled(100, 0.0)];
  }
  
  double _calculateConfidence(double predicted, List<double> historical) {
    // Calculate confidence based on volatility
    double volatility = _calculateVolatility(historical);
    double error = (predicted - historical.last).abs() / historical.last;
    return 1.0 - (error / (volatility + 0.01));
  }
  
  double _calculateVolatility(List<double> prices) {
    if (prices.length < 2) return 0;
    
    double sum = 0;
    for (int i = 1; i < prices.length; i++) {
      sum += ((prices[i] - prices[i-1]) / prices[i-1]).abs();
    }
    return sum / (prices.length - 1);
  }
}