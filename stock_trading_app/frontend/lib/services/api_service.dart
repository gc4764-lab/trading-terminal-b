import 'package:dio/dio.dart';
import 'package:stock_trading_app/models/watchlist.dart';
import 'package:stock_trading_app/models/alert.dart';
import 'package:stock_trading_app/models/order.dart';
import 'package:stock_trading_app/models/position.dart';

class ApiService {
  static const String baseUrl = 'http://localhost:8080/api';
  final Dio _dio = Dio(BaseOptions(baseUrl: baseUrl));

  // Watchlist endpoints
  Future<List<WatchlistItem>> getWatchlist() async {
    final response = await _dio.get('/watchlist');
    return (response.data as List)
        .map((json) => WatchlistItem.fromJson(json))
        .toList();
  }

  Future<WatchlistItem> addToWatchlist(WatchlistItem item) async {
    final response = await _dio.post('/watchlist', data: item.toJson());
    return WatchlistItem.fromJson(response.data);
  }

  Future<WatchlistItem> updateWatchlistItem(WatchlistItem item) async {
    final response = await _dio.put('/watchlist/${item.id}', data: item.toJson());
    return WatchlistItem.fromJson(response.data);
  }

  Future<void> deleteFromWatchlist(String id) async {
    await _dio.delete('/watchlist/$id');
  }

  // Alert endpoints
  Future<List<Alert>> getAlerts() async {
    final response = await _dio.get('/alerts');
    return (response.data as List)
        .map((json) => Alert.fromJson(json))
        .toList();
  }

  Future<Alert> createAlert(Alert alert) async {
    final response = await _dio.post('/alerts', data: alert.toJson());
    return Alert.fromJson(response.data);
  }

  Future<Alert> updateAlert(Alert alert) async {
    final response = await _dio.put('/alerts/${alert.id}', data: alert.toJson());
    return Alert.fromJson(response.data);
  }

  Future<void> deleteAlert(String id) async {
    await _dio.delete('/alerts/$id');
  }

  // Order endpoints
  Future<List<Order>> getOrders() async {
    final response = await _dio.get('/orders');
    return (response.data as List)
        .map((json) => Order.fromJson(json))
        .toList();
  }

  Future<Order> placeOrder(Order order) async {
    final response = await _dio.post('/orders', data: order.toJson());
    return Order.fromJson(response.data);
  }

  // Position endpoints
  Future<List<Position>> getPositions() async {
    final response = await _dio.get('/positions');
    return (response.data as List)
        .map((json) => Position.fromJson(json))
        .toList();
  }

  Future<List<Holding>> getHoldings() async {
    final response = await _dio.get('/holdings');
    return (response.data as List)
        .map((json) => Holding.fromJson(json))
        .toList();
  }

  // News endpoint
  Future<List<News>> getLatestNews() async {
    final response = await _dio.get('/news');
    return (response.data as List)
        .map((json) => News.fromJson(json))
        .toList();
  }

  // Settings endpoints
  Future<Settings> getSettings() async {
    final response = await _dio.get('/settings');
    return Settings.fromJson(response.data);
  }

  Future<Settings> updateSettings(Settings settings) async {
    final response = await _dio.put('/settings', data: settings.toJson());
    return Settings.fromJson(response.data);
  }

  // Chart config endpoints
  Future<ChartConfig> getChartConfig() async {
    final response = await _dio.get('/charts/config');
    return ChartConfig.fromJson(response.data);
  }

  Future<ChartConfig> updateChartConfig(ChartConfig config) async {
    final response = await _dio.put('/charts/config', data: config.toJson());
    return ChartConfig.fromJson(response.data);
  }

  // Broker endpoints
  Future<List<BrokerConfig>> getBrokers() async {
    final response = await _dio.get('/brokers');
    return (response.data as List)
        .map((json) => BrokerConfig.fromJson(json))
        .toList();
  }

  Future<BrokerConfig> connectBroker(BrokerConfig config) async {
    final response = await _dio.post('/brokers', data: config.toJson());
    return BrokerConfig.fromJson(response.data);
  }

  Future<void> disconnectBroker(String id) async {
    await _dio.delete('/brokers/$id');
  }
  
  
  // added later
  // News
Future<List<News>> getLatestNews() async {
  final response = await _dio.get('/news');
  return (response.data as List)
      .map((json) => News.fromJson(json))
      .toList();
}

// Chart
Future<ChartConfig> getChartConfig() async {
  final response = await _dio.get('/charts/config');
  return ChartConfig.fromJson(response.data);
}

Future<ChartConfig> updateChartConfig(ChartConfig config) async {
  final response = await _dio.put('/charts/config', data: config.toJson());
  return ChartConfig.fromJson(response.data);
}

// Historical data
Future<List<ChartData>> getHistoricalData(String symbol, String timeframe) async {
  // Replace with actual API call
  final response = await _dio.get('/market/historical', queryParameters: {
    'symbol': symbol,
    'timeframe': timeframe,
  });
  return (response.data as List)
      .map((json) => ChartData.fromJson(json))
      .toList();
}

// Broker
Future<List<BrokerConfig>> getBrokers() async {
  final response = await _dio.get('/brokers');
  return (response.data as List)
      .map((json) => BrokerConfig.fromJson(json))
      .toList();
}

Future<BrokerConfig> connectBroker(BrokerConfig config) async {
  final response = await _dio.post('/brokers', data: config.toJson());
  return BrokerConfig.fromJson(response.data);
}

Future<void> disconnectBroker(String id) async {
  await _dio.delete('/brokers/$id');
}
}

// added later

class ChartData {
  final DateTime date;
  final double open;
  final double high;
  final double low;
  final double close;
  final double volume;

  ChartData({
    required this.date,
    required this.open,
    required this.high,
    required this.low,
    required this.close,
    required this.volume,
  });

  factory ChartData.fromJson(Map<String, dynamic> json) {
    return ChartData(
      date: DateTime.parse(json['date']),
      open: json['open'].toDouble(),
      high: json['high'].toDouble(),
      low: json['low'].toDouble(),
      close: json['close'].toDouble(),
      volume: json['volume'].toDouble(),
    );
  }
}