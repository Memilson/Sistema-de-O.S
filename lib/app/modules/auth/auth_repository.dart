import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:serviceflow/app/app_routes.dart';
import 'package:serviceflow/app/core/helpers/app.config.dart';
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
    final response = await _supabase.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );
    await _persistSession(response.session);
    await _storage.write(key: 'last_email', value: email.trim());
    return response;
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

  Future<void> enviarResetSenha({required String email}) async {
    await _supabase.auth.resetPasswordForEmail(
      email.trim(),
      redirectTo: _buildResetRedirectTo(),
    );
  }

  Future<UserResponse> redefinirSenha({required String novaSenha}) async {
    return _supabase.auth.updateUser(UserAttributes(password: novaSenha));
  }

  String _buildResetRedirectTo() {
    if (kIsWeb) {
      final base = Uri.base;
      if (base.hasScheme && base.hasAuthority) {
        return '${base.scheme}://${base.authority}${AppRoutes.resetPassword}';
      }
    }

    final configuredUrl = AppConfig.supabaseRedirectUrl?.trim();
    if (configuredUrl != null && configuredUrl.isNotEmpty) {
      if (configuredUrl.endsWith('/')) {
        return '${configuredUrl.substring(0, configuredUrl.length - 1)}${AppRoutes.resetPassword}';
      }
      return '$configuredUrl${AppRoutes.resetPassword}';
    }

    return 'serviceflow://auth/reset-password';
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
