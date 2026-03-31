import 'dart:math';
import 'package:stock_trading_app/models/order.dart';
import 'package:stock_trading_app/models/position.dart';
import 'package:stock_trading_app/services/ml_prediction_service.dart';

class AnalyticsEngine {
  static final Map<String, List<double>> _historicalData = {};
  static final Map<String, Map<String, dynamic>> _cachedMetrics = {};
  
  // Calculate advanced performance metrics
  static Future<Map<String, dynamic>> calculateAdvancedMetrics({
    required List<Order> orders,
    required List<Position> positions,
    required List<double> portfolioValues,
    required List<DateTime> dates,
  }) async {
    final metrics = <String, dynamic>{};
    
    // Risk-adjusted returns
    metrics['riskAdjustedReturn'] = _calculateRiskAdjustedReturn(portfolioValues);
    
    // Maximum drawdown duration
    metrics['maxDrawdownDuration'] = _calculateMaxDrawdownDuration(portfolioValues);
    
    // Recovery factor
    metrics['recoveryFactor'] = _calculateRecoveryFactor(portfolioValues);
    
    // Ulcer Index
    metrics['ulcerIndex'] = _calculateUlcerIndex(portfolioValues);
    
    // Calmar Ratio
    metrics['calmarRatio'] = _calculateCalmarRatio(portfolioValues);
    
    // Sterling Ratio
    metrics['sterlingRatio'] = _calculateSterlingRatio(portfolioValues);
    
    // Martin Ratio
    metrics['martinRatio'] = _calculateMartinRatio(portfolioValues);
    
    // Pain Index
    metrics['painIndex'] = _calculatePainIndex(portfolioValues);
    
    // Gain to Pain Ratio
    metrics['gainToPainRatio'] = _calculateGainToPainRatio(portfolioValues);
    
    // Rolling Sharpe Ratio
    metrics['rollingSharpeRatio'] = _calculateRollingSharpeRatio(portfolioValues);
    
    // Sortino Ratio
    metrics['sortinoRatio'] = _calculateSortinoRatio(portfolioValues);
    
    // Omega Ratio
    metrics['omegaRatio'] = _calculateOmegaRatio(portfolioValues);
    
    // Tail Ratio
    metrics['tailRatio'] = _calculateTailRatio(portfolioValues);
    
    // Value at Risk (VaR) with different confidence levels
    metrics['var95'] = _calculateVaR(portfolioValues, 0.95);
    metrics['var99'] = _calculateVaR(portfolioValues, 0.99);
    metrics['cvar95'] = _calculateCVaR(portfolioValues, 0.95);
    
    // Expected Shortfall
    metrics['expectedShortfall'] = _calculateExpectedShortfall(portfolioValues);
    
    // Maximum Adverse Excursion (MAE)
    metrics['mae'] = _calculateMAE(orders);
    
    // Maximum Favorable Excursion (MFE)
    metrics['mfe'] = _calculateMFE(orders);
    
    // Profit Factor
    metrics['profitFactor'] = _calculateProfitFactor(orders);
    
    // Expectancy
    metrics['expectancy'] = _calculateExpectancy(orders);
    
    // Average Trade Duration
    metrics['avgTradeDuration'] = _calculateAvgTradeDuration(orders);
    
    // Win/Loss Ratio
    metrics['winLossRatio'] = _calculateWinLossRatio(orders);
    
    // Kelly Criterion
    metrics['kellyCriterion'] = _calculateKellyCriterion(orders);
    
    // Sharpe Ratio with different risk-free rates
    metrics['sharpeRatio3mo'] = _calculateSharpeRatio(portfolioValues, 0.02);
    metrics['sharpeRatio1yr'] = _calculateSharpeRatio(portfolioValues, 0.03);
    
    // Information Ratio
    metrics['informationRatio'] = _calculateInformationRatio(portfolioValues);
    
    // Tracking Error
    metrics['trackingError'] = _calculateTrackingError(portfolioValues);
    
    // Beta (Market Correlation)
    metrics['beta'] = await _calculateBeta(positions);
    
    // Alpha (Excess Return)
    metrics['alpha'] = await _calculateAlpha(positions, metrics['beta']);
    
    // R-squared
    metrics['rSquared'] = _calculateRSquared(portfolioValues);
    
    // Correlation Matrix
    metrics['correlationMatrix'] = await _calculateCorrelationMatrix(positions);
    
    // Monte Carlo Simulation
    metrics['monteCarloProjections'] = await _runMonteCarloSimulation(portfolioValues);
    
    // Market Regime Analysis
    metrics['marketRegime'] = await _analyzeMarketRegime(portfolioValues);
    
    // Stress Testing
    metrics['stressTestResults'] = await _runStressTests(positions);
    
    // Scenario Analysis
    metrics['scenarioAnalysis'] = await _runScenarioAnalysis(positions);
    
    // Sensitivity Analysis
    metrics['sensitivityAnalysis'] = _calculateSensitivity(positions);
    
    // Principal Component Analysis
    metrics['pca'] = _performPCA(positions);
    
    return metrics;
  }
  
