import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/services/auth_service.dart';
import '../../core/constants/app_routes.dart';

class AuthCallbackPage extends StatefulWidget {
  const AuthCallbackPage({super.key});

  @override
  State<AuthCallbackPage> createState() => _AuthCallbackPageState();
}

class _AuthCallbackPageState extends State<AuthCallbackPage> {
  String _status = 'Iniciando processamento...';
  String _error = '';

  @override
  void initState() {
    super.initState();
    _handleAuthCallback();
  }

  void _updateStatus(String status) {
    if (mounted) {
      setState(() {
        _status = status;
      });
    }
  }

  void _updateError(String error) {
    if (mounted) {
      setState(() {
        _error = error;
      });
    }
  }

  Future<void> _handleAuthCallback() async {
    try {
      print('🔄 [AuthCallback] Processando callback OAuth...');
      print(
        '🔄 [AuthCallback] URL atual: ${ModalRoute.of(context)?.settings.name}',
      );

      final authService = Provider.of<AuthService>(context, listen: false);

      // ✅ CORREÇÃO CRÍTICA: Verificação inicial mais robusta
      print(
        '🔍 [AuthCallback] Estado inicial - isLoggedIn: ${authService.isLoggedIn}',
      );
      print(
        '🔍 [AuthCallback] Estado inicial - currentUser: ${authService.currentUser?.email}',
      );

      // Se já está logado, redirecionar imediatamente
      if (authService.isLoggedIn && mounted) {
        print(
          '✅ [AuthCallback] Usuário já autenticado: ${authService.currentUser?.email}',
        );
        _updateStatus('Usuário já autenticado! Redirecionando...');
        await Future.delayed(const Duration(seconds: 1));
        Navigator.of(context).pushReplacementNamed(AppRoutes.dashboard);
        return;
      }

      // ✅ CRÍTICO: Usar o método handleAuthCallback do AuthService
      _updateStatus('Processando autenticação...');
      final result = await authService.handleAuthCallback();

      if (result['success'] == true && mounted) {
        final user = result['user'];
        print(
          '✅ [AuthCallback] Callback processado com sucesso: ${user?.email}',
        );
        _updateStatus('Login realizado com sucesso! Redirecionando...');

        // Aguardar um momento antes de redirecionar
        await Future.delayed(const Duration(seconds: 2));
        Navigator.of(context).pushReplacementNamed(AppRoutes.dashboard);
        return;
      }

      // ✅ FALLBACK: Se o método direto falhou, tentar com retry
      _updateStatus('Aguardando processamento...');

      for (int i = 1; i <= 10; i++) {
        print(
          '🔄 [AuthCallback] Tentativa $i/10 - Aguardando processamento...',
        );
        _updateStatus('Verificando autenticação... (tentativa $i/10)');
        await Future.delayed(const Duration(seconds: 1));

        print(
          '🔍 [AuthCallback] Tentativa $i - isLoggedIn: ${authService.isLoggedIn}',
        );
        print(
          '🔍 [AuthCallback] Tentativa $i - currentUser: ${authService.currentUser?.email}',
        );

        if (authService.isLoggedIn && mounted) {
          print(
            '✅ [AuthCallback] Usuário autenticado na tentativa $i: ${authService.currentUser?.email}',
          );
          _updateStatus('Login realizado com sucesso! Redirecionando...');
          await Future.delayed(const Duration(seconds: 1));
          Navigator.of(context).pushReplacementNamed(AppRoutes.dashboard);
          return;
        }
      }

      // Se chegou aqui, o login falhou
      print(
        '❌ [AuthCallback] Falha definitiva na autenticação após 10 tentativas',
      );
      print(
        '❌ [AuthCallback] Estado final - isLoggedIn: ${authService.isLoggedIn}',
      );
      print(
        '❌ [AuthCallback] Estado final - currentUser: ${authService.currentUser}',
      );

      _updateStatus('Erro na autenticação');
      _updateError('Falha na autenticação após múltiplas tentativas');

      if (mounted) {
        await Future.delayed(const Duration(seconds: 3));
        Navigator.of(context).pushReplacementNamed(AppRoutes.login);
      }
    } catch (e, stackTrace) {
      print('❌ [AuthCallback] Erro no callback: $e');
      print('❌ [AuthCallback] Stack trace: $stackTrace');

      _updateStatus('Erro crítico na autenticação');
      _updateError(e.toString());

      if (mounted) {
        await Future.delayed(const Duration(seconds: 3));
        Navigator.of(context).pushReplacementNamed(AppRoutes.login);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // ✅ VISUAL MELHORADO
              if (_error.isEmpty) ...[
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: const CircularProgressIndicator(strokeWidth: 3),
                ),
                const SizedBox(height: 32),
                const Text(
                  'Processando Autenticação',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  _status,
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
              ] else ...[
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Icon(
                    Icons.error_outline,
                    size: 30,
                    color: Colors.red.shade400,
                  ),
                ),
                const SizedBox(height: 32),
                const Text(
                  'Erro na Autenticação',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Colors.red,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  _status,
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _error,
                    style: TextStyle(fontSize: 12, color: Colors.red.shade700),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Redirecionando para login...',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
