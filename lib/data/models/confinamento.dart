class Confinamento {
  final String id;
  final String nome;
  final String? razaoSocial;
  final String? cnpj;
  final String? endereco;
  final String? telefone;
  final String? email;
  final bool ativo;
  final String? masterUserId;
  final DateTime? dataAssinatura;

  Confinamento({
    required this.id,
    required this.nome,
    this.razaoSocial,
    this.cnpj,
    this.endereco,
    this.telefone,
    this.email,
    this.ativo = true,
    this.masterUserId,
    this.dataAssinatura,
  });

  factory Confinamento.fromJson(Map<String, dynamic> json) {
    return Confinamento(
      id: json['id'] as String,
      nome: json['nome'] as String,
      razaoSocial: json['razao_social'] as String?,
      cnpj: json['cnpj'] as String?,
      endereco: json['endereco'] as String?,
      telefone: json['telefone'] as String?,
      email: json['email'] as String?,
      ativo: json['ativo'] as bool? ?? true,
      masterUserId: json['master_user_id'] as String?,
      dataAssinatura: json['data_assinatura'] != null
          ? DateTime.parse(json['data_assinatura'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nome': nome,
      'razao_social': razaoSocial,
      'cnpj': cnpj,
      'endereco': endereco,
      'telefone': telefone,
      'email': email,
      'ativo': ativo,
      'master_user_id': masterUserId,
      'data_assinatura': dataAssinatura?.toIso8601String(),
    };
  }

  @override
  String toString() => 'Confinamento(id: $id, nome: $nome, ativo: $ativo)';
}