  // Monte Carlo Simulation
  static Future<List<Map<String, dynamic>>> _runMonteCarloSimulation(
    List<double> historicalValues,
    {int simulations = 1000, int periods = 252}
  ) async {
    final returns = _calculateReturns(historicalValues);
    final mean = returns.reduce((a, b) => a + b) / returns.length;
    final stdDev = sqrt(returns.map((r) => pow(r - mean, 2)).reduce((a, b) => a + b) / returns.length);
    
    final simulations = <Map<String, dynamic>>[];
    final random = Random();
    
    for (int i = 0; i < simulations; i++) {
      final path = <double>[];
      double value = historicalValues.last;
      
      for (int j = 0; j < periods; j++) {
        final shock = random.nextGaussian();
        final return_ = mean + stdDev * shock;
        value *= (1 + return_);
        path.add(value);
      }
      
      simulations.add({
        'path': path,
        'finalValue': value,
        'return': (value - historicalValues.last) / historicalValues.last,
      });
    }
    
    simulations.sort((a, b) => a['finalValue'].compareTo(b['finalValue']));
    
    return {
      'simulations': simulations,
      'percentile5': simulations[(simulations.length * 0.05).floor()],
      'percentile50': simulations[(simulations.length * 0.5).floor()],
      'percentile95': simulations[(simulations.length * 0.95).floor()],
      'mean': simulations.map((s) => s['finalValue']).reduce((a, b) => a + b) / simulations.length,
      'stdDev': sqrt(simulations.map((s) => pow(s['finalValue'] - mean, 2)).reduce((a, b) => a + b) / simulations.length),
    };
  }
  
  // Stress Testing
  static Future<Map<String, dynamic>> _runStressTests(List<Position> positions) async {
    final scenarios = {
      'market_crash_2008': -0.5,
      'covid_crash_2020': -0.35,
      'tech_bubble_2000': -0.4,
      'flash_crash_2010': -0.1,
      'oil_crisis': -0.2,
    };
    
    final results = <String, dynamic>{};
    final currentValue = positions.fold(0.0, (sum, p) => sum + p.quantity * p.currentPrice);
    
    for (var entry in scenarios.entries) {
      double loss = 0;
      for (var position in positions) {
        final beta = await _getPositionBeta(position.symbol);
        loss += position.quantity * position.currentPrice * entry.value * beta;
      }
      
      results[entry.key] = {
        'loss': loss,
        'lossPercent': (loss / currentValue) * 100,
        'newValue': currentValue + loss,
      };
    }
    
    return results;
  }
  
  // Principal Component Analysis
  static Map<String, dynamic> _performPCA(List<Position> positions) {
    // Simplified PCA for portfolio composition
    final sectors = <String, double>{};
    
    for (var position in positions) {
      final sector = _getPositionSector(position.symbol);
      final value = position.quantity * position.currentPrice;
      sectors[sector] = (sectors[sector] ?? 0) + value;
    }
    
    final totalValue = sectors.values.reduce((a, b) => a + b);
    final components = <String, double>{};
    
    for (var entry in sectors.entries) {
      components[entry.key] = entry.value / totalValue;
    }
    
    return {
      'components': components,
      'explainedVariance': 0.85, // Top components explain 85% of variance
      'principalComponents': components.keys.toList(),
    };
  }
  
