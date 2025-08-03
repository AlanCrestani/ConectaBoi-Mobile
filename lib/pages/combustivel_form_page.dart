import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/combustivel_provider.dart';
import '../models/lancamento_combustivel.dart';

class CombustivelFormPage extends StatefulWidget {
  final LancamentoCombustivel? lancamento;

  const CombustivelFormPage({super.key, this.lancamento});

  @override
  State<CombustivelFormPage> createState() => _CombustivelFormPageState();
}

class _CombustivelFormPageState extends State<CombustivelFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _confinamentoIdController = TextEditingController();
  final _quantidadeLitrosController = TextEditingController();
  final _precoUnitarioController = TextEditingController();
  final _valorTotalController = TextEditingController();
  final _equipamentoController = TextEditingController();
  final _operadorController = TextEditingController();
  final _observacoesController = TextEditingController();

  DateTime _data = DateTime.now();
  String _tipoCombustivel = 'Diesel';

  bool _isEditing = false;
  bool _calcularValorTotal = true;

  @override
  void initState() {
    super.initState();
    _isEditing = widget.lancamento != null;

    if (_isEditing) {
      _preencherFormulario(widget.lancamento!);
    } else {
      _data = DateTime.now();
    }
  }

  void _preencherFormulario(LancamentoCombustivel lancamento) {
    _confinamentoIdController.text = lancamento.confinamentoId;
    _data = lancamento.data;
    _tipoCombustivel = lancamento.tipoCombustivel;
    _quantidadeLitrosController.text = lancamento.quantidadeLitros.toString();
    _precoUnitarioController.text = lancamento.precoUnitario.toString();
    _valorTotalController.text = lancamento.valorTotal.toString();
    _equipamentoController.text = lancamento.equipamento;
    _operadorController.text = lancamento.operador;
    _observacoesController.text = lancamento.observacoes ?? '';
  }

  @override
  void dispose() {
    _confinamentoIdController.dispose();
    _quantidadeLitrosController.dispose();
    _precoUnitarioController.dispose();
    _valorTotalController.dispose();
    _equipamentoController.dispose();
    _operadorController.dispose();
    _observacoesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Editar Lançamento' : 'Novo Lançamento'),
        backgroundColor: Colors.green.shade600,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _salvarLancamento,
          ),
        ],
      ),
      body: Consumer<CombustivelProvider>(
        builder: (context, provider, child) {
          return Stack(
            children: [
              Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Confinamento ID
                    TextFormField(
                      controller: _confinamentoIdController,
                      decoration: const InputDecoration(
                        labelText: 'ID do Confinamento *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.badge),
                      ),
                      validator: (value) {
                        if (value?.isEmpty ?? true) {
                          return 'ID do confinamento é obrigatório';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Data
                    TextFormField(
                      decoration: const InputDecoration(
                        labelText: 'Data *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.calendar_today),
                      ),
                      readOnly: true,
                      controller: TextEditingController(
                        text: DateFormat('dd/MM/yyyy').format(_data),
                      ),
                      onTap: _selecionarData,
                      validator: (value) {
                        if (value?.isEmpty ?? true) {
                          return 'Data é obrigatória';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Tipo de Combustível
                    DropdownButtonFormField<String>(
                      value: _tipoCombustivel,
                      decoration: const InputDecoration(
                        labelText: 'Tipo de Combustível *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.local_gas_station),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'Diesel',
                          child: Text('Diesel'),
                        ),
                        DropdownMenuItem(
                          value: 'Gasolina',
                          child: Text('Gasolina'),
                        ),
                        DropdownMenuItem(
                          value: 'Etanol',
                          child: Text('Etanol'),
                        ),
                        DropdownMenuItem(value: 'GNV', child: Text('GNV')),
                        DropdownMenuItem(value: 'Outro', child: Text('Outro')),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _tipoCombustivel = value!;
                        });
                      },
                      validator: (value) {
                        if (value?.isEmpty ?? true) {
                          return 'Tipo de combustível é obrigatório';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Quantidade em Litros
                    TextFormField(
                      controller: _quantidadeLitrosController,
                      decoration: const InputDecoration(
                        labelText: 'Quantidade (Litros) *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.opacity),
                        suffixText: 'L',
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                          RegExp(r'^\d+\.?\d{0,2}'),
                        ),
                      ],
                      onChanged: _calcularValorTotalSeNecessario,
                      validator: (value) {
                        if (value?.isEmpty ?? true) {
                          return 'Quantidade é obrigatória';
                        }
                        final quantidade = double.tryParse(value!);
                        if (quantidade == null || quantidade <= 0) {
                          return 'Quantidade deve ser maior que zero';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Preço Unitário
                    TextFormField(
                      controller: _precoUnitarioController,
                      decoration: const InputDecoration(
                        labelText: 'Preço por Litro *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.attach_money),
                        prefixText: 'R\$ ',
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                          RegExp(r'^\d+\.?\d{0,2}'),
                        ),
                      ],
                      onChanged: _calcularValorTotalSeNecessario,
                      validator: (value) {
                        if (value?.isEmpty ?? true) {
                          return 'Preço por litro é obrigatório';
                        }
                        final preco = double.tryParse(value!);
                        if (preco == null || preco <= 0) {
                          return 'Preço deve ser maior que zero';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Valor Total com switch para cálculo automático
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _valorTotalController,
                                decoration: const InputDecoration(
                                  labelText: 'Valor Total *',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.money),
                                  prefixText: 'R\$ ',
                                ),
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(
                                    RegExp(r'^\d+\.?\d{0,2}'),
                                  ),
                                ],
                                enabled: !_calcularValorTotal,
                                validator: (value) {
                                  if (value?.isEmpty ?? true) {
                                    return 'Valor total é obrigatório';
                                  }
                                  final valor = double.tryParse(value!);
                                  if (valor == null || valor <= 0) {
                                    return 'Valor deve ser maior que zero';
                                  }
                                  return null;
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Switch(
                              value: _calcularValorTotal,
                              onChanged: (value) {
                                setState(() {
                                  _calcularValorTotal = value;
                                  if (value) {
                                    _calcularValorTotalSeNecessario('');
                                  }
                                });
                              },
                            ),
                            const SizedBox(width: 8),
                            const Text('Calcular automaticamente'),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Equipamento
                    TextFormField(
                      controller: _equipamentoController,
                      decoration: const InputDecoration(
                        labelText: 'Equipamento *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.build),
                      ),
                      validator: (value) {
                        if (value?.isEmpty ?? true) {
                          return 'Equipamento é obrigatório';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Operador
                    TextFormField(
                      controller: _operadorController,
                      decoration: const InputDecoration(
                        labelText: 'Operador *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person),
                      ),
                      validator: (value) {
                        if (value?.isEmpty ?? true) {
                          return 'Operador é obrigatório';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Observações
                    TextFormField(
                      controller: _observacoesController,
                      decoration: const InputDecoration(
                        labelText: 'Observações',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.note),
                      ),
                      maxLines: 3,
                      maxLength: 500,
                    ),
                    const SizedBox(height: 24),

                    // Botões
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Cancelar'),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _salvarLancamento,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green.shade600,
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('Salvar'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (provider.isLoading)
                Container(
                  color: Colors.black.withValues(alpha: 0.3),
                  child: const Center(child: CircularProgressIndicator()),
                ),
            ],
          );
        },
      ),
    );
  }

  void _selecionarData() async {
    final data = await showDatePicker(
      context: context,
      initialDate: _data,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (data != null) {
      setState(() {
        _data = data;
      });
    }
  }

  void _calcularValorTotalSeNecessario(String value) {
    if (_calcularValorTotal) {
      final quantidade = double.tryParse(_quantidadeLitrosController.text);
      final preco = double.tryParse(_precoUnitarioController.text);

      if (quantidade != null && preco != null) {
        final valorTotal = quantidade * preco;
        _valorTotalController.text = valorTotal.toStringAsFixed(2);
      }
    }
  }

  void _salvarLancamento() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final provider = context.read<CombustivelProvider>();

    final lancamento = LancamentoCombustivel(
      id: _isEditing ? widget.lancamento!.id : null,
      confinamentoId: _confinamentoIdController.text,
      data: _data,
      tipoCombustivel: _tipoCombustivel,
      quantidadeLitros: double.parse(_quantidadeLitrosController.text),
      precoUnitario: double.parse(_precoUnitarioController.text),
      valorTotal: double.parse(_valorTotalController.text),
      equipamento: _equipamentoController.text,
      operador: _operadorController.text,
      observacoes: _observacoesController.text.isEmpty
          ? null
          : _observacoesController.text,
      mobileCreatedAt: DateTime.now(),
    );

    bool sucesso;
    if (_isEditing) {
      sucesso = await provider.atualizarLancamento(lancamento);
    } else {
      sucesso = await provider.criarLancamento(lancamento);
    }

    if (sucesso && mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isEditing
                ? 'Lançamento atualizado com sucesso!'
                : 'Lançamento criado com sucesso!',
          ),
          backgroundColor: Colors.green,
        ),
      );
    } else if (mounted && provider.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(provider.error!), backgroundColor: Colors.red),
      );
    }
  }
}
