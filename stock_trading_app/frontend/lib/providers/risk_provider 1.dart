import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stock_trading_app/models/position.dart';
import 'package:stock_trading_app/services/api_service.dart';

class RiskMetrics {
  final double totalExposure;
  final double maxDrawdown;
  final double sharpeRatio;
  final double volatility;
  final double concentrationRisk;
  final double maxConcentration;
  final double maxPositionSize;
  final double maxDailyLoss;
  final double currentDailyLoss;
  final double stopLoss;
  final int maxLeverage;
  final double var95; // Value at Risk 95%
  final double expectedShortfall;
  final double beta;
  final double alpha;
  final double sortinoRatio;
  final double calmarRatio;

  RiskMetrics({
    required this.totalExposure,
    required this.maxDrawdown,
    required this.sharpeRatio,
    required this.volatility,
    required this.concentrationRisk,
    required this.maxConcentration,
    required this.maxPositionSize,
    required this.maxDailyLoss,
    required this.currentDailyLoss,
    required this.stopLoss,
    required this.maxLeverage,
    required this.var95,
    required this.expectedShortfall,
    required this.beta,
    required this.alpha,
    required this.sortinoRatio,
    required this.calmarRatio,
  });

  factory RiskMetrics.initial() {
    return RiskMetrics(
      totalExposure: 0,
      maxDrawdown: 0,
      sharpeRatio: 0,
      volatility: 0,
      concentrationRisk: 0,
      maxConcentration: 0.25,
      maxPositionSize: 0.10,
      maxDailyLoss: 0.02,
      currentDailyLoss: 0,
      stopLoss: 0.05,
      maxLeverage: 3,
      var95: 0,
      expectedShortfall: 0,
      beta: 1,
      alpha: 0,
      sortinoRatio: 0,
      calmarRatio: 0,
    );
  }

  RiskMetrics copyWith({
    double? totalExposure,
    double? maxDrawdown,
    double? sharpeRatio,
    double? volatility,
    double? concentrationRisk,
    double? maxConcentration,
    double? maxPositionSize,
    double? maxDailyLoss,
    double? currentDailyLoss,
    double? stopLoss,
    int? maxLeverage,
    double? var95,
    double? expectedShortfall,
    double? beta,
    double? alpha,
    double? sortinoRatio,
    double? calmarRatio,
  }) {
    return RiskMetrics(
      totalExposure: totalExposure ?? this.totalExposure,
      maxDrawdown: maxDrawdown ?? this.maxDrawdown,
      sharpeRatio: sharpeRatio ?? this.sharpeRatio,
      volatility: volatility ?? this.volatility,
      concentrationRisk: concentrationRisk ?? this.concentrationRisk,
      maxConcentration: maxConcentration ?? this.maxConcentration,
      maxPositionSize: maxPositionSize ?? this.maxPositionSize,
      maxDailyLoss: maxDailyLoss ?? this.maxDailyLoss,
      currentDailyLoss: currentDailyLoss ?? this.currentDailyLoss,
      stopLoss: stopLoss ?? this.stopLoss,
      maxLeverage: maxLeverage ?? this.maxLeverage,
      var95: var95 ?? this.var95,
      expectedShortfall: expectedShortfall ?? this.expectedShortfall,
      beta: beta ?? this.beta,
      alpha: alpha ?? this.alpha,
      sortinoRatio: sortinoRatio ?? this.sortinoRatio,
      calmarRatio: calmarRatio ?? this.calmarRatio,
    );
  }
}

final riskProvider = StateNotifierProvider<RiskNotifier, RiskMetrics>((ref) {
  return RiskNotifier();
});

class RiskNotifier extends StateNotifier<RiskMetrics> {
  final ApiService _apiService = ApiService();
  List<double> _historicalReturns = [];

  RiskNotifier() : super(RiskMetrics.initial());

  void updateMaxPositionSize(double value) {
    state = state.copyWith(maxPositionSize: value);
    _saveRiskLimits();
  }

  void updateMaxDailyLoss(double value) {
    state = state.copyWith(maxDailyLoss: value);
    _saveRiskLimits();
  }

