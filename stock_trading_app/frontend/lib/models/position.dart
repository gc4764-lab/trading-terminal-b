class Position {
  final String id;
  final String brokerId;
  final String symbol;
  final int quantity;
  final double avgPrice;
  final double currentPrice;
  final double pnl;
  final DateTime updatedAt;

  Position({
    required this.id,
    required this.brokerId,
    required this.symbol,
    required this.quantity,
    required this.avgPrice,
    required this.currentPrice,
    required this.pnl,
    required this.updatedAt,
  });

  factory Position.fromJson(Map<String, dynamic> json) {
    return Position(
      id: json['id'],
      brokerId: json['brokerId'],
      symbol: json['symbol'],
      quantity: json['quantity'],
      avgPrice: json['avgPrice'].toDouble(),
      currentPrice: json['currentPrice'].toDouble(),
      pnl: json['pnl'].toDouble(),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }
}

class Holding {
  final String id;
  final String brokerId;
  final String symbol;
  final int quantity;
  final double purchasePrice;
  final double currentPrice;
  final double totalValue;
  final DateTime updatedAt;

  Holding({
    required this.id,
    required this.brokerId,
    required this.symbol,
    required this.quantity,
    required this.purchasePrice,
    required this.currentPrice,
    required this.totalValue,
    required this.updatedAt,
  });

  factory Holding.fromJson(Map<String, dynamic> json) {
    return Holding(
      id: json['id'],
      brokerId: json['brokerId'],
      symbol: json['symbol'],
      quantity: json['quantity'],
      purchasePrice: json['purchasePrice'].toDouble(),
      currentPrice: json['currentPrice'].toDouble(),
      totalValue: json['totalValue'].toDouble(),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }
}