import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'auth_service.dart';

class MockAuthService extends AuthService {
  bool _isLoggedIn = false;
  User? _mockUser;

  @override
  User? get currentUser => _mockUser;

  @override
  bool get isLoggedIn => _isLoggedIn;

  @override
  Stream<AuthState> get authStateChanges {
    if (_mockUser != null) {
      return Stream.value(
        AuthState(
          AuthChangeEvent.signedIn,
          Session(
            accessToken: 'mock-access-token',
            refreshToken: 'mock-refresh-token',
            expiresIn: 3600,
            tokenType: 'Bearer',
            user: _mockUser!,
          ),
        ),
      );
    } else {
      return Stream.value(AuthState(AuthChangeEvent.signedOut, null));
    }
  }

  @override
  Future<AuthResponse> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    // Simular login com dados válidos
    if (email.isNotEmpty && password.length >= 6) {
      _mockUser = User(
        id: 'mock-user-id',
        appMetadata: {},
        userMetadata: {'email': email},
        aud: 'authenticated',
        createdAt: DateTime.now().toIso8601String(),
        email: email,
      );
      _isLoggedIn = true;

      return AuthResponse(
        user: _mockUser,
        session: Session(
          accessToken: 'mock-access-token',
          refreshToken: 'mock-refresh-token',
          expiresIn: 3600,
          tokenType: 'Bearer',
          user: _mockUser!,
        ),
      );
    } else {
      throw Exception('Email ou senha inválidos');
    }
  }

  @override
  Future<AuthResponse> signUpWithEmailAndPassword(
    String email,
    String password,
  ) async {
    // Simular criação de conta
    return signInWithEmailAndPassword(email, password);
  }

  @override
  Future<AuthResponse?> signInWithGoogle() async {
    // Simular login com Google
    try {
      final response = await signInWithEmailAndPassword(
        'google.user@exemplo.com',
        'password123',
      );

      return response;
    } catch (e) {
      throw Exception('Erro ao fazer login com Google: $e');
    }
  }

  @override
  Future<void> signOut() async {
    _mockUser = null;
    _isLoggedIn = false;
  }

  @override
  Future<void> resetPassword(String email) async {
    // Simular reset de senha
    await Future.delayed(const Duration(seconds: 1));
  }

  @override
  Future<Map<String, dynamic>?> getUserProfile() async {
    if (!isLoggedIn) return null;

    return {
      'user_id': _mockUser!.id,
      'email': _mockUser!.email,
      'name': 'Usuário Mock',
      'confinamento_nome': 'Fazenda Teste - Mock',
      'cargo': 'Desenvolvedor',
      'created_at': DateTime.now().toIso8601String(),
    };
  }

  @override
  Future<List<Map<String, dynamic>>> getUserConfinamentos() async {
    if (!isLoggedIn) return [];

    return [
      {
        'confinamento_id': 'mock-conf-1',
        'confinamentos': {
          'id': 'mock-conf-1',
          'nome': 'Fazenda Teste Mock',
          'razao_social': 'Mock Agropecuária Ltda',
          'ativo': true,
        },
      },
    ];
  }

  @override
  Future<String?> getUserRole(String confinamentoId) async {
    if (!isLoggedIn) return null;
    return 'master'; // Mock user sempre tem acesso master
  }

  /// Métodos estáticos específicos para teste (mantidos para compatibilidade)
  static Future<AuthResponse?> signInForTesting({
    String email = 'teste@conectaboi.com.br',
    String password = '123456789',
  }) async {
    try {
      final mockService = MockAuthService();
      return await mockService.signInWithEmailAndPassword(email, password);
    } catch (e) {
      debugPrint('❌ Erro no login de teste: $e');
      rethrow;
    }
  }

  static Future<bool> testSupabaseConnection() async {
    try {
      debugPrint('🔌 Testando conexão com Supabase...');

      // Em modo mock, simula conexão OK
      await Future.delayed(const Duration(seconds: 1));
      debugPrint('✅ Conexão simulada com sucesso (modo mock)!');
      return true;
    } catch (e) {
      debugPrint('❌ Erro na simulação de conexão: $e');
      return false;
    }
  }

  static Future<void> createTestData() async {
    try {
      debugPrint('🧪 Simulando criação de dados de teste...');
      await Future.delayed(const Duration(seconds: 1));
      debugPrint('🎉 Dados de teste simulados com sucesso!');
    } catch (e) {
      debugPrint('❌ Erro ao simular dados de teste: $e');
    }
  }
}
