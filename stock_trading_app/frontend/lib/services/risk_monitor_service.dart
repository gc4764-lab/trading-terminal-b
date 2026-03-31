import 'dart:async';
import 'package:stock_trading_app/models/order.dart';
import 'package:stock_trading_app/models/position.dart';

class RiskMonitorService {
  static final RiskMonitorService _instance = RiskMonitorService._internal();
  factory RiskMonitorService() => _instance;
  RiskMonitorService._internal();
  
  final Map<String, Timer> _monitoringTimers = {};
  final Map<String, List<RiskRule>> _activeRules = {};
  final StreamController<RiskAlert> _alertController = StreamController<RiskAlert>.broadcast();
  
  Stream<RiskAlert> get alerts => _alertController.stream;
  
  // Initialize risk monitoring
  void initialize(String userId) {
    _loadRiskRules(userId);
    _startMonitoring(userId);
  }
  
  // Add risk rule
  void addRiskRule(String userId, RiskRule rule) {
    if (!_activeRules.containsKey(userId)) {
      _activeRules[userId] = [];
    }
    _activeRules[userId]!.add(rule);
  }
  
  // Monitor portfolio risk in real-time
  void _startMonitoring(String userId) {
    _monitoringTimers[userId] = Timer.periodic(const Duration(seconds: 1), (timer) async {
      await _checkRiskLevels(userId);
    });
  }
  
  // Check all risk levels
  Future<void> _checkRiskLevels(String userId) async {
    final positions = await _getCurrentPositions(userId);
    final orders = await _getPendingOrders(userId);
    final accountValue = await _getAccountValue(userId);
    
    for (var rule in _activeRules[userId] ?? []) {
      await _evaluateRule(rule, positions, orders, accountValue, userId);
    }
  }
  
  // Evaluate individual risk rule
  Future<void> _evaluateRule(
    RiskRule rule,
    List<Position> positions,
    List<Order> orders,
    double accountValue,
    String userId,
  ) async {
    double currentValue = 0;
    
    switch (rule.type) {
      case RiskType.maxPositionSize:
        currentValue = _calculateMaxPositionSize(positions, accountValue);
        break;
      case RiskType.maxDailyLoss:
        currentValue = await _calculateDailyLoss(userId);
        break;
      case RiskType.maxConcentration:
        currentValue = _calculateConcentration(positions);
        break;
      case RiskType.maxLeverage:
        currentValue = _calculateLeverage(positions, accountValue);
        break;
      case RiskType.maxDrawdown:
        currentValue = await _calculateDrawdown(userId);
        break;
      case RiskType.varLimit:
        currentValue = await _calculateVaR(positions);
        break;
      case RiskType.stopLoss:
        currentValue = _calculateStopLossViolations(positions);
        break;
    }
    
    if (currentValue > rule.threshold) {
      final alert = RiskAlert(
        userId: userId,
        rule: rule,
        currentValue: currentValue,
        timestamp: DateTime.now(),
        severity: _calculateSeverity(currentValue, rule.threshold),
      );
      
      _alertController.add(alert);
      await _handleRiskViolation(alert);
    }
  }
  
  // Handle risk violation
  Future<void> _handleRiskViolation(RiskAlert alert) async {
    // Log violation
    await _logViolation(alert);
    
    // Send notification
    await NotificationService.sendRiskAlert(alert);
    
    // Take automated action based on severity
    if (alert.severity == RiskSeverity.critical) {
      await _takeEmergencyAction(alert);
    } else if (alert.severity == RiskSeverity.high) {
      await _sendWarning(alert);
    }
  }
  
  // Emergency action for critical violations
  Future<void> _takeEmergencyAction(RiskAlert alert) async {
    switch (alert.rule.action) {
      case RiskAction.blockNewOrders:
        await _blockNewOrders(alert.userId);
        break;
      case RiskAction.closePositions:
        await _closeAllPositions(alert.userId);
        break;
      case RiskAction.reduceLeverage:
        await _reduceLeverage(alert.userId);
        break;
      case RiskAction.notifyAdmin:
        await _notifyAdmin(alert);
        break;
    }
  }
  
  // Calculate position size percentage
  double _calculateMaxPositionSize(List<Position> positions, double accountValue) {
    if (positions.isEmpty) return 0;
    final largestPosition = positions.map((p) => p.quantity * p.currentPrice).reduce((a, b) => a > b ? a : b);
    return (largestPosition / accountValue) * 100;
  }
  
