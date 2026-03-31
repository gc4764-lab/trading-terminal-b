import 'package:stock_trading_app/models/order.dart';
import 'package:stock_trading_app/models/chart_data.dart';
import 'package:stock_trading_app/services/indicator_service.dart';

class BacktestResult {
  final double totalReturn;
  final double sharpeRatio;
  final double maxDrawdown;
  final int totalTrades;
  final int winningTrades;
  final int losingTrades;
  final double winRate;
  final double averageWin;
  final double averageLoss;
  final double profitFactor;
  
  BacktestResult({
    required this.totalReturn,
    required this.sharpeRatio,
    required this.maxDrawdown,
    required this.totalTrades,
    required this.winningTrades,
    required this.losingTrades,
    required this.winRate,
    required this.averageWin,
    required this.averageLoss,
    required this.profitFactor,
  });
}

class BacktestingService {
  static Future<BacktestResult> runBacktest({
    required List<ChartData> historicalData,
    required String strategy,
    required Map<String, dynamic> parameters,
    double initialCapital = 100000,
  }) async {
    List<double> returns = [];
    List<Order> trades = [];
    double capital = initialCapital;
    double position = 0;
    
    for (int i = 100; i < historicalData.length; i++) {
      // Get signals based on strategy
      Signal signal = await _getSignal(
        historicalData.sublist(0, i + 1),
        strategy,
        parameters,
      );
      
      // Execute trade based on signal
      if (signal.type == 'BUY' && position == 0) {
        double shares = capital / historicalData[i].close;
        position = shares;
        capital = 0;
        trades.add(Order(
          id: '',
          brokerId: 'backtest',
          symbol: 'TEST',
          side: 'buy',
          type: 'market',
          quantity: shares.floor(),
          price: historicalData[i].close,
          status: 'filled',
          createdAt: historicalData[i].date,
          updatedAt: historicalData[i].date,
        ));
      } else if (signal.type == 'SELL' && position > 0) {
        capital = position * historicalData[i].close;
        position = 0;
        trades.add(Order(
          id: '',
          brokerId: 'backtest',
          symbol: 'TEST',
          side: 'sell',
          type: 'market',
          quantity: position.floor(),
          price: historicalData[i].close,
          status: 'filled',
          createdAt: historicalData[i].date,
          updatedAt: historicalData[i].date,
        ));
        
        // Calculate return
        double return_ = (capital - initialCapital) / initialCapital;
        returns.add(return_);
      }
    }
    
    // Calculate metrics
    double totalReturn = (capital + (position * historicalData.last.close) - initialCapital) / initialCapital;
    double sharpeRatio = _calculateSharpeRatio(returns);
    double maxDrawdown = _calculateMaxDrawdown(returns);
    
    // Calculate trade statistics
    int winningTrades = 0;
    int losingTrades = 0;
    double totalWins = 0;
    double totalLosses = 0;
    
    for (int i = 0; i < trades.length; i += 2) {
      if (i + 1 < trades.length) {
        double tradeReturn = (trades[i + 1].price - trades[i].price) / trades[i].price;
        if (tradeReturn > 0) {
          winningTrades++;
          totalWins += tradeReturn;
        } else {
          losingTrades++;
          totalLosses += tradeReturn.abs();
        }
      }
    }
    
    int totalTrades = trades.length ~/ 2;
    double winRate = totalTrades > 0 ? winningTrades / totalTrades : 0;
    double averageWin = winningTrades > 0 ? totalWins / winningTrades : 0;
    double averageLoss = losingTrades > 0 ? totalLosses / losingTrades : 0;
    double profitFactor = totalLosses > 0 ? totalWins / totalLosses : 0;
    
    return BacktestResult(
      totalReturn: totalReturn,
      sharpeRatio: sharpeRatio,
      maxDrawdown: maxDrawdown,
      totalTrades: totalTrades,
      winningTrades: winningTrades,
      losingTrades: losingTrades,
      winRate: winRate,
      averageWin: averageWin,
      averageLoss: averageLoss,
      profitFactor: profitFactor,
    );
  }
  
