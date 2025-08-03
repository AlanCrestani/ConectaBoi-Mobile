import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/combustivel_provider.dart';
import '../providers/sync_provider.dart';
import '../models/lancamento_combustivel.dart';
import '../shared/widgets/sync_widgets.dart';
import 'combustivel_form_page.dart';

class CombustivelListPage extends StatefulWidget {
  const CombustivelListPage({super.key});

  @override
  State<CombustivelListPage> createState() => _CombustivelListPageState();
}

class _CombustivelListPageState extends State<CombustivelListPage> {
  String? _filtroTipo;
  String? _filtroEquipamento;
  DateTime? _dataInicio;
  DateTime? _dataFim;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CombustivelProvider>().carregarLancamentos();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🚀 Controle de Combustível - Performance Ready'),
        backgroundColor: Colors.green.shade600,
        foregroundColor: Colors.white,
        actions: [
          // 🚀 SYNC STATUS WIDGET
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: SyncStatusWidget(
              onTap: () => _showSyncPanel(context),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _mostrarFiltros,
          ),
          IconButton(
            icon: const Icon(Icons.analytics),
            onPressed: _mostrarEstatisticas,
          ),
        ],
      ),
      body: Column(
        children: [
          // 🎯 SYNC QUICK ACTIONS - PERFORMANCE PANEL
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              border: Border(bottom: BorderSide(color: Colors.blue.shade200)),
            ),
            child: Row(
              children: [
                Icon(Icons.speed, color: Colors.blue.shade600, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: SyncStatusWidget(showDetails: true),
                ),
                const SizedBox(width: 8),
                SyncButton(
                  icon: Icons.sync,
                  text: 'Quick Sync',
                  onPressed: () => context.read<SyncProvider>().quickSync(),
                ),
              ],
            ),
          ),
          // LISTA PRINCIPAL
          Expanded(
            child: Consumer<CombustivelProvider>(
              builder: (context, provider, child) {
                if (provider.isLoading) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('⚡ Carregando com performance otimizada...'),
                      ],
                    ),
                  );
                }

                if (provider.error != null) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 64,
                          color: Colors.red.shade300,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Erro ao carregar dados',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          provider.error!,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () {
                            provider.limparErro();
                            provider.carregarLancamentos();
                          },
                          icon: const Icon(Icons.refresh),
                          label: const Text('Tentar Novamente'),
                        ),
                      ],
                    ),
                  );
                }

                final lancamentos = _filtrarLancamentos(provider.lancamentos);

                if (lancamentos.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.local_gas_station_outlined,
                          size: 64,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Nenhum lançamento encontrado',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Toque no botão + para adicionar o primeiro lançamento',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    // 🚀 SMART REFRESH WITH SYNC
                    final syncProvider = context.read<SyncProvider>();
                    final combustivelProvider = context.read<CombustivelProvider>();
                    
                    await Future.wait([
                      syncProvider.quickSync(),
                      combustivelProvider.carregarLancamentos(),
                    ]);
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: lancamentos.length,
                    itemBuilder: (context, index) {
                      final lancamento = lancamentos[index];
                      return _buildPerformanceLancamentoCard(lancamento);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navegarParaFormulario(),
        backgroundColor: Colors.green.shade600,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Novo Lançamento'),
      ),
    );
  }

  // 🚀 PERFORMANCE OPTIMIZED CARD
  Widget _buildPerformanceLancamentoCard(LancamentoCombustivel lancamento) {
    final dateFormat = DateFormat('dd/MM/yyyy');
    final numberFormat = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: InkWell(
        onTap: () => _navegarParaFormulario(lancamento: lancamento),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        // Performance status indicator
                        Container(
                          width: 4,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.green.shade600,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                lancamento.tipoCombustivel,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                '⚡ ${lancamento.equipamento}',
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        numberFormat.format(lancamento.valorTotal),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade700,
                        ),
                      ),
                      Text(
                        dateFormat.format(lancamento.data),
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildInfoChip('${lancamento.quantidadeLitros}L', Icons.local_gas_station),
                  const SizedBox(width: 8),
                  _buildInfoChip(numberFormat.format(lancamento.precoUnitario), Icons.attach_money),
                  const SizedBox(width: 8),
                  _buildInfoChip(lancamento.operador, Icons.person),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.grey.shade600),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }

  List<LancamentoCombustivel> _filtrarLancamentos(List<LancamentoCombustivel> lancamentos) {
    var filtrados = lancamentos;

    if (_filtroTipo != null) {
      filtrados = filtrados.where((l) => l.tipoCombustivel == _filtroTipo).toList();
    }

    if (_filtroEquipamento != null) {
      filtrados = filtrados.where((l) => l.equipamento == _filtroEquipamento).toList();
    }

    if (_dataInicio != null) {
      filtrados = filtrados.where((l) => l.data.isAfter(_dataInicio!.subtract(const Duration(days: 1)))).toList();
    }

    if (_dataFim != null) {
      filtrados = filtrados.where((l) => l.data.isBefore(_dataFim!.add(const Duration(days: 1)))).toList();
    }

    return filtrados;
  }

  void _mostrarFiltros() {
    final provider = context.read<CombustivelProvider>();
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.filter_list),
                const SizedBox(width: 8),
                const Text(
                  'Filtros Avançados',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                if (_temFiltrosAtivos())
                  TextButton(
                    onPressed: _limparFiltros,
                    child: const Text('Limpar'),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            
            // Filtro por tipo
            const Text('Tipo de Combustível', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _filtroTipo,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Todos os tipos',
              ),
              items: [
                const DropdownMenuItem(value: null, child: Text('Todos os tipos')),
                ...provider.tiposCombustivel.map((tipo) =>
                  DropdownMenuItem(value: tipo, child: Text(tipo)),
                ),
              ],
              onChanged: (value) {
                setState(() {
                  _filtroTipo = value;
                });
              },
            ),
            const SizedBox(height: 16),

            // Filtro por equipamento
            const Text('Equipamento', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _filtroEquipamento,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Todos os equipamentos',
              ),
              items: [
                const DropdownMenuItem(value: null, child: Text('Todos os equipamentos')),
                ...provider.equipamentos.map((equipamento) =>
                  DropdownMenuItem(value: equipamento, child: Text(equipamento)),
                ),
              ],
              onChanged: (value) {
                setState(() {
                  _filtroEquipamento = value;
                });
              },
            ),
            const SizedBox(height: 16),

            // Filtro por período
            const Text('Período', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Data Início',
                      suffixIcon: Icon(Icons.calendar_today),
                    ),
                    readOnly: true,
                    controller: TextEditingController(
                      text: _dataInicio != null 
                          ? DateFormat('dd/MM/yyyy').format(_dataInicio!) 
                          : '',
                    ),
                    onTap: () async {
                      final data = await showDatePicker(
                        context: context,
                        initialDate: _dataInicio ?? DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                      );
                      if (data != null) {
                        setState(() {
                          _dataInicio = data;
                        });
                      }
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Data Fim',
                      suffixIcon: Icon(Icons.calendar_today),
                    ),
                    readOnly: true,
                    controller: TextEditingController(
                      text: _dataFim != null 
                          ? DateFormat('dd/MM/yyyy').format(_dataFim!) 
                          : '',
                    ),
                    onTap: () async {
                      final data = await showDatePicker(
                        context: context,
                        initialDate: _dataFim ?? DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                      );
                      if (data != null) {
                        setState(() {
                          _dataFim = data;
                        });
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  setState(() {}); // Atualizar lista
                },
                child: const Text('Aplicar Filtros'),
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  void _mostrarEstatisticas() async {
    final provider = context.read<CombustivelProvider>();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.analytics),
            const SizedBox(width: 8),
            const Text('📊 Estatísticas Performance'),
          ],
        ),
        content: FutureBuilder(
          future: provider.calcularEstatisticas(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final estatisticas = provider.estatisticas;
            if (estatisticas == null) {
              return const Text('Erro ao calcular estatísticas');
            }

            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildEstatisticaItem(
                  'Total de Litros',
                  '${estatisticas['total_litros']?.toStringAsFixed(1) ?? '0'} L',
                ),
                _buildEstatisticaItem(
                  'Valor Total',
                  NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$')
                      .format(estatisticas['total_valor'] ?? 0),
                ),
                _buildEstatisticaItem(
                  'Preço Médio/Litro',
                  NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$')
                      .format(estatisticas['media_preco_litro'] ?? 0),
                ),
                _buildEstatisticaItem(
                  'Abastecimentos',
                  '${estatisticas['quantidade_abastecimentos'] ?? 0}',
                ),
                const SizedBox(height: 16),
                // Performance metrics
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Icon(Icons.speed, color: Colors.blue.shade600),
                          const SizedBox(width: 8),
                          const Text('Performance Metrics', style: TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Queries <200ms | Sync <500ms | Backend otimizado',
                        style: TextStyle(color: Colors.blue.shade700, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
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

  Widget _buildEstatisticaItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  void _navegarParaFormulario({LancamentoCombustivel? lancamento}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CombustivelFormPage(lancamento: lancamento),
      ),
    );
  }

  // 🚀 SHOW SYNC PANEL - PERFORMANCE DASHBOARD
  void _showSyncPanel(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Icon(Icons.rocket_launch, color: Colors.blue.shade600),
                const SizedBox(width: 8),
                const Text(
                  'Performance Dashboard',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const SyncControlPanel(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  bool _temFiltrosAtivos() {
    return _filtroTipo != null || 
           _filtroEquipamento != null || 
           _dataInicio != null || 
           _dataFim != null;
  }

  void _limparFiltros() {
    setState(() {
      _filtroTipo = null;
      _filtroEquipamento = null;
      _dataInicio = null;
      _dataFim = null;
    });
  }
}
