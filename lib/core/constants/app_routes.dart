class AppRoutes {
  // Auth Routes
  static const String login = '/login';
  static const String splash = '/splash';
  static const String authCallback =
      '/auth/callback'; // ✅ Nova rota para OAuth callback

  // Main Navigation Routes - Combustível
  static const String dashboard = '/dashboard';
  static const String tanques = '/tanques';
  static const String abastecimento = '/abastecimento';
  static const String movimentacoes = '/movimentacoes';
  static const String veiculos = '/veiculos';
  static const String equipamentos = '/equipamentos';
  static const String relatorios = '/relatorios';

  // Sub Routes - Combustível
  static const String tanqueDetalhes = '/tanques/detalhes';
  static const String novoAbastecimento = '/abastecimento/novo';
  static const String novaEntrada = '/entrada/nova';
  static const String movimentacaoDetalhes = '/movimentacoes/detalhes';
  static const String veiculoDetalhes = '/veiculos/detalhes';
  static const String equipamentoDetalhes = '/equipamentos/detalhes';

  // Sistema Routes
  static const String profile = '/profile';
  static const String settings = '/settings';
  static const String notifications = '/notifications';

  // Admin Routes (Master role only)
  static const String gestaoUsuarios = '/gestao-usuarios';
  static const String configuracoes = '/configuracoes';

  // Utility Routes
  static const String offline = '/offline';
  static const String error = '/error';
}

// Navigation Labels for Bottom Navigation and Drawer
class NavigationLabels {
  static const String dashboard = 'Dashboard';
  static const String tanques = 'Tanques';
  static const String abastecimento = 'Abastecimento';
  static const String movimentacoes = 'Movimentações';
  static const String veiculos = 'Veículos';
  static const String equipamentos = 'Equipamentos';
  static const String relatorios = 'Relatórios';
  static const String profile = 'Perfil';
  static const String settings = 'Configurações';
  static const String logout = 'Sair';
}
