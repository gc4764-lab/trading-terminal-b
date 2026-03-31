import 'package:flutter/material.dart';
import 'package:stock_trading_app/models/position.dart';

class PositionItem extends StatelessWidget {
  final Position position;

  const PositionItem({super.key, required this.position});

  @override
  Widget build(BuildContext context) {
    final pnlPercentage = (position.pnl / (position.quantity * position.avgPrice)) * 100;
    final isProfit = position.pnl >= 0;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: isProfit ? Colors.green[100] : Colors.red[100],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            isProfit ? Icons.arrow_upward : Icons.arrow_downward,
            color: isProfit ? Colors.green : Colors.red,
          ),
        ),
        title: Text(
          position.symbol,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${position.quantity} shares @ \$${position.avgPrice.toStringAsFixed(2)}'),
            Text(
              'Current: \$${position.currentPrice.toStringAsFixed(2)}',
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '\$${position.pnl.toStringAsFixed(2)}',
              style: TextStyle(
                color: isProfit ? Colors.green : Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '${pnlPercentage.toStringAsFixed(2)}%',
              style: TextStyle(
                color: isProfit ? Colors.green : Colors.red,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}