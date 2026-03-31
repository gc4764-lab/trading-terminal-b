import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:multi_window/multi_window.dart';
import 'package:stock_trading_app/widgets/detachable_chart.dart';

class MultiMonitorScreen extends ConsumerStatefulWidget {
  const MultiMonitorScreen({super.key});

  @override
  ConsumerState<MultiMonitorScreen> createState() => _MultiMonitorScreenState();
}

class _MultiMonitorScreenState extends ConsumerState<MultiMonitorScreen> {
  final List<Widget> _detachedWindows = [];

  @override
  void initState() {
    super.initState();
    _initMultiWindow();
  }

  Future<void> _initMultiWindow() async {
    await MultiWindow.ensureInitialized();
    
    MultiWindow.setMethodHandler((call) async {
      switch (call.method) {
        case 'close':
          // Handle close
          break;
        default:
          break;
      }
      return null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Multi-Monitor Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.open_in_new),
            onPressed: _openNewWindow,
            tooltip: 'Open in new window',
          ),
        ],
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 1.5,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: _detachedWindows.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return _buildMainChart();
          }
          return _buildDetachedWindow(index - 1);
        },
      ),
    );
  }

  Widget _buildMainChart() {
    return Card(
      elevation: 4,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.grey)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Main Chart',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.open_in_new, size: 20),
                  onPressed: _openNewWindow,
                  tooltip: 'Detach to new window',
                ),
              ],
            ),
          ),
          Expanded(
            child: DetachableChart(symbol: 'AAPL'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetachedWindow(int index) {
    return Card(
      elevation: 4,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.grey)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Chart ${index + 1}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.refresh, size: 20),
                      onPressed: () {},
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 20),
                      onPressed: () {
                        setState(() {
                          _detachedWindows.removeAt(index);
                        });
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: DetachableChart(symbol: 'GOOGL'),
          ),
        ],
      ),
    );
  }

  Future<void> _openNewWindow() async {
    const window = MultiWindow(
      arguments: {'type': 'chart', 'symbol': 'AAPL'},
    );
    await window.show();
    
    setState(() {
      _detachedWindows.add(const SizedBox());
    });
  }
}