import 'package:flutter/material.dart';
import 'package:stock_trading_app/models/alert.dart';

class AlertItem extends StatelessWidget {
  final Alert alert;
  final VoidCallback onToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const AlertItem({
    super.key,
    required this.alert,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: Icon(
          alert.isActive ? Icons.notifications_active : Icons.notifications_off,
          color: alert.isActive ? Colors.green : Colors.grey,
        ),
        title: Text(
          '${alert.symbol} - ${alert.type.toUpperCase()}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          '${alert.condition} ${alert.value}',
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Switch(
              value: alert.isActive,
              onChanged: (_) => onToggle(),
            ),
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