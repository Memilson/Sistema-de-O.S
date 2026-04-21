import 'package:dio/dio.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../helpers/app.config.dart';
import '../models/error.model.dart';

class DioClient {
  final Dio instance;
  final SupabaseClient _supabase;

  DioClient({Dio? dio, SupabaseClient? supabase})
      : instance = dio ??
            Dio(
              BaseOptions(
                baseUrl: AppConfig.supabaseUrl,
                connectTimeout: const Duration(seconds: 20),
                receiveTimeout: const Duration(seconds: 20),
              ),
            ),
        _supabase = supabase ?? Supabase.instance.client {
    _addInterceptors();
  }

  void _addInterceptors() {
    instance.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          final token = _supabase.auth.currentSession?.accessToken;
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onError: (error, handler) {
          final responseData = error.response?.data;
          if (responseData is Map<String, dynamic>) {
            handler.next(
              error.copyWith(error: ErrorModel.fromJson(responseData)),
            );
            return;
          }
          handler.next(error);
        },
      ),
    );
  }
}
