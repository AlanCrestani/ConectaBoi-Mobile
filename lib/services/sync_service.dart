import 'dart:async';
import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/lancamento_combustivel.dart';
import 'combustivel_service.dart';
import '../core/services/performance_monitor.dart';

enum SyncStatus { idle, syncing, conflict, error, completed }

class SyncService {
  static const String _lastSyncKey = 'last_sync_timestamp';
  static const String _pendingChangesKey = 'pending_changes';
  static const int _batchSize = 50;
  static const Duration _syncTimeout = Duration(seconds: 30);
  
  final SupabaseClient _supabase = Supabase.instance.client;
  final CombustivelService _combustivelService = CombustivelService();
  final PerformanceMonitor _monitor = PerformanceMonitor();
  
  final StreamController<SyncStatus> _statusController = StreamController.broadcast();
  final StreamController<double> _progressController = StreamController.broadcast();
  final StreamController<String> _errorController = StreamController.broadcast();
  
  Stream<SyncStatus> get statusStream => _statusController.stream;
  Stream<double> get progressStream => _progressController.stream;
  Stream<String> get errorStream => _errorController.stream;
  
  SyncStatus _currentStatus = SyncStatus.idle;
  List<Map<String, dynamic>> _pendingChanges = [];
  DateTime? _lastSyncTime;
  
  // ⚡ SYNC PERFORMANCE OTIMIZADA
  Future<bool> syncData({bool forceFull = false}) async {
    if (_currentStatus == SyncStatus.syncing) return false;
    
    final syncTimer = _monitor.startTimer('full_sync');
    
    try {
      _updateStatus(SyncStatus.syncing);
      _updateProgress(0.0);
      
      // 1. Carregar estado local
      await _loadLocalState();
      _updateProgress(0.1);
      
      // 2. Determinar estratégia de sync
      final needsFullSync = forceFull || _lastSyncTime == null;
      
      if (needsFullSync) {
        return await _performFullSync();
      } else {
        return await _performIncrementalSync();
      }
    } catch (e) {
      _updateStatus(SyncStatus.error);
      _updateError('Erro na sincronização: $e');
      return false;
    } finally {
      syncTimer.stop();
      _monitor.logMetric('sync_duration_ms', syncTimer.elapsedMilliseconds);
    }
  }
  
  // 🚀 SYNC COMPLETO COM PERFORMANCE GARANTIDA
  Future<bool> _performFullSync() async {
    final timer = _monitor.startTimer('full_sync_operation');
    
    try {
      // Upload pending changes primeiro
      await _uploadPendingChanges();
      _updateProgress(0.3);
      
      // Download otimizado com paginação
      final remoteData = await _downloadRemoteDataBatched();
      _updateProgress(0.7);
      
      // Merge local com conflict resolution
      await _mergeDataWithConflictResolution(remoteData);
      _updateProgress(0.9);
      
      // Atualizar timestamp
      await _updateLastSyncTime();
      _updateProgress(1.0);
      
      _updateStatus(SyncStatus.completed);
      return true;
      
    } catch (e) {
      timer.stop();
      throw e;
    }
  }
  
  // ⚡ SYNC INCREMENTAL SUPER RÁPIDO
  Future<bool> _performIncrementalSync() async {
    final timer = _monitor.startTimer('incremental_sync');
    
    try {
      // Changes desde último sync
      final since = _lastSyncTime!;
      
      // Upload pending (prioritário)
      await _uploadPendingChanges();
      _updateProgress(0.4);
      
      // Download apenas alterações
      final changes = await _downloadChangesSince(since);
      _updateProgress(0.8);
      
      // Apply changes rapidamente
      await _applyIncrementalChanges(changes);
      _updateProgress(0.95);
      
      await _updateLastSyncTime();
      _updateProgress(1.0);
      
      _updateStatus(SyncStatus.completed);
      timer.stop();
      
      // Log performance
      _monitor.logMetric('incremental_sync_ms', timer.elapsedMilliseconds);
      return true;
      
    } catch (e) {
      timer.stop();
      throw e;
    }
  }
  
