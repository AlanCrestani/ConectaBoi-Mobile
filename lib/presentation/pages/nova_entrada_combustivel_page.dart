import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/supabase_service.dart';
import '../../core/constants/app_colors.dart';

class NovaEntradaCombustivelPage extends StatefulWidget {
  const NovaEntradaCombustivelPage({super.key});

  @override
  State<NovaEntradaCombustivelPage> createState() =>
      _NovaEntradaCombustivelPageState();
}

class _NovaEntradaCombustivelPageState
    extends State<NovaEntradaCombustivelPage> {
  final _formKey = GlobalKey<FormState>();
  final _nomeController = TextEditingController();
  final _capacidadeController = TextEditingController();
  final _quantidadeEntradaController = TextEditingController();
  final _precoController = TextEditingController();
  final _observacoesController = TextEditingController();

  String _tipoCombustivel = 'diesel';
  bool _isLoading = false;

  final List<String> _tiposCombustivel = [
    'diesel',
    'gasolina_comum',
    'gasolina_aditivada',
    'etanol',
    'gnv',
  ];

  @override
  void dispose() {
    _nomeController.dispose();
    _capacidadeController.dispose();
    _quantidadeEntradaController.dispose();
    _precoController.dispose();
    _observacoesController.dispose();
    super.dispose();
  }

  Future<void> _salvarEntrada() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final authService = context.read<AuthService>();
      if (!authService.isLoggedIn) {
        throw Exception('Usuário não logado');
      }

      final userId = authService.currentUser!.id;

      // Buscar dados do usuário para pegar o confinamento
      final confinamentos = await authService.getUserConfinamentos();
      if (confinamentos.isEmpty) {
        throw Exception('Usuário não possui confinamentos associados');
      }

      final confinamentoId = confinamentos.first['confinamentos']['id'];

      // Inserir lançamento de combustível diretamente na tabela principal
      await SupabaseService.client.from('combustivel_lancamentos').insert({
        'confinamento_id': confinamentoId,
        'data': DateTime.now().toIso8601String().split('T')[0], // YYYY-MM-DD
        'tipo_combustivel': _tipoCombustivel,
        'quantidade_litros': double.parse(_quantidadeEntradaController.text),
        'preco_unitario': double.parse(_precoController.text),
        'valor_total':
            double.parse(_quantidadeEntradaController.text) *
            double.parse(_precoController.text),
        'equipamento': _nomeController.text
            .trim(), // Usar o nome como equipamento/local
        'operador': 'Sistema', // Operador padrão
        'observacoes': 'Primeira entrada - ${_nomeController.text.trim()}',
        'created_by': userId,
        'mobile_created_at': DateTime.now().toIso8601String(),
        'device_id': 'web-dashboard', // Identificar que veio do web
        'sync_status': 'synced', // Já está no servidor
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Entrada de combustível registrada com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(); // Voltar para o dashboard
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Erro ao registrar entrada: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nova Entrada de Combustível'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.local_gas_station, color: AppColors.primary),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Primeiro Cadastro',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                          Text(
                            'Registre seu primeiro tanque e entrada de combustível',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Dados do Tanque
              const Text(
                '📋 Dados do Tanque',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _nomeController,
                decoration: const InputDecoration(
                  labelText: 'Nome do Tanque',
                  hintText: 'Ex: Tanque Diesel Principal',
                  prefixIcon: Icon(Icons.label),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Nome é obrigatório';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              DropdownButtonFormField<String>(
                value: _tipoCombustivel,
                decoration: const InputDecoration(
                  labelText: 'Tipo de Combustível',
                  prefixIcon: Icon(Icons.local_gas_station),
                ),
                items: _tiposCombustivel.map((tipo) {
                  return DropdownMenuItem(
                    value: tipo,
                    child: Text(_getTipoDisplayName(tipo)),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _tipoCombustivel = value!;
                  });
                },
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _capacidadeController,
                decoration: const InputDecoration(
                  labelText: 'Capacidade Total (Litros)',
                  hintText: 'Ex: 10000',
                  prefixIcon: Icon(Icons.storage),
                  suffixText: 'L',
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                ],
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Capacidade é obrigatória';
                  }
                  final numero = double.tryParse(value);
                  if (numero == null || numero <= 0) {
                    return 'Capacidade deve ser maior que zero';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Dados da Entrada
              const Text(
                '⛽ Entrada Inicial',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _quantidadeEntradaController,
                decoration: const InputDecoration(
                  labelText: 'Quantidade de Entrada (Litros)',
                  hintText: 'Ex: 8000',
                  prefixIcon: Icon(Icons.add_circle),
                  suffixText: 'L',
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                ],
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Quantidade é obrigatória';
                  }
                  final numero = double.tryParse(value);
                  if (numero == null || numero <= 0) {
                    return 'Quantidade deve ser maior que zero';
                  }

                  // Verificar se não excede a capacidade
                  final capacidade = double.tryParse(
                    _capacidadeController.text,
                  );
                  if (capacidade != null && numero > capacidade) {
                    return 'Quantidade não pode exceder a capacidade';
                  }

                  return null;
                },
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _precoController,
                decoration: const InputDecoration(
                  labelText: 'Preço por Litro (Opcional)',
                  hintText: 'Ex: 5.50',
                  prefixIcon: Icon(Icons.attach_money),
                  suffixText: 'R\$/L',
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                ],
                validator: (value) {
                  if (value != null && value.trim().isNotEmpty) {
                    final numero = double.tryParse(value);
                    if (numero == null || numero <= 0) {
                      return 'Preço deve ser maior que zero';
                    }
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _observacoesController,
                decoration: const InputDecoration(
                  labelText: 'Observações (Opcional)',
                  hintText: 'Ex: Abastecimento inicial do tanque',
                  prefixIcon: Icon(Icons.notes),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 32),

              // Resumo
              if (_quantidadeEntradaController.text.isNotEmpty &&
                  _precoController.text.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.green.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '💰 Resumo Financeiro',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Quantidade:'),
                          Text('${_quantidadeEntradaController.text} L'),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Preço/Litro:'),
                          Text('R\$ ${_precoController.text}'),
                        ],
                      ),
                      const Divider(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Valor Total:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'R\$ ${_calcularValorTotal()}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 32),

              // Botões
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isLoading
                          ? null
                          : () => Navigator.of(context).pop(),
                      child: const Text('Cancelar'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _salvarEntrada,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : const Text('✅ Registrar Entrada'),
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

  String _getTipoDisplayName(String tipo) {
    switch (tipo) {
      case 'diesel':
        return '🛢️ Diesel';
      case 'gasolina_comum':
        return '⛽ Gasolina Comum';
      case 'gasolina_aditivada':
        return '⛽ Gasolina Aditivada';
      case 'etanol':
        return '🌾 Etanol';
      case 'gnv':
        return '💨 GNV';
      default:
        return tipo;
    }
  }

  String _calcularValorTotal() {
    final quantidade = double.tryParse(_quantidadeEntradaController.text) ?? 0;
    final preco = double.tryParse(_precoController.text) ?? 0;
    final total = quantidade * preco;
    return total.toStringAsFixed(2);
  }
}
