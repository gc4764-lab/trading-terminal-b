import 'package:flutter/material.dart';
import 'package:stock_trading_app/models/order.dart';
import 'package:intl/intl.dart';

class OrderItem extends StatelessWidget {
  final Order order;

  const OrderItem({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM dd, HH:mm');
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: order.side == 'buy' ? Colors.green[100] : Colors.red[100],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            order.side == 'buy' ? Icons.trending_up : Icons.trending_down,
            color: order.side == 'buy' ? Colors.green : Colors.red,
          ),
        ),
        title: Text(
          '${order.symbol.toUpperCase()} - ${order.side.toUpperCase()}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${order.quantity} shares @ \$${order.price.toStringAsFixed(2)}'),
            Text(
              'Status: ${order.status}',
              style: TextStyle(
                color: _getStatusColor(order.status),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              dateFormat.format(order.createdAt),
              style: const TextStyle(fontSize: 12),
            ),
            if (order.filledPrice != null)
              Text(
                'Filled: \$${order.filledPrice!.toStringAsFixed(2)}',
                style: const TextStyle(fontSize: 12),
              ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'filled':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}