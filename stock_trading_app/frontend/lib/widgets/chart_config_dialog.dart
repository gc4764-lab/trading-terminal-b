import 'package:flutter/material.dart';
import 'package:stock_trading_app/models/chart_config.dart';

class ChartConfigDialog extends StatefulWidget {
  final ChartConfig config;
  final Function(ChartConfig) onSave;

  const ChartConfigDialog({super.key, required this.config, required this.onSave});

  @override
  State<ChartConfigDialog> createState() => _ChartConfigDialogState();
}

class _ChartConfigDialogState extends State<ChartConfigDialog> {
  late TextEditingController _rowsController;
  late TextEditingController _columnsController;
  late List<TextEditingController> _symbolControllers;
  late String _layout;

  @override
  void initState() {
    super.initState();
    _rowsController = TextEditingController(text: widget.config.rows.toString());
    _columnsController = TextEditingController(text: widget.config.columns.toString());
    _symbolControllers = widget.config.symbols.map((s) => TextEditingController(text: s)).toList();
    _layout = widget.config.layout;
  }

  @override
  void dispose() {
    _rowsController.dispose();
    _columnsController.dispose();
    for (var c in _symbolControllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Chart Configuration'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              value: _layout,
              decoration: const InputDecoration(labelText: 'Layout'),
              items: const [
                DropdownMenuItem(value: 'grid', child: Text('Grid')),
                DropdownMenuItem(value: 'single', child: Text('Single')),
              ],
              onChanged: (value) => setState(() => _layout = value!),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _rowsController,
              decoration: const InputDecoration(labelText: 'Rows'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _columnsController,
              decoration: const InputDecoration(labelText: 'Columns'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            const Text('Symbols:', style: TextStyle(fontWeight: FontWeight.bold)),
            ..._buildSymbolFields(),
            ElevatedButton(
              onPressed: _addSymbolField,
              child: const Text('Add Symbol'),
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
          child: const Text('Save'),
        ),
      ],
    );
  }

  List<Widget> _buildSymbolFields() {
    List<Widget> widgets = [];
    for (int i = 0; i < _symbolControllers.length; i++) {
      widgets.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _symbolControllers[i],
                  decoration: const InputDecoration(labelText: 'Symbol'),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.remove_circle),
                onPressed: () => _removeSymbolField(i),
              ),
            ],
          ),
        ),
      );
    }
    return widgets;
  }

  void _addSymbolField() {
    setState(() {
      _symbolControllers.add(TextEditingController());
    });
  }

  void _removeSymbolField(int index) {
    setState(() {
      _symbolControllers[index].dispose();
      _symbolControllers.removeAt(index);
    });
  }

  void _save() {
    final rows = int.tryParse(_rowsController.text) ?? 2;
    final columns = int.tryParse(_columnsController.text) ?? 2;
    final symbols = _symbolControllers.map((c) => c.text.trim()).where((s) => s.isNotEmpty).toList();
    if (symbols.isEmpty) return;

    final newConfig = widget.config.copyWith(
      layout: _layout,
      rows: rows,
      columns: columns,
      symbols: symbols,
    );
    widget.onSave(newConfig);
    Navigator.pop(context);
  }
}import 'package:flutter/material.dart';
import 'package:stock_trading_app/models/chart_config.dart';

class ChartConfigDialog extends StatefulWidget {
  final ChartConfig config;
  final Function(ChartConfig) onSave;

  const ChartConfigDialog({super.key, required this.config, required this.onSave});

  @override
  State<ChartConfigDialog> createState() => _ChartConfigDialogState();
}

class _ChartConfigDialogState extends State<ChartConfigDialog> {
  late TextEditingController _rowsController;
  late TextEditingController _columnsController;
  late List<TextEditingController> _symbolControllers;
  late String _layout;

  @override
  void initState() {
    super.initState();
    _rowsController = TextEditingController(text: widget.config.rows.toString());
    _columnsController = TextEditingController(text: widget.config.columns.toString());
    _symbolControllers = widget.config.symbols.map((s) => TextEditingController(text: s)).toList();
    _layout = widget.config.layout;
  }

  @override
  void dispose() {
    _rowsController.dispose();
    _columnsController.dispose();
    for (var c in _symbolControllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Chart Configuration'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              value: _layout,
              decoration: const InputDecoration(labelText: 'Layout'),
              items: const [
                DropdownMenuItem(value: 'grid', child: Text('Grid')),
                DropdownMenuItem(value: 'single', child: Text('Single')),
              ],
              onChanged: (value) => setState(() => _layout = value!),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _rowsController,
              decoration: const InputDecoration(labelText: 'Rows'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _columnsController,
              decoration: const InputDecoration(labelText: 'Columns'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            const Text('Symbols:', style: TextStyle(fontWeight: FontWeight.bold)),
            ..._buildSymbolFields(),
            ElevatedButton(
              onPressed: _addSymbolField,
              child: const Text('Add Symbol'),
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
          child: const Text('Save'),
        ),
      ],
    );
  }

  List<Widget> _buildSymbolFields() {
    List<Widget> widgets = [];
    for (int i = 0; i < _symbolControllers.length; i++) {
      widgets.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _symbolControllers[i],
                  decoration: const InputDecoration(labelText: 'Symbol'),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.remove_circle),
                onPressed: () => _removeSymbolField(i),
              ),
            ],
          ),
        ),
      );
    }
    return widgets;
  }

  void _addSymbolField() {
    setState(() {
      _symbolControllers.add(TextEditingController());
    });
  }

  void _removeSymbolField(int index) {
    setState(() {
      _symbolControllers[index].dispose();
      _symbolControllers.removeAt(index);
    });
  }

  void _save() {
    final rows = int.tryParse(_rowsController.text) ?? 2;
    final columns = int.tryParse(_columnsController.text) ?? 2;
    final symbols = _symbolControllers.map((c) => c.text.trim()).where((s) => s.isNotEmpty).toList();
    if (symbols.isEmpty) return;

    final newConfig = widget.config.copyWith(
      layout: _layout,
      rows: rows,
      columns: columns,
      symbols: symbols,
    );
    widget.onSave(newConfig);
    Navigator.pop(context);
  }
}