import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stock_trading_app/models/watchlist.dart';
import 'package:stock_trading_app/widgets/watchlist_item.dart';
import 'package:stock_trading_app/widgets/add_edit_watchlist_dialog.dart';

class WatchlistScreen extends ConsumerWidget {
  const WatchlistScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final watchlistAsync = ref.watch(watchlistProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Watchlist'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => showDialog(
              context: context,
              builder: (context) => const AddEditWatchlistDialog(),
            ),
          ),
        ],
      ),
      body: watchlistAsync.when(
        data: (items) => ListView.builder(
          itemCount: items.length,
          itemBuilder: (context, index) {
            return WatchlistItem(
              item: items[index],
              onEdit: () => showDialog(
                context: context,
                builder: (context) => AddEditWatchlistDialog(item: items[index]),
              ),
              onDelete: () => _confirmDelete(context, ref, items[index]),
            );
          },
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Error: $error')),
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, WatchlistItem item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Stock'),
        content: Text('Are you sure you want to delete ${item.symbol}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              ref.read(watchlistProvider.notifier).delete(item.id);
              Navigator.pop(context);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}