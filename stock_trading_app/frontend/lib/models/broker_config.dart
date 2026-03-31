class BrokerConfig {
  final String id;
  final String name;
  final String type; // zerodha, upstox, angel
  final String apiKey;
  final String apiSecret;
  final String accessToken;
  final bool isConnected;
  final DateTime createdAt;
  final DateTime updatedAt;

  BrokerConfig({
    required this.id,
    required this.name,
    required this.type,
    required this.apiKey,
    required this.apiSecret,
    required this.accessToken,
    required this.isConnected,
    required this.createdAt,
    required this.updatedAt,
  });

  factory BrokerConfig.fromJson(Map<String, dynamic> json) {
    return BrokerConfig(
      id: json['id'],
      name: json['name'],
      type: json['type'],
      apiKey: json['apiKey'],
      apiSecret: json['apiSecret'],
      accessToken: json['accessToken'],
      isConnected: json['isConnected'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'type': type,
    'apiKey': apiKey,
    'apiSecret': apiSecret,
    'accessToken': accessToken,
    'isConnected': isConnected,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };
}