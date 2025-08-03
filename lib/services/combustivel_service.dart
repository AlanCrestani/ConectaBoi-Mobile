import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/lancamento_combustivel.dart';

class CombustivelService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Buscar todos os lançamentos
  Future<List<LancamentoCombustivel>> buscarLancamentos() async {
    try {
      final response = await _supabase
          .from('lancamentos_combustivel')
          .select()
          .order('data', ascending: false);

      return (response as List)
          .map((item) => LancamentoCombustivel.fromJson(item))
          .toList();
    } catch (e) {
      throw Exception('Erro ao buscar lançamentos: $e');
    }
  }

  // Buscar lançamentos por período
  Future<List<LancamentoCombustivel>> buscarLancamentosPorPeriodo(
    DateTime dataInicio,
    DateTime dataFim,
  ) async {
    try {
      final response = await _supabase
          .from('lancamentos_combustivel')
          .select()
          .gte('data', dataInicio.toIso8601String().split('T')[0])
          .lte('data', dataFim.toIso8601String().split('T')[0])
          .order('data', ascending: false);

      return (response as List)
          .map((item) => LancamentoCombustivel.fromJson(item))
          .toList();
    } catch (e) {
      throw Exception('Erro ao buscar lançamentos por período: $e');
    }
  }

  // Buscar lançamentos por confinamento
  Future<List<LancamentoCombustivel>> buscarLancamentosPorConfinamento(
    String confinamentoId,
  ) async {
    try {
      final response = await _supabase
          .from('lancamentos_combustivel')
          .select()
          .eq('confinamento_id', confinamentoId)
          .order('data', ascending: false);

      return (response as List)
          .map((item) => LancamentoCombustivel.fromJson(item))
          .toList();
    } catch (e) {
      throw Exception('Erro ao buscar lançamentos por confinamento: $e');
    }
  }

  // Criar novo lançamento
  Future<LancamentoCombustivel> criarLancamento(
    LancamentoCombustivel lancamento,
  ) async {
    try {
      final response = await _supabase
          .from('lancamentos_combustivel')
          .insert(lancamento.toJson())
          .select()
          .single();

      return LancamentoCombustivel.fromJson(response);
    } catch (e) {
      throw Exception('Erro ao criar lançamento: $e');
    }
  }

  // Atualizar lançamento
  Future<LancamentoCombustivel> atualizarLancamento(
    LancamentoCombustivel lancamento,
  ) async {
    try {
      final response = await _supabase
          .from('lancamentos_combustivel')
          .update(lancamento.toJson())
          .eq('id', lancamento.id!)
          .select()
          .single();

      return LancamentoCombustivel.fromJson(response);
    } catch (e) {
      throw Exception('Erro ao atualizar lançamento: $e');
    }
  }

  // Deletar lançamento
  Future<void> deletarLancamento(String id) async {
    try {
      await _supabase.from('lancamentos_combustivel').delete().eq('id', id);
    } catch (e) {
      throw Exception('Erro ao deletar lançamento: $e');
    }
  }

  // Calcular estatísticas de consumo
  Future<Map<String, dynamic>> calcularEstatisticas(
    String? confinamentoId,
    DateTime? dataInicio,
    DateTime? dataFim,
  ) async {
    try {
      var query = _supabase.from('lancamentos_combustivel').select();

      if (confinamentoId != null) {
        query = query.eq('confinamento_id', confinamentoId);
      }

      if (dataInicio != null) {
        query = query.gte('data', dataInicio.toIso8601String().split('T')[0]);
      }

      if (dataFim != null) {
        query = query.lte('data', dataFim.toIso8601String().split('T')[0]);
      }

      final response = await query;
      final lancamentos = (response as List)
          .map((item) => LancamentoCombustivel.fromJson(item))
          .toList();

      if (lancamentos.isEmpty) {
        return {
          'total_litros': 0.0,
          'total_valor': 0.0,
          'media_preco_litro': 0.0,
          'quantidade_abastecimentos': 0,
        };
      }

      double totalLitros = lancamentos.fold(
        0.0,
        (sum, l) => sum + l.quantidadeLitros,
      );
      double totalValor = lancamentos.fold(0.0, (sum, l) => sum + l.valorTotal);

      double mediaPrecoLitro = totalValor / totalLitros;

      return {
        'total_litros': totalLitros,
        'total_valor': totalValor,
        'media_preco_litro': mediaPrecoLitro,
        'quantidade_abastecimentos': lancamentos.length,
      };
    } catch (e) {
      throw Exception('Erro ao calcular estatísticas: $e');
    }
  }

  // Buscar último lançamento por confinamento
  Future<LancamentoCombustivel?> buscarUltimoLancamento(
    String confinamentoId,
  ) async {
    try {
      final response = await _supabase
          .from('lancamentos_combustivel')
          .select()
          .eq('confinamento_id', confinamentoId)
          .order('data', ascending: false)
          .limit(1);

      if (response.isEmpty) return null;

      return LancamentoCombustivel.fromJson(response.first);
    } catch (e) {
      throw Exception('Erro ao buscar último lançamento: $e');
    }
  }

  // Validar lançamento antes de salvar
  Future<Map<String, String>?> validarLancamento(
    LancamentoCombustivel lancamento,
  ) async {
    final erros = <String, String>{};

    // Validar litros
    if (lancamento.quantidadeLitros <= 0) {
      erros['quantidade_litros'] =
          'Quantidade de litros deve ser maior que zero';
    }

    // Validar valor total
    if (lancamento.valorTotal <= 0) {
      erros['valor_total'] = 'Valor total deve ser maior que zero';
    }

    // Validar preço por litro
    if (lancamento.precoUnitario <= 0) {
      erros['preco_unitario'] = 'Preço por litro deve ser maior que zero';
    }

    // Verificar consistência entre preço unitário, quantidade e valor total
    final valorCalculado =
        lancamento.quantidadeLitros * lancamento.precoUnitario;
    if ((valorCalculado - lancamento.valorTotal).abs() > 0.01) {
      erros['valor_total'] =
          'Valor total não confere com quantidade × preço unitário';
    }

    // Validar data
    if (lancamento.data.isAfter(DateTime.now())) {
      erros['data'] = 'Data não pode ser futura';
    }

    // Validar campos obrigatórios
    if (lancamento.tipoCombustivel.isEmpty) {
      erros['tipo_combustivel'] = 'Tipo de combustível é obrigatório';
    }

    if (lancamento.equipamento.isEmpty) {
      erros['equipamento'] = 'Equipamento é obrigatório';
    }

    if (lancamento.operador.isEmpty) {
      erros['operador'] = 'Operador é obrigatório';
    }

    return erros.isEmpty ? null : erros;
  }
}
