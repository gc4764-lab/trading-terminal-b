import 'package:flutter/material.dart';
import 'package:stock_trading_app/models/order.dart';
import 'package:stock_trading_app/providers/broker_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class PlaceOrderDialog extends ConsumerStatefulWidget {
  final Function(Order) onPlace;

  const PlaceOrderDialog({super.key, required this.onPlace});

  @override
  ConsumerState<PlaceOrderDialog> createState() => _PlaceOrderDialogState();
}

class _PlaceOrderDialogState extends ConsumerState<PlaceOrderDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _symbolController;
  late TextEditingController _quantityController;
  late TextEditingController _priceController;
  String _side = 'buy';
  String _type = 'market';
  String? _selectedBrokerId;

  @override
  void initState() {
    super.initState();
    _symbolController = TextEditingController();
    _quantityController = TextEditingController();
    _priceController = TextEditingController();
  }

  @override
  void dispose() {
    _symbolController.dispose();
    _quantityController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final brokersAsync = ref.watch(brokersProvider);

    return AlertDialog(
      title: const Text('Place Order'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              brokersAsync.when(
                data: (brokers) {
                  if (brokers.isEmpty) {
                    return const Text('No brokers connected. Please connect a broker first.');
                  }
                  return DropdownButtonFormField<String>(
                    value: _selectedBrokerId,
                    decoration: const InputDecoration(labelText: 'Broker'),
                    items: brokers.map((b) {
                      return DropdownMenuItem(value: b.id, child: Text(b.name));
                    }).toList(),
                    onChanged: (value) => setState(() => _selectedBrokerId = value),
                    validator: (value) => value == null ? 'Select broker' : null,
                  );
                },
                loading: () => const CircularProgressIndicator(),
                error: (error, _) => Text('Error loading brokers: $error'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _symbolController,
                decoration: const InputDecoration(labelText: 'Symbol'),
                validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _side,
                decoration: const InputDecoration(labelText: 'Side'),
                items: const [
                  DropdownMenuItem(value: 'buy', child: Text('Buy')),
                  DropdownMenuItem(value: 'sell', child: Text('Sell')),
                ],
                onChanged: (value) => setState(() => _side = value!),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _type,
                decoration: const InputDecoration(labelText: 'Order Type'),
                items: const [
                  DropdownMenuItem(value: 'market', child: Text('Market')),
                  DropdownMenuItem(value: 'limit', child: Text('Limit')),
                  DropdownMenuItem(value: 'stop', child: Text('Stop')),
                ],
                onChanged: (value) => setState(() => _type = value!),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _quantityController,
                decoration: const InputDecoration(labelText: 'Quantity'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value?.isEmpty ?? true) return 'Required';
                  if (int.tryParse(value!) == null) return 'Invalid number';
                  return null;
                },
              ),
              if (_type != 'market') ...[
                const SizedBox(height: 16),
                TextFormField(
                  controller: _priceController,
                  decoration: const InputDecoration(labelText: 'Price'),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value?.isEmpty ?? true) return 'Required';
                    if (double.tryParse(value!) == null) return 'Invalid number';
                    return null;
                  },
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _placeOrder,
          child: const Text('Place Order'),
        ),
      ],
    );
  }

  void _placeOrder() {
    if (_formKey.currentState!.validate() && _selectedBrokerId != null) {
      final order = Order(
        id: '',
        brokerId: _selectedBrokerId!,
        symbol: _symbolController.text,
        side: _side,
        type: _type,
        quantity: int.parse(_quantityController.text),
        price: _type == 'market' ? 0 : double.parse(_priceController.text),
        status: 'pending',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      widget.onPlace(order);
      Navigator.pop(context);
    }
  }
}