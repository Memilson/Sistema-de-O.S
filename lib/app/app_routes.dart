import 'package:flutter/material.dart';
import 'modules/splash/presentation/pages/splash_page.dart';
import 'modules/auth/presentation/pages/forgot_password_page.dart';
import 'modules/auth/presentation/pages/login_page.dart';
import 'modules/auth/presentation/pages/reset_password_page.dart';
import 'modules/clientes/presentation/pages/clientes_page.dart';
import 'modules/clientes/presentation/pages/cadastro_cliente_page.dart';
import 'modules/dashboard/presentation/pages/dashboard_page.dart';
import 'modules/ordens/presentation/pages/ordem_detalhe_page.dart';
import 'modules/ordens/presentation/pages/ordens_page.dart';
import 'modules/ordens/presentation/pages/nova_os_page.dart';
class AppRoutes {
  static const splash = '/splash';
  static const login = '/auth/login';
  static const forgotPassword = '/auth/forgot-password';
  static const resetPassword = '/auth/reset-password';
  static const dashboard = '/dashboard';
  static const clientes = '/clientes';
  static const cadastroCliente = '/clientes/cadastro';
  static const ordens = '/ordens';
  static const novaOs = '/ordens/nova';
  static const ordemDetalhe = '/ordens/detalhe';
  static Map<String, WidgetBuilder> get routes => {
    splash: (_) => const SplashPage(),
    login: (_) => const LoginPage(),
    forgotPassword: (_) => const ForgotPasswordPage(),
    resetPassword: (_) => const ResetPasswordPage(),
    dashboard: (_) => const DashboardPage(),
    clientes: (_) => const ClientesPage(),
    cadastroCliente: (_) => const CadastroClientePage(),
    ordens: (_) => const OrdensPage(),
    novaOs: (_) => const NovaOsPage(),
    ordemDetalhe: (_) => const OrdemDetalhePage(),
  };
}
