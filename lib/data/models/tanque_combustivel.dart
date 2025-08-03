class TanqueCombustivel {
  final String id;
  final String confinamentoId;
  final String nome;
  final String tipoCombustivel; // diesel, gasolina, etanol, etc.
  final double capacidadeMaxima; // em litros
  final double nivelAtual; // em litros
  final double nivelMinimo; // em litros
  final double nivelCritico; // em litros
  final String? localizacao;
  final bool ativo;
  final DateTime? ultimaManutencao;
  final DateTime? proximaManutencao;
  final DateTime createdAt;
  final DateTime updatedAt;

  TanqueCombustivel({
    required this.id,
    required this.confinamentoId,
    required this.nome,
    required this.tipoCombustivel,
    required this.capacidadeMaxima,
    required this.nivelAtual,
    required this.nivelMinimo,
    required this.nivelCritico,
    this.localizacao,
    this.ativo = true,
    this.ultimaManutencao,
    this.proximaManutencao,
    required this.createdAt,
    required this.updatedAt,
  });

  factory TanqueCombustivel.fromJson(Map<String, dynamic> json) {
    return TanqueCombustivel(
      id: json['id'] as String,
      confinamentoId: json['confinamento_id'] as String,
      nome: json['nome'] as String,
      tipoCombustivel: json['tipo_combustivel'] as String,
      capacidadeMaxima: (json['capacidade_maxima'] as num).toDouble(),
      nivelAtual: (json['nivel_atual'] as num).toDouble(),
      nivelMinimo: (json['nivel_minimo'] as num).toDouble(),
      nivelCritico: (json['nivel_critico'] as num).toDouble(),
      localizacao: json['localizacao'] as String?,
      ativo: json['ativo'] as bool? ?? true,
      ultimaManutencao: json['ultima_manutencao'] != null
          ? DateTime.parse(json['ultima_manutencao'] as String)
          : null,
      proximaManutencao: json['proxima_manutencao'] != null
          ? DateTime.parse(json['proxima_manutencao'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'confinamento_id': confinamentoId,
      'nome': nome,
      'tipo_combustivel': tipoCombustivel,
      'capacidade_maxima': capacidadeMaxima,
      'nivel_atual': nivelAtual,
      'nivel_minimo': nivelMinimo,
      'nivel_critico': nivelCritico,
      'localizacao': localizacao,
      'ativo': ativo,
      'ultima_manutencao': ultimaManutencao?.toIso8601String(),
      'proxima_manutencao': proximaManutencao?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // Calculated properties
  double get percentualDisponivel =>
      capacidadeMaxima > 0 ? (nivelAtual / capacidadeMaxima) * 100 : 0;

  double get litrosDisponiveis => nivelAtual;
  double get litrosRestantes => capacidadeMaxima - nivelAtual;

  String get status {
    if (nivelAtual <= nivelCritico) return 'critico';
    if (nivelAtual <= nivelMinimo) return 'baixo';
    if (percentualDisponivel >= 80) return 'cheio';
    return 'normal';
  }

  bool get precisaAbastecimento => nivelAtual <= nivelMinimo;
  bool get nivelCriticoAtingido => nivelAtual <= nivelCritico;

  int get diasParaVazio {
    // Estimativa baseada no consumo médio (implementar com dados históricos)
    const consumoMedioDiario = 50.0; // litros/dia - placeholder
    return consumoMedioDiario > 0
        ? (nivelAtual / consumoMedioDiario).ceil()
        : 999;
  }

  @override
  String toString() =>
      'TanqueCombustivel(nome: $nome, tipo: $tipoCombustivel, nivel: ${nivelAtual}L/${capacidadeMaxima}L)';
}
