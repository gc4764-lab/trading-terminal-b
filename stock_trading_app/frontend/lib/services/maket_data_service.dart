import 'dart:async';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:stock_trading_app/models/chart_config.dart';

class MarketDataService {
  static const String wsUrl = 'ws://localhost:8080/ws';
  WebSocketChannel? _channel;
  final Map<String, List<StreamController<Map<String, dynamic>>>> _subscriptions = {};

  Future<void> connect() async {
    _channel = WebSocketChannel.connect(Uri.parse(wsUrl));
    
    _channel!.stream.listen((message) {
      final data = Map<String, dynamic>.from(message);
      final symbol = data['symbol'];
      
      if (_subscriptions.containsKey(symbol)) {
        for (var controller in _subscriptions[symbol]!) {
          controller.add(data);
        }
      }
    });
  }

  Stream<Map<String, dynamic>> subscribe(String symbol) {
    final controller = StreamController<Map<String, dynamic>>();
    
    if (!_subscriptions.containsKey(symbol)) {
      _subscriptions[symbol] = [];
    }
    _subscriptions[symbol]!.add(controller);
    
    // Send subscription request
    _channel?.sink.add({
      'action': 'subscribe',
      'symbol': symbol,
    });
    
    return controller.stream;
  }

  void unsubscribe(String symbol) {
    _subscriptions.remove(symbol);
    
    // Send unsubscription request
    _channel?.sink.add({
      'action': 'unsubscribe',
      'symbol': symbol,
    });
  }

  Future<List<ChartData>> getHistoricalData(String symbol, String timeframe) async {
    // Implement historical data fetching
    // This would call your backend API
    return [];
  }

  void dispose() {
    _channel?.sink.close();
    for (var controllers in _subscriptions.values) {
      for (var controller in controllers) {
        controller.close();
      }
    }
    _subscriptions.clear();
  }
}