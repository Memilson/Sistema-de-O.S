import 'package:flutter_dotenv/flutter_dotenv.dart';
class AppConfig {
  static String get supabaseUrl {
    final value = _requiredEnv('SUPABASE_URL');
    if (value.startsWith('http')) return value;
    return 'https://$value.supabase.co';
  }
  static String get supabaseKey => _requiredEnv('SUPABASE_ANON_PUBLIC');
  static String? get supabaseRedirectUrl {
    final value = dotenv.env['SUPABASE_REDIRECT_URL']?.trim();
    if (value == null || value.isEmpty) return null;
    return value;
  }
  static String? get supportWhatsappNumber {
    final value = dotenv.env['SUPPORT_WHATSAPP']?.trim();
    if (value == null || value.isEmpty) return null;
    return value.replaceAll(RegExp(r'\D'), '');
  }
  static const String groupId = "SF-GP-01";
  static String _requiredEnv(String key) {
    final value = dotenv.env[key]?.trim();
    if (value == null || value.isEmpty) throw StateError('Variável $key não configurada no .env');
    return value;
  }
}
