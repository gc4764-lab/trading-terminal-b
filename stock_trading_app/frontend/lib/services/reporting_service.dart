import 'dart:convert';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:stock_trading_app/models/order.dart';
import 'package:stock_trading_app/models/position.dart';
import 'package:intl/intl.dart';

class ReportingService {
  static final PdfColor _primaryColor = PdfColors.blue;
  static final PdfColor _successColor = PdfColors.green;
  static final PdfColor _dangerColor = PdfColors.red;
  
  // Generate comprehensive trading report
  static Future<Uint8List> generateTradingReport({
    required List<Order> orders,
    required List<Position> positions,
    required DateTime startDate,
    required DateTime endDate,
    required Map<String, dynamic> performanceMetrics,
  }) async {
    final pdf = pw.Document();
    
    // Cover Page
    pdf.addPage(_buildCoverPage(startDate, endDate, performanceMetrics));
    
    // Executive Summary
    pdf.addPage(_buildExecutiveSummary(performanceMetrics));
    
    // Trade Analysis
    pdf.addPage(_buildTradeAnalysis(orders, performanceMetrics));
    
    // Performance Charts
    pdf.addPage(_buildPerformanceCharts(performanceMetrics));
    
    // Position Summary
    pdf.addPage(_buildPositionSummary(positions));
    
    // Trade History
    pdf.addPage(_buildTradeHistory(orders));
    
    // Risk Analysis
    pdf.addPage(_buildRiskAnalysis(performanceMetrics));
    
    // Future Outlook
    pdf.addPage(_buildFutureOutlook(performanceMetrics));
    
    return pdf.save();
  }
  
  static pw.Page _buildCoverPage(DateTime start, DateTime end, Map<String, dynamic> metrics) {
    return pw.Page(
      build: (context) => pw.Center(
        child: pw.Column(
          mainAxisAlignment: pw.MainAxisAlignment.center,
          children: [
            pw.Text(
              'Trading Performance Report',
              style: pw.TextStyle(fontSize: 32, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 20),
            pw.Text(
              DateFormat('MMMM dd, yyyy').format(start),
              style: const pw.TextStyle(fontSize: 18),
            ),
            pw.Text('to', style: const pw.TextStyle(fontSize: 18)),
            pw.Text(
              DateFormat('MMMM dd, yyyy').format(end),
              style: const pw.TextStyle(fontSize: 18),
            ),
            pw.SizedBox(height: 40),
            pw.Container(
              width: 200,
              height: 200,
              decoration: pw.BoxDecoration(
                shape: pw.BoxShape.circle,
                color: _getPerformanceColor(metrics['totalReturn']),
              ),
              child: pw.Center(
                child: pw.Column(
                  mainAxisAlignment: pw.MainAxisAlignment.center,
                  children: [
                    pw.Text(
                      '${(metrics['totalReturn'] * 100).toStringAsFixed(1)}%',
                      style: const pw.TextStyle(fontSize: 36, color: PdfColors.white),
                    ),
                    pw.Text(
                      'Total Return',
                      style: const pw.TextStyle(fontSize: 14, color: PdfColors.white),
                    ),
                  ],
                ),
              ),
            ),
            pw.SizedBox(height: 40),
            pw.Text(
              'Generated on ${DateFormat('MMMM dd, yyyy HH:mm').format(DateTime.now())}',
              style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey),
            ),
          ],
        ),
      ),
    );
  }
  