  // 📤 UPLOAD OTIMIZADO EM LOTES
  Future<void> _uploadPendingChanges() async {
    if (_pendingChanges.isEmpty) return;
    
    final uploadTimer = _monitor.startTimer('upload_pending');
    
    try {
      // Processar em lotes para performance
      for (int i = 0; i < _pendingChanges.length; i += _batchSize) {
        final batch = _pendingChanges.skip(i).take(_batchSize).toList();
        
        await _processBatch(batch);
        
        // Update progress
        final progress = 0.1 + (0.2 * (i / _pendingChanges.length));
        _updateProgress(progress);
      }
      
      // Limpar pending após upload
      _pendingChanges.clear();
      await _savePendingChanges();
      
    } finally {
      uploadTimer.stop();
      _monitor.logMetric('upload_duration_ms', uploadTimer.elapsedMilliseconds);
    }
  }
  
  // 📥 DOWNLOAD OTIMIZADO EM LOTES
  Future<List<LancamentoCombustivel>> _downloadRemoteDataBatched() async {
    final downloadTimer = _monitor.startTimer('download_batched');
    
    try {
      final allData = <LancamentoCombustivel>[];
      int offset = 0;
      
      while (true) {
        // Query otimizada com limit/offset
        final response = await _supabase
            .from('lancamentos_combustivel')
            .select()
            .order('updated_at', ascending: false)
            .range(offset, offset + _batchSize - 1);
        
        if (response.isEmpty) break;
        
        final batch = (response as List)
            .map((item) => LancamentoCombustivel.fromJson(item))
            .toList();
        
        allData.addAll(batch);
        offset += _batchSize;
        
        // Progress update
        if (offset % (_batchSize * 4) == 0) {
          final progress = 0.3 + (0.4 * (offset / 1000)); // Estimate
          _updateProgress(progress.clamp(0.3, 0.7));
        }
        
        // Break if batch not full (end of data)
        if (batch.length < _batchSize) break;
      }
      
      return allData;
      
    } finally {
      downloadTimer.stop();
      _monitor.logMetric('download_duration_ms', downloadTimer.elapsedMilliseconds);
    }
  }
  
  // 🔄 DOWNLOAD INCREMENTAL ULTRA RÁPIDO
  Future<List<LancamentoCombustivel>> _downloadChangesSince(DateTime since) async {
    final timer = _monitor.startTimer('download_changes');
    
    try {
      // Query otimizada apenas com mudanças
      final response = await _supabase
          .from('lancamentos_combustivel')
          .select()
          .gte('updated_at', since.toIso8601String())
          .order('updated_at', ascending: false)
          .limit(500); // Limite para performance
      
      final changes = (response as List)
          .map((item) => LancamentoCombustivel.fromJson(item))
          .toList();
      
      _monitor.logMetric('incremental_changes_count', changes.length);
      return changes;
      
    } finally {
      timer.stop();
      _monitor.logMetric('download_changes_ms', timer.elapsedMilliseconds);
    }
  }
  
  // 🎯 CONFLICT RESOLUTION INTELIGENTE
  Future<void> _mergeDataWithConflictResolution(
    List<LancamentoCombustivel> remoteData,
  ) async {
    final mergeTimer = _monitor.startTimer('conflict_resolution');
    
    try {
      final conflicts = <String, Map<String, dynamic>>{};
      
      for (final remoteItem in remoteData) {
        // Verifica se existe localmente
        final localItem = await _findLocalItem(remoteItem.id!);
        
        if (localItem == null) {
          // Novo item - sem conflito
          continue;
        }
        
        // Resolve conflito por timestamp
        final conflict = _resolveConflict(localItem, remoteItem);
        
        if (conflict != null) {
          conflicts[remoteItem.id!] = conflict;
        }
      }
      
      // Log conflicts para debug
      if (conflicts.isNotEmpty) {
        _monitor.logMetric('conflicts_resolved', conflicts.length);
        _updateStatus(SyncStatus.conflict);
        
        // Auto-resolve usando "last write wins"
        await _autoResolveConflicts(conflicts);
      }
      
    } finally {
      mergeTimer.stop();
      _monitor.logMetric('merge_duration_ms', mergeTimer.elapsedMilliseconds);
    }
  }
  
  // 🤖 AUTO-RESOLVE CONFLICTS
  Future<void> _autoResolveConflicts(
    Map<String, Map<String, dynamic>> conflicts,
  ) async {
    for (final entry in conflicts.entries) {
      final conflict = entry.value;
      final remoteItem = conflict['remote'] as LancamentoCombustivel;
      final localItem = conflict['local'] as LancamentoCombustivel;
      
      // Strategy: Last write wins (most recent updatedAt)
      final useRemote = remoteItem.updatedAt?.isAfter(
        localItem.updatedAt ?? DateTime.now(),
      ) ?? true;
      
      if (useRemote) {
        // Apply remote version
        await _applyRemoteChange(remoteItem);
      }
      // Se usar local, não faz nada (já está correto)
    }
  }
  
