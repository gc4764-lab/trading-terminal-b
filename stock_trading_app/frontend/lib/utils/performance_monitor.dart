import 'dart:developer';

class PerformanceMonitor {
  static final Map<String, DateTime> _timers = {};
  static final Map<String, List<Duration>> _metrics = {};
  
  static void startTimer(String name) {
    _timers[name] = DateTime.now();
  }
  
  static void stopTimer(String name) {
    final start = _timers[name];
    if (start != null) {
      final duration = DateTime.now().difference(start);
      _recordMetric(name, duration);
      _timers.remove(name);
      
      if (duration > const Duration(milliseconds: 100)) {
        log('Performance warning: $name took ${duration.inMilliseconds}ms');
      }
    }
  }
  
  static void _recordMetric(String name, Duration duration) {
    if (!_metrics.containsKey(name)) {
      _metrics[name] = [];
    }
    _metrics[name]!.add(duration);
    
    // Keep only last 100 measurements
    if (_metrics[name]!.length > 100) {
      _metrics[name]!.removeAt(0);
    }
  }
  
  static Map<String, dynamic> getMetrics() {
    final metrics = <String, dynamic>{};
    
    _metrics.forEach((name, durations) {
      if (durations.isNotEmpty) {
        final total = durations.fold(Duration.zero, (sum, d) => sum + d);
        final average = total ~/ durations.length;
        
        metrics[name] = {
          'count': durations.length,
          'averageMs': average.inMilliseconds,
          'totalMs': total.inMilliseconds,
        };
      }
    });
    
    return metrics;
  }
  
  static void printMetrics() {
    final metrics = getMetrics();
    log('Performance Metrics:');
    metrics.forEach((name, data) {
      log('  $name: ${data['averageMs']}ms avg (${data['count']} calls)');
    });
  }
  
  static Future<T> measure<T>(String name, Future<T> Function() operation) async {
    startTimer(name);
    try {
      return await operation();
    } finally {
      stopTimer(name);
    }
  }
}