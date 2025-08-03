import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/combustivel_provider.dart';
import '../models/lancamento_combustivel.dart';
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
        title: const Text('Controle de Combustível'),
        backgroundColor: Colors.green.shade600,
        foregroundColor: Colors.white,
        actions: [
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
      body: Consumer<CombustivelProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
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
                  ElevatedButton(
                    onPressed: () {
                      provider.limparErro();
                      provider.carregarLancamentos();
                    },
                    child: const Text('Tentar Novamente'),
                  ),
                ],
              ),
            );
          }

          final lancamentos = _aplicarFiltros(provider.lancamentos);

          if (lancamentos.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.local_gas_station_outlined,
                    size: 64,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Nenhum lançamento encontrado',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Adicione o primeiro lançamento de combustível',
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => provider.carregarLancamentos(),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: lancamentos.length,
              itemBuilder: (context, index) {
                final lancamento = lancamentos[index];
                return _buildLancamentoCard(lancamento);
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navegarParaFormulario(),
        backgroundColor: Colors.green.shade600,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildLancamentoCard(LancamentoCombustivel lancamento) {
    final dateFormat = DateFormat('dd/MM/yyyy');
    final numberFormat = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
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
                    child: Text(
                      lancamento.tipoCombustivel,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'editar') {
                        _navegarParaFormulario(lancamento: lancamento);
                      } else if (value == 'deletar') {
                        _confirmarExclusao(lancamento);
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'editar',
                        child: Row(
                          children: [
                            Icon(Icons.edit),
                            SizedBox(width: 8),
                            Text('Editar'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'deletar',
                        child: Row(
                          children: [
                            Icon(Icons.delete, color: Colors.red),
                            SizedBox(width: 8),
                            Text(
                              'Excluir',
                              style: TextStyle(color: Colors.red),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 16,
                    color: Colors.grey.shade600,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    dateFormat.format(lancamento.data),
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.build, size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      lancamento.equipamento,
                      style: TextStyle(color: Colors.grey.shade600),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.person, size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      lancamento.operador,
                      style: TextStyle(color: Colors.grey.shade600),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Column(
                      children: [
                        Text(
                          '${lancamento.quantidadeLitros.toStringAsFixed(2)}L',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Quantidade',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      children: [
                        Text(
                          numberFormat.format(lancamento.precoUnitario),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Preço/Litro',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      children: [
                        Text(
                          numberFormat.format(lancamento.valorTotal),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                        Text(
                          'Total',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (lancamento.observacoes?.isNotEmpty == true) ...[
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    lancamento.observacoes!,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade700,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  List<LancamentoCombustivel> _aplicarFiltros(
    List<LancamentoCombustivel> lancamentos,
  ) {
    var filtered = lancamentos;

    if (_filtroTipo != null) {
      filtered = filtered
          .where((l) => l.tipoCombustivel == _filtroTipo)
          .toList();
    }

    if (_filtroEquipamento != null) {
      filtered = filtered
          .where((l) => l.equipamento == _filtroEquipamento)
          .toList();
    }

    if (_dataInicio != null) {
      filtered = filtered
          .where(
            (l) =>
                l.data.isAfter(_dataInicio!) ||
                l.data.isAtSameMomentAs(_dataInicio!),
          )
          .toList();
    }

    if (_dataFim != null) {
      filtered = filtered
          .where(
            (l) =>
                l.data.isBefore(_dataFim!) ||
                l.data.isAtSameMomentAs(_dataFim!),
          )
          .toList();
    }

    return filtered;
  }

  void _mostrarFiltros() {
    final provider = context.read<CombustivelProvider>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Filtros', style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _filtroTipo,
                decoration: const InputDecoration(
                  labelText: 'Tipo de Combustível',
                  border: OutlineInputBorder(),
                ),
                items: [
                  const DropdownMenuItem(value: null, child: Text('Todos')),
                  ...provider.tiposCombustivel.map(
                    (tipo) => DropdownMenuItem(value: tipo, child: Text(tipo)),
                  ),
                ],
                onChanged: (value) => setState(() => _filtroTipo = value),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _filtroEquipamento,
                decoration: const InputDecoration(
                  labelText: 'Equipamento',
                  border: OutlineInputBorder(),
                ),
                items: [
                  const DropdownMenuItem(value: null, child: Text('Todos')),
                  ...provider.equipamentos.map(
                    (equipamento) => DropdownMenuItem(
                      value: equipamento,
                      child: Text(equipamento),
                    ),
                  ),
                ],
                onChanged: (value) =>
                    setState(() => _filtroEquipamento = value),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      decoration: const InputDecoration(
                        labelText: 'Data Início',
                        border: OutlineInputBorder(),
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
                          setState(() => _dataInicio = data);
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      decoration: const InputDecoration(
                        labelText: 'Data Fim',
                        border: OutlineInputBorder(),
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
                          setState(() => _dataFim = data);
                        }
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () {
                        setState(() {
                          _filtroTipo = null;
                          _filtroEquipamento = null;
                          _dataInicio = null;
                          _dataFim = null;
                        });
                        this.setState(() {});
                        Navigator.pop(context);
                      },
                      child: const Text('Limpar Filtros'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        this.setState(() {});
                        Navigator.pop(context);
                      },
                      child: const Text('Aplicar'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _mostrarEstatisticas() {
    final provider = context.read<CombustivelProvider>();
    provider.calcularEstatisticas();

    showDialog(
      context: context,
      builder: (context) => Consumer<CombustivelProvider>(
        builder: (context, provider, child) {
          final stats = provider.estatisticas;
          if (stats == null) {
            return const AlertDialog(content: CircularProgressIndicator());
          }

          final numberFormat = NumberFormat.currency(
            locale: 'pt_BR',
            symbol: 'R\$',
          );

          return AlertDialog(
            title: const Text('Estatísticas'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildStatRow(
                  'Total de Litros:',
                  '${stats['total_litros'].toStringAsFixed(2)}L',
                ),
                _buildStatRow(
                  'Valor Total:',
                  numberFormat.format(stats['total_valor']),
                ),
                _buildStatRow(
                  'Preço Médio/Litro:',
                  numberFormat.format(stats['media_preco_litro']),
                ),
                _buildStatRow(
                  'Total de Abastecimentos:',
                  '${stats['quantidade_abastecimentos']}',
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Fechar'),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
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

  void _confirmarExclusao(LancamentoCombustivel lancamento) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Exclusão'),
        content: const Text('Tem certeza que deseja excluir este lançamento?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<CombustivelProvider>().deletarLancamento(
                lancamento.id!,
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
  }
}
