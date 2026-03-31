import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:stock_trading_app/services/ml_prediction_service.dart';

class ModelTrainingService {
  static final MLPredictionService _mlService = MLPredictionService();
  
  // Train new model with latest data
  static Future<void> trainNewModel({
    required List<String> symbols,
    required DateTime startDate,
    required DateTime endDate,
    required Map<String, dynamic> hyperparameters,
  }) async {
    // Fetch historical data for training
    final trainingData = await _fetchTrainingData(symbols, startDate, endDate);
    
    // Prepare features and labels
    final features = _prepareFeatures(trainingData);
    final labels = _prepareLabels(trainingData);
    
    // Split data into train/validation/test sets
    final splits = _splitData(features, labels);
    
    // Train ensemble model
    final model = await _trainEnsembleModel(splits.train, hyperparameters);
    
    // Validate model
    final metrics = await _validateModel(model, splits.validation);
    
    // Test model
    final testMetrics = await _testModel(model, splits.test);
    
    // Save model if performance is better than current
    if (testMetrics['accuracy'] > 0.7) {
      await _saveModel(model, metrics, testMetrics);
    }
    
    // Log training results
    await _logTrainingResults(metrics, testMetrics, hyperparameters);
  }
  
  // Fetch training data
  static Future<List<Map<String, dynamic>>> _fetchTrainingData(
    List<String> symbols,
    DateTime startDate,
    DateTime endDate,
  ) async {
    final data = <Map<String, dynamic>>[];
    
    for (var symbol in symbols) {
      final historicalData = await _getHistoricalData(symbol, startDate, endDate);
      data.add({
        'symbol': symbol,
        'data': historicalData,
      });
    }
    
    return data;
  }
  
  // Prepare features for model
  static List<List<double>> _prepareFeatures(List<Map<String, dynamic>> data) {
    final features = <List<double>>[];
    
    for (var item in data) {
      final prices = item['data'].map<double>((d) => d['close'] as double).toList();
      final volumes = item['data'].map<double>((d) => d['volume'] as double).toList();
      final technicals = _calculateTechnicalIndicators(prices);
      
      for (int i = 60; i < prices.length; i++) {
        final feature = <double>[];
        
        // Price features
        feature.addAll(prices.sublist(i - 60, i));
        
        // Volume features
        final maxVolume = volumes.reduce((a, b) => a > b ? a : b);
        feature.addAll(volumes.sublist(i - 60, i).map((v) => v / maxVolume));
        
        // Technical indicators
        feature.addAll(technicals.map((t) => t[i]));
        
        features.add(feature);
      }
    }
    
    return features;
  }
  
  // Prepare labels (future prices)
  static List<double> _prepareLabels(List<Map<String, dynamic>> data) {
    final labels = <double>[];
    
    for (var item in data) {
      final prices = item['data'].map<double>((d) => d['close'] as double).toList();
      
      for (int i = 60; i < prices.length - 1; i++) {
        final futurePrice = prices[i + 1];
        final label = (futurePrice - prices[i]) / prices[i];
        labels.add(label);
      }
    }
    
    return labels;
  }
  
  // Split data into train/validation/test
  static Map<String, dynamic> _splitData(List<List<double>> features, List<double> labels) {
    final indices = List.generate(features.length, (i) => i);
    indices.shuffle();
    
    final trainSize = (features.length * 0.7).floor();
    final valSize = (features.length * 0.15).floor();
    
    final trainIndices = indices.sublist(0, trainSize);
    final valIndices = indices.sublist(trainSize, trainSize + valSize);
    final testIndices = indices.sublist(trainSize + valSize);
    
    return {
      'train': {
        'features': trainIndices.map((i) => features[i]).toList(),
        'labels': trainIndices.map((i) => labels[i]).toList(),
      },
      'validation': {
        'features': valIndices.map((i) => features[i]).toList(),
        'labels': valIndices.map((i) => labels[i]).toList(),
      },
      'test': {
        'features': testIndices.map((i) => features[i]).toList(),
        'labels': testIndices.map((i) => labels[i]).toList(),
      },
    };
  }
  
  // Train ensemble model
  static Future<dynamic> _trainEnsembleModel(
    Map<String, dynamic> trainData,
    Map<String, dynamic> hyperparameters,
  ) async {
    // This would integrate with TensorFlow Lite training
    // For now, return mock model
    return {'type': 'ensemble', 'version': DateTime.now().toIso8601String()};
  }
  
  // Validate model
  static Future<Map<String, dynamic>> _validateModel(dynamic model, Map<String, dynamic> valData) async {
    final predictions = <double>[];
    
    for (var features in valData['features']) {
      final prediction = await _predictWithModel(model, features);
      predictions.add(prediction);
    }
    
    final actuals = valData['labels'] as List<double>;
    
    return {
      'mse': _calculateMSE(predictions, actuals),
      'mae': _calculateMAE(predictions, actuals),
      'rmse': sqrt(_calculateMSE(predictions, actuals)),
      'mape': _calculateMAPE(predictions, actuals),
      'r2': _calculateR2(predictions, actuals),
    };
  }
  
  // Test model
  static Future<Map<String, dynamic>> _testModel(dynamic model, Map<String, dynamic> testData) async {
    return await _validateModel(model, testData);
  }
  
