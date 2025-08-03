import 'package:flutter/material.dart';
import '../models/lancamento_combustivel.dart';
import '../services/combustivel_service.dart';

class CombustivelProvider extends ChangeNotifier {
  final CombustivelService _service = CombustivelService();

  List<LancamentoCombustivel> _lancamentos = [];
  bool _isLoading = false;
  String? _error;
  Map<String, dynamic>? _estatisticas;

  List<LancamentoCombustivel> get lancamentos => _lancamentos;
  bool get isLoading => _isLoading;
  String? get error => _error;
  Map<String, dynamic>? get estatisticas => _estatisticas;

  // Buscar todos os lançamentos
  Future<void> carregarLancamentos() async {
    _setLoading(true);
    try {
      _lancamentos = await _service.buscarLancamentos();
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  // Buscar lançamentos por período
  Future<void> carregarLancamentosPorPeriodo(
    DateTime inicio,
    DateTime fim,
  ) async {
    _setLoading(true);
    try {
      _lancamentos = await _service.buscarLancamentosPorPeriodo(inicio, fim);
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  // Buscar lançamentos por confinamento
  Future<void> carregarLancamentosPorConfinamento(String confinamentoId) async {
    _setLoading(true);
    try {
      _lancamentos = await _service.buscarLancamentosPorConfinamento(
        confinamentoId,
      );
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  // Criar novo lançamento
  Future<bool> criarLancamento(LancamentoCombustivel lancamento) async {
    _setLoading(true);
    try {
      // Validar lançamento
      final erros = await _service.validarLancamento(lancamento);
      if (erros != null) {
        _error = erros.values.join('\n');
        return false;
      }

      final novoLancamento = await _service.criarLancamento(lancamento);
      _lancamentos.insert(0, novoLancamento);
      _error = null;
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Atualizar lançamento
  Future<bool> atualizarLancamento(LancamentoCombustivel lancamento) async {
    _setLoading(true);
    try {
      // Validar lançamento
      final erros = await _service.validarLancamento(lancamento);
      if (erros != null) {
        _error = erros.values.join('\n');
        return false;
      }

      final lancamentoAtualizado = await _service.atualizarLancamento(
        lancamento,
      );
      final index = _lancamentos.indexWhere((l) => l.id == lancamento.id);
      if (index != -1) {
        _lancamentos[index] = lancamentoAtualizado;
      }
      _error = null;
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Deletar lançamento
  Future<bool> deletarLancamento(String id) async {
    _setLoading(true);
    try {
      await _service.deletarLancamento(id);
      _lancamentos.removeWhere((l) => l.id == id);
      _error = null;
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Calcular estatísticas
  Future<void> calcularEstatisticas({
    String? confinamentoId,
    DateTime? dataInicio,
    DateTime? dataFim,
  }) async {
    try {
      _estatisticas = await _service.calcularEstatisticas(
        confinamentoId,
        dataInicio,
        dataFim,
      );
      notifyListeners();
    } catch (e) {
      _error = e.toString();
    }
  }

  // Buscar último lançamento
  Future<LancamentoCombustivel?> buscarUltimoLancamento(
    String confinamentoId,
  ) async {
    try {
      return await _service.buscarUltimoLancamento(confinamentoId);
    } catch (e) {
      _error = e.toString();
      return null;
    }
  }

  // Filtrar lançamentos por tipo de combustível
  List<LancamentoCombustivel> filtrarPorTipoCombustivel(String tipo) {
    return _lancamentos.where((l) => l.tipoCombustivel == tipo).toList();
  }

  // Filtrar lançamentos por equipamento
  List<LancamentoCombustivel> filtrarPorEquipamento(String equipamento) {
    return _lancamentos.where((l) => l.equipamento == equipamento).toList();
  }

  // Filtrar lançamentos por operador
  List<LancamentoCombustivel> filtrarPorOperador(String operador) {
    return _lancamentos.where((l) => l.operador == operador).toList();
  }

  // Obter tipos de combustível únicos
  List<String> get tiposCombustivel {
    final tipos = _lancamentos.map((l) => l.tipoCombustivel).toSet().toList();
    tipos.sort();
    return tipos;
  }

  // Obter equipamentos únicos
  List<String> get equipamentos {
    final equipamentos = _lancamentos
        .map((l) => l.equipamento)
        .toSet()
        .toList();
    equipamentos.sort();
    return equipamentos;
  }

  // Obter operadores únicos
  List<String> get operadores {
    final operadores = _lancamentos.map((l) => l.operador).toSet().toList();
    operadores.sort();
    return operadores;
  }

  // Limpar dados
  void limparDados() {
    _lancamentos.clear();
    _estatisticas = null;
    _error = null;
    notifyListeners();
  }

  // Limpar erro
  void limparErro() {
    _error = null;
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
