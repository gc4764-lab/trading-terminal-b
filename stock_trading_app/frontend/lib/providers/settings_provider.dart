import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stock_trading_app/models/settings.dart';
import 'package:stock_trading_app/services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

final settingsProvider = StateNotifierProvider<SettingsNotifier, Settings>((ref) {
  return SettingsNotifier();
});

class SettingsNotifier extends StateNotifier<Settings> {
  SettingsNotifier() : super(Settings.defaultSettings()) {
    _loadSettings();
  }

  final ApiService _apiService = ApiService();

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final theme = prefs.getString('theme') ?? 'system';
      final fontSize = prefs.getInt('fontSize') ?? 14;
      final notifications = prefs.getBool('notifications') ?? true;
      final autoRefresh = prefs.getBool('autoRefresh') ?? true;
      final refreshRate = prefs.getInt('refreshRate') ?? 5;

      state = Settings(
        theme: theme,
        fontSize: fontSize,
        notifications: notifications,
        autoRefresh: autoRefresh,
        refreshRate: refreshRate,
      );
    } catch (e) {
      print('Error loading settings: $e');
    }
  }

  Future<void> updateSettings(Settings newSettings) async {
    state = newSettings;
    
    // Save to local storage
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('theme', newSettings.theme);
    await prefs.setInt('fontSize', newSettings.fontSize);
    await prefs.setBool('notifications', newSettings.notifications);
    await prefs.setBool('autoRefresh', newSettings.autoRefresh);
    await prefs.setInt('refreshRate', newSettings.refreshRate);
    
    // Sync with backend
    try {
      await _apiService.updateSettings(newSettings);
    } catch (e) {
      print('Error syncing settings: $e');
    }
  }

  void setTheme(String theme) {
    updateSettings(state.copyWith(theme: theme));
  }

  void setFontSize(int fontSize) {
    updateSettings(state.copyWith(fontSize: fontSize));
  }

  void setNotifications(bool enabled) {
    updateSettings(state.copyWith(notifications: enabled));
  }

  void setAutoRefresh(bool enabled) {
    updateSettings(state.copyWith(autoRefresh: enabled));
  }

  void setRefreshRate(int rate) {
    updateSettings(state.copyWith(refreshRate: rate));
  }
}