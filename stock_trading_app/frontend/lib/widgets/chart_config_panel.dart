import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stock_trading_app/providers/chart_provider.dart';

class ChartConfigPanel extends ConsumerWidget {
  final VoidCallback onConfigChanged;

  const ChartConfigPanel({super.key, required this.onConfigChanged});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(chartConfigProvider);
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.grey[900],
      child: Row(
        children: [
          DropdownButton<String>(
            value: config.timeframe,
            items: const [
              DropdownMenuItem(value: '1m', child: Text('1 min')),
              DropdownMenuItem(value: '5m', child: Text('5 min')),
              DropdownMenuItem(value: '15m', child: Text('15 min')),
              DropdownMenuItem(value: '1h', child: Text('1 hour')),
              DropdownMenuItem(value: '1D', child: Text('1 day')),
              DropdownMenuItem(value: '1W', child: Text('1 week')),
            ],
            onChanged: (value) {
              if (value != null) {
                final newConfig = config.copyWith(timeframe: value);
                ref.read(chartConfigProvider.notifier).updateConfig(newConfig);
                onConfigChanged();
              }
            },
          ),
          const SizedBox(width: 16),
          ElevatedButton(
            onPressed: () {
              // Add indicator
              final newConfig = config.copyWith(
                indicators: [...config.indicators, 'New Indicator'],
              );
              ref.read(chartConfigProvider.notifier).updateConfig(newConfig);
              onConfigChanged();
            },
            child: const Text('Add Indicator'),
          ),
        ],
      ),
    );
  }
}