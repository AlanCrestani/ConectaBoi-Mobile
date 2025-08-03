import 'dart:async';

class PerformanceTimer {
  final Stopwatch _stopwatch = Stopwatch();

  void start() => _stopwatch.start();
  void stop() => _stopwatch.stop();
  void reset() => _stopwatch.reset();

  int get elapsedMilliseconds => _stopwatch.elapsedMilliseconds;
  int get elapsedMicroseconds => _stopwatch.elapsedMicroseconds;
  Duration get elapsed => _stopwatch.elapsed;
}

class PerformanceMonitor {
  static final PerformanceMonitor _instance = PerformanceMonitor._internal();
  factory PerformanceMonitor() => _instance;
  PerformanceMonitor._internal();

  final Map<String, List<int>> _metrics = {};
  final Map<String, PerformanceTimer> _activeTimers = {};
  final List<Map<String, dynamic>> _performanceLogs = [];

  // ⏱️ TIMER MANAGEMENT
  PerformanceTimer startTimer(String name) {
    final timer = PerformanceTimer();
    timer.start();
    _activeTimers[name] = timer;
    return timer;
  }

  void stopTimer(String name) {
    final timer = _activeTimers[name];
    if (timer != null) {
      timer.stop();
      logMetric('${name}_ms', timer.elapsedMilliseconds);
      _activeTimers.remove(name);
    }
  }

  // 📊 METRICS LOGGING
  void logMetric(String name, dynamic value) {
    final numValue = value is num ? value.toInt() : 0;

    if (!_metrics.containsKey(name)) {
      _metrics[name] = [];
    }

    _metrics[name]!.add(numValue);

    // Log para debug
    _performanceLogs.add({
      'metric': name,
      'value': numValue,
      'timestamp': DateTime.now().toIso8601String(),
    });

    // Manter apenas últimos 100 logs
    if (_performanceLogs.length > 100) {
      _performanceLogs.removeAt(0);
    }
  }

  // 📈 ANALYTICS
  Map<String, dynamic> getMetricStats(String name) {
    final values = _metrics[name];
    if (values == null || values.isEmpty) {
      return {'count': 0, 'min': 0, 'max': 0, 'avg': 0, 'total': 0};
    }

    values.sort();

    return {
      'count': values.length,
      'min': values.first,
      'max': values.last,
      'avg': values.reduce((a, b) => a + b) / values.length,
      'total': values.reduce((a, b) => a + b),
      'p50': values[values.length ~/ 2],
      'p90': values[(values.length * 0.9).round()],
      'p95': values[(values.length * 0.95).round()],
    };
  }

  Map<String, dynamic> getAllMetrics() {
    final result = <String, dynamic>{};

    for (final metricName in _metrics.keys) {
      result[metricName] = getMetricStats(metricName);
    }

    return result;
  }

  // 🎯 PERFORMANCE TARGETS
  bool isPerformanceTarget(String operation, int milliseconds) {
    switch (operation) {
      case 'full_sync':
        return milliseconds < 5000; // 5s target
      case 'incremental_sync':
        return milliseconds < 500; // 500ms target
      case 'query_single':
        return milliseconds < 200; // 200ms target
      case 'upload_batch':
        return milliseconds < 1000; // 1s target
      case 'download_batch':
        return milliseconds < 1500; // 1.5s target
      default:
        return true;
    }
  }

  // 🚨 PERFORMANCE ALERTS
  void checkPerformanceTargets() {
    final alerts = <String>[];

    final syncStats = getMetricStats('full_sync_ms');
    if (syncStats['avg'] > 5000) {
      alerts.add('Full sync averaging ${syncStats['avg']}ms (target: <5000ms)');
    }

    final incrementalStats = getMetricStats('incremental_sync_ms');
    if (incrementalStats['avg'] > 500) {
      alerts.add(
        'Incremental sync averaging ${incrementalStats['avg']}ms (target: <500ms)',
      );
    }

    final queryStats = getMetricStats('query_duration_ms');
    if (queryStats['avg'] > 200) {
      alerts.add('Queries averaging ${queryStats['avg']}ms (target: <200ms)');
    }

    if (alerts.isNotEmpty) {
      print('🚨 PERFORMANCE ALERTS:');
      for (final alert in alerts) {
        print('  - $alert');
      }
    }
  }

