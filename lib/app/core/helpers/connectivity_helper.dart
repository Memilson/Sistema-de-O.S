import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

import 'app.config.dart';

/// Verifica se há conectividade com a internet de forma confiável.
///
/// Usa dois níveis de verificação:
/// 1. [connectivity_plus] para checar se há uma interface de rede ativa.
/// 2. Uma conexão TCP real ao host do Supabase para confirmar acesso à internet
///    (evita falso positivo em redes Wi-Fi sem WAN ou captive portals).
class ConnectivityHelper {
  static Future<bool> isOnline() async {
    // connectivity_plus v6 retorna List<ConnectivityResult>
    final results = await Connectivity().checkConnectivity();
    final hasInterface =
        results.isNotEmpty && results.any((r) => r != ConnectivityResult.none);

    if (!hasInterface) return false;

    // No Web não temos acesso a dart:io — confiamos na verificação de interface
    if (kIsWeb) return true;

    // Verificação real: tenta conectar ao host do Supabase via TCP na porta 443
    try {
      final host = Uri.parse(AppConfig.supabaseUrl).host;
      final socket = await Socket.connect(
        host,
        443,
        timeout: const Duration(seconds: 5),
      );
      socket.destroy();
      return true;
    } catch (_) {
      return false;
    }
  }
}
