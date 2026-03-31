import 'package:stock_trading_app/brokers/broker_interface.dart';
import 'package:stock_trading_app/brokers/zerodha_broker.dart';
import 'package:stock_trading_app/brokers/upstox_broker.dart';
import 'package:stock_trading_app/brokers/angel_broker.dart';

class BrokerFactory {
  static BrokerInterface? createBroker(String type) {
    switch (type.toLowerCase()) {
      case 'zerodha':
        return ZerodhaBroker();
      case 'upstox':
        return UpstoxBroker();
      case 'angel':
        return AngelBroker();
      default:
        return null;
    }
  }
  
  static List<String> getSupportedBrokers() {
    return ['zerodha', 'upstox', 'angel'];
  }
}