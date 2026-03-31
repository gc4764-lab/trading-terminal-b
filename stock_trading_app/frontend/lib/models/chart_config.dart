class ChartConfig {
  final String id;
  final String layout; // grid, single
  final int rows;
  final int columns;
  final List<String> symbols;
  final String timeframe;
  final List<String> indicators;
  final DateTime updatedAt;

  ChartConfig({
    required this.id,
    required this.layout,
    required this.rows,
    required this.columns,
    required this.symbols,
    required this.timeframe,
    required this.indicators,
    required this.updatedAt,
  });

  factory ChartConfig.defaultConfig() {
    return ChartConfig(
      id: 'default',
      layout: 'grid',
      rows: 2,
      columns: 2,
      symbols: ['AAPL', 'GOOGL', 'MSFT', 'AMZN'],
      timeframe: '1D',
      indicators: ['SMA', 'EMA'],
      updatedAt: DateTime.now(),
    );
  }

  factory ChartConfig.fromJson(Map<String, dynamic> json) {
    return ChartConfig(
      id: json['id'],
      layout: json['layout'],
      rows: json['rows'],
      columns: json['columns'],
      symbols: List<String>.from(json['symbols']),
      timeframe: json['timeframe'],
      indicators: List<String>.from(json['indicators']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'layout': layout,
    'rows': rows,
    'columns': columns,
    'symbols': symbols,
    'timeframe': timeframe,
    'indicators': indicators,
    'updatedAt': updatedAt.toIso8601String(),
  };

  ChartConfig copyWith({
    String? id,
    String? layout,
    int? rows,
    int? columns,
    List<String>? symbols,
    String? timeframe,
    List<String>? indicators,
    DateTime? updatedAt,
  }) {
    return ChartConfig(
      id: id ?? this.id,
      layout: layout ?? this.layout,
      rows: rows ?? this.rows,
      columns: columns ?? this.columns,
      symbols: symbols ?? this.symbols,
      timeframe: timeframe ?? this.timeframe,
      indicators: indicators ?? this.indicators,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}