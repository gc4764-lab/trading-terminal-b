import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stock_trading_app/models/alert.dart';
import 'package:stock_trading_app/providers/alerts_provider.dart';

class AddEditAlertDialog extends ConsumerStatefulWidget {
  final Alert? alert;

  const AddEditAlertDialog({super.key, this.alert});

  @override
  ConsumerState<AddEditAlertDialog> createState() => _AddEditAlertDialogState();
}

class _AddEditAlertDialogState extends ConsumerState<AddEditAlertDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _symbolController;
  late TextEditingController _valueController;
  String _type = 'price';
  String _condition = 'above';

  @override
  void initState() {
    super.initState();
    _symbolController = TextEditingController(text: widget.alert?.symbol ?? '');
    _valueController = TextEditingController(text: widget.alert?.value.toString() ?? '');
    _type = widget.alert?.type ?? 'price';
    _condition = widget.alert?.condition ?? 'above';
  }

  @override
  void dispose() {
    _symbolController.dispose();
    _valueController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.alert == null ? 'Add Alert' : 'Edit Alert'),
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
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _type,
              decoration: const InputDecoration(labelText: 'Type'),
              items: const [
                DropdownMenuItem(value: 'price', child: Text('Price')),
                DropdownMenuItem(value: 'volume', child: Text('Volume')),
                DropdownMenuItem(value: 'percentage', child: Text('Percentage Change')),
              ],
              onChanged: (value) => setState(() => _type = value!),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _condition,
              decoration: const InputDecoration(labelText: 'Condition'),
              items: const [
                DropdownMenuItem(value: 'above', child: Text('Above')),
                DropdownMenuItem(value: 'below', child: Text('Below')),
                DropdownMenuItem(value: 'crosses', child: Text('Crosses')),
              ],
              onChanged: (value) => setState(() => _condition = value!),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _valueController,
              decoration: const InputDecoration(labelText: 'Value'),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value?.isEmpty ?? true) return 'Required';
                if (double.tryParse(value!) == null) return 'Invalid number';
                return null;
              },
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
          child: Text(widget.alert == null ? 'Add' : 'Save'),
        ),
      ],
    );
  }

  void _save() {
    if (_formKey.currentState!.validate()) {
      final now = DateTime.now();
      final alert = Alert(
        id: widget.alert?.id ?? '',
        symbol: _symbolController.text,
        type: _type,
        condition: _condition,
        value: double.parse(_valueController.text),
        isActive: widget.alert?.isActive ?? true,
        triggeredAt: widget.alert?.triggeredAt,
        createdAt: widget.alert?.createdAt ?? now,
        updatedAt: now,
      );
      if (widget.alert == null) {
        ref.read(alertsProvider.notifier).add(alert);
      } else {
        ref.read(alertsProvider.notifier).update(alert);
      }
      Navigator.pop(context);
    }
  }
}