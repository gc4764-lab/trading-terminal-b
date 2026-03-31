import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stock_trading_app/widgets/navigation_drawer.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = const [
    WatchlistScreen(),
    ChartGridScreen(),
    RiskManagementScreen(),
    OrdersScreen(),
    PositionsScreen(),
    AlertsScreen(),
    NewsScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Stock Trading App'),
        actions: [
          IconButton(
            icon: const Icon(Icons.broker),
            onPressed: () => _showBrokerDialog(),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _refreshData(),
          ),
        ],
      ),
      drawer: NavigationDrawer(
        selectedIndex: _selectedIndex,
        onItemSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
          Navigator.pop(context);
        },
      ),
      body: _screens[_selectedIndex],
    );
  }

  void _showBrokerDialog() {
    showDialog(
      context: context,
      builder: (context) => BrokerConnectionDialog(),
    );
  }

  void _refreshData() {
    // Refresh all data
    ref.read(watchlistProvider.notifier).refresh();
    ref.read(positionsProvider.notifier).refresh();
    ref.read(ordersProvider.notifier).refresh();
  }
}