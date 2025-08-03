import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/sync_provider.dart';
import '../../services/sync_service.dart';

class SyncStatusWidget extends StatelessWidget {
  final bool showDetails;
  final VoidCallback? onTap;
  
  const SyncStatusWidget({
    super.key,
    this.showDetails = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<SyncProvider>(
      builder: (context, syncProvider, child) {
        return GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: syncProvider.getStatusColor().withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: syncProvider.getStatusColor().withOpacity(0.3),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildStatusIcon(syncProvider),
                const SizedBox(width: 8),
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        syncProvider.getStatusMessage(),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: syncProvider.getStatusColor(),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (showDetails) ..._buildDetails(context, syncProvider),
                    ],
                  ),
                ),
                if (syncProvider.pendingChangesCount > 0)
                  _buildPendingBadge(syncProvider),
              ],
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildStatusIcon(SyncProvider syncProvider) {
    if (syncProvider.status == SyncStatus.syncing) {
      return SizedBox(
        width: 16,
        height: 16,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation(syncProvider.getStatusColor()),
          value: syncProvider.progress > 0 ? syncProvider.progress : null,
        ),
      );
    }
    
    return Icon(
      syncProvider.getStatusIcon(),
      size: 16,
      color: syncProvider.getStatusColor(),
    );
  }
  
  List<Widget> _buildDetails(BuildContext context, SyncProvider syncProvider) {
    final details = <Widget>[];
    
    if (syncProvider.status == SyncStatus.syncing && syncProvider.progress > 0) {
      details.add(
        LinearProgressIndicator(
          value: syncProvider.progress,
          backgroundColor: Colors.grey[300],
          valueColor: AlwaysStoppedAnimation(syncProvider.getStatusColor()),
        ),
      );
    }
    
    if (syncProvider.error != null) {
      details.add(
        Text(
          syncProvider.error!,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Colors.red,
            fontSize: 11,
          ),
        ),
      );
    }
    
    return details;
  }
  
  Widget _buildPendingBadge(SyncProvider syncProvider) {
    return Container(
      margin: const EdgeInsets.only(left: 8),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.orange,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        '${syncProvider.pendingChangesCount}',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class SyncControlPanel extends StatelessWidget {
  const SyncControlPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SyncProvider>(
      builder: (context, syncProvider, child) {
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.sync,
                      color: Theme.of(context).primaryColor,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Sincronização',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    _buildPerformanceBadge(context, syncProvider),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Status atual
                SyncStatusWidget(showDetails: true),
                const SizedBox(height: 16),
                
                // Controles
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ElevatedButton.icon(
                      onPressed: syncProvider.status == SyncStatus.syncing 
                          ? null 
                          : () => syncProvider.quickSync(),
                      icon: const Icon(Icons.sync, size: 18),
                      label: const Text('Sync Rápido'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: syncProvider.status == SyncStatus.syncing 
                          ? null 
                          : () => syncProvider.performSync(forceFull: true),
                      icon: const Icon(Icons.refresh, size: 18),
                      label: const Text('Sync Completo'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () => syncProvider.smartSync(),
                      icon: const Icon(Icons.auto_awesome, size: 18),
                      label: const Text('Sync Inteligente'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Auto Sync Toggle
                SwitchListTile(
                  title: const Text('Sincronização Automática'),
                  subtitle: const Text('Sincronizar automaticamente a cada 5 minutos'),
                  value: syncProvider.autoSyncEnabled,
                  onChanged: (value) {
                    if (value) {
                      syncProvider.enableAutoSync();
                    } else {
                      syncProvider.disableAutoSync();
                    }
                  },
                ),
                
                // Métricas
                if (syncProvider.lastSyncTime != null) ...[
                  const Divider(),
                  _buildMetrics(context, syncProvider),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildPerformanceBadge(BuildContext context, SyncProvider syncProvider) {
    final isOptimal = syncProvider.isPerformanceOptimal;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isOptimal ? Colors.green : Colors.orange,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isOptimal ? Icons.speed : Icons.warning,
            size: 14,
            color: Colors.white,
          ),
          const SizedBox(width: 4),
          Text(
            isOptimal ? 'Performance OK' : 'Performance Baixa',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildMetrics(BuildContext context, SyncProvider syncProvider) {
    final metrics = syncProvider.getSyncMetrics();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Métricas de Performance',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        _buildMetricRow('Último Sync:', _formatLastSync(metrics['last_sync'])),
        _buildMetricRow('Mudanças Pendentes:', '${metrics['pending_changes']}'),
        _buildMetricRow('Performance:', metrics['performance_optimal'] ? '✅ Ótima' : '⚠️ Pode melhorar'),
        
        const SizedBox(height: 8),
        TextButton.icon(
          onPressed: () => _showPerformanceReport(context, syncProvider),
          icon: const Icon(Icons.analytics, size: 16),
          label: const Text('Ver Relatório Completo'),
        ),
      ],
    );
  }
  
  Widget _buildMetricRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          const SizedBox(width: 8),
          Text(value),
        ],
      ),
    );
  }
  
  String _formatLastSync(String? lastSync) {
    if (lastSync == null) return 'Nunca';
    
    final time = DateTime.parse(lastSync);
    final diff = DateTime.now().difference(time);
    
    if (diff.inMinutes < 1) {
      return 'Há ${diff.inSeconds}s';
    } else if (diff.inHours < 1) {
      return 'Há ${diff.inMinutes}min';
    } else {
      return 'Há ${diff.inHours}h';
    }
  }
  
  void _showPerformanceReport(BuildContext context, SyncProvider syncProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Relatório de Performance'),
        content: SingleChildScrollView(
          child: Text(
            syncProvider.getPerformanceReport(),
            style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fechar'),
          ),
          TextButton(
            onPressed: () {
              syncProvider.checkPerformanceTargets();
              Navigator.pop(context);
            },
            child: const Text('Verificar Metas'),
          ),
        ],
      ),
    );
  }
}

class SyncButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final String? text;
  final IconData? icon;
  
  const SyncButton({
    super.key,
    this.onPressed,
    this.text,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<SyncProvider>(
      builder: (context, syncProvider, child) {
        final isLoading = syncProvider.status == SyncStatus.syncing;
        
        return ElevatedButton.icon(
          onPressed: isLoading ? null : (onPressed ?? () => syncProvider.smartSync()),
          icon: isLoading 
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Icon(icon ?? Icons.sync),
          label: Text(text ?? 'Sincronizar'),
        );
      },
    );
  }
}
