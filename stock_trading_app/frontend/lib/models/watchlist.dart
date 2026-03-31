class WatchlistItem {
  final String id;
  final String symbol;
  final String name;
  final String exchange;
  final DateTime createdAt;
  final DateTime updatedAt;

  WatchlistItem({
    required this.id,
    required this.symbol,
    required this.name,
    required this.exchange,
    required this.createdAt,
    required this.updatedAt,
  });

  factory WatchlistItem.fromJson(Map<String, dynamic> json) {
    return WatchlistItem(
      id: json['id'],
      symbol: json['symbol'],
      name: json['name'],
      exchange: json['exchange'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'symbol': symbol,
    'name': name,
    'exchange': exchange,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };
}