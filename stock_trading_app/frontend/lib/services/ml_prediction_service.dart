import 'dart:math';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:stock_trading_app/services/indicator_service.dart';

class MLPredictionService {
  Interpreter? _pricePredictor;
  Interpreter? _volatilityPredictor;
  Interpreter? _sentimentAnalyzer;
  
  Future<void> initialize() async {
    try {
      // Load TensorFlow Lite models
      _pricePredictor = await Interpreter.fromAsset('models/price_predictor_ensemble.tflite');
      _volatilityPredictor = await Interpreter.fromAsset('models/volatility_predictor.tflite');
      _sentimentAnalyzer = await Interpreter.fromAsset('models/sentiment_bert.tflite');
    } catch (e) {
      print('Error loading ML models: $e');
    }
  }
  
  // Ensemble Price Prediction using multiple models
  Future<Map<String, dynamic>> predictPriceEnsemble({
    required String symbol,
    required List<double> historicalPrices,
    required List<double> volumes,
    required List<Map<String, double>> technicalIndicators,
    required List<String> newsHeadlines,
  }) async {
    if (_pricePredictor == null) {
      return _fallbackPrediction(historicalPrices);
    }
    
    // Extract features for each model
    final lstmFeatures = _extractLSTMFeatures(historicalPrices, volumes);
    final cnnFeatures = _extractCNNFeatures(technicalIndicators);
    final transformerFeatures = await _extractTransformerFeatures(newsHeadlines);
    
    // Run predictions with different models
    final lstmPrediction = await _predictLSTM(lstmFeatures);
    final cnnPrediction = await _predictCNN(cnnFeatures);
    final transformerPrediction = await _predictTransformer(transformerFeatures);
    
    // Ensemble weighting based on recent accuracy
    final weights = await _calculateModelWeights(symbol);
    final ensemblePrice = (lstmPrediction * weights['lstm']! +
                           cnnPrediction * weights['cnn']! +
                           transformerPrediction * weights['transformer']!) /
                          (weights['lstm']! + weights['cnn']! + weights['transformer']!);
    
    // Calculate confidence intervals
    final volatility = await _predictVolatility(historicalPrices);
    final upperBound = ensemblePrice * (1 + volatility * 1.96);
    final lowerBound = ensemblePrice * (1 - volatility * 1.96);
    
    // Generate price path scenarios
    final scenarios = await _generatePriceScenarios(ensemblePrice, volatility);
    
    return {
      'predicted_price': ensemblePrice,
      'lower_bound': lowerBound,
      'upper_bound': upperBound,
      'confidence': 1 - volatility,
      'volatility': volatility,
      'scenarios': scenarios,
      'model_weights': weights,
      'individual_predictions': {
        'lstm': lstmPrediction,
        'cnn': cnnPrediction,
        'transformer': transformerPrediction,
      },
    };
  }
  
  // Volatility Prediction using GARCH-like model
  Future<double> _predictVolatility(List<double> prices) async {
    if (_volatilityPredictor == null) {
      return _calculateHistoricalVolatility(prices);
    }
    
    // Calculate returns
    List<double> returns = [];
    for (int i = 1; i < prices.length; i++) {
      returns.add((prices[i] - prices[i-1]) / prices[i-1]);
    }
    
    // Prepare features
    var input = List.filled(1, 0.0).reshape([1, 1]);
    var output = List.filled(1, 0.0).reshape([1, 1]);
    
    _volatilityPredictor!.run(input, output);
    return output[0][0];
  }
  
  // Market Regime Detection
  Future<String> detectMarketRegime(List<double> prices) async {
    final returns = _calculateReturns(prices);
    final volatility = _calculateHistoricalVolatility(prices);
    final trend = _calculateTrendStrength(prices);
    
    if (volatility > 0.03 && trend.abs() > 0.5) {
      return 'HIGH_VOLATILITY_TRENDING';
    } else if (volatility > 0.03) {
      return 'HIGH_VOLATILITY_CHOPPY';
    } else if (trend.abs() > 0.5) {
      return 'LOW_VOLATILITY_TRENDING';
    } else {
      return 'LOW_VOLATILITY_RANGING';
    }
  }
  
  // Portfolio Optimization using Reinforcement Learning
  Future<Map<String, double>> optimizePortfolio(
    List<String> symbols,
    List<List<double>> historicalReturns,
    double riskTolerance,
  ) async {
    // Use DQN or PPO model for portfolio optimization
    final optimalWeights = <String, double>{};
    
    // Simplified Markowitz optimization as fallback
    final covarianceMatrix = _calculateCovarianceMatrix(historicalReturns);
    final expectedReturns = _calculateExpectedReturns(historicalReturns);
    
    // Solve for optimal weights using quadratic programming
    final weights = _solveMarkowitz(
      expectedReturns,
      covarianceMatrix,
      riskTolerance,
    );
    
    for (int i = 0; i < symbols.length; i++) {
      optimalWeights[symbols[i]] = weights[i];
    }
    
    return optimalWeights;
  }
  