  // 📋 REPORTS
  String generatePerformanceReport() {
    final buffer = StringBuffer();
    buffer.writeln('📊 PERFORMANCE REPORT');
    buffer.writeln('Generated: ${DateTime.now()}');
    buffer.writeln('');

    // Sync Performance
    buffer.writeln('🔄 SYNC PERFORMANCE:');
    final fullSync = getMetricStats('full_sync_ms');
    if (fullSync['count'] > 0) {
      buffer.writeln(
        '  Full Sync: ${fullSync['avg'].toStringAsFixed(0)}ms avg (${fullSync['count']} ops)',
      );
      buffer.writeln(
        '    Min: ${fullSync['min']}ms | Max: ${fullSync['max']}ms',
      );
      buffer.writeln(
        '    P90: ${fullSync['p90']}ms | P95: ${fullSync['p95']}ms',
      );
    }

    final incrementalSync = getMetricStats('incremental_sync_ms');
    if (incrementalSync['count'] > 0) {
      buffer.writeln(
        '  Incremental: ${incrementalSync['avg'].toStringAsFixed(0)}ms avg (${incrementalSync['count']} ops)',
      );
      buffer.writeln(
        '    Min: ${incrementalSync['min']}ms | Max: ${incrementalSync['max']}ms',
      );
    }

    buffer.writeln('');

    // Query Performance
    buffer.writeln('🔍 QUERY PERFORMANCE:');
    final queryStats = getMetricStats('query_duration_ms');
    if (queryStats['count'] > 0) {
      buffer.writeln(
        '  Average: ${queryStats['avg'].toStringAsFixed(0)}ms (${queryStats['count']} queries)',
      );
      buffer.writeln(
        '  Range: ${queryStats['min']}ms - ${queryStats['max']}ms',
      );
    }

    buffer.writeln('');

    // Network Performance
    buffer.writeln('🌐 NETWORK PERFORMANCE:');
    final uploadStats = getMetricStats('upload_duration_ms');
    if (uploadStats['count'] > 0) {
      buffer.writeln(
        '  Upload: ${uploadStats['avg'].toStringAsFixed(0)}ms avg',
      );
    }

    final downloadStats = getMetricStats('download_duration_ms');
    if (downloadStats['count'] > 0) {
      buffer.writeln(
        '  Download: ${downloadStats['avg'].toStringAsFixed(0)}ms avg',
      );
    }

    buffer.writeln('');

    // Data Volume
    buffer.writeln('📦 DATA VOLUME:');
    final changesStats = getMetricStats('incremental_changes_count');
    if (changesStats['count'] > 0) {
      buffer.writeln(
        '  Avg changes per sync: ${changesStats['avg'].toStringAsFixed(0)}',
      );
    }

    final conflictsStats = getMetricStats('conflicts_resolved');
    if (conflictsStats['count'] > 0) {
      buffer.writeln('  Conflicts resolved: ${conflictsStats['total']}');
    }

    return buffer.toString();
  }

  // 🧹 CLEANUP
  void clear() {
    _metrics.clear();
    _activeTimers.clear();
    _performanceLogs.clear();
  }

  void clearOldData({Duration olderThan = const Duration(hours: 24)}) {
    final cutoff = DateTime.now().subtract(olderThan);

    _performanceLogs.removeWhere((log) {
      final timestamp = DateTime.parse(log['timestamp']);
      return timestamp.isBefore(cutoff);
    });
  }

  // 🎯 BENCHMARK HELPERS
  Future<T> benchmark<T>(String name, Future<T> Function() operation) async {
    final timer = startTimer(name);
    try {
      final result = await operation();
      return result;
    } finally {
      timer.stop();
      logMetric('${name}_ms', timer.elapsedMilliseconds);
    }
  }

  T benchmarkSync<T>(String name, T Function() operation) {
    final timer = startTimer(name);
    try {
      final result = operation();
      return result;
    } finally {
      timer.stop();
      logMetric('${name}_ms', timer.elapsedMilliseconds);
    }
  }
}