  // ⚡ APPLY CHANGES PERFORMANCE
  Future<void> _applyIncrementalChanges(
    List<LancamentoCombustivel> changes,
  ) async {
    final applyTimer = _monitor.startTimer('apply_changes');
    
    try {
      for (final change in changes) {
        await _applyRemoteChange(change);
      }
    } finally {
      applyTimer.stop();
      _monitor.logMetric('apply_changes_ms', applyTimer.elapsedMilliseconds);
    }
  }
  
  // 🔧 UTILITY METHODS
  Future<void> _processBatch(List<Map<String, dynamic>> batch) async {
    for (final change in batch) {
      final action = change['action'] as String;
      final data = change['data'] as Map<String, dynamic>;
      
      switch (action) {
        case 'create':
          await _supabase.from('lancamentos_combustivel').insert(data);
          break;
        case 'update':
          await _supabase
              .from('lancamentos_combustivel')
              .update(data)
              .eq('id', data['id']);
          break;
        case 'delete':
          await _supabase
              .from('lancamentos_combustivel')
              .delete()
              .eq('id', data['id']);
          break;
      }
    }
  }
  
  Future<LancamentoCombustivel?> _findLocalItem(String id) async {
    // Mock implementation - would use local SQLite
    try {
      final items = await _combustivelService.buscarLancamentos();
      return items.firstWhere((item) => item.id == id);
    } catch (e) {
      return null;
    }
  }
  
  Map<String, dynamic>? _resolveConflict(
    LancamentoCombustivel local,
    LancamentoCombustivel remote,
  ) {
    // Verifica se há diferenças significativas
    final localHash = _calculateHash(local);
    final remoteHash = _calculateHash(remote);
    
    if (localHash != remoteHash) {
      return {
        'local': local,
        'remote': remote,
        'type': 'data_conflict',
      };
    }
    
    return null;
  }
  
  String _calculateHash(LancamentoCombustivel item) {
    // Hash simples para detectar mudanças
    return '${item.quantidadeLitros}_${item.valorTotal}_${item.tipoCombustivel}_${item.operador}';
  }
  
  Future<void> _applyRemoteChange(LancamentoCombustivel item) async {
    // Apply remote change locally (seria SQLite em produção)
    // Por agora, apenas aceita a mudança
  }
  
  // 💾 STATE MANAGEMENT
  Future<void> _loadLocalState() async {
    final prefs = await SharedPreferences.getInstance();
    
    final lastSyncString = prefs.getString(_lastSyncKey);
    if (lastSyncString != null) {
      _lastSyncTime = DateTime.parse(lastSyncString);
    }
    
    final pendingString = prefs.getString(_pendingChangesKey);
    if (pendingString != null) {
      final pendingList = jsonDecode(pendingString) as List;
      _pendingChanges = pendingList.cast<Map<String, dynamic>>();
    }
  }
  
  Future<void> _updateLastSyncTime() async {
    _lastSyncTime = DateTime.now();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastSyncKey, _lastSyncTime!.toIso8601String());
  }
  
  Future<void> _savePendingChanges() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_pendingChangesKey, jsonEncode(_pendingChanges));
  }
  
  // 📊 EVENT STREAMS
  void _updateStatus(SyncStatus status) {
    _currentStatus = status;
    _statusController.add(status);
  }
  
  void _updateProgress(double progress) {
    _progressController.add(progress);
  }
  
  void _updateError(String error) {
    _errorController.add(error);
  }
  
  // 📱 PUBLIC API
  Future<void> addPendingChange(String action, Map<String, dynamic> data) async {
    _pendingChanges.add({
      'action': action,
      'data': data,
      'timestamp': DateTime.now().toIso8601String(),
    });
    await _savePendingChanges();
  }
  
  SyncStatus get currentStatus => _currentStatus;
  DateTime? get lastSyncTime => _lastSyncTime;
  int get pendingChangesCount => _pendingChanges.length;
  
  // 🎯 PERFORMANCE METRICS
  Map<String, dynamic> getPerformanceMetrics() {
    return _monitor.getAllMetrics();
  }
  
  void dispose() {
    _statusController.close();
    _progressController.close();
    _errorController.close();
  }
}
