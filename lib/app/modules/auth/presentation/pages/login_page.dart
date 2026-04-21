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
      } on AuthException catch (e) {
        if (!mounted) return;
        hideLoading(context);
        showError(context, e.message);
      } catch (_) {
        if (!mounted) return;
        hideLoading(context);
        showError(context, 'Erro ao autenticar no Supabase');
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

        showSuccess(
          context,
          'Conta criada. Confirme seu e-mail para fazer login.',
        );
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
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: AppLogo(width: double.infinity, height: 200),
                ),
                const SizedBox(height: 40),
                CustomTextField(
                  label: 'E-mail',
                  controller: emailController,
                  prefixIcon: AppIcons.email,
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Informe o e-mail';
                    }
                    if (!value.contains('@')) {
                      return 'E-mail inválido';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  label: 'Senha',
                  controller: senhaController,
                  prefixIcon: AppIcons.lock,
                  isPassword: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Informe a senha';
                    }
                    if (value.length <= 6) {
                      return 'A senha deve ter mais de 6 caracteres';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 32),
                CustomButton(
                  label: _criandoConta ? 'Criar conta' : 'Entrar',
                  onPressed: _criandoConta ? _criarConta : _fazerLogin,
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () {
                    setState(() => _criandoConta = !_criandoConta);
                  },
                  child: Text(
                    _criandoConta ? 'Já tenho conta' : 'Criar nova conta',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
