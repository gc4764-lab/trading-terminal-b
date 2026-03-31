import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stock_trading_app/screens/watchlist_screen.dart';
import 'package:stock_trading_app/screens/chart_grid_screen.dart';
import 'package:stock_trading_app/screens/risk_management_screen.dart';
import 'package:stock_trading_app/screens/orders_screen.dart';
import 'package:stock_trading_app/screens/positions_screen.dart';
import 'package:stock_trading_app/screens/alerts_screen.dart';
import 'package:stock_trading_app/screens/news_screen.dart';
import 'package:stock_trading_app/screens/settings_screen.dart';

class MobileHomeScreen extends ConsumerStatefulWidget {
  const MobileHomeScreen({super.key});

  @override
  ConsumerState<MobileHomeScreen> createState() => _MobileHomeScreenState();
}

class _MobileHomeScreenState extends ConsumerState<MobileHomeScreen> {
  int _selectedIndex = 0;
  
  final List<Widget> _screens = [
    const WatchlistScreen(),
    const ChartGridScreen(),
    const RiskManagementScreen(),
    const OrdersScreen(),
    const PositionsScreen(),
    const AlertsScreen(),
    const NewsScreen(),
    const SettingsScreen(),
  ];
  
  final List<String> _titles = [
    'Watchlist',
    'Charts',
    'Risk',
    'Orders',
    'Positions',
    'Alerts',
    'News',
    'Settings',
  ];
  
  final List<IconData> _icons = [
    Icons.list,
    Icons.show_chart,
    Icons.security,
    Icons.shopping_cart,
    Icons.account_balance,
    Icons.notifications,
    Icons.newspaper,
    Icons.settings,
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_selectedIndex]),
        actions: [
          if (_selectedIndex == 0)
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () => _showAddStockDialog(),
            ),
          if (_selectedIndex == 1)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => _showChartConfigDialog(),
            ),
          if (_selectedIndex == 5)
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () => _showAddAlertDialog(),
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshData,
          ),
        ],
      ),
      body: _screens[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        destinations: List.generate(
          _titles.length,
          (index) => NavigationDestination(
            icon: Icon(_icons[index]),
            label: _titles[index],
          ),
        ),
      ),
    );
  }
  
  void _showAddStockDialog() {
    // Implementation
  }
  
  void _showChartConfigDialog() {
    // Implementation
  }
  
  void _showAddAlertDialog() {
    // Implementation
  }
  
  void _refreshData() {
    // Refresh all data
  }
}