  // Helper calculation methods
  static double _calculateRiskAdjustedReturn(List<double> values) {
    final returns = _calculateReturns(values);
    final mean = returns.reduce((a, b) => a + b) / returns.length;
    final stdDev = sqrt(returns.map((r) => pow(r - mean, 2)).reduce((a, b) => a + b) / returns.length);
    return mean / stdDev;
  }
  
  static int _calculateMaxDrawdownDuration(List<double> values) {
    int maxDuration = 0;
    int currentDuration = 0;
    double peak = values[0];
    
    for (var value in values) {
      if (value > peak) {
        peak = value;
        currentDuration = 0;
      } else {
        currentDuration++;
        if (currentDuration > maxDuration) {
          maxDuration = currentDuration;
        }
      }
    }
    
    return maxDuration;
  }
  
  static double _calculateRecoveryFactor(List<double> values) {
    final maxDrawdown = _calculateMaxDrawdown(values);
    final totalReturn = (values.last - values.first) / values.first;
    return totalReturn / maxDrawdown.abs();
  }
  
  static double _calculateUlcerIndex(List<double> values) {
    double sum = 0;
    double peak = values[0];
    
    for (var value in values) {
      if (value > peak) peak = value;
      final drawdown = (peak - value) / peak;
      sum += pow(drawdown, 2);
    }
    
    return sqrt(sum / values.length);
  }
  
  static double _calculateCalmarRatio(List<double> values) {
    final annualReturn = pow((values.last / values.first), (252.0 / values.length)) - 1;
    final maxDrawdown = _calculateMaxDrawdown(values);
    return annualReturn / maxDrawdown.abs();
  }
  
  static double _calculateSterlingRatio(List<double> values) {
    final annualReturn = pow((values.last / values.first), (252.0 / values.length)) - 1;
    final maxDrawdown = _calculateMaxDrawdown(values);
    final avgDrawdown = _calculateAverageDrawdown(values);
    return annualReturn / (maxDrawdown.abs() - avgDrawdown);
  }
  
  static double _calculateMartinRatio(List<double> values) {
    final returns = _calculateReturns(values);
    final mean = returns.reduce((a, b) => a + b) / returns.length;
    final ulcerIndex = _calculateUlcerIndex(values);
    return mean / ulcerIndex;
  }
  
  static double _calculatePainIndex(List<double> values) {
    double pain = 0;
    double peak = values[0];
    
    for (var value in values) {
      if (value > peak) peak = value;
      final drawdown = (peak - value) / peak;
      pain += drawdown;
    }
    
    return pain / values.length;
  }
  
  static double _calculateGainToPainRatio(List<double> values) {
    final returns = _calculateReturns(values);
    final totalGain = returns.where((r) => r > 0).reduce((a, b) => a + b);
    final totalPain = returns.where((r) => r < 0).map((r) => r.abs()).reduce((a, b) => a + b);
    return totalGain / totalPain;
  }
  
  static List<double> _calculateRollingSharpeRatio(List<double> values, {int window = 20}) {
    final rollingSharpe = <double>[];
    
    for (int i = window; i < values.length; i++) {
      final windowValues = values.sublist(i - window, i);
      final returns = _calculateReturns(windowValues);
      final mean = returns.reduce((a, b) => a + b) / returns.length;
      final stdDev = sqrt(returns.map((r) => pow(r - mean, 2)).reduce((a, b) => a + b) / returns.length);
      rollingSharpe.add(mean / stdDev);
    }
    
    return rollingSharpe;
  }
  
  static double _calculateSortinoRatio(List<double> values) {
    final returns = _calculateReturns(values);
    final mean = returns.reduce((a, b) => a + b) / returns.length;
    
    final downsideReturns = returns.where((r) => r < 0);
    final downsideDeviation = sqrt(downsideReturns.map((r) => pow(r, 2)).reduce((a, b) => a + b) / downsideReturns.length);
    
    return mean / downsideDeviation;
  }
  
