import 'package:supabase_flutter/supabase_flutter.dart';
import '../constants/supabase_config.dart';

class SupabaseService {
  static SupabaseClient? _client;

  static SupabaseClient get client {
    if (_client == null) {
      throw Exception('Supabase not initialized. Call initialize() first.');
    }
    return _client!;
  }

  static Future<void> initialize() async {
    await Supabase.initialize(
      url: SupabaseConfig.url,
      anonKey: SupabaseConfig.anonKey,
      authOptions: const FlutterAuthClientOptions(
        authFlowType: AuthFlowType.pkce, // ✅ CRUCIAL para OAuth!
      ),
    );
    _client = Supabase.instance.client;
  }

  static bool get isInitialized => _client != null;

  // Auth helpers
  static User? get currentUser => client.auth.currentUser;
  static Stream<AuthState> get authStateChanges =>
      client.auth.onAuthStateChange;
  static bool get isLoggedIn => currentUser != null;

  // Common queries for combustivel app
  static SupabaseQueryBuilder get usuariosCombustivel =>
      client.from('usuarios_combustivel');
  static SupabaseQueryBuilder get tanquesCombustivel =>
      client.from('tanques_combustivel');
  static SupabaseQueryBuilder get movimentacoesCombustivel =>
      client.from('movimentacoes_combustivel');
}