  static Future<Signal> _getSignal(
    List<ChartData> data,
    String strategy,
    Map<String, dynamic> parameters,
  ) async {
    List<double> closes = data.map((d) => d.close).toList();
    
    switch (strategy) {
      case 'sma_crossover':
        int fastPeriod = parameters['fastPeriod'] ?? 10;
        int slowPeriod = parameters['slowPeriod'] ?? 30;
        
        List<double> fastSMA = IndicatorService.calculateSMA(closes, fastPeriod);
        List<double> slowSMA = IndicatorService.calculateSMA(closes, slowPeriod);
        
        if (fastSMA.length >= 2 && slowSMA.length >= 2) {
          if (fastSMA.last > slowSMA.last && fastSMA[fastSMA.length - 2] <= slowSMA[slowSMA.length - 2]) {
            return Signal(type: 'BUY', strength: 1.0);
          } else if (fastSMA.last < slowSMA.last && fastSMA[fastSMA.length - 2] >= slowSMA[slowSMA.length - 2]) {
            return Signal(type: 'SELL', strength: 1.0);
          }
        }
        break;
        
      case 'rsi':
        int period = parameters['period'] ?? 14;
        double overbought = parameters['overbought'] ?? 70;
        double oversold = parameters['oversold'] ?? 30;
        
        List<double> rsi = IndicatorService.calculateRSI(closes, period);
        
        if (rsi.isNotEmpty) {
          if (rsi.last <= oversold) {
            return Signal(type: 'BUY', strength: (oversold - rsi.last) / oversold);
          } else if (rsi.last >= overbought) {
            return Signal(type: 'SELL', strength: (rsi.last - overbought) / (100 - overbought));
          }
        }
        break;
        
      case 'macd':
        List<double> macdData = IndicatorService.calculateMACD(closes, 12, 26, 9)['macd']!;
        List<double> signalData = IndicatorService.calculateMACD(closes, 12, 26, 9)['signal']!;
        
        if (macdData.length >= 2 && signalData.length >= 2) {
          if (macdData.last > signalData.last && macdData[macdData.length - 2] <= signalData[signalData.length - 2]) {
            return Signal(type: 'BUY', strength: 1.0);
          } else if (macdData.last < signalData.last && macdData[macdData.length - 2] >= signalData[signalData.length - 2]) {
            return Signal(type: 'SELL', strength: 1.0);
          }
        }
        break;
    }
    
    return Signal(type: 'HOLD', strength: 0);
  }
  
  static double _calculateSharpeRatio(List<double> returns) {
    if (returns.isEmpty) return 0;
    
    double mean = returns.reduce((a, b) => a + b) / returns.length;
    double variance = 0;
    for (var r in returns) {
      variance += pow(r - mean, 2);
    }
    variance /= returns.length;
    double stdDev = sqrt(variance);
    
    double riskFreeRate = 0.02 / 252; // Daily risk-free rate
    return stdDev == 0 ? 0 : (mean - riskFreeRate) / stdDev * sqrt(252);
  }
  
  static double _calculateMaxDrawdown(List<double> returns) {
    if (returns.isEmpty) return 0;
    
    double peak = 0;
    double maxDrawdown = 0;
    double cumulativeReturn = 0;
    
    for (var r in returns) {
      cumulativeReturn += r;
      if (cumulativeReturn > peak) {
        peak = cumulativeReturn;
      }
      double drawdown = (peak - cumulativeReturn) / (1 + peak);
      if (drawdown > maxDrawdown) {
        maxDrawdown = drawdown;
      }
    }
    
    return maxDrawdown;
  }
}

class Signal {
  final String type; // BUY, SELL, HOLD
  final double strength; // 0-1
  
  Signal({required this.type, required this.strength});
}