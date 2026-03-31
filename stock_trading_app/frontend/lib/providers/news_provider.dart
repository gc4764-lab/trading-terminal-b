import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stock_trading_app/models/news.dart';
import 'package:stock_trading_app/services/api_service.dart';

final newsProvider = StateNotifierProvider<NewsNotifier, AsyncValue<List<News>>>((ref) {
  return NewsNotifier();
});

class NewsNotifier extends StateNotifier<AsyncValue<List<News>>> {
  final ApiService _apiService = ApiService();

  NewsNotifier() : super(const AsyncValue.loading()) {
    refresh();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    try {
      final news = await _apiService.getLatestNews();
      state = AsyncValue.data(news);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}