  void updateStopLoss(double value) {
    state = state.copyWith(stopLoss: value);
    _saveRiskLimits();
  }

  void updateMaxLeverage(int value) {
    state = state.copyWith(maxLeverage: value);
    _saveRiskLimits();
  }

  void updateMaxConcentration(double value) {
    state = state.copyWith(maxConcentration: value);
    _saveRiskLimits();
  }

  Future<void> _saveRiskLimits() async {
    try {
      await _apiService.updateRiskLimits({
        'maxPositionSize': state.maxPositionSize,
        'maxDailyLoss': state.maxDailyLoss,
        'stopLoss': state.stopLoss,
        'maxLeverage': state.maxLeverage,
        'maxConcentration': state.maxConcentration,
      });
    } catch (e) {
      print('Error saving risk limits: $e');
    }
  }

  void updateMetricsFromPositions(List<Position> positions) async {
    if (positions.isEmpty) {
      state = RiskMetrics.initial();
      return;
    }

    // Calculate total exposure
    double totalExposure = 0;
    Map<String, double> sectorExposure = {};
    List<double> positionValues = [];

    for (var position in positions) {
      double positionValue = position.quantity * position.currentPrice;
      totalExposure += positionValue;
      positionValues.add(positionValue);
      
      // Track sector exposure (simplified - would need sector data)
      String sector = await _getSectorForSymbol(position.symbol);
      sectorExposure[sector] = (sectorExposure[sector] ?? 0) + positionValue;
    }

    // Calculate concentration risk (Herfindahl index)
    double concentrationRisk = 0;
    for (var value in positionValues) {
      double weight = value / totalExposure;
      concentrationRisk += weight * weight;
    }

    // Calculate volatility from historical returns
    double volatility = _calculateVolatility();
    
    // Calculate Sharpe ratio
    double sharpeRatio = _calculateSharpeRatio(volatility);
    
    // Calculate Sortino ratio (downside risk)
    double sortinoRatio = _calculateSortinoRatio();
    
    // Calculate Calmar ratio
    double calmarRatio = _calculateCalmarRatio();
    
    // Calculate VaR (Value at Risk)
    double var95 = _calculateVaR(0.95);
    
    // Calculate Expected Shortfall
    double expectedShortfall = _calculateExpectedShortfall(0.95);
    
    // Calculate Beta (market correlation)
    double beta = await _calculateBeta(positions);
    
    // Calculate Alpha (excess return)
    double alpha = await _calculateAlpha(beta);
    
    // Calculate current daily loss
    double currentDailyLoss = _calculateDailyLoss(positions);

    state = state.copyWith(
      totalExposure: totalExposure,
      concentrationRisk: concentrationRisk,
      volatility: volatility,
      sharpeRatio: sharpeRatio,
      sortinoRatio: sortinoRatio,
      calmarRatio: calmarRatio,
      var95: var95,
      expectedShortfall: expectedShortfall,
      beta: beta,
      alpha: alpha,
      currentDailyLoss: currentDailyLoss,
    );
  }

  double _calculateVolatility() {
    if (_historicalReturns.length < 2) return 0;
    
    double mean = _historicalReturns.reduce((a, b) => a + b) / _historicalReturns.length;
    double variance = _historicalReturns.map((r) => (r - mean) * (r - mean)).reduce((a, b) => a + b) / (_historicalReturns.length - 1);
    return variance.sqrt();
  }

  double _calculateSharpeRatio(double volatility) {
    if (volatility == 0) return 0;
    double averageReturn = _historicalReturns.isEmpty ? 0 : 
        _historicalReturns.reduce((a, b) => a + b) / _historicalReturns.length;
    double riskFreeRate = 0.02; // 2% risk-free rate
    return (averageReturn - riskFreeRate) / volatility;
  }

  double _calculateSortinoRatio() {
    if (_historicalReturns.isEmpty) return 0;
    
    double averageReturn = _historicalReturns.reduce((a, b) => a + b) / _historicalReturns.length;
    double downsideVariance = _historicalReturns
        .where((r) => r < 0)
        .map((r) => (r - averageReturn) * (r - averageReturn))
        .reduce((a, b) => a + b);
    
    double downsideDeviation = downsideVariance.sqrt();
    double riskFreeRate = 0.02;
    
    return downsideDeviation == 0 ? 0 : (averageReturn - riskFreeRate) / downsideDeviation;
  }

