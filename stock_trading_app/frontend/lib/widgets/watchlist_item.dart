import 'package:flutter/material.dart';
import 'package:stock_trading_app/models/watchlist.dart';

class WatchlistItem extends StatelessWidget {
  final WatchlistItem item;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const WatchlistItem({
    super.key,
    required this.item,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.blue[100],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              item.symbol.substring(0, 1),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),
        ),
        title: Text(
          item.symbol,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(item.name),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, size: 20),
              onPressed: onEdit,
            ),
            IconButton(
              icon: const Icon(Icons.delete, size: 20),
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}