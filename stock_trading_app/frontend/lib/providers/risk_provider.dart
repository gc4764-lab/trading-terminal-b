import 'package:flutter_riverpod/flutter_riverpod.dart';

class RiskMetrics {
  final double totalExposure;
  final double maxDrawdown;
  final double sharpeRatio;
  final double maxPositionSize;
  final double maxDailyLoss;
  final double stopLoss;

  RiskMetrics({
    required this.totalExposure,
    required this.maxDrawdown,
    required this.sharpeRatio,
    required this.maxPositionSize,
    required this.maxDailyLoss,
    required this.stopLoss,
  });
}

final riskProvider = StateNotifierProvider<RiskNotifier, RiskMetrics>((ref) {
  return RiskNotifier();
});

class RiskNotifier extends StateNotifier<RiskMetrics> {
  RiskNotifier()
      : super(RiskMetrics(
          totalExposure: 0,
          maxDrawdown: 0,
          sharpeRatio: 0,
          maxPositionSize: 0.1,
          maxDailyLoss: 0.02,
          stopLoss: 0.05,
        ));

  void updateMaxPositionSize(double value) {
    state = RiskMetrics(
      totalExposure: state.totalExposure,
      maxDrawdown: state.maxDrawdown,
      sharpeRatio: state.sharpeRatio,
      maxPositionSize: value,
      maxDailyLoss: state.maxDailyLoss,
      stopLoss: state.stopLoss,
    );
    // Save to backend if needed
  }

  void updateMaxDailyLoss(double value) {
    state = RiskMetrics(
      totalExposure: state.totalExposure,
      maxDrawdown: state.maxDrawdown,
      sharpeRatio: state.sharpeRatio,
      maxPositionSize: state.maxPositionSize,
      maxDailyLoss: value,
      stopLoss: state.stopLoss,
    );
  }

  void updateStopLoss(double value) {
    state = RiskMetrics(
      totalExposure: state.totalExposure,
      maxDrawdown: state.maxDrawdown,
      sharpeRatio: state.sharpeRatio,
      maxPositionSize: state.maxPositionSize,
      maxDailyLoss: state.maxDailyLoss,
      stopLoss: value,
    );
  }

  void updateMetricsFromPositions(List<Position> positions) {
    double totalValue = 0;
    double pnlSum = 0;
    for (var p in positions) {
      totalValue += p.quantity * p.currentPrice;
      pnlSum += p.pnl;
    }
    // Calculate Sharpe ratio and drawdown (simplified)
    double sharpe = pnlSum / (totalValue + 1); // placeholder
    double drawdown = 0; // placeholder

    state = RiskMetrics(
      totalExposure: totalValue,
      maxDrawdown: drawdown,
      sharpeRatio: sharpe,
      maxPositionSize: state.maxPositionSize,
      maxDailyLoss: state.maxDailyLoss,
      stopLoss: state.stopLoss,
    );
  }
}