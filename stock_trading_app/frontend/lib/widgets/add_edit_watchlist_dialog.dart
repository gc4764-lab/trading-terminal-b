import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stock_trading_app/models/watchlist.dart';
import 'package:stock_trading_app/providers/watchlist_provider.dart';

class AddEditWatchlistDialog extends ConsumerStatefulWidget {
  final WatchlistItem? item;

  const AddEditWatchlistDialog({super.key, this.item});

  @override
  ConsumerState<AddEditWatchlistDialog> createState() => _AddEditWatchlistDialogState();
}

class _AddEditWatchlistDialogState extends ConsumerState<AddEditWatchlistDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _symbolController;
  late TextEditingController _nameController;
  late TextEditingController _exchangeController;

  @override
  void initState() {
    super.initState();
    _symbolController = TextEditingController(text: widget.item?.symbol ?? '');
    _nameController = TextEditingController(text: widget.item?.name ?? '');
    _exchangeController = TextEditingController(text: widget.item?.exchange ?? '');
  }

  @override
  void dispose() {
    _symbolController.dispose();
    _nameController.dispose();
    _exchangeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.item == null ? 'Add Stock' : 'Edit Stock'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _symbolController,
              decoration: const InputDecoration(labelText: 'Symbol'),
              validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
            ),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Company Name'),
              validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
            ),
            TextFormField(
              controller: _exchangeController,
              decoration: const InputDecoration(labelText: 'Exchange'),
              validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _save,
          child: Text(widget.item == null ? 'Add' : 'Save'),
        ),
      ],
    );
  }

  void _save() {
    if (_formKey.currentState!.validate()) {
      final now = DateTime.now();
      final item = WatchlistItem(
        id: widget.item?.id ?? '', // Will be set by backend
        symbol: _symbolController.text,
        name: _nameController.text,
        exchange: _exchangeController.text,
        createdAt: widget.item?.createdAt ?? now,
        updatedAt: now,
      );
      if (widget.item == null) {
        ref.read(watchlistProvider.notifier).add(item);
      } else {
        ref.read(watchlistProvider.notifier).update(item);
      }
      Navigator.pop(context);
    }
  }
}