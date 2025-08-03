import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/supabase_service.dart';
import '../../core/constants/app_routes.dart';
import '../../core/constants/app_colors.dart';
import '../../shared/widgets/metric_card.dart';
import '../../data/models/dashboard_combustivel.dart';

class DashboardCombustivelPage extends StatefulWidget {
  const DashboardCombustivelPage({super.key});

  @override
  State<DashboardCombustivelPage> createState() =>
      _DashboardCombustivelPageState();
}

class _DashboardCombustivelPageState extends State<DashboardCombustivelPage> {
  bool _isLoading = true;
  String? _userName;
  String? _confinamentoName;
  DashboardCombustivel _dashboardData = DashboardCombustivel.empty();

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);

    try {
      final authService = context.read<AuthService>();

      if (authService.isLoggedIn) {
        // Carregar dados reais do usuário logado
        final profile = await authService.getUserProfile();
        if (profile != null) {
          _userName =
              profile['nome_completo'] as String? ??
              profile['name'] as String? ??
              'Usuário';
        }

        final confinamentos = await authService.getUserConfinamentos();
        if (confinamentos.isNotEmpty) {
          _confinamentoName =
              confinamentos.first['confinamentos']['nome'] as String? ??
              'Fazenda';
        }

        // Carregar dados reais do dashboard
        _dashboardData = await _loadRealDashboardData();
      } else {
        // Fallback para dados mock se não estiver logado
        _userName = 'Usuário Offline';
        _confinamentoName = 'Fazenda Teste - Modo Offline';
        _dashboardData = _getMockDashboardData();
      }
    } catch (e) {
      debugPrint('Error loading dashboard data: $e');
      // Em caso de erro, usar dados mock como fallback
      _userName = 'Usuário (Erro na conexão)';
      _confinamentoName = 'Fazenda Teste - Modo Offline';
      _dashboardData = _getMockDashboardData();
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // Carregar dados reais do Supabase
  Future<DashboardCombustivel> _loadRealDashboardData() async {
    try {
      final authService = context.read<AuthService>();

      if (!authService.isLoggedIn) {
        return DashboardCombustivel.empty();
      }

      // Buscar lançamentos de combustível do usuário
      final userId = authService.currentUser!.id;

      final lancamentosResponse = await SupabaseService.client
          .from('combustivel_lancamentos')
          .select('*')
          .eq('created_by', userId);

      // Buscar movimentações de hoje
      final hoje = DateTime.now();

      // Calcular métricas baseadas nos lançamentos
      final lancamentos = lancamentosResponse as List<dynamic>;

      // Totais agregados
      double totalDisponivel = 0;
      double totalConsumidoHoje = 0;
      double totalAbastecidoHoje = 0;
      Map<String, double> distribucaoPorTipo = {};

      // Calcular totais dos lançamentos
      for (final lancamento in lancamentos) {
        final quantidade =
            (lancamento['quantidade_litros'] as num?)?.toDouble() ?? 0.0;
        final tipo = lancamento['tipo_combustivel'] as String? ?? 'diesel';
        final data = lancamento['data'] as String?;

        // Somar total disponível (simplificado - assumindo que tudo que foi comprado ainda está disponível)
        totalDisponivel += quantidade;

        // Distribuição por tipo
        distribucaoPorTipo[tipo] = (distribucaoPorTipo[tipo] ?? 0) + quantidade;

        // Verificar se é de hoje para consumo diário
        if (data == hoje.toIso8601String().split('T')[0]) {
          totalAbastecidoHoje += quantidade;
        }
      }

      // Consumo estimado (para demonstração, vamos usar 10% do total como consumido hoje)
      totalConsumidoHoje = totalDisponivel * 0.1;

      // Valor estimado do estoque (preço médio)
      double precoMedio = 5.50; // R$ 5,50/L para diesel
      if (lancamentos.isNotEmpty) {
        final precos = lancamentos
            .map((l) => (l['preco_unitario'] as num?)?.toDouble() ?? 5.50)
            .toList();
        precoMedio = precos.reduce((a, b) => a + b) / precos.length;
      }
      final valorTotalEstoque = totalDisponivel * precoMedio;

      // Consumo médio (buscar últimos 7 dias)
      final seteAtras = hoje.subtract(const Duration(days: 7));
      final consumoResponse = await SupabaseService.client
          .from('combustivel_lancamentos')
          .select('quantidade_litros, data')
          .eq('created_by', userId)
          .gte('data', seteAtras.toIso8601String().split('T')[0]);

      final consumos = consumoResponse as List<dynamic>;
      double totalConsumo7Dias = 0;
      for (final consumo in consumos) {
        totalConsumo7Dias +=
            (consumo['quantidade_litros'] as num?)?.toDouble() ?? 0.0;
      }
      final consumoMedioDiario = consumos.isNotEmpty
          ? totalConsumo7Dias / 7
          : 0.0;
      final diasAutonomia = consumoMedioDiario > 0
          ? (totalDisponivel / consumoMedioDiario).round()
          : 999;

      return DashboardCombustivel(
        totalTanques: lancamentos.length,
        totalCapacidade:
            totalDisponivel * 1.2, // Assumir 20% de margem de capacidade
        totalDisponivel: totalDisponivel,
        totalConsumidoHoje: totalConsumidoHoje,
        totalAbastecidoHoje: totalAbastecidoHoje,
        valorTotalEstoque: valorTotalEstoque,
        tanquesBaixoNivel: 0, // Simplificado por enquanto
        tanquesCriticos: 0, // Simplificado por enquanto
        veiculosAtivos: 5, // Dados simulados - implementar integração futura
        equipamentosAtivos:
            12, // Dados simulados - implementar integração futura
        consumoMedioDiario: consumoMedioDiario,
        diasAutonomiaMedia: diasAutonomia,
        ultimaAtualizacao: DateTime.now(),
        distribucaoPorTipo: distribucaoPorTipo,
        consumoPorDia:
            _generateSimulatedConsumptionHistory(), // Dados simulados básicos
      );
    } catch (e) {
      debugPrint('Erro ao carregar dados reais: $e');
      // Retornar dados zerados em caso de erro
      return DashboardCombustivel.empty();
    }
  }

  Map<String, double> _generateSimulatedConsumptionHistory() {
    final Map<String, double> history = {};
    final now = DateTime.now();

    // Gerar dados dos últimos 7 dias
    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final dateKey = date.toIso8601String().split('T')[0];
      // Simular consumo variável entre 150-250 litros por dia
      final consumption = 150.0 + (i * 15.0) + (date.weekday % 3 * 20.0);
      history[dateKey] = consumption;
    }

    return history;
  }

  // Mock data for development
  DashboardCombustivel _getMockDashboardData() {
    return DashboardCombustivel(
      totalTanques: 4,
      totalCapacidade: 15000.0,
      totalDisponivel: 8750.0,
      totalConsumidoHoje: 180.5,
      totalAbastecidoHoje: 2000.0,
      valorTotalEstoque: 45600.0,
      tanquesBaixoNivel: 1,
      tanquesCriticos: 0,
      veiculosAtivos: 12,
      equipamentosAtivos: 8,
      consumoMedioDiario: 165.3,
      diasAutonomiaMedia: 52,
      ultimaAtualizacao: DateTime.now(),
      distribucaoPorTipo: {
        'diesel': 6500.0,
        'gasolina': 1750.0,
        'etanol': 500.0,
      },
      consumoPorDia: {
        '2025-07-26': 150.0,
        '2025-07-27': 175.0,
        '2025-07-28': 160.0,
        '2025-07-29': 180.0,
        '2025-07-30': 165.0,
        '2025-07-31': 180.5,
      },
    );
  }

  Future<void> _handleLogout() async {
    try {
      // Simular logout para modo offline
      await Future.delayed(const Duration(milliseconds: 500));

      if (mounted) {
        Navigator.of(context).pushReplacementNamed(AppRoutes.login);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao sair: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _showProfileDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Perfil do Usuário'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Nome: ${_userName ?? "Usuário"}'),
            Text('Confinamento: ${_confinamentoName ?? "Não definido"}'),
            const SizedBox(height: 16),
            const Text('Funcionalidade em desenvolvimento'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }

  void _showSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Configurações'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('• Configurar notificações'),
            Text('• Definir alertas personalizados'),
            Text('• Preferências de exibição'),
            SizedBox(height: 16),
            Text('Funcionalidade em desenvolvimento'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }

  void _showAlertDetails(String alerta) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Detalhes do Alerta'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(alerta),
            const SizedBox(height: 16),
            const Text(
              'Detalhes adicionais serão implementados em versões futuras.',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Controle de Combustível'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDashboardData,
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'profile':
                  _showProfileDialog();
                  break;
                case 'settings':
                  _showSettingsDialog();
                  break;
                case 'logout':
                  _handleLogout();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'profile',
                child: ListTile(
                  leading: Icon(Icons.person),
                  title: Text('Perfil'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'settings',
                child: ListTile(
                  leading: Icon(Icons.settings),
                  title: Text('Configurações'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'logout',
                child: ListTile(
                  leading: Icon(Icons.logout, color: AppColors.error),
                  title: Text('Sair', style: TextStyle(color: AppColors.error)),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadDashboardData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Welcome section
                    _buildWelcomeSection(),

                    const SizedBox(height: 24),

                    // Status geral
                    _buildStatusSection(),

                    const SizedBox(height: 24),

                    // Métricas principais
                    _buildMetricsSection(),

                    const SizedBox(height: 24),

                    // Tanques
                    _buildTanquesSection(),

                    const SizedBox(height: 24),

                    // Quick actions
                    _buildQuickActionsSection(),

                    const SizedBox(height: 24),

                    // Alertas
                    _buildAlertsSection(),
                  ],
                ),
              ),
            ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: 0,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.local_gas_station),
            label: 'Tanques',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_road),
            label: 'Abastecer',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.analytics),
            label: 'Relatórios',
          ),
        ],
        onTap: (index) {
          switch (index) {
            case 0:
              // Already on dashboard
              break;
            case 1:
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Tanques - Em desenvolvimento')),
              );
              break;
            case 2:
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Abastecimento - Em desenvolvimento'),
                ),
              );
              break;
            case 3:
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Relatórios - Em desenvolvimento'),
                ),
              );
              break;
          }
        },
      ),
      floatingActionButton: _dashboardData.totalTanques == 0
          ? FloatingActionButton.extended(
              onPressed: () {
                Navigator.of(context).pushNamed(AppRoutes.novaEntrada);
              },
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add),
              label: const Text('Primeira Entrada'),
            )
          : FloatingActionButton(
              onPressed: () {
                Navigator.of(context).pushNamed(AppRoutes.novaEntrada);
              },
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              child: const Icon(Icons.add),
            ),
    );
  }

  Widget _buildWelcomeSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: AppColors.primary,
              child: const Icon(
                Icons.local_gas_station,
                color: AppColors.textOnPrimary,
                size: 30,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Olá, ${_userName ?? 'Usuário'}!',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  if (_confinamentoName != null)
                    Text(
                      _confinamentoName!,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  const SizedBox(height: 4),
                  Text(
                    'Última atualização: ${_dashboardData.ultimaAtualizacao.toString().substring(0, 16)}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              _getStatusIcon(_dashboardData.statusGeral),
              size: 32,
              color: _getStatusColor(_dashboardData.statusGeral),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Status Geral: ${_dashboardData.statusGeral}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: _getStatusColor(_dashboardData.statusGeral),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Autonomia: ${_dashboardData.diasAutonomiaMedia} dias',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  Text(
                    'Ocupação: ${_dashboardData.percentualOcupacao.toStringAsFixed(1)}%',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Resumo de Hoje', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: MetricCard(
                title: 'Disponível',
                value:
                    '${(_dashboardData.totalDisponivel / 1000).toStringAsFixed(1)}k L',
                subtitle:
                    'de ${(_dashboardData.totalCapacidade / 1000).toStringAsFixed(1)}k L',
                icon: Icons.local_gas_station,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: MetricCard(
                title: 'Consumido',
                value:
                    '${_dashboardData.totalConsumidoHoje.toStringAsFixed(1)} L',
                subtitle: 'hoje',
                icon: Icons.trending_down,
                color: AppColors.warning,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: MetricCard(
                title: 'Abastecido',
                value:
                    '${(_dashboardData.totalAbastecidoHoje / 1000).toStringAsFixed(1)}k L',
                subtitle: 'hoje',
                icon: Icons.trending_up,
                color: AppColors.success,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: MetricCard(
                title: 'Estoque',
                value:
                    'R\$ ${(_dashboardData.valorTotalEstoque / 1000).toStringAsFixed(1)}k',
                subtitle: 'valor total',
                icon: Icons.attach_money,
                color: AppColors.info,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTanquesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Status dos Tanques',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${_dashboardData.totalTanques} Tanques',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    if (_dashboardData.tanquesCriticos > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.error,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${_dashboardData.tanquesCriticos} Críticos',
                          style: const TextStyle(
                            color: AppColors.textOnPrimary,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                if (_dashboardData.distribucaoPorTipo.isNotEmpty) ...[
                  ..._dashboardData.distribucaoPorTipo.entries.map(
                    (entry) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: _getTipoCombustivelColor(entry.key),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _formatTipoCombustivel(entry.key),
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ),
                          Text(
                            '${(entry.value / 1000).toStringAsFixed(1)}k L',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Ações Rápidas', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                'Abastecer',
                Icons.add_road,
                AppColors.success,
                () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Navegando para Abastecimento...'),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildActionCard(
                'Ver Tanques',
                Icons.local_gas_station,
                AppColors.primary,
                () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Navegando para Tanques...')),
                  );
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                'Relatórios',
                Icons.analytics,
                AppColors.info,
                () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Navegando para Relatórios...'),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildActionCard(
                'Lançamentos',
                Icons.list_alt,
                AppColors.secondary,
                () {
                  Navigator.pushNamed(context, '/combustivel');
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard(
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(icon, size: 32, color: color),
              const SizedBox(height: 8),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAlertsSection() {
    final alertas = _dashboardData.alertasCriticos;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Alertas', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 16),
        if (alertas.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Icon(Icons.check_circle, size: 48, color: AppColors.success),
                  const SizedBox(height: 8),
                  Text(
                    'Tudo em ordem!',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Não há alertas críticos no momento.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          )
        else
          ...alertas.map(
            (alerta) => Card(
              color: AppColors.warning.withValues(alpha: 0.1),
              child: ListTile(
                leading: Icon(Icons.warning, color: AppColors.warning),
                title: Text(alerta),
                trailing: IconButton(
                  icon: const Icon(Icons.arrow_forward_ios),
                  onPressed: () {
                    _showAlertDetails(alerta);
                  },
                ),
              ),
            ),
          ),
      ],
    );
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'Crítico':
        return Icons.error;
      case 'Atenção':
        return Icons.warning;
      case 'Baixo':
        return Icons.info;
      default:
        return Icons.check_circle;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Crítico':
        return AppColors.error;
      case 'Atenção':
        return AppColors.warning;
      case 'Baixo':
        return AppColors.info;
      default:
        return AppColors.success;
    }
  }

  Color _getTipoCombustivelColor(String tipo) {
    switch (tipo) {
      case 'diesel':
        return AppColors.primary;
      case 'gasolina':
        return AppColors.warning;
      case 'etanol':
        return AppColors.success;
      default:
        return AppColors.secondary;
    }
  }

  String _formatTipoCombustivel(String tipo) {
    switch (tipo) {
      case 'diesel':
        return 'Diesel';
      case 'gasolina':
        return 'Gasolina';
      case 'etanol':
        return 'Etanol';
      default:
        return tipo;
    }
  }
}
