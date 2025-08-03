import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/services/auth_service.dart';
import '../../core/constants/app_routes.dart';
import '../../core/constants/app_colors.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _animationController.forward();

    // ✅ CORREÇÃO CRÍTICA: Verificar autenticação após inicialização
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    // Aguardar animação inicial
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    try {
      final authService = Provider.of<AuthService>(context, listen: false);

      // ✅ CRÍTICO: Aguardar inicialização do AuthService
      int attempts = 0;
      while (!authService.isInitialized && attempts < 10) {
        print(
          '🔄 [Splash] Aguardando inicialização do AuthService... (tentativa ${attempts + 1})',
        );
        await Future.delayed(const Duration(milliseconds: 500));
        attempts++;
      }

      if (!mounted) return;

      // Verificar se usuário está logado
      if (authService.isLoggedIn) {
        print('✅ [Splash] Usuário logado: ${authService.currentUser?.email}');
        print('🔄 [Splash] Redirecionando para Dashboard...');
        Navigator.of(context).pushReplacementNamed(AppRoutes.dashboard);
      } else {
        print('ℹ️ [Splash] Usuário não logado - redirecionando para Login');
        Navigator.of(context).pushReplacementNamed(AppRoutes.login);
      }
    } catch (e) {
      print('❌ [Splash] Erro ao verificar autenticação: $e');
      if (mounted) {
        Navigator.of(context).pushReplacementNamed(AppRoutes.login);
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo/Icon
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.local_gas_station,
                  size: 60,
                  color: AppColors.primary,
                ),
              ),

              const SizedBox(height: 24),

              // App Name
              Text(
                'ConectaBoi Combustível',
                style: Theme.of(context).textTheme.displayMedium?.copyWith(
                  color: AppColors.textOnPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 8),

              // Tagline
              Text(
                'Controle Inteligente de Combustível',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.textOnPrimary.withValues(alpha: 0.8),
                ),
              ),

              const SizedBox(height: 48),

              // Loading indicator
              const SizedBox(
                width: 40,
                height: 40,
                child: CircularProgressIndicator(
                  color: AppColors.surface,
                  strokeWidth: 3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