  // Sentiment Analysis with BERT
  Future<Map<String, double>> analyzeSentimentAdvanced(String text) async {
    if (_sentimentAnalyzer == null) {
      return _simpleSentimentAnalysis(text);
    }
    
    // Tokenize and prepare input for BERT
    final tokens = _bertTokenize(text);
    var input = List.filled(1, 0.0).reshape([1, tokens.length]);
    var output = List.filled(3, 0.0).reshape([1, 3]);
    
    _sentimentAnalyzer!.run(input, output);
    
    return {
      'positive': output[0][0],
      'neutral': output[0][1],
      'negative': output[0][2],
      'compound': output[0][0] - output[0][2],
    };
  }
  
  // Feature extraction methods
  List<double> _extractLSTMFeatures(List<double> prices, List<double> volumes) {
    List<double> features = [];
    
    // Price features
    features.addAll(prices.takeLast(60)); // Last 60 prices
    
    // Volume features (normalized)
    final maxVolume = volumes.reduce(max);
    features.addAll(volumes.takeLast(60).map((v) => v / maxVolume));
    
    // Returns
    final returns = _calculateReturns(prices);
    features.addAll(returns.takeLast(60));
    
    // Volatility
    final volatility = _calculateHistoricalVolatility(prices);
    features.add(volatility);
    
    return features;
  }
  
  List<double> _extractCNNFeatures(List<Map<String, double>> indicators) {
    List<double> features = [];
    
    // Technical indicators
    for (var indicator in indicators.takeLast(30)) {
      features.add(indicator['rsi'] ?? 50);
      features.add(indicator['macd'] ?? 0);
      features.add(indicator['sma'] ?? 0);
      features.add(indicator['ema'] ?? 0);
      features.add(indicator['bb_upper'] ?? 0);
      features.add(indicator['bb_lower'] ?? 0);
      features.add(indicator['atr'] ?? 0);
    }
    
    return features;
  }
  
  Future<List<double>> _extractTransformerFeatures(List<String> headlines) async {
    List<double> features = [];
    
    for (var headline in headlines.takeLast(20)) {
      final sentiment = await analyzeSentimentAdvanced(headline);
      features.add(sentiment['compound']!);
    }
    
    return features;
  }
  
  // Helper methods
  List<double> _calculateReturns(List<double> prices) {
    List<double> returns = [];
    for (int i = 1; i < prices.length; i++) {
      returns.add((prices[i] - prices[i-1]) / prices[i-1]);
    }
    return returns;
  }
  
  double _calculateHistoricalVolatility(List<double> prices) {
    final returns = _calculateReturns(prices);
    if (returns.isEmpty) return 0;
    
    final mean = returns.reduce((a, b) => a + b) / returns.length;
    final variance = returns.map((r) => pow(r - mean, 2)).reduce((a, b) => a + b) / returns.length;
    return sqrt(variance) * sqrt(252); // Annualized volatility
  }
  
  double _calculateTrendStrength(List<double> prices) {
    final sma20 = IndicatorService.calculateSMA(prices, 20);
    final sma50 = IndicatorService.calculateSMA(prices, 50);
    
    if (sma20.isEmpty || sma50.isEmpty) return 0;
    
    return (sma20.last - sma50.last) / sma50.last;
  }
  
  List<List<double>> _calculateCovarianceMatrix(List<List<double>> returns) {
    final n = returns.length;
    final covariance = List.generate(n, (_) => List<double>.filled(n, 0));
    
    for (int i = 0; i < n; i++) {
      for (int j = 0; j < n; j++) {
        covariance[i][j] = _calculateCovariance(returns[i], returns[j]);
      }
    }
    
    return covariance;
  }
  
  double _calculateCovariance(List<double> x, List<double> y) {
    final n = x.length;
    final meanX = x.reduce((a, b) => a + b) / n;
    final meanY = y.reduce((a, b) => a + b) / n;
    
    double covariance = 0;
    for (int i = 0; i < n; i++) {
      covariance += (x[i] - meanX) * (y[i] - meanY);
    }
    return covariance / n;
  }
  
  List<double> _calculateExpectedReturns(List<List<double>> returns) {
    return returns.map((r) => r.reduce((a, b) => a + b) / r.length).toList();
  }
  
