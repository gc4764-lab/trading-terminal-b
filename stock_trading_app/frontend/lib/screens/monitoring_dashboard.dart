import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';
import 'package:stock_trading_app/services/monitoring_service.dart';
import 'package:stock_trading_app/widgets/alert_ticker.dart';

class MonitoringDashboard extends ConsumerStatefulWidget {
  const MonitoringDashboard({super.key});

  @override
  ConsumerState<MonitoringDashboard> createState() => _MonitoringDashboardState();
}

class _MonitoringDashboardState extends ConsumerState<MonitoringDashboard> {
  final MonitoringService _monitoringService = MonitoringService();
  Map<String, dynamic> _systemMetrics = {};
  List<Map<String, dynamic>> _activeAlerts = [];
  bool _isConnected = false;

  @override
  void initState() {
    super.initState();
    _connectToMonitoring();
  }

  Future<void> _connectToMonitoring() async {
    await _monitoringService.connect();
    setState(() => _isConnected = true);
    
    _monitoringService.onMetricsUpdate((metrics) {
      setState(() => _systemMetrics = metrics);
    });
    
    _monitoringService.onAlert((alert) {
      setState(() => _activeAlerts.insert(0, alert));
      _showAlertNotification(alert);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('System Monitoring'),
        actions: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _isConnected ? Colors.green : Colors.red,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  _isConnected ? 'Connected' : 'Disconnected',
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _monitoringService.refreshMetrics(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Alert Ticker
          if (_activeAlerts.isNotEmpty)
            AlertTicker(
              alerts: _activeAlerts,
              onDismiss: (index) {
                setState(() => _activeAlerts.removeAt(index));
              },
            ),
          
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // System Health Metrics
                  const Text(
                    'System Health',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 4,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1.2,
                    children: [
                      _buildMetricGauge(
                        title: 'CPU Usage',
                        value: _systemMetrics['cpuUsage'] ?? 0,
                        unit: '%',
                        maxValue: 100,
                        color: Colors.blue,
                      ),
                      _buildMetricGauge(
                        title: 'Memory Usage',
                        value: _systemMetrics['memoryUsage'] ?? 0,
                        unit: '%',
                        maxValue: 100,
                        color: Colors.green,
                      ),
                      _buildMetricGauge(
                        title: 'Active Users',
                        value: _systemMetrics['activeUsers'] ?? 0,
                        maxValue: 10000,
                        color: Colors.orange,
                      ),
                      _buildMetricGauge(
                        title: 'API Latency',
                        value: _systemMetrics['apiLatency'] ?? 0,
                        unit: 'ms',
                        maxValue: 500,
                        color: Colors.purple,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  // Real-time Metrics
                  const Text(
                    'Real-time Metrics',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    elevation: 4,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          _buildMetricRow('API Requests/sec', _systemMetrics['apiRequestsPerSec'] ?? 0, 'req/s'),
                          const Divider(),
                          _buildMetricRow('WebSocket Connections', _systemMetrics['wsConnections'] ?? 0, ''),
                          const Divider(),
                          _buildMetricRow('Database Queries/sec', _systemMetrics['dbQueriesPerSec'] ?? 0, 'q/s'),
                          const Divider(),
                          _buildMetricRow('Cache Hit Rate', (_systemMetrics['cacheHitRate'] ?? 0).toStringAsFixed(1), '%'),
                          const Divider(),
                          _buildMetricRow('Error Rate', (_systemMetrics['errorRate'] ?? 0).toStringAsFixed(2), '%'),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Performance Timeline
                  const Text(
                    'Performance Timeline',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    elevation: 4,
                    child: SizedBox(
                      height: 200,
                      child: _buildPerformanceChart(),
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Service Status
                  const Text(
                    'Service Status',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    elevation: 4,
                    child: ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _systemMetrics['services']?.length ?? 0,
                      separatorBuilder: (_, __) => const Divider(),
                      itemBuilder: (context, index) {
                        final service = _systemMetrics['services'][index];
                        return ListTile(
                          leading: Icon(
                            service['status'] == 'healthy'
                                ? Icons.check_circle
                                : service['status'] == 'degraded'
                                    ? Icons.warning
                                    : Icons.error,
                            color: service['status'] == 'healthy'
                                ? Colors.green
                                : service['status'] == 'degraded'
                                    ? Colors.orange
                                    : Colors.red,
                          ),
                          title: Text(service['name']),
                          subtitle: Text(service['description'] ?? ''),
                          trailing: Text(
                            '${service['responseTime']}ms',
                            style: TextStyle(
                              color: service['responseTime'] > 100
                                  ? Colors.red
                                  : Colors.green,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricGauge({
    required String title,
    required double value,
    String unit = '',
    required double maxValue,
    required Color color,
  }) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 80,
              child: SfRadialGauge(
                axes: [
                  RadialAxis(
                    minimum: 0,
                    maximum: maxValue,
                    ranges: [
                      GaugeRange(
                        startValue: 0,
                        endValue: maxValue * 0.6,
                        color: Colors.green,
                      ),
                      GaugeRange(
                        startValue: maxValue * 0.6,
                        endValue: maxValue * 0.8,
                        color: Colors.orange,
                      ),
                      GaugeRange(
                        startValue: maxValue * 0.8,
                        endValue: maxValue,
                        color: Colors.red,
                      ),
                    ],
                    pointers: [
                      NeedlePointer(value: value, enableAnimation: true),
                    ],
                    annotations: [
                      GaugeAnnotation(
                        widget: Text(
                          '${value.toStringAsFixed(0)}$unit',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        angle: 90,
                        positionFactor: 0.5,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricRow(String label, dynamic value, String unit) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 14)),
          Text(
            '$value$unit',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceChart() {
    // Implementation of performance chart
    return Container();
  }

  void _showAlertNotification(Map<String, dynamic> alert) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(alert['message']),
        backgroundColor: alert['severity'] == 'critical'
            ? Colors.red
            : alert['severity'] == 'warning'
                ? Colors.orange
                : Colors.blue,
        duration: const Duration(seconds: 5),
        action: SnackBarAction(
          label: 'View',
          onPressed: () {
            // Navigate to alert details
          },
        ),
      ),
    );
  }
}