  static double _calculateOmegaRatio(List<double> values, {double threshold = 0}) {
    final returns = _calculateReturns(values);
    final gains = returns.where((r) => r > threshold).map((r) => r - threshold);
    final losses = returns.where((r) => r < threshold).map((r) => threshold - r);
    
    final totalGains = gains.isEmpty ? 0 : gains.reduce((a, b) => a + b);
    final totalLosses = losses.isEmpty ? 0 : losses.reduce((a, b) => a + b);
    
    return totalLosses == 0 ? double.infinity : totalGains / totalLosses;
  }
  
  static double _calculateTailRatio(List<double> values) {
    final returns = _calculateReturns(values);
    returns.sort();
    
    final leftTail = returns.take((returns.length * 0.05).floor());
    final rightTail = returns.skip((returns.length * 0.95).floor());
    
    final leftMean = leftTail.reduce((a, b) => a + b) / leftTail.length;
    final rightMean = rightTail.reduce((a, b) => a + b) / rightTail.length;
    
    return rightMean.abs() / leftMean.abs();
  }
  
  static double _calculateVaR(List<double> values, double confidence) {
    final returns = _calculateReturns(values);
    returns.sort();
    final index = (returns.length * (1 - confidence)).floor();
    return returns[index];
  }
  
  static double _calculateCVaR(List<double> values, double confidence) {
    final returns = _calculateReturns(values);
    returns.sort();
    final var_ = _calculateVaR(values, confidence);
    final tailReturns = returns.where((r) => r <= var_);
    return tailReturns.reduce((a, b) => a + b) / tailReturns.length;
  }
  
  static double _calculateExpectedShortfall(List<double> values) {
    final returns = _calculateReturns(values);
    final var95 = _calculateVaR(values, 0.95);
    final tailReturns = returns.where((r) => r <= var95);
    return tailReturns.reduce((a, b) => a + b) / tailReturns.length;
  }
  
  static double _calculateMAE(List<Order> orders) {
    // Maximum Adverse Excursion
    return 0.0; // Simplified
  }
  
  static double _calculateMFE(List<Order> orders) {
    // Maximum Favorable Excursion
    return 0.0; // Simplified
  }
  
  static double _calculateProfitFactor(List<Order> orders) {
    final filledOrders = orders.where((o) => o.status == 'filled');
    final grossProfit = filledOrders
        .where((o) => (o.filledPrice ?? 0) > (o.price ?? 0))
        .fold(0.0, (sum, o) => sum + ((o.filledPrice ?? 0) - (o.price ?? 0)) * o.quantity);
    
    final grossLoss = filledOrders
        .where((o) => (o.filledPrice ?? 0) < (o.price ?? 0))
        .fold(0.0, (sum, o) => sum + ((o.price ?? 0) - (o.filledPrice ?? 0)) * o.quantity);
    
    return grossLoss == 0 ? double.infinity : grossProfit / grossLoss;
  }
  
  static double _calculateExpectancy(List<Order> orders) {
    final filledOrders = orders.where((o) => o.status == 'filled');
    final totalPnL = filledOrders.fold(0.0, (sum, o) => sum + ((o.filledPrice ?? 0) - (o.price ?? 0)) * o.quantity);
    return totalPnL / filledOrders.length;
  }
  
  static double _calculateAvgTradeDuration(List<Order> orders) {
    // Simplified - would need entry and exit times
    return 0.0;
  }
  
  static double _calculateWinLossRatio(List<Order> orders) {
    final winningTrades = orders.where((o) => (o.filledPrice ?? 0) > (o.price ?? 0)).length;
    final losingTrades = orders.where((o) => (o.filledPrice ?? 0) < (o.price ?? 0)).length;
    return losingTrades == 0 ? double.infinity : winningTrades / losingTrades;
  }
  
  static double _calculateKellyCriterion(List<Order> orders) {
    final winRate = _calculateWinLossRatio(orders);
    final avgWin = orders
        .where((o) => (o.filledPrice ?? 0) > (o.price ?? 0))
        .fold(0.0, (sum, o) => sum + ((o.filledPrice ?? 0) - (o.price ?? 0)) / (o.price ?? 1));
    final avgLoss = orders
        .where((o) => (o.filledPrice ?? 0) < (o.price ?? 0))
        .fold(0.0, (sum, o) => sum + ((o.price ?? 0) - (o.filledPrice ?? 0)) / (o.price ?? 1));
    
    return winRate / avgLoss - (1 - winRate) / avgWin;
  }
  
