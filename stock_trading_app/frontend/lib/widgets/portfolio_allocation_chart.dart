import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:stock_trading_app/models/position.dart';

class PortfolioAllocationChart extends StatelessWidget {
  final List<Position> positions;

  const PortfolioAllocationChart({super.key, required this.positions});

  @override
  Widget build(BuildContext context) {
    if (positions.isEmpty) {
      return const Center(child: Text('No positions to display'));
    }

    final totalValue = positions.fold(0.0, (sum, p) => sum + (p.quantity * p.currentPrice));
    final pieSections = _buildPieSections(totalValue);

    return PieChart(
      PieChartData(
        sections: pieSections,
        centerSpaceRadius: 40,
        sectionsSpace: 2,
        pieTouchData: PieTouchData(
          touchCallback: (FlTouchEvent event, pieTouchResponse) {
            // Handle tap for detailed view
          },
        ),
      ),
    );
  }

  List<PieChartSectionData> _buildPieSections(double totalValue) {
    final sections = <PieChartSectionData>[];
    final colors = [
      Colors.blue,
      Colors.red,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.indigo,
      Colors.pink,
    ];

    for (int i = 0; i < positions.length && i < colors.length; i++) {
      final position = positions[i];
      final value = position.quantity * position.currentPrice;
      final percentage = (value / totalValue) * 100;
      
      sections.add(
        PieChartSectionData(
          color: colors[i % colors.length],
          value: value,
          title: '${position.symbol}\n${percentage.toStringAsFixed(1)}%',
          radius: 80,
          titleStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          badgeWidget: percentage > 15
              ? Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${percentage.toStringAsFixed(0)}%',
                    style: const TextStyle(fontSize: 10),
                  ),
                )
              : null,
        ),
      );
    }
    
    return sections;
  }
}