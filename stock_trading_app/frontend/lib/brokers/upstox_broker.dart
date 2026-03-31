import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:stock_trading_app/models/order.dart';
import 'package:stock_trading_app/models/position.dart';
import 'package:stock_trading_app/brokers/broker_interface.dart';

class UpstoxBroker implements BrokerInterface {
  String _accessToken = '';
  String _apiKey = '';
  String _apiSecret = '';
  
  static const String baseUrl = 'https://api.upstox.com/v2';
  
  @override
  String get name => 'Upstox';
  
  @override
  String get type => 'upstox';
  
  @override
  Future<bool> connect(String apiKey, String apiSecret) async {
    _apiKey = apiKey;
    _apiSecret = apiSecret;
    
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login/authorization/token'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'code': apiKey,
          'client_id': apiSecret,
          'client_secret': apiSecret,
          'redirect_uri': 'https://api.upstox.com/v2/login/redirect',
          'grant_type': 'authorization_code',
        }),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _accessToken = data['access_token'];
        return true;
      }
      return false;
    } catch (e) {
      print('Error connecting to Upstox: $e');
      return false;
    }
  }
  
  @override
  Future<void> disconnect() async {
    _accessToken = '';
  }
  
  @override
  Future<bool> isConnected() async {
    return _accessToken.isNotEmpty;
  }
  
  @override
  Future<Order> placeOrder(Order order) async {
    final response = await http.post(
      Uri.parse('$baseUrl/order/place'),
      headers: {
        'Authorization': 'Bearer $_accessToken',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'quantity': order.quantity,
        'product': 'D',
        'validity': 'DAY',
        'price': order.price,
        'tag': 'flutter_app',
        'instrument_token': order.symbol,
        'transaction_type': order.side.toUpperCase(),
        'order_type': order.type.toUpperCase(),
      }),
    );
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return Order(
        id: data['order_id'].toString(),
        brokerId: 'upstox',
        symbol: order.symbol,
        side: order.side,
        type: order.type,
        quantity: order.quantity,
        price: order.price,
        status: 'pending',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    }
    
    throw Exception('Failed to place order: ${response.body}');
  }
  
  @override
  Future<List<Order>> getOrders() async {
    final response = await http.get(
      Uri.parse('$baseUrl/order/get-orders'),
      headers: {
        'Authorization': 'Bearer $_accessToken',
      },
    );
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      List<Order> orders = [];
      
      for (var item in data['data']) {
        orders.add(Order(
          id: item['order_id'].toString(),
          brokerId: 'upstox',
          symbol: item['trading_symbol'],
          side: item['transaction_type'].toLowerCase(),
          type: item['order_type'].toLowerCase(),
          quantity: item['quantity'],
          price: double.parse(item['price'].toString()),
          status: item['status'].toLowerCase(),
          filledPrice: item['average_price'] != null 
              ? double.parse(item['average_price'].toString()) 
              : null,
          filledQuantity: item['filled_quantity'],
          createdAt: DateTime.parse(item['order_timestamp']),
          updatedAt: DateTime.parse(item['exchange_timestamp']),
        ));
      }
      
      return orders;
    }
    
    return [];
  }
  
  @override
  Future<List<Position>> getPositions() async {
    final response = await http.get(
      Uri.parse('$baseUrl/portfolio/short-term-positions'),
      headers: {
        'Authorization': 'Bearer $_accessToken',
      },
    );
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      List<Position> positions = [];
      
      for (var item in data['data']) {
        positions.add(Position(
          id: item['instrument_token'].toString(),
          brokerId: 'upstox',
          symbol: item['trading_symbol'],
          quantity: item['quantity'],
          avgPrice: double.parse(item['average_price'].toString()),
          currentPrice: double.parse(item['last_price'].toString()),
          pnl: double.parse(item['pnl'].toString()),
          updatedAt: DateTime.now(),
        ));
      }
      
      return positions;
    }
    
    return [];
  }
  
  @override
  Future<List<Holding>> getHoldings() async {
    final response = await http.get(
      Uri.parse('$baseUrl/portfolio/long-term-holdings'),
      headers: {
        'Authorization': 'Bearer $_accessToken',
      },
    );
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      List<Holding> holdings = [];
      
      for (var item in data['data']) {
        holdings.add(Holding(
          id: item['instrument_token'].toString(),
          brokerId: 'upstox',
          symbol: item['trading_symbol'],
          quantity: item['quantity'],
          purchasePrice: double.parse(item['average_price'].toString()),
          currentPrice: double.parse(item['ltp'].toString()),
          totalValue: double.parse(item['total_value'].toString()),
          updatedAt: DateTime.now(),
        ));
      }
      
      return holdings;
    }
    
    return [];
  }
  
  @override
  Future<double> getAccountBalance() async {
    final response = await http.get(
      Uri.parse('$baseUrl/user/get-funds-and-margin'),
      headers: {
        'Authorization': 'Bearer $_accessToken',
      },
    );
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return double.parse(data['data']['equity']['available_balance'].toString());
    }
    
    return 0;
  }
  
  @override
  Stream<Map<String, dynamic>> getMarketData(List<String> symbols) {
    // Implement WebSocket connection for Upstox
    return Stream.empty();
  }
}