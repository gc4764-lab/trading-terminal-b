import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stock_trading_app/providers/positions_provider.dart';
import 'package:stock_trading_app/widgets/position_item.dart';
import 'package:stock_trading_app/widgets/holding_item.dart';

class PositionsScreen extends ConsumerStatefulWidget {
  const PositionsScreen({super.key});

  @override
  ConsumerState<PositionsScreen> createState() => _PositionsScreenState();
}

class _PositionsScreenState extends ConsumerState<PositionsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final positionsAsync = ref.watch(positionsProvider);
    final holdingsAsync = ref.watch(holdingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Positions & Holdings'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Positions'),
            Tab(text: 'Holdings'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.read(positionsProvider.notifier).refresh();
              ref.read(holdingsProvider.notifier).refresh();
            },
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          positionsAsync.when(
            data: (positions) => ListView.builder(
              itemCount: positions.length,
              itemBuilder: (context, index) => PositionItem(position: positions[index]),
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => Center(child: Text('Error: $error')),
          ),
          holdingsAsync.when(
            data: (holdings) => ListView.builder(
              itemCount: holdings.length,
              itemBuilder: (context, index) => HoldingItem(holding: holdings[index]),
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => Center(child: Text('Error: $error')),
          ),
        ],
      ),
    );
  }
}