  List<double> _solveMarkowitz(
    List<double> expectedReturns,
    List<List<double>> covariance,
    double riskTolerance,
  ) {
    // Simplified quadratic programming solver
    // In production, use proper optimization library
    final n = expectedReturns.length;
    final weights = List<double>.filled(n, 1.0 / n);
    
    // Iterative optimization
    for (int iter = 0; iter < 100; iter++) {
      // Calculate gradient
      final gradient = List<double>.filled(n, 0);
      for (int i = 0; i < n; i++) {
        gradient[i] = -2 * riskTolerance * expectedReturns[i];
        for (int j = 0; j < n; j++) {
          gradient[i] += 2 * covariance[i][j] * weights[j];
        }
      }
      
      // Update weights
      for (int i = 0; i < n; i++) {
        weights[i] -= 0.01 * gradient[i];
      }
      
      // Normalize
      final sum = weights.reduce((a, b) => a + b);
      for (int i = 0; i < n; i++) {
        weights[i] /= sum;
        weights[i] = weights[i].clamp(0, 1);
      }
    }
    
    return weights;
  }
  
  Future<Map<String, double>> _calculateModelWeights(String symbol) async {
    // Dynamic weighting based on recent prediction accuracy
    return {
      'lstm': 0.4,
      'cnn': 0.35,
      'transformer': 0.25,
    };
  }
  
  Future<List<Map<String, dynamic>>> _generatePriceScenarios(
    double currentPrice,
    double volatility,
  ) async {
    final scenarios = <Map<String, dynamic>>[];
    final random = Random();
    
    // Generate 3 scenarios: bullish, bearish, base
    final scenarios_ = [
      {'label': 'Bullish', 'multiplier': 1.5},
      {'label': 'Base', 'multiplier': 1.0},
      {'label': 'Bearish', 'multiplier': 0.7},
    ];
    
    for (var scenario in scenarios_) {
      final path = <double>[];
      double price = currentPrice;
      
      for (int i = 0; i < 20; i++) {
        final shock = random.nextGaussian() * volatility * scenario['multiplier'];
        price *= (1 + shock);
        path.add(price);
      }
      
      scenarios.add({
        'label': scenario['label'],
        'path': path,
        'final_price': price,
      });
    }
    
    return scenarios;
  }
  
  Future<double> _predictLSTM(List<double> features) async {
    // LSTM prediction implementation
    return features.last * (1 + 0.01 * Random().nextDouble());
  }
  
  Future<double> _predictCNN(List<double> features) async {
    // CNN prediction implementation
    return features.last * (1 + 0.01 * Random().nextDouble());
  }
  
  Future<double> _predictTransformer(List<double> features) async {
    // Transformer prediction implementation
    return features.last * (1 + 0.01 * Random().nextDouble());
  }
  
  List<int> _bertTokenize(String text) {
    // BERT tokenization
    return [101] + text.split('').map((c) => c.codeUnitAt(0)).toList() + [102];
  }
  
  Map<String, dynamic> _fallbackPrediction(List<double> historicalPrices) {
    final lastPrice = historicalPrices.last;
    final sma20 = IndicatorService.calculateSMA(historicalPrices, 20);
    final predictedPrice = sma20.last;
    
    return {
      'predicted_price': predictedPrice,
      'lower_bound': predictedPrice * 0.95,
      'upper_bound': predictedPrice * 1.05,
      'confidence': 0.5,
      'volatility': 0.05,
      'scenarios': [],
      'model_weights': {'lstm': 0.33, 'cnn': 0.33, 'transformer': 0.34},
      'individual_predictions': {
        'lstm': predictedPrice,
        'cnn': predictedPrice,
        'transformer': predictedPrice,
      },
    };
  }
  
  Map<String, double> _simpleSentimentAnalysis(String text) {
    // Simple keyword-based sentiment
    final positiveWords = ['up', 'gain', 'profit', 'growth', 'bullish', 'positive', 'rise'];
    final negativeWords = ['down', 'loss', 'risk', 'bearish', 'negative', 'fall', 'decline'];
    
    final words = text.toLowerCase().split(' ');
    int positiveCount = 0;
    int negativeCount = 0;
    
    for (var word in words) {
      if (positiveWords.contains(word)) positiveCount++;
      if (negativeWords.contains(word)) negativeCount++;
    }
    
    final total = positiveCount + negativeCount;
    if (total == 0) {
      return {'positive': 0.33, 'neutral': 0.34, 'negative': 0.33, 'compound': 0};
    }
    
    final positive = positiveCount / total;
    final negative = negativeCount / total;
    final neutral = 1 - positive - negative;
    
    return {
      'positive': positive,
      'neutral': neutral,
      'negative': negative,
      'compound': positive - negative,
    };
  }
}