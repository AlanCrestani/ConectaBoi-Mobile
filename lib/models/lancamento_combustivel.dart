class LancamentoCombustivel {
  final String? id;
  final String confinamentoId;
  final DateTime data;
  final String tipoCombustivel;
  final double quantidadeLitros;
  final double precoUnitario;
  final double valorTotal;
  final String equipamento;
  final String operador;
  final String? observacoes;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? createdBy;
  final DateTime? mobileSyncedAt;
  final DateTime? mobileCreatedAt;
  final bool isSynced;

  LancamentoCombustivel({
    this.id,
    required this.confinamentoId,
    required this.data,
    required this.tipoCombustivel,
    required this.quantidadeLitros,
    required this.precoUnitario,
    required this.valorTotal,
    required this.equipamento,
    required this.operador,
    this.observacoes,
    this.createdAt,
    this.updatedAt,
    this.createdBy,
    this.mobileSyncedAt,
    this.mobileCreatedAt,
    this.isSynced = false,
  });

  factory LancamentoCombustivel.fromJson(Map<String, dynamic> json) {
    return LancamentoCombustivel(
      id: json['id'],
      confinamentoId: json['confinamento_id'],
      data: DateTime.parse(json['data']),
      tipoCombustivel: json['tipo_combustivel'],
      quantidadeLitros: (json['quantidade_litros'] as num).toDouble(),
      precoUnitario: (json['preco_unitario'] as num).toDouble(),
      valorTotal: (json['valor_total'] as num).toDouble(),
      equipamento: json['equipamento'],
      operador: json['operador'],
      observacoes: json['observacoes'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
      createdBy: json['created_by'],
      mobileSyncedAt: json['mobile_synced_at'] != null
          ? DateTime.parse(json['mobile_synced_at'])
          : null,
      mobileCreatedAt: json['mobile_created_at'] != null
          ? DateTime.parse(json['mobile_created_at'])
          : null,
      isSynced: json['mobile_synced_at'] != null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'confinamento_id': confinamentoId,
      'data': data.toIso8601String().split('T')[0],
      'tipo_combustivel': tipoCombustivel,
      'quantidade_litros': quantidadeLitros,
      'preco_unitario': precoUnitario,
      'valor_total': valorTotal,
      'equipamento': equipamento,
      'operador': operador,
      'observacoes': observacoes,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'created_by': createdBy,
      'mobile_synced_at': mobileSyncedAt?.toIso8601String(),
      'mobile_created_at': mobileCreatedAt?.toIso8601String(),
    };
  }

  Map<String, dynamic> toLocalDb() {
    return {
      'id': id,
      'confinamento_id': confinamentoId,
      'data': data.toIso8601String().split('T')[0],
      'tipo_combustivel': tipoCombustivel,
      'quantidade_litros': quantidadeLitros,
      'preco_unitario': precoUnitario,
      'valor_total': valorTotal,
      'equipamento': equipamento,
      'operador': operador,
      'observacoes': observacoes,
      'is_synced': isSynced ? 1 : 0,
      'mobile_created_at':
          mobileCreatedAt?.toIso8601String() ??
          DateTime.now().toIso8601String(),
    };
  }

  LancamentoCombustivel copyWith({
    String? id,
    String? confinamentoId,
    DateTime? data,
    String? tipoCombustivel,
    double? quantidadeLitros,
    double? precoUnitario,
    double? valorTotal,
    String? equipamento,
    String? operador,
    String? observacoes,
    bool? isSynced,
    DateTime? mobileSyncedAt,
  }) {
    return LancamentoCombustivel(
      id: id ?? this.id,
      confinamentoId: confinamentoId ?? this.confinamentoId,
      data: data ?? this.data,
      tipoCombustivel: tipoCombustivel ?? this.tipoCombustivel,
      quantidadeLitros: quantidadeLitros ?? this.quantidadeLitros,
      precoUnitario: precoUnitario ?? this.precoUnitario,
      valorTotal: valorTotal ?? this.valorTotal,
      equipamento: equipamento ?? this.equipamento,
      operador: operador ?? this.operador,
      observacoes: observacoes ?? this.observacoes,
      createdAt: createdAt,
      updatedAt: updatedAt,
      createdBy: createdBy,
      mobileSyncedAt: mobileSyncedAt ?? this.mobileSyncedAt,
      mobileCreatedAt: mobileCreatedAt,
      isSynced: isSynced ?? this.isSynced,
    );
  }
}
