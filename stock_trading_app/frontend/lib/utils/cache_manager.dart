import 'package:hive_flutter/hive_flutter.dart';
import 'dart:convert';

class CacheManager {
  static const String _marketDataBox = 'market_data';
  static const String _settingsBox = 'settings';
  static const String _watchlistBox = 'watchlist';
  
  static Future<void> init() async {
    await Hive.initFlutter();
    await Hive.openBox(_marketDataBox);
    await Hive.openBox(_settingsBox);
    await Hive.openBox(_watchlistBox);
  }
  
  static Future<void> cacheMarketData(String symbol, dynamic data, {Duration ttl = const Duration(minutes: 5)}) async {
    final box = Hive.box(_marketDataBox);
    final cacheData = {
      'data': data,
      'expiresAt': DateTime.now().add(ttl).toIso8601String(),
    };
    await box.put(symbol, jsonEncode(cacheData));
  }
  
  static dynamic getCachedMarketData(String symbol) {
    final box = Hive.box(_marketDataBox);
    final cached = box.get(symbol);
    
    if (cached == null) return null;
    
    final cacheData = jsonDecode(cached);
    final expiresAt = DateTime.parse(cacheData['expiresAt']);
    
    if (DateTime.now().isAfter(expiresAt)) {
      box.delete(symbol);
      return null;
    }
    
    return cacheData['data'];
  }
  
  static Future<void> clearCache() async {
    await Hive.box(_marketDataBox).clear();
    await Hive.box(_watchlistBox).clear();
  }
  
  static Future<void> clearExpiredCache() async {
    final box = Hive.box(_marketDataBox);
    final keys = box.keys.toList();
    
    for (var key in keys) {
      final cached = box.get(key);
      if (cached != null) {
        final cacheData = jsonDecode(cached);
        final expiresAt = DateTime.parse(cacheData['expiresAt']);
        if (DateTime.now().isAfter(expiresAt)) {
          await box.delete(key);
        }
      }
    }
  }
}