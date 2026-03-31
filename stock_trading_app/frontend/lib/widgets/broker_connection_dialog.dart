import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stock_trading_app/providers/broker_provider.dart';
import 'package:stock_trading_app/models/broker_config.dart';

class BrokerConnectionDialog extends ConsumerStatefulWidget {
  const BrokerConnectionDialog({super.key});

  @override
  ConsumerState<BrokerConnectionDialog> createState() => _BrokerConnectionDialogState();
}

class _BrokerConnectionDialogState extends ConsumerState<BrokerConnectionDialog> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedBrokerType;
  late TextEditingController _nameController;
  late TextEditingController _apiKeyController;
  late TextEditingController _apiSecretController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _apiKeyController = TextEditingController();
    _apiSecretController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _apiKeyController.dispose();
    _apiSecretController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Connect Broker'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: _selectedBrokerType,
                decoration: const InputDecoration(labelText: 'Broker Type'),
                items: const [
                  DropdownMenuItem(value: 'zerodha', child: Text('Zerodha')),
                  DropdownMenuItem(value: 'upstox', child: Text('Upstox')),
                  DropdownMenuItem(value: 'angel', child: Text('Angel One')),
                ],
                onChanged: (value) => setState(() => _selectedBrokerType = value),
                validator: (value) => value == null ? 'Select broker' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Account Name'),
                validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _apiKeyController,
                decoration: const InputDecoration(labelText: 'API Key'),
                validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _apiSecretController,
                decoration: const InputDecoration(labelText: 'API Secret'),
                validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
              ),
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
          onPressed: _connect,
          child: const Text('Connect'),
        ),
      ],
    );
  }

  void _connect() {
    if (_formKey.currentState!.validate()) {
      final config = BrokerConfig(
        id: '',
        name: _nameController.text,
        type: _selectedBrokerType!,
        apiKey: _apiKeyController.text,
        apiSecret: _apiSecretController.text,
        accessToken: '',
        isConnected: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      ref.read(brokerProvider.notifier).connect(config);
      Navigator.pop(context);
    }
  }
}