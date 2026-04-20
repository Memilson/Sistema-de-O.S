import 'package:flutter/material.dart';

import 'modules/splash/presentation/pages/splash_page.dart';
import 'modules/auth/presentation/pages/login_page.dart';
import 'modules/clientes/presentation/pages/cadastro_cliente_page.dart';
import 'modules/ordens/presentation/pages/nova_os_page.dart';

class AppRoutes {
  static const splash = '/splash';
  static const login = '/auth/login';
  static const dashboard = '/dashboard';
  static const cadastroCliente = '/clientes/cadastro';
  static const novaOs = '/ordens/nova';

  static Map<String, WidgetBuilder> get routes => {
        splash: (_) => const SplashPage(),
        login: (_) => const LoginPage(),
        cadastroCliente: (_) => const CadastroClientePage(),
        novaOs: (_) => const NovaOsPage(),
      };
}
