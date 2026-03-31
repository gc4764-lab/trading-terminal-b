import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:stock_trading_app/widgets/chart_config_panel.dart';
import 'package:stock_trading_app/providers/chart_provider.dart';

class ChartGridScreen extends ConsumerStatefulWidget {
  const ChartGridScreen({super.key});

  @override
  ConsumerState<ChartGridScreen> createState() => _ChartGridScreenState();
}

class _ChartGridScreenState extends ConsumerState<ChartGridScreen> {
  bool _showConfig = false;

  @override
  Widget build(BuildContext context) {
    final chartConfig = ref.watch(chartConfigProvider);
    final chartData = ref.watch(chartDataProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chart Grid'),
        actions: [
          IconButton(
            icon: Icon(_showConfig ? Icons.close : Icons.settings),
            onPressed: () => setState(() => _showConfig = !_showConfig),
          ),
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => _showEditConfigDialog(),
          ),
        ],
      ),
      body: Column(
        children: [
          if (_showConfig) ChartConfigPanel(onConfigChanged: _updateConfig),
          Expanded(
            child: GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: chartConfig.columns,
                childAspectRatio: 1.5,
              ),
              itemCount: chartConfig.symbols.length,
              itemBuilder: (context, index) {
                return Card(
                  margin: const EdgeInsets.all(8),
                  child: _buildChart(chartConfig.symbols[index], chartData),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChart(String symbol, Map<String, List<ChartData>> data) {
    final seriesData = data[symbol] ?? [];
    
    return SfCartesianChart(
      title: ChartTitle(text: symbol),
      primaryXAxis: DateTimeAxis(),
      primaryYAxis: NumericAxis(),
      series: <ChartSeries>[
        LineSeries<ChartData, DateTime>(
          dataSource: seriesData,
          xValueMapper: (ChartData data, _) => data.date,
          yValueMapper: (ChartData data, _) => data.price,
          color: Colors.blue,
        ),
      ],
      tooltipBehavior: TooltipBehavior(enable: true),
    );
  }

  void _showEditConfigDialog() {
    showDialog(
      context: context,
      builder: (context) => ChartConfigDialog(
        config: ref.read(chartConfigProvider),
        onSave: (newConfig) {
          ref.read(chartConfigProvider.notifier).updateConfig(newConfig);
        },
      ),
    );
  }

  void _updateConfig() {
    ref.read(chartConfigProvider.notifier).refresh();
  }
}