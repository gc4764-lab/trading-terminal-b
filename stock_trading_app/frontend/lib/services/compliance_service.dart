import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:stock_trading_app/models/order.dart';

class ComplianceService {
  static Database? _database;
  static final Map<String, List<Regulation>> _regulations = {};
  
  // Initialize compliance database
  static Future<void> initialize() async {
    _database = await openDatabase(
      'compliance.db',
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE audit_logs(
            id TEXT PRIMARY KEY,
            user_id TEXT,
            action TEXT,
            details TEXT,
            ip_address TEXT,
            timestamp DATETIME
          )
        ''');
        
        await db.execute('''
          CREATE TABLE trade_reviews(
            id TEXT PRIMARY KEY,
            order_id TEXT,
            reviewer_id TEXT,
            status TEXT,
            comments TEXT,
            reviewed_at DATETIME
          )
        ''');
        
        await db.execute('''
          CREATE TABLE risk_assessments(
            id TEXT PRIMARY KEY,
            user_id TEXT,
            score REAL,
            level TEXT,
            assessed_at DATETIME
          )
        ''');
      },
    );
    
    _loadRegulations();
  }
  
  // Audit logging
  static Future<void> logAuditEvent({
    required String userId,
    required String action,
    required Map<String, dynamic> details,
    required String ipAddress,
  }) async {
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    await _database?.insert('audit_logs', {
      'id': id,
      'user_id': userId,
      'action': action,
      'details': jsonEncode(details),
      'ip_address': ipAddress,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }
  
  // Pre-trade compliance check
  static Future<ComplianceResult> checkOrderCompliance(Order order, String userId) async {
    final violations = <String>[];
    
    // Check position limits
    final positionLimit = await _checkPositionLimit(userId, order.symbol);
    if (!positionLimit.passed) {
      violations.add(positionLimit.message);
    }
    
    // Check daily loss limit
    final dailyLoss = await _checkDailyLossLimit(userId);
    if (!dailyLoss.passed) {
      violations.add(dailyLoss.message);
    }
    
    // Check concentration risk
    final concentration = await _checkConcentrationRisk(userId, order);
    if (!concentration.passed) {
      violations.add(concentration.message);
    }
    
    // Check pattern day trading rules
    final pdtRule = await _checkPDTRule(userId);
    if (!pdtRule.passed) {
      violations.add(pdtRule.message);
    }
    
    // Check restricted symbols
    if (_isRestrictedSymbol(order.symbol)) {
      violations.add('Trading in ${order.symbol} is restricted');
    }
    
    // Check market hours
    if (!_isMarketOpen()) {
      violations.add('Market is currently closed');
    }
    
    return ComplianceResult(
      passed: violations.isEmpty,
      violations: violations,
      requiresReview: violations.isNotEmpty && violations.length <= 2,
    );
  }
  
  // Post-trade review
  static Future<void> submitForReview(String orderId, String userId) async {
    final reviewId = DateTime.now().millisecondsSinceEpoch.toString();
    await _database?.insert('trade_reviews', {
      'id': reviewId,
      'order_id': orderId,
      'reviewer_id': userId,
      'status': 'pending',
      'reviewed_at': DateTime.now().toIso8601String(),
    });
  }
  
  // Risk assessment for new users
  static Future<RiskAssessment> assessUserRisk(String userId, Map<String, dynamic> userData) async {
    double riskScore = 0;
    List<String> riskFactors = [];
    
    // Check trading experience
    final experience = userData['experience'] ?? 'beginner';
    switch (experience) {
      case 'beginner':
        riskScore += 30;
        riskFactors.add('Limited trading experience');
        break;
      case 'intermediate':
        riskScore += 15;
        break;
      case 'advanced':
        riskScore += 5;
        break;
    }
    
    // Check income level
    final income = userData['annualIncome'] ?? 0;
    if (income < 50000) {
      riskScore += 25;
      riskFactors.add('Low annual income');
    }
    
    // Check net worth
    final netWorth = userData['netWorth'] ?? 0;
    if (netWorth < 100000) {
      riskScore += 20;
      riskFactors.add('Low net worth');
    }
    
    // Check intended leverage
    final leverage = userData['intendedLeverage'] ?? 1;
    if (leverage > 3) {
      riskScore += 20;
      riskFactors.add('High intended leverage');
    }
    
    // Determine risk level
    String riskLevel;
    if (riskScore < 30) {
      riskLevel = 'low';
    } else if (riskScore < 60) {
      riskLevel = 'medium';
    } else {
      riskLevel = 'high';
    }
    
    // Store assessment
    final assessmentId = DateTime.now().millisecondsSinceEpoch.toString();
    await _database?.insert('risk_assessments', {
      'id': assessmentId,
      'user_id': userId,
      'score': riskScore,
      'level': riskLevel,
      'assessed_at': DateTime.now().toIso8601String(),
    });
    
    return RiskAssessment(
      score: riskScore,
      level: riskLevel,
      factors: riskFactors,
      recommendedLimits: _getRecommendedLimits(riskLevel),
    );
  }
  
  // Generate compliance report
  static Future<String> generateComplianceReport(String userId, DateTime startDate, DateTime endDate) async {
    final audits = await _database?.query(
      'audit_logs',
      where: 'user_id = ? AND timestamp BETWEEN ? AND ?',
      whereArgs: [userId, startDate.toIso8601String(), endDate.toIso8601String()],
    );
    
    final reviews = await _database?.query(
      'trade_reviews',
      where: 'reviewer_id = ? AND reviewed_at BETWEEN ? AND ?',
      whereArgs: [userId, startDate.toIso8601String(), endDate.toIso8601String()],
    );
    
    final report = StringBuffer();
    report.writeln('Compliance Report for User: $userId');
    report.writeln('Period: $startDate to $endDate');
    report.writeln('=' * 50);
    report.writeln();
    
    report.writeln('Audit Events: ${audits?.length ?? 0}');
    for (var audit in audits ?? []) {
      report.writeln('  - ${audit['action']} at ${audit['timestamp']}');
    }
    report.writeln();
    
    report.writeln('Trade Reviews: ${reviews?.length ?? 0}');
    for (var review in reviews ?? []) {
      report.writeln('  - Order ${review['order_id']}: ${review['status']}');
      if (review['comments'] != null) {
        report.writeln('    Comments: ${review['comments']}');
      }
    }
    report.writeln();
    
    report.writeln('Risk Assessment Summary:');
    final assessment = await _database?.query(
      'risk_assessments',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'assessed_at DESC',
      limit: 1,
    );
    
    if (assessment != null && assessment.isNotEmpty) {
      report.writeln('  - Risk Score: ${assessment.first['score']}');
      report.writeln('  - Risk Level: ${assessment.first['level']}');
    }
    
    return report.toString();
  }
  
  // Helper methods
  static Future<LimitCheck> _checkPositionLimit(String userId, String symbol) async {
    // Implementation
    return LimitCheck(passed: true, message: '');
  }
  
  static Future<LimitCheck> _checkDailyLossLimit(String userId) async {
    // Implementation
    return LimitCheck(passed: true, message: '');
  }
  
  static Future<LimitCheck> _checkConcentrationRisk(String userId, Order order) async {
    // Implementation
    return LimitCheck(passed: true, message: '');
  }
  
  static Future<LimitCheck> _checkPDTRule(String userId) async {
    // Implementation
    return LimitCheck(passed: true, message: '');
  }
  
  static bool _isRestrictedSymbol(String symbol) {
    final restrictedSymbols = ['PENNY_STOCK', 'RESTRICTED_1'];
    return restrictedSymbols.contains(symbol);
  }
  
  static bool _isMarketOpen() {
    final now = DateTime.now();
    final hour = now.hour;
    final minute = now.minute;
    final weekday = now.weekday;
    
    // Market hours: 9:30 AM - 4:00 PM, Monday-Friday
    if (weekday >= 1 && weekday <= 5) {
      if (hour > 9 || (hour == 9 && minute >= 30)) {
        if (hour < 16) {
          return true;
        }
      }
    }
    return false;
  }
  
  static Map<String, dynamic> _getRecommendedLimits(String riskLevel) {
    switch (riskLevel) {
      case 'low':
        return {
          'maxPositionSize': 0.20,
          'maxDailyLoss': 0.05,
          'maxLeverage': 5,
          'requiresMarginApproval': false,
        };
      case 'medium':
        return {
          'maxPositionSize': 0.10,
          'maxDailyLoss': 0.03,
          'maxLeverage': 3,
          'requiresMarginApproval': true,
        };
      case 'high':
        return {
          'maxPositionSize': 0.05,
          'maxDailyLoss': 0.02,
          'maxLeverage': 2,
          'requiresMarginApproval': true,
        };
      default:
        return {
          'maxPositionSize': 0.10,
          'maxDailyLoss': 0.03,
          'maxLeverage': 3,
          'requiresMarginApproval': true,
        };
    }
  }
  
  static void _loadRegulations() {
    // Load from configuration
    _regulations['US'] = [
      Regulation(
        name: 'Pattern Day Trader Rule',
        description: 'Minimum $25,000 equity for day trading',
        appliesTo: ['US'],
        isActive: true,
      ),
      Regulation(
        name: 'Position Limits',
        description: 'Maximum position size limits',
        appliesTo: ['US', 'EU'],
        isActive: true,
      ),
    ];
  }
}

class ComplianceResult {
  final bool passed;
  final List<String> violations;
  final bool requiresReview;
  
  ComplianceResult({
    required this.passed,
    required this.violations,
    required this.requiresReview,
  });
}

class LimitCheck {
  final bool passed;
  final String message;
  
  LimitCheck({required this.passed, required this.message});
}

class Regulation {
  final String name;
  final String description;
  final List<String> appliesTo;
  final bool isActive;
  
  Regulation({
    required this.name,
    required this.description,
    required this.appliesTo,
    required this.isActive,
  });
}

class RiskAssessment {
  final double score;
  final String level;
  final List<String> factors;
  final Map<String, dynamic> recommendedLimits;
  
  RiskAssessment({
    required this.score,
    required this.level,
    required this.factors,
    required this.recommendedLimits,
  });
}