  // Save model
  static Future<void> _saveModel(dynamic model, Map<String, dynamic> valMetrics, Map<String, dynamic> testMetrics) async {
    final appDir = await getApplicationDocumentsDirectory();
    final modelDir = Directory('${appDir.path}/models');
    
    if (!await modelDir.exists()) {
      await modelDir.create(recursive: true);
    }
    
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final modelPath = '${modelDir.path}/model_$timestamp.tflite';
    
    // Save model file
    // await model.save(modelPath);
    
    // Save metadata
    final metadata = {
      'version': timestamp,
      'created_at': DateTime.now().toIso8601String(),
      'validation_metrics': valMetrics,
      'test_metrics': testMetrics,
      'hyperparameters': {},
    };
    
    final metadataFile = File('${modelDir.path}/model_$timestamp.json');
    await metadataFile.writeAsString(jsonEncode(metadata));
  }
  
  // Log training results
  static Future<void> _logTrainingResults(
    Map<String, dynamic> valMetrics,
    Map<String, dynamic> testMetrics,
    Map<String, dynamic> hyperparameters,
  ) async {
    final logEntry = {
      'timestamp': DateTime.now().toIso8601String(),
      'validation_metrics': valMetrics,
      'test_metrics': testMetrics,
      'hyperparameters': hyperparameters,
    };
    
    final appDir = await getApplicationDocumentsDirectory();
    final logFile = File('${appDir.path}/training_logs.json');
    
    List<dynamic> logs = [];
    if (await logFile.exists()) {
      final content = await logFile.readAsString();
      logs = jsonDecode(content);
    }
    
    logs.add(logEntry);
    await logFile.writeAsString(jsonEncode(logs));
  }
  
  // Helper methods
  static Future<List<Map<String, dynamic>>> _getHistoricalData(
    String symbol,
    DateTime startDate,
    DateTime endDate,
  ) async {
    // Fetch from database or API
    return [];
  }
  
  static List<List<double>> _calculateTechnicalIndicators(List<double> prices) {
    // Calculate technical indicators for each point
    final indicators = <List<double>>[];
    
    for (int i = 0; i < prices.length; i++) {
      final window = prices.sublist(0, i + 1);
      indicators.add([
        _calculateRSI(window),
        _calculateMACD(window),
        _calculateSMA(window, 20),
        _calculateEMA(window, 20),
        _calculateBollingerUpper(window),
        _calculateBollingerLower(window),
        _calculateATR(window),
      ]);
    }
    
    return indicators;
  }
  
  static double _calculateRSI(List<double> prices) {
    if (prices.length < 15) return 50;
    // Simplified RSI calculation
    return 50;
  }
  
  static double _calculateMACD(List<double> prices) {
    if (prices.length < 26) return 0;
    // Simplified MACD calculation
    return 0;
  }
  
  static double _calculateSMA(List<double> prices, int period) {
    if (prices.length < period) return prices.last;
    final sum = prices.sublist(prices.length - period).reduce((a, b) => a + b);
    return sum / period;
  }
  
  static double _calculateEMA(List<double> prices, int period) {
    if (prices.length < period) return prices.last;
    // Simplified EMA calculation
    return prices.last;
  }
  
  static double _calculateBollingerUpper(List<double> prices) {
    if (prices.length < 20) return prices.last * 1.1;
    final sma = _calculateSMA(prices, 20);
    return sma * 1.1;
  }
  
  static double _calculateBollingerLower(List<double> prices) {
    if (prices.length < 20) return prices.last * 0.9;
    final sma = _calculateSMA(prices, 20);
    return sma * 0.9;
  }
  
  static double _calculateATR(List<double> prices) {
    if (prices.length < 15) return 0;
    // Simplified ATR calculation
    return (prices.last - prices[prices.length - 2]).abs();
  }
  
  static Future<double> _predictWithModel(dynamic model, List<double> features) async {
    // Run inference with model
    return features.last * (1 + 0.01 * Random().nextDouble());
  }
  
  static double _calculateMSE(List<double> predictions, List<double> actuals) {
    double sum = 0;
    for (int i = 0; i < predictions.length; i++) {
      sum += pow(predictions[i] - actuals[i], 2);
    }
    return sum / predictions.length;
  }
  
  static double _calculateMAE(List<double> predictions, List<double> actuals) {
    double sum = 0;
    for (int i = 0; i < predictions.length; i++) {
      sum += (predictions[i] - actuals[i]).abs();
    }
    return sum / predictions.length;
  }
  
  static double _calculateMAPE(List<double> predictions, List<double> actuals) {
    double sum = 0;
    for (int i = 0; i < predictions.length; i++) {
      sum += ((predictions[i] - actuals[i]) / actuals[i]).abs();
    }
    return (sum / predictions.length) * 100;
  }
  
  static double _calculateR2(List<double> predictions, List<double> actuals) {
    final mean = actuals.reduce((a, b) => a + b) / actuals.length;
    double ssRes = 0;
    double ssTot = 0;
    
    for (int i = 0; i < predictions.length; i++) {
      ssRes += pow(predictions[i] - actuals[i], 2);
      ssTot += pow(actuals[i] - mean, 2);
    }
    
    return 1 - (ssRes / ssTot);
  }
}