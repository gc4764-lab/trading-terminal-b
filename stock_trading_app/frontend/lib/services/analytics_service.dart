import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_analytics/observer.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

class AnalyticsService {
  static final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;
  
  static void logScreenView(String screenName) {
    _analytics.logScreenView(
      screenName: screenName,
      screenClass: screenName,
    );
  }
  
  static void logEvent(String name, {Map<String, dynamic>? parameters}) {
    _analytics.logEvent(
      name: name,
      parameters: parameters,
    );
  }
  
  static void logOrder(Order order) {
    _analytics.logEvent(
      name: 'order_placed',
      parameters: {
        'symbol': order.symbol,
        'side': order.side,
        'quantity': order.quantity,
        'type': order.type,
      },
    );
  }
  
  static void logError(dynamic error, StackTrace? stackTrace) {
    Sentry.captureException(
      error,
      stackTrace: stackTrace,
    );
    
    _analytics.logEvent(
      name: 'error',
      parameters: {
        'error': error.toString(),
      },
    );
  }
  
  static Future<void> setUserProperties({
    String? userId,
    String? userName,
    String? email,
  }) async {
    if (userId != null) {
      await _analytics.setUserId(id: userId);
      Sentry.setUser(SentryUser(id: userId, email: email, username: userName));
    }
  }
}