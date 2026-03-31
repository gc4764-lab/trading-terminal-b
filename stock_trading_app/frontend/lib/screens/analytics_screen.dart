import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:stock_trading_app/services/analytics_service.dart';
import 'package:stock_trading_app/widgets/analytics_cards.dart';

class AnalyticsScreen extends ConsumerStatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  ConsumerState<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends ConsumerState<AnalyticsScreen> {
  late AnalyticsService _analyticsService;
  String _selectedTimeframe = '1M';
  bool _isLoading = true;
  Map<String, dynamic> _analyticsData = {};

  @override
  void initState() {
    super.initState();
    _analyticsService = AnalyticsService();
    _loadAnalytics();
  }

  Future<void> _loadAnalytics() async {
    setState(() => _isLoading = true);
    try {
      final data = await _analyticsService.getPerformanceMetrics(
        timeframe: _selectedTimeframe,
      );
      setState(() {
        _analyticsData = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      print('Error loading analytics: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Advanced Analytics'),
        actions: [
          DropdownButton<String>(
            value: _selectedTimeframe,
            items: const [
              DropdownMenuItem(value: '1W', child: Text('1 Week')),
              DropdownMenuItem(value: '1M', child: Text('1 Month')),
              DropdownMenuItem(value: '3M', child: Text('3 Months')),
              DropdownMenuItem(value: '6M', child: Text('6 Months')),
              DropdownMenuItem(value: '1Y', child: Text('1 Year')),
              DropdownMenuItem(value: 'ALL', child: Text('All Time')),
            ],
            onChanged: (value) {
              if (value != null) {
                setState(() => _selectedTimeframe = value);
                _loadAnalytics();
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAnalytics,
          ),
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: () => _exportAnalytics(),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Key Metrics Cards
                  Row(
                    children: [
                      Expanded(
                        child: AnalyticsCard(
                          title: 'Total Return',
                          value: _analyticsData['totalReturn'] ?? 0,
                          prefix: '\$',
                          color: Colors.green,
                          icon: Icons.trending_up,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: AnalyticsCard(
                          title: 'Sharpe Ratio',
                          value: _analyticsData['sharpeRatio'] ?? 0,
                          precision: 2,
                          color: Colors.blue,
                          icon: Icons.show_chart,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: AnalyticsCard(
                          title: 'Max Drawdown',
                          value: _analyticsData['maxDrawdown'] ?? 0,
                          suffix: '%',
                          color: Colors.red,
                          icon: Icons.trending_down,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  // Performance Chart
                  Card(
                    elevation: 4,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Portfolio Performance',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            height: 400,
                            child: SfCartesianChart(
                              primaryXAxis: DateTimeAxis(
                                title: AxisTitle(text: 'Date'),
                              ),
                              primaryYAxis: NumericAxis(
                                title: AxisTitle(text: 'Value (\$)'),
                                numberFormat: '\$#,##0',
                              ),
                              series: <ChartSeries>[
                                LineSeries<PerformancePoint, DateTime>(
                                  dataSource: _analyticsData['performanceData'],
                                  xValueMapper: (PerformancePoint data, _) => data.date,
                                  yValueMapper: (PerformancePoint data, _) => data.value,
                                  name: 'Portfolio Value',
                                  color: Colors.blue,
                                  markerSettings: const MarkerSettings(isVisible: false),
                                ),
                                LineSeries<PerformancePoint, DateTime>(
                                  dataSource: _analyticsData['benchmarkData'],
                                  xValueMapper: (PerformancePoint data, _) => data.date,
                                  yValueMapper: (PerformancePoint data, _) => data.value,
                                  name: 'Benchmark',
                                  color: Colors.grey,
                                  dashArray: [5, 5],
                                  markerSettings: const MarkerSettings(isVisible: false),
                                ),
                              ],
                              tooltipBehavior: TooltipBehavior(enable: true),
                              zoomPanBehavior: ZoomPanBehavior(
                                enablePinching: true,
                                enablePanning: true,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Risk Metrics Grid
                  const Text(
                    'Risk Metrics',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1.5,
                    children: [
                      RiskMetricCard(
                        title: 'Value at Risk (95%)',
                        value: _analyticsData['var95'] ?? 0,
                        prefix: '\$',
                        description: 'Maximum expected loss',
                      ),
                      RiskMetricCard(
                        title: 'Expected Shortfall',
                        value: _analyticsData['expectedShortfall'] ?? 0,
                        prefix: '\$',
                        description: 'Average loss beyond VaR',
                      ),
                      RiskMetricCard(
                        title: 'Beta',
                        value: _analyticsData['beta'] ?? 0,
                        precision: 2,
                        description: 'Market correlation',
                      ),
                      RiskMetricCard(
                        title: 'Alpha',
                        value: _analyticsData['alpha'] ?? 0,
                        precision: 2,
                        suffix: '%',
                        description: 'Excess return',
                      ),
                      RiskMetricCard(
                        title: 'Sortino Ratio',
                        value: _analyticsData['sortinoRatio'] ?? 0,
                        precision: 2,
                        description: 'Downside risk-adjusted return',
                      ),
                      RiskMetricCard(
                        title: 'Calmar Ratio',
                        value: _analyticsData['calmarRatio'] ?? 0,
                        precision: 2,
                        description: 'Return vs max drawdown',
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  // Trade Analysis
                  Card(
                    elevation: 4,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Trade Analysis',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: _buildTradeMetric(
                                  'Win Rate',
                                  '${(_analyticsData['winRate'] ?? 0).toStringAsFixed(1)}%',
                                  Icons.thumb_up,
                                  Colors.green,
                                ),
                              ),
                              Expanded(
                                child: _buildTradeMetric(
                                  'Profit Factor',
                                  (_analyticsData['profitFactor'] ?? 0).toStringAsFixed(2),
                                  Icons.assessment,
                                  Colors.blue,
                                ),
                              ),
                              Expanded(
                                child: _buildTradeMetric(
                                  'Avg Win/Loss',
                                  '${(_analyticsData['avgWinLoss'] ?? 0).toStringAsFixed(2)}',
                                  Icons.compare_arrows,
                                  Colors.orange,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            height: 300,
                            child: BarChart(
                              BarChartData(
                                barGroups: _buildTradeDistribution(),
                                titlesData: FlTitlesData(
                                  bottomTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      getTitlesWidget: (value, meta) {
                                        const titles = ['Winning', 'Losing', 'Break-even'];
                                        return Text(titles[value.toInt()]);
                                      },
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Monthly Returns Heatmap
                  Card(
                    elevation: 4,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Monthly Returns Heatmap',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildMonthlyHeatmap(_analyticsData['monthlyReturns'] ?? {}),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildTradeMetric(String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            Text(
              title,
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  List<BarChartGroupData> _buildTradeDistribution() {
    final data = _analyticsData['tradeDistribution'] ?? {};
    return [
      BarChartGroupData(x: 0, bars: [BarChartRodData(toY: data['winning'] ?? 0, color: Colors.green)]),
      BarChartGroupData(x: 1, bars: [BarChartRodData(toY: data['losing'] ?? 0, color: Colors.red)]),
      BarChartGroupData(x: 2, bars: [BarChartRodData(toY: data['breakeven'] ?? 0, color: Colors.grey)]),
    ];
  }

  Widget _buildMonthlyHeatmap(Map<String, double> monthlyReturns) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 12,
        childAspectRatio: 1,
        crossAxisSpacing: 2,
        mainAxisSpacing: 2,
      ),
      itemCount: 12,
      itemBuilder: (context, index) {
        final month = index + 1;
        final return_ = monthlyReturns['$month'] ?? 0;
        final color = _getReturnColor(return_);
        
        return Container(
          decoration: BoxDecoration(
            color: color,
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Center(
            child: Text(
              '${return_.toStringAsFixed(1)}%',
              style: TextStyle(
                color: return_.abs() > 5 ? Colors.white : Colors.black,
                fontSize: 10,
              ),
            ),
          ),
        );
      },
    );
  }

  Color _getReturnColor(double return_) {
    if (return_ > 10) return Colors.green[900]!;
    if (return_ > 5) return Colors.green[700]!;
    if (return_ > 2) return Colors.green[500]!;
    if (return_ > 0) return Colors.green[300]!;
    if (return_ > -2) return Colors.red[300]!;
    if (return_ > -5) return Colors.red[500]!;
    if (return_ > -10) return Colors.red[700]!;
    return Colors.red[900]!;
  }

  void _exportAnalytics() async {
    // Export analytics data
  }
}

class PerformancePoint {
  final DateTime date;
  final double value;
  
  PerformancePoint({required this.date, required this.value});
}

class RiskMetricCard extends StatelessWidget {
  final String title;
  final double value;
  final String? prefix;
  final String? suffix;
  final int precision;
  final String description;

  const RiskMetricCard({
    super.key,
    required this.title,
    required this.value,
    this.prefix,
    this.suffix,
    this.precision = 0,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
            const SizedBox(height: 8),
            Text(
              '${prefix ?? ''}${value.toStringAsFixed(precision)}${suffix ?? ''}',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              description,
              style: TextStyle(color: Colors.grey[500], fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }
}