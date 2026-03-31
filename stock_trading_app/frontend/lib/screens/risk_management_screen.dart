import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:stock_trading_app/providers/risk_provider.dart';

class RiskManagementScreen extends ConsumerWidget {
  const RiskManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final riskMetrics = ref.watch(riskProvider);
    final positions = ref.watch(positionsProvider);

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
                  color: Colors.blue,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _RiskCard(
                  title: 'Max Drawdown',
                  value: '${riskMetrics.maxDrawdown.toStringAsFixed(2)}%',
                  color: Colors.red,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _RiskCard(
                  title: 'Sharpe Ratio',
                  value: riskMetrics.sharpeRatio.toStringAsFixed(2),
                  color: Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          // Portfolio Allocation Chart
          Card(
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
                    child: PieChart(
                      PieChartData(
                        sections: _buildPieSections(positions),
                        centerSpaceRadius: 40,
                        sectionsSpace: 2,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          
          // Risk Limits Configuration
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Risk Limits',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  _RiskLimitSlider(
                    label: 'Max Position Size (% of portfolio)',
                    value: riskMetrics.maxPositionSize,
                    onChanged: (value) => ref.read(riskProvider.notifier).updateMaxPositionSize(value),
                  ),
                  _RiskLimitSlider(
                    label: 'Max Daily Loss (%)',
                    value: riskMetrics.maxDailyLoss,
                    onChanged: (value) => ref.read(riskProvider.notifier).updateMaxDailyLoss(value),
                  ),
                  _RiskLimitSlider(
                    label: 'Stop Loss (%)',
                    value: riskMetrics.stopLoss,
                    onChanged: (value) => ref.read(riskProvider.notifier).updateStopLoss(value),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<PieChartSectionData> _buildPieSections(List<Position> positions) {
    // Calculate allocation based on positions
    // Implementation details
    return [];
  }
}

class _RiskCard extends StatelessWidget {
  final String title;
  final String value;
  final Color color;

  const _RiskCard({
    required this.title,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}