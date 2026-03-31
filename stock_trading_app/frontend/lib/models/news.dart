class News {
  final String title;
  final String? description;
  final String url;
  final String? imageUrl;
  final String source;
  final DateTime publishedAt;

  News({
    required this.title,
    this.description,
    required this.url,
    this.imageUrl,
    required this.source,
    required this.publishedAt,
  });

  factory News.fromJson(Map<String, dynamic> json) {
    return News(
      title: json['title'],
      description: json['description'],
      url: json['url'],
      imageUrl: json['imageUrl'],
      source: json['source'],
      publishedAt: DateTime.parse(json['publishedAt']),
    );
  }
}