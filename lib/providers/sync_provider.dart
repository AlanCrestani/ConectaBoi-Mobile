import 'package:flutter/material.dart';
import '../services/sync_service.dart';
import '../core/services/performance_monitor.dart';

class SyncProvider extends ChangeNotifier {
  final SyncService _syncService = SyncService();
  final PerformanceMonitor _monitor = PerformanceMonitor();

  SyncStatus _status = SyncStatus.idle;
  double _progress = 0.0;
  String? _error;
  bool _autoSyncEnabled = true;
  DateTime? _lastSyncTime;

  // Getters
  SyncStatus get status => _status;
  double get progress => _progress;
  String? get error => _error;
  bool get autoSyncEnabled => _autoSyncEnabled;
  DateTime? get lastSyncTime => _lastSyncTime;
  int get pendingChangesCount => _syncService.pendingChangesCount;

  // Performance getters
  bool get isPerformanceOptimal => _isPerformanceOptimal();
  Map<String, dynamic> get performanceMetrics => _monitor.getAllMetrics();

  SyncProvider() {
    _initializeSyncProvider();
  }

  void _initializeSyncProvider() {
    // Listen to sync service streams
    _syncService.statusStream.listen((status) {
      _status = status;
      notifyListeners();
    });

    _syncService.progressStream.listen((progress) {
      _progress = progress;
      notifyListeners();
    });

    _syncService.errorStream.listen((error) {
      _error = error;
      notifyListeners();
    });

    // Load initial state
    _lastSyncTime = _syncService.lastSyncTime;
  }

  // 🚀 MAIN SYNC OPERATIONS
  Future<bool> performSync({bool forceFull = false}) async {
    final syncTimer = _monitor.startTimer('provider_sync');

    try {
      _error = null;
      notifyListeners();

      final success = await _syncService.syncData(forceFull: forceFull);

      if (success) {
        _lastSyncTime = DateTime.now();
        _error = null;
      }

      return success;
    } catch (e) {
      _error = 'Falha na sincronização: $e';
      return false;
    } finally {
      syncTimer.stop();
      _monitor.logMetric('provider_sync_ms', syncTimer.elapsedMilliseconds);
      notifyListeners();
    }
  }

  // ⚡ FAST INCREMENTAL SYNC
  Future<bool> quickSync() async {
    if (_status == SyncStatus.syncing) return false;

    final timer = _monitor.startTimer('quick_sync');

    try {
      final success = await _syncService.syncData(forceFull: false);

      if (success) {
        _lastSyncTime = DateTime.now();
      }

      return success;
    } finally {
      timer.stop();
      _monitor.logMetric('quick_sync_ms', timer.elapsedMilliseconds);
    }
  }

  // 📱 OFFLINE OPERATIONS
  Future<void> addOfflineChange(
    String action,
    Map<String, dynamic> data,
  ) async {
    await _syncService.addPendingChange(action, data);
    notifyListeners();
  }

  // 🔄 AUTO SYNC MANAGEMENT
  void enableAutoSync() {
    _autoSyncEnabled = true;
    notifyListeners();
    _startAutoSyncTimer();
  }

  void disableAutoSync() {
    _autoSyncEnabled = false;
    notifyListeners();
  }

  void _startAutoSyncTimer() {
    if (!_autoSyncEnabled) return;

    // Auto sync a cada 5 minutos se há mudanças pendentes
    Future.delayed(const Duration(minutes: 5), () {
      if (_autoSyncEnabled && pendingChangesCount > 0) {
        quickSync();
      }
      _startAutoSyncTimer();
    });
  }

  // 📊 PERFORMANCE MONITORING
  bool _isPerformanceOptimal() {
    final metrics = _monitor.getAllMetrics();

    // Check if last sync was fast enough
    final incrementalStats = metrics['incremental_sync_ms'];
    if (incrementalStats != null && incrementalStats['avg'] > 500) {
      return false;
    }

    // Check if queries are fast
    final queryStats = metrics['query_duration_ms'];
    if (queryStats != null && queryStats['avg'] > 200) {
      return false;
    }

    return true;
  }

  String getPerformanceReport() {
    return _monitor.generatePerformanceReport();
  }

  void checkPerformanceTargets() {
    _monitor.checkPerformanceTargets();
  }

  // 🛠️ UTILITY METHODS
  String getStatusMessage() {
    switch (_status) {
      case SyncStatus.idle:
        if (_lastSyncTime != null) {
          final diff = DateTime.now().difference(_lastSyncTime!);
          if (diff.inMinutes < 1) {
            return 'Sincronizado há ${diff.inSeconds}s';
          } else if (diff.inHours < 1) {
            return 'Sincronizado há ${diff.inMinutes}min';
          } else {
            return 'Sincronizado há ${diff.inHours}h';
          }
        }
        return 'Aguardando sincronização';

      case SyncStatus.syncing:
        return 'Sincronizando... ${(_progress * 100).toInt()}%';

      case SyncStatus.conflict:
        return 'Resolvendo conflitos...';

      case SyncStatus.error:
        return 'Erro na sincronização';

      case SyncStatus.completed:
        return 'Sincronização concluída';
    }
  }

  Color getStatusColor() {
    switch (_status) {
      case SyncStatus.idle:
        return pendingChangesCount > 0 ? Colors.orange : Colors.green;
      case SyncStatus.syncing:
        return Colors.blue;
      case SyncStatus.conflict:
        return Colors.orange;
      case SyncStatus.error:
        return Colors.red;
      case SyncStatus.completed:
        return Colors.green;
    }
  }

  IconData getStatusIcon() {
    switch (_status) {
      case SyncStatus.idle:
        return pendingChangesCount > 0 ? Icons.sync_problem : Icons.sync;
      case SyncStatus.syncing:
        return Icons.sync;
      case SyncStatus.conflict:
        return Icons.warning;
      case SyncStatus.error:
        return Icons.error;
      case SyncStatus.completed:
        return Icons.check_circle;
    }
  }

  // 🎯 SMART SYNC STRATEGIES
  Future<bool> smartSync() async {
    // Decide strategy based on conditions
    final now = DateTime.now();

    // If never synced or > 1 hour ago, do full sync
    if (_lastSyncTime == null || now.difference(_lastSyncTime!).inHours > 1) {
      return await performSync(forceFull: true);
    }

    // If many pending changes, prioritize upload
    if (pendingChangesCount > 10) {
      return await performSync(forceFull: false);
    }

    // Otherwise, quick incremental sync
    return await quickSync();
  }

  // 📈 METRICS FOR UI
  Map<String, dynamic> getSyncMetrics() {
    return {
      'last_sync': _lastSyncTime?.toIso8601String(),
      'pending_changes': pendingChangesCount,
      'auto_sync_enabled': _autoSyncEnabled,
      'performance_optimal': isPerformanceOptimal,
      'status': _status.toString(),
      'error': _error,
    };
  }

  @override
  void dispose() {
    _syncService.dispose();
    super.dispose();
  }
}
