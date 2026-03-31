import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:draggable_home/draggable_home.dart';
import 'package:stock_trading_app/widgets/dashboard_widgets.dart';

class CustomizableDashboard extends ConsumerStatefulWidget {
  const CustomizableDashboard({super.key});

  @override
  ConsumerState<CustomizableDashboard> createState() => _CustomizableDashboardState();
}

class _CustomizableDashboardState extends ConsumerState<CustomizableDashboard> {
  List<DashboardWidget> _widgets = [];
  bool _isEditMode = false;
  
  @override
  void initState() {
    super.initState();
    _loadDashboardLayout();
  }
  
  Future<void> _loadDashboardLayout() async {
    // Load saved layout from shared preferences
    final savedLayout = await DashboardLayoutService.getLayout();
    setState(() {
      _widgets = savedLayout;
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return DraggableHome(
      title: const Text('Dashboard'),
      leading: IconButton(
        icon: Icon(_isEditMode ? Icons.done : Icons.edit),
        onPressed: () => setState(() => _isEditMode = !_isEditMode),
      ),
      actions: [
        if (_isEditMode)
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showAddWidgetDialog,
          ),
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: _refreshDashboard,
        ),
      ],
      body: _isEditMode ? _buildEditMode() : _buildViewMode(),
      floatingActionButton: _isEditMode ? null : _buildQuickActions(),
    );
  }
  
  Widget _buildViewMode() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: _widgets.length,
      itemBuilder: (context, index) {
        return DashboardWidgetCard(
          widget: _widgets[index],
          isEditMode: false,
        );
      },
    );
  }
  
  Widget _buildEditMode() {
    return ReorderableListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _widgets.length,
      onReorder: _reorderWidgets,
      itemBuilder: (context, index) {
        return DashboardWidgetCard(
          key: ValueKey(_widgets[index].id),
          widget: _widgets[index],
          isEditMode: true,
          onRemove: () => _removeWidget(index),
          onConfigure: () => _configureWidget(_widgets[index]),
        );
      },
    );
  }
  
  Widget _buildQuickActions() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        FloatingActionButton(
          heroTag: 'quick_buy',
          child: const Icon(Icons.trending_up),
          onPressed: () => _showQuickOrderDialog('buy'),
        ),
        const SizedBox(height: 16),
        FloatingActionButton(
          heroTag: 'quick_sell',
          child: const Icon(Icons.trending_down),
          onPressed: () => _showQuickOrderDialog('sell'),
        ),
      ],
    );
  }
  
  void _showAddWidgetDialog() {
    showDialog(
      context: