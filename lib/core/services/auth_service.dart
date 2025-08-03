import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import 'supabase_service.dart';

class AuthService extends ChangeNotifier {
  final SupabaseClient _supabase = SupabaseService.client;

  // Estado interno controlado
  bool _isLoggedIn = false;
  User? _currentUser;
  bool _isInitialized = false;

  // Getters públicos
  bool get isLoggedIn => _isLoggedIn;
  User? get currentUser => _currentUser;
  bool get isInitialized => _isInitialized;

  // Auth state stream
  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;

  // ✅ CORREÇÃO CRÍTICA 1: Inicialização completa
  Future<void> initialize() async {
    try {
      print('🚀 [AuthService] Inicializando serviço de autenticação...');

      // Verificar sessão existente
      final session = _supabase.auth.currentSession;

      if (session != null) {
        _isLoggedIn = true;
        _currentUser = session.user;
        print(
          '✅ [AuthService] Sessão existente encontrada: ${session.user.email}',
        );
      } else {
        _isLoggedIn = false;
        _currentUser = null;
        print('ℹ️ [AuthService] Nenhuma sessão existente encontrada');
      }

      // ✅ CRÍTICO: Listener para mudanças de estado
      _supabase.auth.onAuthStateChange.listen((data) {
        final event = data.event;
        final session = data.session;

        print(
          '🔄 [AuthService] Estado mudou: $event, usuário: ${session?.user.email}',
        );

        if (event == AuthChangeEvent.signedIn && session != null) {
          _isLoggedIn = true;
          _currentUser = session.user;
          print('✅ [AuthService] Usuário logado: ${session.user.email}');
          notifyListeners();
        } else if (event == AuthChangeEvent.signedOut) {
          _isLoggedIn = false;
          _currentUser = null;
          print('👋 [AuthService] Usuário deslogado');
          notifyListeners();
        } else if (event == AuthChangeEvent.tokenRefreshed && session != null) {
          _isLoggedIn = true;
          _currentUser = session.user;
          print('🔄 [AuthService] Token atualizado: ${session.user.email}');
          notifyListeners();
        }
      });

      _isInitialized = true;
      print('✅ [AuthService] Inicialização completa');
    } catch (error) {
      print('❌ [AuthService] Erro na inicialização: $error');
      _isInitialized = true; // Continuar mesmo com erro
    }
  }

  // Sign in with email and password
  Future<AuthResponse> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      return response;
    } catch (e) {
      rethrow;
    }
  }

  // Sign up with email and password
  Future<AuthResponse> signUpWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
      );
      return response;
    } catch (e) {
      rethrow;
    }
  }

  // ✅ CORREÇÃO CRÍTICA 2: Sign in with Google
  Future<Map<String, dynamic>> signInWithGoogle() async {
    try {
      print('🚀 [AuthService] Iniciando login Google...');

      // Definir redirectTo baseado na plataforma
      String redirectTo;
      if (kIsWeb) {
        // Para web, usar localhost:3000 callback (porta fixa)
        redirectTo = 'http://localhost:3000/auth/callback';
        print('🌐 [AuthService] Usando callback WEB: $redirectTo');
      } else {
        // Para mobile, usar o scheme customizado
        redirectTo = 'io.supabase.flutter://login-callback/';
        print('📱 [AuthService] Usando callback MOBILE: $redirectTo');
      }

      // ✅ CRÍTICO: OAuth com configurações corretas
      final result = await _supabase.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: redirectTo,
        queryParams: {
          'access_type': 'offline', // ✅ OFFLINE ACCESS
          'prompt': 'consent', // ✅ FORÇAR CONSENTIMENTO
        },
      );

      if (result == true) {
        print('✅ [AuthService] Redirecionamento OAuth iniciado com sucesso');
        return {'success': true};
      } else {
        print('❌ [AuthService] Falha no redirecionamento OAuth');
        return {'success': false, 'error': 'Falha no redirecionamento OAuth'};
      }
    } catch (error) {
      print('❌ [AuthService] Erro no login Google: $error');
      return {'success': false, 'error': error.toString()};
    }
  }

  // ✅ CORREÇÃO CRÍTICA 3: Processar callback OAuth
  Future<Map<String, dynamic>> handleAuthCallback() async {
    try {
      print('🔄 [AuthService] Processando callback OAuth...');

      // ✅ CRÍTICO: Supabase detecta automaticamente o callback
      final session = _supabase.auth.currentSession;

      if (session != null) {
        print(
          '✅ [AuthService] Callback processado com sucesso: ${session.user.email}',
        );
        _isLoggedIn = true;
        _currentUser = session.user;
        notifyListeners();
        return {'success': true, 'user': session.user};
      } else {
        // Aguardar um pouco mais para o processamento
        await Future.delayed(const Duration(seconds: 2));

        final newSession = _supabase.auth.currentSession;
        if (newSession != null) {
          print(
            '✅ [AuthService] Callback processado após delay: ${newSession.user.email}',
          );
          _isLoggedIn = true;
          _currentUser = newSession.user;
          notifyListeners();
          return {'success': true, 'user': newSession.user};
        } else {
          throw Exception('Nenhuma sessão encontrada após callback');
        }
      }
    } catch (error) {
      print('❌ [AuthService] Erro no handleAuthCallback: $error');
      return {'success': false, 'error': error.toString()};
    }
  }

  // ✅ CORREÇÃO CRÍTICA 4: Sign out
  Future<Map<String, dynamic>> signOut() async {
    try {
      print('🚀 [AuthService] Fazendo logout...');
      await _supabase.auth.signOut();

      _isLoggedIn = false;
      _currentUser = null;
      notifyListeners();

      print('✅ [AuthService] Logout realizado com sucesso');
      return {'success': true};
    } catch (error) {
      print('❌ [AuthService] Erro no logout: $error');
      return {'success': false, 'error': error.toString()};
    }
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    try {
      await _supabase.auth.resetPasswordForEmail(email);
    } catch (e) {
      rethrow;
    }
  }

  // Get user profile
  Future<Map<String, dynamic>?> getUserProfile() async {
    if (!isLoggedIn || _currentUser == null) return null;

    try {
      final response = await _supabase
          .from('profiles')
          .select()
          .eq('user_id', _currentUser!.id)
          .single();

      return response;
    } catch (e) {
      return null;
    }
  }

  // Get user confinamentos
  Future<List<Map<String, dynamic>>> getUserConfinamentos() async {
    if (!isLoggedIn || _currentUser == null) return [];

    try {
      final response = await _supabase
          .from('user_confinamentos')
          .select('''
            confinamento_id,
            confinamentos!inner(
              id,
              nome,
              razao_social,
              ativo
            )
          ''')
          .eq('user_id', _currentUser!.id);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      return [];
    }
  }

  // Get user role for specific confinamento
  Future<String?> getUserRole(String confinamentoId) async {
    if (!isLoggedIn || _currentUser == null) return null;

    try {
      final response = await _supabase
          .from('user_roles')
          .select('role')
          .eq('user_id', _currentUser!.id)
          .eq('confinamento_id', confinamentoId)
          .single();

      return response['role'] as String?;
    } catch (e) {
      return null;
    }
  }

  // Check if user has permission
  bool hasPermission(String? userRole, List<String> requiredRoles) {
    if (userRole == null) return false;
    return requiredRoles.contains(userRole);
  }

  // Check if user is master
  bool isMaster(String? userRole) {
    return userRole == 'master';
  }

  // Check if user has gerencial access
  bool hasGerencialAccess(String? userRole) {
    return ['master', 'gerencial'].contains(userRole);
  }

  // Check if user has supervisor access
  bool hasSupervisorAccess(String? userRole) {
    return ['master', 'gerencial', 'supervisor'].contains(userRole);
  }

  // ✅ Método de teste para verificar configuração OAuth
  Future<void> testGoogleLogin() async {
    try {
      print('🧪 [AuthService] Testando configuração Google OAuth...');

      // Definir redirectTo baseado na plataforma
      String redirectTo;
      if (kIsWeb) {
        redirectTo = 'http://localhost:3000/auth/callback';
        print('🧪 [AuthService] Testando com callback WEB: $redirectTo');
      } else {
        redirectTo = 'io.supabase.flutter://login-callback/';
        print('🧪 [AuthService] Testando com callback MOBILE: $redirectTo');
      }

      final response = await _supabase.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: redirectTo,
        queryParams: {'access_type': 'offline', 'prompt': 'consent'},
      );

      print('🧪 [AuthService] Teste OAuth iniciado: $response');
    } catch (e) {
      print('❌ [AuthService] Erro no teste OAuth: $e');
    }
  }
}
