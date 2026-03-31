class Settings {
  final String theme;
  final int fontSize;
  final bool notifications;
  final bool autoRefresh;
  final int refreshRate;

  Settings({
    required this.theme,
    required this.fontSize,
    required this.notifications,
    required this.autoRefresh,
    required this.refreshRate,
  });

  factory Settings.defaultSettings() {
    return Settings(
      theme: 'system',
      fontSize: 14,
      notifications: true,
      autoRefresh: true,
      refreshRate: 5,
    );
  }

  factory Settings.fromJson(Map<String, dynamic> json) {
    return Settings(
      theme: json['theme'],
      fontSize: json['fontSize'],
      notifications: json['notifications'],
      autoRefresh: json['autoRefresh'],
      refreshRate: json['refreshRate'],
    );
  }

  Map<String, dynamic> toJson() => {
    'theme': theme,
    'fontSize': fontSize,
    'notifications': notifications,
    'autoRefresh': autoRefresh,
    'refreshRate': refreshRate,
  };

  Settings copyWith({
    String? theme,
    int? fontSize,
    bool? notifications,
    bool? autoRefresh,
    int? refreshRate,
  }) {
    return Settings(
      theme: theme ?? this.theme,
      fontSize: fontSize ?? this.fontSize,
      notifications: notifications ?? this.notifications,
      autoRefresh: autoRefresh ?? this.autoRefresh,
      refreshRate: refreshRate ?? this.refreshRate,
    );
  }
}