  static pw.Page _buildExecutiveSummary(Map<String, dynamic> metrics) {
    return pw.Page(
      build: (context) => pw.Padding(
        padding: const pw.EdgeInsets.all(40),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              'Executive Summary',
              style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 20),
            pw.Divider(),
            pw.SizedBox(height: 20),
            _buildMetricRow('Total Return', '${(metrics['totalReturn'] * 100).toStringAsFixed(2)}%', _getPerformanceColor(metrics['totalReturn'])),
            pw.SizedBox(height: 10),
            _buildMetricRow('Sharpe Ratio', metrics['sharpeRatio'].toStringAsFixed(2), _getSharpeColor(metrics['sharpeRatio'])),
            pw.SizedBox(height: 10),
            _buildMetricRow('Max Drawdown', '${(metrics['maxDrawdown'] * 100).toStringAsFixed(2)}%', _dangerColor),
            pw.SizedBox(height: 10),
            _buildMetricRow('Win Rate', '${(metrics['winRate'] * 100).toStringAsFixed(2)}%', _getWinRateColor(metrics['winRate'])),
            pw.SizedBox(height: 10),
            _buildMetricRow('Profit Factor', metrics['profitFactor'].toStringAsFixed(2), _getProfitFactorColor(metrics['profitFactor'])),
            pw.SizedBox(height: 30),
            pw.Text(
              'Key Insights',
              style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 10),
            ..._generateInsights(metrics).map((insight) => pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 8),
              child: pw.Row(
                children: [
                  pw.Icon(pw.IconData(0xe5ca), size: 16, color: _primaryColor),
                  pw.SizedBox(width: 8),
                  pw.Expanded(child: pw.Text(insight)),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }
  
  static pw.Page _buildTradeAnalysis(List<Order> orders, Map<String, dynamic> metrics) {
    final winningTrades = orders.where((o) => o.status == 'filled' && (o.filledPrice ?? 0) > (o.price ?? 0)).toList();
    final losingTrades = orders.where((o) => o.status == 'filled' && (o.filledPrice ?? 0) < (o.price ?? 0)).toList();
    
    return pw.Page(
      build: (context) => pw.Padding(
        padding: const pw.EdgeInsets.all(40),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              'Trade Analysis',
              style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 20),
            pw.Divider(),
            pw.SizedBox(height: 20),
            pw.Row(
              children: [
                pw.Expanded(
                  child: _buildTradeCard(
                    'Winning Trades',
                    winningTrades.length.toString(),
                    _successColor,
                    Icons.trending_up,
                  ),
                ),
                pw.SizedBox(width: 20),
                pw.Expanded(
                  child: _buildTradeCard(
                    'Losing Trades',
                    losingTrades.length.toString(),
                    _dangerColor,
                    Icons.trending_down,
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 30),
            pw.Text(
              'Trade Distribution by Day',
              style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 20),
            _buildTradeDistributionChart(orders),
            pw.SizedBox(height: 30),
            pw.Text(
              'Best & Worst Trades',
              style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 10),
            _buildBestWorstTrades(orders),
          ],
        ),
      ),
    );
  }
  
  static pw.Page _buildPerformanceCharts(Map<String, dynamic> metrics) {
    return pw.Page(
      build: (context) => pw.Padding(
        padding: const pw.EdgeInsets.all(40),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              'Performance Visualization',
              style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 20),
            pw.Divider(),
            pw.SizedBox(height: 20),
            pw.Text(
              'Equity Curve',
              style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 10),
            _buildEquityCurve(metrics['equityCurve']),
            pw.SizedBox(height: 30),
            pw.Text(
              'Monthly Returns Heatmap',
              style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 10),
            _buildMonthlyHeatmap(metrics['monthlyReturns']),
          ],
        ),
      ),
    );
  }
  
