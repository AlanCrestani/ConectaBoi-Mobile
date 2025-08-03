import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/services/auth_service.dart';
import 'core/services/supabase_service.dart';
import 'core/constants/supabase_config.dart';
import 'shared/themes/app_theme.dart';
import 'presentation/pages/splash_page.dart';
import 'presentation/pages/login_page.dart';
import 'presentation/pages/auth_callback_page.dart';
import 'presentation/pages/dashboard_combustivel_page.dart';
import 'presentation/pages/nova_entrada_combustivel_page.dart';
import 'providers/combustivel_provider.dart';
import 'providers/sync_provider.dart';
import 'pages/combustivel_list_page.dart';
import 'core/constants/app_routes.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // ✅ CORREÇÃO CRÍTICA: Inicialização completa
    debugPrint('🔍 Iniciando Supabase...');
    debugPrint('🔍 URL: ${SupabaseConfig.url}');

    await SupabaseService.initialize();
    debugPrint('✅ Supabase inicializado com sucesso');

    // ✅ CRÍTICO: Pré-inicializar AuthService
    debugPrint('🔍 Inicializando AuthService...');
    // AuthService será inicializado no Provider
    debugPrint('✅ Setup de inicialização preparado');
  } catch (e) {
    debugPrint('⚠️ Erro ao inicializar Supabase: $e');
    debugPrint('🔧 Continuando em modo de desenvolvimento...');
  }

  runApp(const ConectaBoiApp());
}

class ConectaBoiApp extends StatelessWidget {
  const ConectaBoiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // ✅ CORREÇÃO CRÍTICA: ChangeNotifierProvider com inicialização
        ChangeNotifierProvider<AuthService>(
          create: (context) {
            final authService = AuthService();
            // ✅ CRÍTICO: Inicializar após criação
            WidgetsBinding.instance.addPostFrameCallback((_) {
              authService.initialize();
            });
            return authService;
          },
        ),
        // 🚀 SYNC PROVIDER - PERFORMANCE OTIMIZADA
        ChangeNotifierProvider<SyncProvider>(
          create: (context) => SyncProvider(),
        ),
        // Provider para controle de combustível
        ChangeNotifierProvider<CombustivelProvider>(
          create: (context) => CombustivelProvider(),
        ),
      ],
      child: MaterialApp(
        title: 'ConectaBoi Combustível',
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        initialRoute: AppRoutes.splash,
        routes: {
          AppRoutes.splash: (context) => const SplashPage(),
          AppRoutes.login: (context) => const LoginPage(),
          AppRoutes.authCallback: (context) => const AuthCallbackPage(),
          AppRoutes.dashboard: (context) => const DashboardCombustivelPage(),
          AppRoutes.novaEntrada: (context) =>
              const NovaEntradaCombustivelPage(),
          '/combustivel': (context) => const CombustivelListPage(),
        },
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
