import 'package:stock_trading_app/models/order.dart';
import 'package:stock_trading_app/models/position.dart';

abstract class BrokerInterface {
  String get name;
  String get type;
  
  Future<bool> connect(String apiKey, String apiSecret);
  Future<void> disconnect();
  Future<bool> isConnected();
  
  Future<Order> placeOrder(Order order);
  Future<List<Order>> getOrders();
  Future<List<Position>> getPositions();
  Future<List<Holding>> getHoldings();
  Future<double> getAccountBalance();
  
  Stream<Map<String, dynamic>> getMarketData(List<String> symbols);
}