import 'package:flutter/material.dart';
import 'package:serviceflow/app/core/helpers/app.config.dart';
import 'package:serviceflow/app/core/mixins/loader.mixin.dart';
import 'package:serviceflow/app/core/mixins/messages.mixin.dart';
import 'package:serviceflow/app/core/services/service_locator.dart';
import 'package:serviceflow/app/core/theme/app_icons.dart';
import 'package:serviceflow/app/app_routes.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../shared/widgets/custom_text_field.dart';
import '../../../../shared/widgets/app_logo.dart';
import '../../../../shared/widgets/custom_button.dart';
import '../../auth_repository.dart';
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}
class _LoginPageState extends State<LoginPage> with MessagesMixin, LoaderMixin {
  final _formKey = GlobalKey<FormState>();
  final _authRepository = ServiceLocator.instance.get<AuthRepository>();
  late TextEditingController emailController;
  late TextEditingController senhaController;
  bool _criandoConta = false;
  @override
  void initState() {
    super.initState();
    emailController = TextEditingController();
    senhaController = TextEditingController();
  }
  @override
  void dispose() {
    emailController.dispose();
    senhaController.dispose();
    super.dispose();
  }
  Future<void> _fazerLogin() async {
    if (_formKey.currentState!.validate()) {
      showLoading(context);
      try {
        await _authRepository.login(
          email: emailController.text,
          password: senhaController.text,
        );
        if (!mounted) return;
        hideLoading(context);
        Navigator.pushReplacementNamed(context, AppRoutes.dashboard);
      } catch (e) {
        if (!mounted) return;

        final isNetworkError = e.toString().contains('SocketException') ||
            e.toString().contains('ClientException');

        if (isNetworkError) {
          // Fallback Offline: verifica se o e-mail digitado é o do último usuário autenticado
          final podeLogarOffline =
              await _authRepository.podeLogarOffline(emailController.text);
          hideLoading(context);

          if (podeLogarOffline) {
            showSuccess(context, 'Entrando no modo offline.');
            Navigator.pushReplacementNamed(context, AppRoutes.dashboard);
          } else {
            showError(
              context,
              'Sem conexão. O login offline está disponível apenas para o último usuário logado.',
            );
          }
        } else {
          hideLoading(context);
          if (e is AuthException) {
            showError(context, e.message);
          } else {
            showError(context, 'Erro ao autenticar: $e');
          }
        }
      }
    }
  }
  Future<void> _criarConta() async {
    if (_formKey.currentState!.validate()) {
      showLoading(context);
      try {
        final response = await _authRepository.criarConta(
          email: emailController.text,
          password: senhaController.text,
          emailRedirectTo: _authRedirectUrl,
        );
        if (!mounted) return;
        hideLoading(context);
        if (response.session != null) {
          Navigator.pushReplacementNamed(context, AppRoutes.dashboard);
          return;
        }
        showSuccess(context, 'Conta criada. Confirme seu e-mail para fazer login.');
        setState(() => _criandoConta = false);
      } on AuthException catch (e) {
        if (!mounted) return;
        hideLoading(context);
        showError(context, e.message);
      } catch (_) {
        if (!mounted) return;
        hideLoading(context);
        showError(context, 'Erro ao criar conta no Supabase');
      }
    }
  }

  String get _authRedirectUrl {
    final configuredUrl = AppConfig.supabaseRedirectUrl;
    if (configuredUrl != null) return configuredUrl;
    final uri = Uri.base;
    if (uri.hasScheme && uri.hasAuthority) {
      return '${uri.scheme}://${uri.authority}/';
    }
    return 'serviceflow://login-callback';
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: const Color(0xFFE0E0E0)),
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const AppLogo(width: 80, height: 80),
                    const SizedBox(height: 12),
                    const Text('ServiceFlow', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Color(0xFF1B1B1F))),
                    const SizedBox(height: 4),
                    const Text('Acesse sua conta', style: TextStyle(fontSize: 13, color: Color(0xFF616161))),
                    const SizedBox(height: 32),
                    CustomTextField(
                      label: 'E-mail',
                      controller: emailController,
                      prefixIcon: AppIcons.email,
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Informe o e-mail';
                        if (!value.contains('@')) return 'E-mail inválido';
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    CustomTextField(
                      label: 'Senha',
                      controller: senhaController,
                      prefixIcon: AppIcons.lock,
                      isPassword: true,
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Informe a senha';
                        if (value.length <= 6) return 'A senha deve ter mais de 6 caracteres';
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    CustomButton(
                      label: _criandoConta ? 'Criar conta' : 'Entrar',
                      onPressed: _criandoConta ? _criarConta : _fazerLogin,
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () => setState(() => _criandoConta = !_criandoConta),
                      child: Text(_criandoConta ? 'Já tenho conta' : 'Criar nova conta'),
                    ),
                    if (!_criandoConta)
                      TextButton(
                        onPressed: () => Navigator.pushNamed(
                          context,
                          AppRoutes.forgotPassword,
                        ),
                        child: const Text('Esqueci minha senha'),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
