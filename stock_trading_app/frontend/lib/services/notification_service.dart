import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:stock_trading_app/models/alert.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  static final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  
  static Future<void> initialize() async {
    // Initialize local notifications
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings();
    const settings = InitializationSettings(android: android, iOS: ios);
    
    await _localNotifications.initialize(settings);
    
    // Initialize Firebase Cloud Messaging
    await _firebaseMessaging.requestPermission();
    
    // Get FCM token
    final token = await _firebaseMessaging.getToken();
    print('FCM Token: $token');
    
    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    
    // Handle background messages
    FirebaseMessaging.onBackgroundMessage(_handleBackgroundMessage);
  }
  
  static Future<void> sendAlertNotification(Alert alert, double currentPrice) async {
    final title = 'Alert Triggered: ${alert.symbol}';
    final body = '${alert.symbol} ${alert.condition} ${alert.value} - Current: $currentPrice';
    
    // Send local notification
    await _showLocalNotification(title, body, alert.id);
    
    // Send push notification
    await _sendPushNotification(title, body, {
      'alertId': alert.id,
      'symbol': alert.symbol,
      'currentPrice': currentPrice.toString(),
    });
  }
  
  static Future<void> sendOrderNotification(String symbol, String side, int quantity, double price) async {
    final title = 'Order ${side.toUpperCase()}';
    final body = '$quantity shares of $symbol at \$${price.toStringAsFixed(2)}';
    
    await _showLocalNotification(title, body, 'order_${DateTime.now().millisecondsSinceEpoch}');
  }
  
  static Future<void> sendPriceAlert(String symbol, double price, double target) async {
    final title = 'Price Alert: $symbol';
    final body = '$symbol reached \$${price.toStringAsFixed(2)} (Target: \$${target.toStringAsFixed(2)})';
    
    await _showLocalNotification(title, body, 'price_alert_$symbol');
  }
  
  static Future<void> sendDailyReport(Map<String, dynamic> metrics) async {
    final title = 'Daily Trading Report';
    final body = 'PnL: \$${metrics['dailyPnL'].toStringAsFixed(2)} | Win Rate: ${(metrics['winRate'] * 100).toStringAsFixed(1)}%';
    
    await _showLocalNotification(title, body, 'daily_report');
  }
  
  static Future<void> _showLocalNotification(String title, String body, String id) async {
    const android = AndroidNotificationDetails(
      'trading_channel',
      'Trading Alerts',
      channelDescription: 'Real-time trading alerts and notifications',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
    );
    
    const ios = DarwinNotificationDetails();
    const details = NotificationDetails(android: android, iOS: ios);
    
    await _localNotifications.show(
      id.hashCode,
      title,
      body,
      details,
    );
  }
  
  static Future<void> _sendPushNotification(String title, String body, Map<String, String> data) async {
    // Send to FCM
    // Implementation depends on your backend
  }
  
  static Future<void> _handleForegroundMessage(RemoteMessage message) async {
    print('Received foreground message: ${message.data}');
    
    if (message.notification != null) {
      await _showLocalNotification(
        message.notification!.title ?? 'Alert',
        message.notification!.body ?? '',
        message.messageId ?? DateTime.now().millisecondsSinceEpoch.toString(),
      );
    }
  }
  
  @pragma('vm:entry-point')
  static Future<void> _handleBackgroundMessage(RemoteMessage message) async {
    print('Received background message: ${message.data}');
    // Handle background message
  }
  
  static Future<void> subscribeToTopic(String topic) async {
    await _firebaseMessaging.subscribeToTopic(topic);
  }
  
  static Future<void> unsubscribeFromTopic(String topic) async {
    await _firebaseMessaging.unsubscribeFromTopic(topic);
  }
}