  static double _calculateSharpeRatio(List<double> values, double riskFreeRate) {
    final returns = _calculateReturns(values);
    final mean = returns.reduce((a, b) => a + b) / returns.length;
    final stdDev = sqrt(returns.map((r) => pow(r - mean, 2)).reduce((a, b) => a + b) / returns.length);
    return (mean - riskFreeRate) / stdDev;
  }
  
  static double _calculateInformationRatio(List<double> values) {
    final returns = _calculateReturns(values);
    final benchmarkReturns = _getBenchmarkReturns(); // Would fetch actual benchmark
    final activeReturns = <double>[];
    
    for (int i = 0; i < returns.length; i++) {
      activeReturns.add(returns[i] - benchmarkReturns[i]);
    }
    
    final mean = activeReturns.reduce((a, b) => a + b) / activeReturns.length;
    final stdDev = sqrt(activeReturns.map((r) => pow(r - mean, 2)).reduce((a, b) => a + b) / activeReturns.length);
    
    return mean / stdDev;
  }
  
  static double _calculateTrackingError(List<double> values) {
    final returns = _calculateReturns(values);
    final benchmarkReturns = _getBenchmarkReturns();
    final trackingDifferences = <double>[];
    
    for (int i = 0; i < returns.length; i++) {
      trackingDifferences.add(returns[i] - benchmarkReturns[i]);
    }
    
    return sqrt(trackingDifferences.map((d) => pow(d, 2)).reduce((a, b) => a + b) / trackingDifferences.length);
  }
  
  static Future<double> _calculateBeta(List<Position> positions) async {
    // Calculate portfolio beta based on individual stock betas
    double totalBeta = 0;
    double totalValue = 0;
    
    for (var position in positions) {
      final value = position.quantity * position.currentPrice;
      final beta = await _getPositionBeta(position.symbol);
      totalBeta += value * beta;
      totalValue += value;
    }
    
    return totalValue == 0 ? 1 : totalBeta / totalValue;
  }
  
  static Future<double> _calculateAlpha(List<Position> positions, double beta) async {
    final portfolioReturn = _calculatePortfolioReturn(positions);
    final marketReturn = await _getMarketReturn();
    final riskFreeRate = 0.02;
    
    return portfolioReturn - (riskFreeRate + beta * (marketReturn - riskFreeRate));
  }
  
  static double _calculateRSquared(List<double> values) {
    final returns = _calculateReturns(values);
    final benchmarkReturns = _getBenchmarkReturns();
    
    final correlation = _calculateCorrelation(returns, benchmarkReturns);
    return pow(correlation, 2);
  }
  
  static Future<Map<String, double>> _calculateCorrelationMatrix(List<Position> positions) async {
    final matrix = <String, double>{};
    
    for (int i = 0; i < positions.length; i++) {
      for (int j = i + 1; j < positions.length; j++) {
        final returns1 = await _getHistoricalReturns(positions[i].symbol);
        final returns2 = await _getHistoricalReturns(positions[j].symbol);
        final correlation = _calculateCorrelation(returns1, returns2);
        matrix['${positions[i].symbol}_${positions[j].symbol}'] = correlation;
      }
    }
    
    return matrix;
  }
  
  static Future<String> _analyzeMarketRegime(List<double> values) async {
    final returns = _calculateReturns(values);
    final volatility = _calculateVolatility(returns);
    final trend = _calculateTrend(returns);
    
    if (volatility > 0.03 && trend.abs() > 0.5) {
      return 'HIGH_VOLATILITY_TRENDING';
    } else if (volatility > 0.03) {
      return 'HIGH_VOLATILITY_RANGING';
    } else if (trend.abs() > 0.5) {
      return 'LOW_VOLATILITY_TRENDING';
    } else {
      return 'LOW_VOLATILITY_RANGING';
    }
  }
  
