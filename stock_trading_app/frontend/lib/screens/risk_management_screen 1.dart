import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:stock_trading_app/providers/risk_provider.dart';
import 'package:stock_trading_app/providers/positions_provider.dart';
import 'package:stock_trading_app/widgets/risk_gauge.dart';
import 'package:stock_trading_app/widgets/portfolio_allocation_chart.dart';

class RiskManagementScreen extends ConsumerStatefulWidget {
  const RiskManagementScreen({super.key});

  @override
  ConsumerState<RiskManagementScreen> createState() => _RiskManagementScreenState();
}

class _RiskManagementScreenState extends ConsumerState<RiskManagementScreen> {
  @override
  void initState() {
    super.initState();
    _updateRiskMetrics();
  }

  Future<void> _updateRiskMetrics() async {
    final positions = await ref.read(positionsProvider.future);
    ref.read(riskProvider.notifier).updateMetricsFromPositions(positions);
  }

  @override
  Widget build(BuildContext context) {
    final riskMetrics = ref.watch(riskProvider);
    final positionsAsync = ref.watch(positionsProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Risk Summary Cards
          Row(
            children: [
              Expanded(
                child: _RiskCard(
                  title: 'Total Exposure',
                  value: '\$${riskMetrics.totalExposure.toStringAsFixed(2)}',
                  subtitle: 'Portfolio Value',
                  color: Colors.blue,
                  icon: Icons.account_balance_wallet,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _RiskCard(
                  title: 'Max Drawdown',
                  value: '${riskMetrics.maxDrawdown.toStringAsFixed(2)}%',
                  subtitle: 'Historical Peak to Trough',
                  color: Colors.red,
                  icon: Icons.trending_down,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _RiskCard(
                  title: 'Sharpe Ratio',
                  value: riskMetrics.sharpeRatio.toStringAsFixed(2),
                  subtitle: 'Risk-Adjusted Return',
                  color: Colors.green,
                  icon: Icons.show_chart,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          // Risk Gauges
          Row(
            children: [
              Expanded(
                child: RiskGauge(
                  title: 'Risk Score',
                  value: _calculateRiskScore(riskMetrics),
                  maxValue: 100,
                  color: _getRiskColor(_calculateRiskScore(riskMetrics)),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: RiskGauge(
                  title: 'Portfolio Volatility',
                  value: riskMetrics.volatility * 100,
                  maxValue: 100,
                  color: Colors.orange,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: RiskGauge(
                  title: 'Concentration Risk',
                  value: riskMetrics.concentrationRisk * 100,
                  maxValue: 100,
                  color: Colors.purple,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          // Portfolio Allocation Chart
          Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Portfolio Allocation',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 300,
                    child: PortfolioAllocationChart(positions: positionsAsync.value ?? []),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          
          // Risk Limits Configuration
          Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Risk Limits Configuration',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  _RiskLimitSlider(
                    label: 'Max Position Size (% of portfolio)',
                    value: riskMetrics.maxPositionSize * 100,
                    minValue: 0,
                    maxValue: 50,
                    onChanged: (value) => ref.read(riskProvider.notifier).updateMaxPositionSize(value / 100),
                  ),
                  const SizedBox(height: 16),
                  _RiskLimitSlider(
                    label: 'Max Daily Loss (%)',
                    value: riskMetrics.maxDailyLoss * 100,
                    minValue: 0,
                    maxValue: 20,
                    onChanged: (value) => ref.read(riskProvider.notifier).updateMaxDailyLoss(value / 100),
                  ),
                  const SizedBox(height: 16),
                  _RiskLimitSlider(
                    label: 'Stop Loss (%)',
                    value: riskMetrics.stopLoss * 100,
                    minValue: 0,
                    maxValue: 30,
                    onChanged: (value) => ref.read(riskProvider.notifier).updateStopLoss(value / 100),
                  ),
                  const SizedBox(height: 16),
                  _RiskLimitSlider(
                    label: 'Max Leverage',
                    value: riskMetrics.maxLeverage,
                    minValue: 1,
                    maxValue: 10,
                    onChanged: (value) => ref.read(riskProvider.notifier).updateMaxLeverage(value.toInt()),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          
          // Risk Warnings
          Card(
            elevation: 4,
            color: Colors.orange[50],
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.warning, color: Colors.orange),
                      SizedBox(width: 8),
                      Text(
                        'Risk Warnings',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildRiskWarning(
                    'Position Size Limit',
                    riskMetrics.maxPositionSize * 100,
                    _getLargestPositionSize(positionsAsync.value ?? []),
                  ),
                  const Divider(),
                  _buildRiskWarning(
                    'Daily Loss Limit',
                    riskMetrics.maxDailyLoss * 100,
                    riskMetrics.currentDailyLoss * 100,
                  ),
                  const Divider(),
                  _buildRiskWarning(
                    'Concentration Limit',
                    riskMetrics.maxConcentration * 100,
                    riskMetrics.concentrationRisk * 100,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRiskWarning(String label, double limit, double current) {
    final isExceeded = current > limit;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(label),
          ),
          Text(
            '${current.toStringAsFixed(1)}% / ${limit.toStringAsFixed(1)}%',
            style: TextStyle(
              color: isExceeded ? Colors.red : Colors.green,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (isExceeded)
            const Padding(
              padding: EdgeInsets.only(left: 8),
              child: Icon(Icons.error, color: Colors.red, size: 20),
            ),
        ],
      ),
    );
  }

  double _calculateRiskScore(RiskMetrics metrics) {
    double score = 100;
    // Penalize high drawdown
    if (metrics.maxDrawdown > 20) score -= 20;
    else if (metrics.maxDrawdown > 10) score -= 10;
    
    // Penalize high concentration
    if (metrics.concentrationRisk > 0.4) score -= 20;
    else if (metrics.concentrationRisk > 0.2) score -= 10;
    
    // Penalize high leverage
    if (metrics.maxLeverage > 3) score -= 20;
    else if (metrics.maxLeverage > 2) score -= 10;
    
    return score.clamp(0, 100);
  }

  Color _getRiskColor(double score) {
    if (score >= 70) return Colors.green;
    if (score >= 40) return Colors.orange;
    return Colors.red;
  }

  double _getLargestPositionSize(List<Position> positions) {
    if (positions.isEmpty) return 0;
    final totalValue = positions.fold(0.0, (sum, p) => sum + (p.quantity * p.currentPrice));
    if (totalValue == 0) return 0;
    final largestPosition = positions.map((p) => p.quantity * p.currentPrice).reduce((a, b) => a > b ? a : b);
    return (largestPosition / totalValue) * 100;
  }
}

class _RiskCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final Color color;
  final IconData icon;

  const _RiskCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 24),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(fontSize: 12, color: Colors.grey[500]),
            ),
          ],
        ),
      ),
    );
  }
}

class _RiskLimitSlider extends StatelessWidget {
  final String label;
  final double value;
  final double minValue;
  final double maxValue;
  final Function(double) onChanged;

  const _RiskLimitSlider({
    required this.label,
    required this.value,
    required this.minValue,
    required this.maxValue,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Slider(
                value: value,
                min: minValue,
                max: maxValue,
                onChanged: onChanged,
              ),
            ),
            const SizedBox(width: 16),
            Container(
              width: 60,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '${value.toStringAsFixed(1)}%',
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ],
    );
  }
}