  static pw.Widget _buildMetricRow(String label, String value, PdfColor color) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(label, style: const pw.TextStyle(fontSize: 14)),
        pw.Text(
          value,
          style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: color),
        ),
      ],
    );
  }
  
  static pw.Widget _buildTradeCard(String title, String value, PdfColor color, IconData icon) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        children: [
          pw.Icon(icon, size: 32, color: color),
          pw.SizedBox(height: 8),
          pw.Text(
            value,
            style: pw.TextStyle(fontSize: 28, fontWeight: pw.FontWeight.bold, color: color),
          ),
          pw.Text(title, style: const pw.TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
  
  static pw.Widget _buildTradeDistributionChart(List<Order> orders) {
    // Group orders by day
    final Map<DateTime, int> dailyTrades = {};
    for (var order in orders) {
      final date = DateTime(order.createdAt.year, order.createdAt.month, order.createdAt.day);
      dailyTrades[date] = (dailyTrades[date] ?? 0) + 1;
    }
    
    final days = dailyTrades.keys.toList()..sort();
    final maxTrades = dailyTrades.values.reduce((a, b) => a > b ? a : b);
    
    return pw.Container(
      height: 200,
      child: pw.Row(
        children: days.map((day) {
          final trades = dailyTrades[day] ?? 0;
          final height = (trades / maxTrades) * 180;
          
          return pw.Expanded(
            child: pw.Column(
              children: [
                pw.Expanded(
                  child: pw.Align(
                    alignment: pw.Alignment.bottomCenter,
                    child: pw.Container(
                      height: height,
                      width: 30,
                      color: _getTradeColor(trades, maxTrades),
                    ),
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  DateFormat('dd').format(day),
                  style: const pw.TextStyle(fontSize: 8),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
  
  static pw.Widget _buildEquityCurve(List<double> curve) {
    final maxValue = curve.reduce((a, b) => a > b ? a : b);
    final minValue = curve.reduce((a, b) => a < b ? a : b);
    final range = maxValue - minValue;
    
    return pw.Container(
      height: 200,
      child: pw.CustomPaint(
        painter: pw.LineChartPainter(
          data: curve,
          minY: minValue - range * 0.1,
          maxY: maxValue + range * 0.1,
          color: _primaryColor,
        ),
      ),
    );
  }
  
  static pw.Widget _buildMonthlyHeatmap(Map<int, Map<int, double>> monthlyReturns) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    
    return pw.Container(
      child: pw.Table(
        border: pw.TableBorder.all(color: PdfColors.grey300),
        children: [
          pw.TableRow(
            children: [
              pw.Container(),
              ...months.map((m) => pw.Container(
                padding: const pw.EdgeInsets.all(8),
                child: pw.Text(m, textAlign: pw.TextAlign.center),
              )),
            ],
          ),
          ...List.generate(5, (year) {
            final yearValue = 2020 + year;
            return pw.TableRow(
              children: [
                pw.Container(
                  padding: const pw.EdgeInsets.all(8),
                  child: pw.Text(yearValue.toString(), textAlign: pw.TextAlign.center),
                ),
                ...months.map((_, month) {
                  final return_ = monthlyReturns[yearValue]?[month + 1] ?? 0;
                  return pw.Container(
                    padding: const pw.EdgeInsets.all(8),
                    color: _getReturnColor(return_),
                    child: pw.Text(
                      '${(return_ * 100).toStringAsFixed(1)}%',
                      textAlign: pw.TextAlign.center,
                      style: pw.TextStyle(
                        color: return_.abs() > 0.05 ? PdfColors.white : PdfColors.black,
                      ),
                    ),
                  );
                }),
              ],
            );
          }),
        ],
      ),
    );
  }
  
  static pw.Widget _buildBestWorstTrades(List<Order> orders) {
    final filledOrders = orders.where((o) => o.status == 'filled' && o.filledPrice != null).toList();
    filledOrders.sort((a, b) => (b.filledPrice! - b.price!).abs().compareTo((a.filledPrice! - a.price!).abs()));
    
    final best = filledOrders.take(5).toList();
    final worst = filledOrders.reversed.take(5).toList();
    
    return pw.Row(
      children: [
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('Best 5 Trades', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 8),
              ...best.map((order) => pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 4),
                child: pw.Text(
                  '${order.symbol}: +${((order.filledPrice! - order.price!) / order.price! * 100).toStringAsFixed(2)}%',
                  style: pw.TextStyle(color: _successColor),
                ),
              )),
            ],
          ),
        ),
        pw.SizedBox(width: 20),
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('Worst 5 Trades', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 8),
              ...worst.map((order) => pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 4),
                child: pw.Text(
                  '${order.symbol}: ${((order.filledPrice! - order.price!) / order.price! * 100).toStringAsFixed(2)}%',
                  style: pw.TextStyle(color: _dangerColor),
                ),
              )),
            ],
          ),
        ),
      ],
    );
  }
  
  static pw.Widget _buildPositionSummary(List<Position> positions) {
    return pw.Page(
      build: (context) => pw.Padding(
        padding: const pw.EdgeInsets.all(40),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              'Current Positions',
              style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 20),
            pw.Divider(),
            pw.SizedBox(height: 20),
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300),
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                  children: [
                    _buildTableHeader('Symbol'),
                    _buildTableHeader('Quantity'),
                    _buildTableHeader('Avg Price'),
                    _buildTableHeader('Current'),
                    _buildTableHeader('PnL'),
                    _buildTableHeader('Value'),
                  ],
                ),
                ...positions.map((position) {
                  final pnlPercent = position.pnl / (position.quantity * position.avgPrice) * 100;
                  return pw.TableRow(
                    children: [
                      _buildTableCell(position.symbol),
                      _buildTableCell(position.quantity.toString()),
                      _buildTableCell('\$${position.avgPrice.toStringAsFixed(2)}'),
                      _buildTableCell('\$${position.currentPrice.toStringAsFixed(2)}'),
                      _buildTableCell(
                        '\$${position.pnl.toStringAsFixed(2)}',
                        color: position.pnl >= 0 ? _successColor : _dangerColor,
                      ),
                      _buildTableCell('\$${(position.quantity * position.currentPrice).toStringAsFixed(2)}'),
                    ],
                  );
                }),
              ],
            ),
            pw.SizedBox(height: 20),
            pw.Text(
              'Total Portfolio Value: \$${positions.fold(0.0, (sum, p) => sum + p.quantity * p.currentPrice).toStringAsFixed(2)}',
              style: const pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
  
  static pw.Widget _buildTradeHistory(List<Order> orders) {
    return pw.Page(
      build: (context) => pw.Padding(
        padding: const pw.EdgeInsets.all(40),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              'Trade History',
              style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 20),
            pw.Divider(),
            pw.SizedBox(height: 20),
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300),
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                  children: [
                    _buildTableHeader('Date'),
                    _buildTableHeader('Symbol'),
                    _buildTableHeader('Side'),
                    _buildTableHeader('Qty'),
                    _buildTableHeader('Price'),
                    _buildTableHeader('Status'),
                  ],
                ),
                ...orders.take(50).map((order) {
                  return pw.TableRow(
                    children: [
                      _buildTableCell(DateFormat('MM/dd HH:mm').format(order.createdAt)),
                      _buildTableCell(order.symbol),
                      _buildTableCell(order.side.toUpperCase()),
                      _buildTableCell(order.quantity.toString()),
                      _buildTableCell('\$${order.price.toStringAsFixed(2)}'),
                      _buildTableCell(order.status),
                    ],
                  );
                }),
              ],
            ),
            if (orders.length > 50)
              pw.Padding(
                padding: const pw.EdgeInsets.only(top: 8),
                child: pw.Text(
                  'Showing 50 of ${orders.length} trades',
                  style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey),
                ),
              ),
          ],
        ),
      ),
    );
  }
  
  static pw.Widget _buildRiskAnalysis(Map<String, dynamic> metrics) {
    return pw.Page(
      build: (context) => pw.Padding(
        padding: const pw.EdgeInsets.all(40),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              'Risk Analysis',
              style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 20),
            pw.Divider(),
            pw.SizedBox(height: 20),
            _buildMetricRow('Value at Risk (95%)', '\$${metrics['var95'].toStringAsFixed(2)}', _dangerColor),
            pw.SizedBox(height: 10),
            _buildMetricRow('Expected Shortfall', '\$${metrics['expectedShortfall'].toStringAsFixed(2)}', _dangerColor),
            pw.SizedBox(height: 10),
            _buildMetricRow('Beta', metrics['beta'].toStringAsFixed(2), _getBetaColor(metrics['beta'])),
            pw.SizedBox(height: 10),
            _buildMetricRow('Alpha', '${(metrics['alpha'] * 100).toStringAsFixed(2)}%', _getAlphaColor(metrics['alpha'])),
            pw.SizedBox(height: 20),
            pw.Text(
              'Risk Recommendations',
              style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 10),
            ..._generateRiskRecommendations(metrics).map((rec) => pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 8),
              child: pw.Row(
                children: [
                  pw.Icon(pw.IconData(0xe88e), size: 16, color: _getRecommendationColor(rec['severity'])),
                  pw.SizedBox(width: 8),
                  pw.Expanded(child: pw.Text(rec['message'])),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }
  
  static pw.Widget _buildFutureOutlook(Map<String, dynamic> metrics) {
    return pw.Page(
      build: (context) => pw.Padding(
        padding: const pw.EdgeInsets.all(40),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              'Future Outlook',
              style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 20),
            pw.Divider(),
            pw.SizedBox(height: 20),
            pw.Text(
              'Predicted Performance',
              style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 10),
            _buildPredictionChart(metrics['predictions']),
            pw.SizedBox(height: 30),
            pw.Text(
              'Recommendations',
              style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 10),
            ..._generateRecommendations(metrics).map((rec) => pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 8),
              child: pw.Row(
                children: [
                  pw.Icon(pw.IconData(0xe8e8), size: 16, color: _primaryColor),
                  pw.SizedBox(width: 8),
                  pw.Expanded(child: pw.Text(rec)),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }
  
  static pw.Widget _buildPredictionChart(List<Map<String, dynamic>> predictions) {
    return pw.Container(
      height: 200,
      child: pw.CustomPaint(
        painter: pw.LineChartPainter(
          data: predictions.map((p) => p['value'] as double).toList(),
          minY: 0,
          maxY: predictions.map((p) => p['value'] as double).reduce((a, b) => a > b ? a : b) * 1.2,
          color: _primaryColor,
          showDots: true,
        ),
      ),
    );
  }
  
  static pw.Widget _buildTableHeader(String text) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(text, style: const pw.TextStyle(fontWeight: pw.FontWeight.bold)),
    );
  }
  
  static pw.Widget _buildTableCell(String text, {PdfColor? color}) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(text, style: color != null ? pw.TextStyle(color: color) : null),
    );
  }
  
  static List<String> _generateInsights(Map<String, dynamic> metrics) {
    final insights = <String>[];
    
    if (metrics['totalReturn'] > 0.2) {
      insights.add('Exceptional performance with 20%+ returns');
    } else if (metrics['totalReturn'] > 0.1) {
      insights.add('Solid performance exceeding market average');
    } else if (metrics['totalReturn'] < 0) {
      insights.add('Negative returns - review trading strategy');
    }
    
    if (metrics['sharpeRatio'] > 2) {
      insights.add('Excellent risk-adjusted returns');
    } else if (metrics['sharpeRatio'] < 1) {
      insights.add('Risk-adjusted returns below optimal levels');
    }
    
    if (metrics['winRate'] > 0.6) {
      insights.add('High win rate indicates good strategy selection');
    } else if (metrics['winRate'] < 0.4) {
      insights.add('Low win rate - consider reducing position sizes');
    }
    
    return insights;
  }
  
  static List<Map<String, String>> _generateRiskRecommendations(Map<String, dynamic> metrics) {
    final recommendations = <Map<String, String>>[];
    
    if (metrics['maxDrawdown'] > 0.2) {
      recommendations.add({
        'severity': 'high',
        'message': 'High drawdown detected - implement stricter stop-losses',
      });
    }
    
    if (metrics['beta'] > 1.5) {
      recommendations.add({
        'severity': 'medium',
        'message': 'Portfolio has high market correlation - consider diversification',
      });
    }
    
    if (metrics['concentrationRisk'] > 0.3) {
      recommendations.add({
        'severity': 'high',
        'message': 'High concentration risk - reduce position sizes in top holdings',
      });
    }
    
    return recommendations;
  }
  
  static List<String> _generateRecommendations(Map<String, dynamic> metrics) {
    final recommendations = <String>[];
    
    if (metrics['totalReturn'] > 0.2 && metrics['sharpeRatio'] > 2) {
      recommendations.add('✓ Maintain current strategy - strong performance metrics');
    }
    
    if (metrics['winRate'] < 0.4) {
      recommendations.add('→ Consider reducing position sizes to improve win rate');
    }
    
    if (metrics['maxDrawdown'] > 0.15) {
      recommendations.add('→ Implement trailing stop-losses to protect profits');
    }
    
    if (metrics['concentrationRisk'] > 0.25) {
      recommendations.add('→ Diversify portfolio to reduce concentration risk');
    }
    
    return recommendations;
  }
  
  static PdfColor _getPerformanceColor(double return_) {
    if (return_ > 0.2) return PdfColors.green;
    if (return_ > 0) return PdfColors.lightGreen;
    if (return_ > -0.1) return PdfColors.orange;
    return PdfColors.red;
  }
  
  static PdfColor _getSharpeColor(double sharpe) {
    if (sharpe > 2) return PdfColors.green;
    if (sharpe > 1) return PdfColors.lightGreen;
    if (sharpe > 0) return PdfColors.orange;
    return PdfColors.red;
  }
  
  static PdfColor _getWinRateColor(double winRate) {
    if (winRate > 0.6) return PdfColors.green;
    if (winRate > 0.4) return PdfColors.orange;
    return PdfColors.red;
  }
  
  static PdfColor _getProfitFactorColor(double pf) {
    if (pf > 2) return PdfColors.green;
    if (pf > 1) return PdfColors.orange;
    return PdfColors.red;
  }
  
  static PdfColor _getBetaColor(double beta) {
    if (beta.between(0.8, 1.2)) return PdfColors.green;
    if (beta.between(0.5, 1.5)) return PdfColors.orange;
    return PdfColors.red;
  }
  
  static PdfColor _getAlphaColor(double alpha) {
    if (alpha > 0) return PdfColors.green;
    return PdfColors.red;
  }
  
  static PdfColor _getTradeColor(int trades, int maxTrades) {
    final ratio = trades / maxTrades;
    if (ratio > 0.7) return PdfColors.red;
    if (ratio > 0.4) return PdfColors.orange;
    return PdfColors.lightGreen;
  }
  
  static PdfColor _getReturnColor(double return_) {
    if (return_ > 0.05) return PdfColors.green;
    if (return_ > 0) return PdfColors.lightGreen;
    if (return_ > -0.05) return PdfColors.orange;
    return PdfColors.red;
  }
  
  static PdfColor _getRecommendationColor(String severity) {
    switch (severity) {
      case 'high':
        return PdfColors.red;
      case 'medium':
        return PdfColors.orange;
      default:
        return PdfColors.green;
    }
  }
}

extension on double {
  bool between(double min, double max) => this >= min && this <= max;
}