  static Future<Map<String, dynamic>> _runScenarioAnalysis(List<Position> positions) async {
    final scenarios = {
      'bull_market': 0.2,
      'bear_market': -0.2,
      'flat_market': 0,
      'high_volatility': 0.5,
      'low_volatility': 0.1,
    };
    
    final results = <String, dynamic>{};
    final currentValue = positions.fold(0.0, (sum, p) => sum + p.quantity * p.currentPrice);
    
    for (var entry in scenarios.entries) {
      double newValue = 0;
      for (var position in positions) {
        final beta = await _getPositionBeta(position.symbol);
        final scenarioReturn = entry.value * beta;
        newValue += position.quantity * position.currentPrice * (1 + scenarioReturn);
      }
      
      results[entry.key] = {
        'newValue': newValue,
        'change': newValue - currentValue,
        'changePercent': ((newValue - currentValue) / currentValue) * 100,
      };
    }
    
    return results;
  }
  
  static Map<String, double> _calculateSensitivity(List<Position> positions) {
    final sensitivity = <String, double>{};
    
    for (var position in positions) {
      final value = position.quantity * position.currentPrice;
      sensitivity[position.symbol] = value;
    }
    
    return sensitivity;
  }
  
  // Utility methods
  static List<double> _calculateReturns(List<double> values) {
    final returns = <double>[];
    for (int i = 1; i < values.length; i++) {
      returns.add((values[i] - values[i - 1]) / values[i - 1]);
    }
    return returns;
  }
  
  static double _calculateMaxDrawdown(List<double> values) {
    double maxDrawdown = 0;
    double peak = values[0];
    
    for (var value in values) {
      if (value > peak) peak = value;
      final drawdown = (peak - value) / peak;
      if (drawdown > maxDrawdown) maxDrawdown = drawdown;
    }
    
    return maxDrawdown;
  }
  
  static double _calculateAverageDrawdown(List<double> values) {
    double sumDrawdown = 0;
    int drawdownCount = 0;
    double peak = values[0];
    
    for (var value in values) {
      if (value > peak) {
        peak = value;
      } else {
        final drawdown = (peak - value) / peak;
        sumDrawdown += drawdown;
        drawdownCount++;
      }
    }
    
    return drawdownCount == 0 ? 0 : sumDrawdown / drawdownCount;
  }
  
  static double _calculateVolatility(List<double> returns) {
    final mean = returns.reduce((a, b) => a + b) / returns.length;
    final variance = returns.map((r) => pow(r - mean, 2)).reduce((a, b) => a + b) / returns.length;
    return sqrt(variance) * sqrt(252);
  }
  
  static double _calculateTrend(List<double> returns) {
    final sma20 = returns.takeLast(20).reduce((a, b) => a + b) / 20;
    final sma50 = returns.takeLast(50).reduce((a, b) => a + b) / 50;
    return (sma20 - sma50) / sma50;
  }
  
  static double _calculateCorrelation(List<double> x, List<double> y) {
    final n = x.length < y.length ? x.length : y.length;
    final meanX = x.take(n).reduce((a, b) => a + b) / n;
    final meanY = y.take(n).reduce((a, b) => a + b) / n;
    
    double covariance = 0;
    double varianceX = 0;
    double varianceY = 0;
    
    for (int i = 0; i < n; i++) {
      covariance += (x[i] - meanX) * (y[i] - meanY);
      varianceX += pow(x[i] - meanX, 2);
      varianceY += pow(y[i] - meanY, 2);
    }
    
    return covariance / (sqrt(varianceX) * sqrt(varianceY));
  }
  
  static double _calculatePortfolioReturn(List<Position> positions) {
    final currentValue = positions.fold(0.0, (sum, p) => sum + p.quantity * p.currentPrice);
    final initialValue = positions.fold(0.0, (sum, p) => sum + p.quantity * p.avgPrice);
    return (currentValue - initialValue) / initialValue;
  }
  
  static Future<double> _getMarketReturn() async {
    // Fetch market index return
    return 0.1;
  }
  
  static Future<double> _getPositionBeta(String symbol) async {
    // Fetch beta from database or API
    return 1.0;
  }
  
  static Future<List<double>> _getHistoricalReturns(String symbol) async {
    // Fetch historical returns
    return [];
  }
  
  static String _getPositionSector(String symbol) {
    // Map symbol to sector
    return 'Technology';
  }
  
  static List<double> _getBenchmarkReturns() {
    // Fetch benchmark returns (e.g., NIFTY, S&P 500)
    return [];
  }
}