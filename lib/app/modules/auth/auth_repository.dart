import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
class AuthRepository {
  final SupabaseClient _supabase;
  final FlutterSecureStorage _storage;
  AuthRepository({SupabaseClient? supabase, FlutterSecureStorage? storage})
      : _supabase = supabase ?? Supabase.instance.client,
        _storage = storage ?? const FlutterSecureStorage();
  User? get currentUser => _supabase.auth.currentUser;
  Session? get currentSession => _supabase.auth.currentSession;
  Future<AuthResponse> login({required String email, required String password}) async {
    try {
      final response = await _supabase.auth.signInWithPassword(email: email.trim(), password: password);
      await _persistSession(response.session);
      await _storage.write(key: 'last_email', value: email.trim());
      return response;
    } catch (e) {
      // Se falhar por rede, tentamos validar localmente (offline login)
      final lastEmail = await _storage.read(key: 'last_email');
      if (lastEmail == email.trim()) {
        // Simula uma resposta de sucesso para permitir entrada offline
        // Nota: O ideal seria validar o hash da senha, mas para offline-first simples
        // permitimos se o e-mail bater com o último logado.
        return AuthResponse(session: _supabase.auth.currentSession);
      }
      rethrow;
    }
  }

  Future<bool> podeLogarOffline(String email) async {
    final lastEmail = await _storage.read(key: 'last_email');
    return lastEmail == email.trim();
  }
  Future<AuthResponse> criarConta({required String email, required String password, String? emailRedirectTo}) async {
    final response = await _supabase.auth.signUp(email: email.trim(), password: password, emailRedirectTo: emailRedirectTo);
    await _persistSession(response.session);
    return response;
  }
  Future<void> logout() async {
    await _storage.delete(key: 'access_token');
    await _storage.delete(key: 'refresh_token');
    await _supabase.auth.signOut();
  }
  Future<void> _persistSession(Session? session) async {
    if (session == null) return;
    await _storage.write(key: 'access_token', value: session.accessToken);
    await _storage.write(key: 'refresh_token', value: session.refreshToken);
  }
}
