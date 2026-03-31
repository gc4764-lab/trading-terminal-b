class Order {
  final String id;
  final String brokerId;
  final String symbol;
  final String side; // buy, sell
  final String type; // market, limit, stop
  final int quantity;
  final double price;
  final String status; // pending, filled, cancelled
  final double? filledPrice;
  final int? filledQuantity;
  final DateTime createdAt;
  final DateTime updatedAt;

  Order({
    required this.id,
    required this.brokerId,
    required this.symbol,
    required this.side,
    required this.type,
    required this.quantity,
    required this.price,
    required this.status,
    this.filledPrice,
    this.filledQuantity,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'],
      brokerId: json['brokerId'],
      symbol: json['symbol'],
      side: json['side'],
      type: json['type'],
      quantity: json['quantity'],
      price: json['price'].toDouble(),
      status: json['status'],
      filledPrice: json['filledPrice']?.toDouble(),
      filledQuantity: json['filledQuantity'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'brokerId': brokerId,
    'symbol': symbol,
    'side': side,
    'type': type,
    'quantity': quantity,
    'price': price,
    'status': status,
    'filledPrice': filledPrice,
    'filledQuantity': filledQuantity,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };
}