  double _calculateCalmarRatio() {
    if (_historicalReturns.isEmpty || state.maxDrawdown == 0) return 0;
    double annualizedReturn = _historicalReturns.reduce((a, b) => a + b) / _historicalReturns.length * 252;
    return annualizedReturn / state.maxDrawdown;
  }

  double _calculateVaR(double confidenceLevel) {
    if (_historicalReturns.isEmpty) return 0;
    List<double> sortedReturns = List.from(_historicalReturns)..sort();
    int index = (confidenceLevel * sortedReturns.length).floor();
    return sortedReturns[index];
  }

  double _calculateExpectedShortfall(double confidenceLevel) {
    if (_historicalReturns.isEmpty) return 0;
    List<double> sortedReturns = List.from(_historicalReturns)..sort();
    int varIndex = (confidenceLevel * sortedReturns.length).floor();
    double sum = 0;
    for (int i = varIndex; i < sortedReturns.length; i++) {
      sum += sortedReturns[i];
    }
    return sum / (sortedReturns.length - varIndex);
  }

  Future<double> _calculateBeta(List<Position> positions) async {
    // Fetch market returns (e.g., NIFTY or S&P 500)
    List<double> marketReturns = await _apiService.getMarketReturns();
    if (marketReturns.isEmpty || _historicalReturns.isEmpty) return 1;
    
    double covariance = _calculateCovariance(_historicalReturns, marketReturns);
    double marketVariance = _calculateVariance(marketReturns);
    
    return marketVariance == 0 ? 1 : covariance / marketVariance;
  }

  Future<double> _calculateAlpha(double beta) async {
    double portfolioReturn = _historicalReturns.isEmpty ? 0 : 
        _historicalReturns.reduce((a, b) => a + b) / _historicalReturns.length;
    List<double> marketReturns = await _apiService.getMarketReturns();
    double marketReturn = marketReturns.isEmpty ? 0 : 
        marketReturns.reduce((a, b) => a + b) / marketReturns.length;
    double riskFreeRate = 0.02;
    
    return portfolioReturn - (riskFreeRate + beta * (marketReturn - riskFreeRate));
  }

  double _calculateCovariance(List<double> x, List<double> y) {
    int n = x.length < y.length ? x.length : y.length;
    if (n == 0) return 0;
    
    double meanX = x.take(n).reduce((a, b) => a + b) / n;
    double meanY = y.take(n).reduce((a, b) => a + b) / n;
    
    double covariance = 0;
    for (int i = 0; i < n; i++) {
      covariance += (x[i] - meanX) * (y[i] - meanY);
    }
    return covariance / n;
  }

  double _calculateVariance(List<double> values) {
    if (values.isEmpty) return 0;
    double mean = values.reduce((a, b) => a + b) / values.length;
    double variance = values.map((v) => (v - mean) * (v - mean)).reduce((a, b) => a + b);
    return variance / values.length;
  }

  double _calculateDailyLoss(List<Position> positions) {
    // Calculate today's P&L
    double todayPnL = 0;
    for (var position in positions) {
      // Assuming we have yesterday's price
      double yesterdayPrice = position.currentPrice / (1 + 0.01); // Placeholder
      todayPnL += position.quantity * (position.currentPrice - yesterdayPrice);
    }
    return todayPnL / state.totalExposure;
  }

  Future<String> _getSectorForSymbol(String symbol) async {
    // Fetch sector from API or local database
    // This is a simplified implementation
    Map<String, String> sectorMap = {
      'AAPL': 'Technology',
      'GOOGL': 'Technology',
      'MSFT': 'Technology',
      'AMZN': 'Consumer Cyclical',
      'TSLA': 'Automotive',
      'JPM': 'Financial',
      'JNJ': 'Healthcare',
    };
    return sectorMap[symbol] ?? 'Other';
  }

  void updateHistoricalReturns(List<double> returns) {
    _historicalReturns = returns;
  }
}

extension on double {
  double sqrt() => math.sqrt(this);
}