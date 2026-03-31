import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stock_trading_app/models/chart_config.dart';
import 'package:stock_trading_app/services/api_service.dart';

final chartConfigProvider = StateNotifierProvider<ChartConfigNotifier, ChartConfig>((ref) {
  return ChartConfigNotifier();
});

final chartDataProvider = FutureProvider<Map<String, List<ChartData>>>((ref) async {
  final config = ref.watch(chartConfigProvider);
  // Fetch data for each symbol in config.symbols
  final apiService = ApiService();
  Map<String, List<ChartData>> data = {};
  for (var symbol in config.symbols) {
    // Implement historical data fetch
    data[symbol] = await apiService.getHistoricalData(symbol, config.timeframe);
  }
  return data;
});

class ChartConfigNotifier extends StateNotifier<ChartConfig> {
  final ApiService _apiService = ApiService();

  ChartConfigNotifier() : super(ChartConfig.defaultConfig()) {
    _loadConfig();
  }

  Future<void> _loadConfig() async {
    try {
      final config = await _apiService.getChartConfig();
      state = config;
    } catch (e) {
      print('Error loading chart config: $e');
    }
  }

  Future<void> updateConfig(ChartConfig newConfig) async {
    state = newConfig;
    try {
      await _apiService.updateChartConfig(newConfig);
    } catch (e) {
      print('Error saving chart config: $e');
    }
  }

  Future<void> refresh() async {
    await _loadConfig();
  }
}