  // Calculate daily loss percentage
  Future<double> _calculateDailyLoss(String userId) async {
    final todayPnL = await _getTodayPnL(userId);
    final accountValue = await _getAccountValue(userId);
    return (todayPnL.abs() / accountValue) * 100;
  }
  
  // Calculate concentration risk
  double _calculateConcentration(List<Position> positions) {
    if (positions.isEmpty) return 0;
    final totalValue = positions.fold(0.0, (sum, p) => sum + p.quantity * p.currentPrice);
    double concentration = 0;
    for (var p in positions) {
      final weight = (p.quantity * p.currentPrice) / totalValue;
      concentration += weight * weight;
    }
    return concentration;
  }
  
  // Calculate leverage
  double _calculateLeverage(List<Position> positions, double accountValue) {
    final totalExposure = positions.fold(0.0, (sum, p) => sum + p.quantity * p.currentPrice);
    return totalExposure / accountValue;
  }
  
  // Calculate drawdown
  Future<double> _calculateDrawdown(String userId) async {
    final peak = await _getPeakValue(userId);
    final current = await _getAccountValue(userId);
    return ((peak - current) / peak) * 100;
  }
  
  // Calculate Value at Risk
  Future<double> _calculateVaR(List<Position> positions) async {
    // Implement VaR calculation using historical simulation
    return 0.0;
  }
  
  // Calculate stop loss violations
  double _calculateStopLossViolations(List<Position> positions) {
    int violations = 0;
    for (var p in positions) {
      final lossPercent = ((p.avgPrice - p.currentPrice) / p.avgPrice) * 100;
      if (lossPercent > 5) { // 5% stop loss
        violations++;
      }
    }
    return violations;
  }
  
  // Helper methods
  Future<List<Position>> _getCurrentPositions(String userId) async {
    // Fetch from database
    return [];
  }
  
  Future<List<Order>> _getPendingOrders(String userId) async {
    // Fetch from database
    return [];
  }
  
  Future<double> _getAccountValue(String userId) async {
    // Fetch from database
    return 100000;
  }
  
  Future<double> _getTodayPnL(String userId) async {
    // Calculate today's P&L
    return 0;
  }
  
  Future<double> _getPeakValue(String userId) async {
    // Get peak account value
    return 100000;
  }
  
  Future<void> _logViolation(RiskAlert alert) async {
    // Log to database
  }
  
  Future<void> _blockNewOrders(String userId) async {
    // Block new order placement
  }
  
  Future<void> _closeAllPositions(String userId) async {
    // Emergency position closure
  }
  
  Future<void> _reduceLeverage(String userId) async {
    // Reduce leverage by closing positions
  }
  
  Future<void> _notifyAdmin(RiskAlert alert) async {
    // Send admin notification
  }
  
  Future<void> _sendWarning(RiskAlert alert) async {
    // Send warning notification
  }
  
  void _loadRiskRules(String userId) {
    // Load from database
  }
  
  RiskSeverity _calculateSeverity(double current, double threshold) {
    final ratio = current / threshold;
    if (ratio >= 2.0) return RiskSeverity.critical;
    if (ratio >= 1.5) return RiskSeverity.high;
    if (ratio >= 1.2) return RiskSeverity.medium;
    return RiskSeverity.low;
  }
  
  void dispose() {
    for (var timer in _monitoringTimers.values) {
      timer.cancel();
    }
    _alertController.close();
  }
}

class RiskRule {
  final String id;
  final RiskType type;
  final double threshold;
  final RiskAction action;
  final String description;
  
  RiskRule({
    required this.id,
    required this.type,
    required this.threshold,
    required this.action,
    required this.description,
  });
}

enum RiskType {
  maxPositionSize,
  maxDailyLoss,
  maxConcentration,
  maxLeverage,
  maxDrawdown,
  varLimit,
  stopLoss,
}

enum RiskAction {
  blockNewOrders,
  closePositions,
  reduceLeverage,
  notifyAdmin,
}

enum RiskSeverity {
  low,
  medium,
  high,
  critical,
}

class RiskAlert {
  final String userId;
  final RiskRule rule;
  final double currentValue;
  final DateTime timestamp;
  final RiskSeverity severity;
  
  RiskAlert({
    required this.userId,
    required this.rule,
    required this.currentValue,
    required this.timestamp,
    required this.severity,
  });
