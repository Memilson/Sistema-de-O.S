import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

class EvidenceStorageService {
  static const bucketName = 'evidencias';

  final SupabaseClient _supabase;

  EvidenceStorageService({SupabaseClient? supabase})
      : _supabase = supabase ?? Supabase.instance.client;

  Future<String> uploadBytes({
    required String ordemId,
    required String fileName,
    required Uint8List bytes,
    required String contentType,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      throw const AuthException('Usuario nao autenticado');
    }

    final path = '${user.id}/ordens/$ordemId/$fileName';
    await _supabase.storage.from(bucketName).uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(
            contentType: contentType,
            upsert: true,
          ),
        );
    return path;
  }
}
