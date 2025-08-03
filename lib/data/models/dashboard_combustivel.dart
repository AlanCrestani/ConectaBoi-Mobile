class DashboardCombustivel {
  final int totalTanques;
  final double totalCapacidade; // litros
  final double totalDisponivel; // litros
  final double totalConsumidoHoje; // litros
  final double totalAbastecidoHoje; // litros
  final double valorTotalEstoque; // R$
  final int tanquesBaixoNivel;
  final int tanquesCriticos;
  final int veiculosAtivos;
  final int equipamentosAtivos;
  final double consumoMedioDiario; // litros/dia
  final int diasAutonomiaMedia; // dias
  final DateTime ultimaAtualizacao;

  // Distribuição por tipo de combustível
  final Map<String, double> distribucaoPorTipo; // tipo -> litros

  // Consumo por período
  final Map<String, double> consumoPorDia; // data -> litros

  DashboardCombustivel({
    required this.totalTanques,
    required this.totalCapacidade,
    required this.totalDisponivel,
    required this.totalConsumidoHoje,
    required this.totalAbastecidoHoje,
    required this.valorTotalEstoque,
    required this.tanquesBaixoNivel,
    required this.tanquesCriticos,
    required this.veiculosAtivos,
    required this.equipamentosAtivos,
    required this.consumoMedioDiario,
    required this.diasAutonomiaMedia,
    required this.ultimaAtualizacao,
    required this.distribucaoPorTipo,
    required this.consumoPorDia,
  });

  factory DashboardCombustivel.fromJson(Map<String, dynamic> json) {
    return DashboardCombustivel(
      totalTanques: json['total_tanques'] as int? ?? 0,
      totalCapacidade: (json['total_capacidade'] as num?)?.toDouble() ?? 0.0,
      totalDisponivel: (json['total_disponivel'] as num?)?.toDouble() ?? 0.0,
      totalConsumidoHoje:
          (json['total_consumido_hoje'] as num?)?.toDouble() ?? 0.0,
      totalAbastecidoHoje:
          (json['total_abastecido_hoje'] as num?)?.toDouble() ?? 0.0,
      valorTotalEstoque:
          (json['valor_total_estoque'] as num?)?.toDouble() ?? 0.0,
      tanquesBaixoNivel: json['tanques_baixo_nivel'] as int? ?? 0,
      tanquesCriticos: json['tanques_criticos'] as int? ?? 0,
      veiculosAtivos: json['veiculos_ativos'] as int? ?? 0,
      equipamentosAtivos: json['equipamentos_ativos'] as int? ?? 0,
      consumoMedioDiario:
          (json['consumo_medio_diario'] as num?)?.toDouble() ?? 0.0,
      diasAutonomiaMedia: json['dias_autonomia_media'] as int? ?? 0,
      ultimaAtualizacao: json['ultima_atualizacao'] != null
          ? DateTime.parse(json['ultima_atualizacao'] as String)
          : DateTime.now(),
      distribucaoPorTipo: Map<String, double>.from(
        (json['distribuicao_por_tipo'] as Map<String, dynamic>?)?.map(
              (key, value) => MapEntry(key, (value as num).toDouble()),
            ) ??
            {},
      ),
      consumoPorDia: Map<String, double>.from(
        (json['consumo_por_dia'] as Map<String, dynamic>?)?.map(
              (key, value) => MapEntry(key, (value as num).toDouble()),
            ) ??
            {},
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total_tanques': totalTanques,
      'total_capacidade': totalCapacidade,
      'total_disponivel': totalDisponivel,
      'total_consumido_hoje': totalConsumidoHoje,
      'total_abastecido_hoje': totalAbastecidoHoje,
      'valor_total_estoque': valorTotalEstoque,
      'tanques_baixo_nivel': tanquesBaixoNivel,
      'tanques_criticos': tanquesCriticos,
      'veiculos_ativos': veiculosAtivos,
      'equipamentos_ativos': equipamentosAtivos,
      'consumo_medio_diario': consumoMedioDiario,
      'dias_autonomia_media': diasAutonomiaMedia,
      'ultima_atualizacao': ultimaAtualizacao.toIso8601String(),
      'distribuicao_por_tipo': distribucaoPorTipo,
      'consumo_por_dia': consumoPorDia,
    };
  }

  // Calculated properties
  double get percentualOcupacao =>
      totalCapacidade > 0 ? (totalDisponivel / totalCapacidade) * 100 : 0;

  double get saldoHoje => totalAbastecidoHoje - totalConsumidoHoje;

  String get statusGeral {
    if (tanquesCriticos > 0) return 'Crítico';
    if (tanquesBaixoNivel > 2) return 'Atenção';
    if (percentualOcupacao < 30) return 'Baixo';
    return 'Normal';
  }

  String get tendenciaConsumo {
    if (consumoPorDia.length < 2) return 'Insuficiente';

    final ultimosDias = consumoPorDia.values.toList()..sort();
    final media = ultimosDias.reduce((a, b) => a + b) / ultimosDias.length;
    final ultimoDia = ultimosDias.last;

    if (ultimoDia > media * 1.2) return 'Aumentando';
    if (ultimoDia < media * 0.8) return 'Diminuindo';
    return 'Estável';
  }

  // Alerts
  List<String> get alertasCriticos {
    List<String> alertas = [];

    if (tanquesCriticos > 0) {
      alertas.add('$tanquesCriticos tanque(s) em nível crítico');
    }

    if (diasAutonomiaMedia <= 3) {
      alertas.add('Autonomia baixa: $diasAutonomiaMedia dias');
    }

    if (consumoMedioDiario > 200) {
      alertas.add(
        'Consumo alto: ${consumoMedioDiario.toStringAsFixed(1)}L/dia',
      );
    }

    return alertas;
  }

  // Empty state constructor
  factory DashboardCombustivel.empty() {
    return DashboardCombustivel(
      totalTanques: 0,
      totalCapacidade: 0.0,
      totalDisponivel: 0.0,
      totalConsumidoHoje: 0.0,
      totalAbastecidoHoje: 0.0,
      valorTotalEstoque: 0.0,
      tanquesBaixoNivel: 0,
      tanquesCriticos: 0,
      veiculosAtivos: 0,
      equipamentosAtivos: 0,
      consumoMedioDiario: 0.0,
      diasAutonomiaMedia: 0,
      ultimaAtualizacao: DateTime.now(),
      distribucaoPorTipo: {},
      consumoPorDia: {},
    );
  }

  @override
  String toString() =>
      'DashboardCombustivel(tanques: $totalTanques, disponível: ${totalDisponivel}L, status: $statusGeral)';
}
