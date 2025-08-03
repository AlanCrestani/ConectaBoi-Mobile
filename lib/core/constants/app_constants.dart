class AppConstants {
  // App Info
  static const String appName = 'ConectaBoi Combustível';
  static const String appVersion = '1.0.0';
  static const String appDescription =
      'Controle de Combustível para Confinamento';

  // Supabase Configuration
  static const String supabaseUrl = 'https://weqvnlbqnkjljiezjrqk.supabase.co';
  static const String supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6IndlcXZubGJxbmtqbGppZXpqcnFrIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MjE5MzE2MTIsImV4cCI6MjAzNzUwNzYxMn0.4eHO4qhp8NkFBQx6Z7tJJQJH3KK8TRCjq9JUREJOxjE'; // Temporary - should be in environment variables

  // API Configuration
  static const String baseApiUrl = 'https://your-backend-url.com/api';

  // User Roles
  static const String roleMaster = 'master';
  static const String roleGerencial = 'gerencial';
  static const String roleSupervisor = 'supervisor';
  static const String roleOperacional = 'operacional';

  // Notification Types
  static const String notificationEstoqueBaixo = 'estoque_baixo';
  static const String notificationLeituraCocho = 'leitura_cocho';
  static const String notificationDesvioAlto = 'desvio_alto';

  // Local Storage Keys
  static const String keyUserToken = 'user_token';
  static const String keyConfinamentoId = 'confinamento_id';
  static const String keyLastSync = 'last_sync';
  static const String keyNotificationsEnabled = 'notifications_enabled';
  static const String keyDarkMode = 'dark_mode';

  // Thresholds
  static const double desvioAltoThreshold = 10.0; // %
  static const int estoqueBaixoDias = 7; // dias
  static const int leiturasPendentesMax = 5;

  // Database Tables
  static const String tableConfinamentos = 'confinamentos';
  static const String tableFatoResumo = 'fato_resumo';
  static const String tableFatoCarregamento = 'fato_carregamento';
  static const String tableFatoTrato = 'fato_trato';
  static const String tableDimCurral = 'dim_curral';
  static const String tableAiFeedback = 'ai_feedback';
  static const String tableUserRoles = 'user_roles';
  static const String tablePushNotifications = 'push_notifications';

  // Date Formats
  static const String dateFormatBR = 'dd/MM/yyyy';
  static const String dateTimeFormatBR = 'dd/MM/yyyy HH:mm';
  static const String dateFormatAPI = 'yyyy-MM-dd';

  // Leitura de Cocho Scale (0-5)
  static const List<String> leiturasCochoLabels = [
    'Vazio (0)',
    'Muito Baixo (1)',
    'Baixo (2)',
    'Médio (3)',
    'Alto (4)',
    'Cheio (5)',
  ];

  // Chart Colors
  static const List<String> chartColors = [
    '#2563EB', // Primary Blue
    '#22C55E', // Success Green
    '#F59E0B', // Warning Orange
    '#EF4444', // Error Red
    '#8B5CF6', // Purple
    '#06B6D4', // Cyan
  ];
}
