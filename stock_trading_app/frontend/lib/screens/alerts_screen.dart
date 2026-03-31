import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stock_trading_app/models/alert.dart';
import 'package:stock_trading_app/widgets/alert_item.dart';
import 'package:stock_trading_app/widgets/add_edit_alert_dialog.dart';

class AlertsScreen extends ConsumerWidget {
  const AlertsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alertsAsync = ref.watch(alertsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Alerts'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => showDialog(
              context: context,
              builder: (context) => const AddEditAlertDialog(),
            ),
          ),
        ],
      ),
      body: alertsAsync.when(
        data: (alerts) => ListView.builder(
          itemCount: alerts.length,
          itemBuilder: (context, index) {
            return AlertItem(
              alert: alerts[index],
              onToggle: () => ref.read(alertsProvider.notifier).toggleAlert(alerts[index].id),
              onEdit: () => showDialog(
                context: context,
                builder: (context) => AddEditAlertDialog(alert: alerts[index]),
              ),
              onDelete: () => _confirmDelete(context, ref, alerts[index]),
            );
          },
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Error: $error')),
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, Alert alert) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Alert'),
        content: Text('Are you sure you want to delete alert for ${alert.symbol}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              ref.read(alertsProvider.notifier).delete(alert.id);
              Navigator.pop(context);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}