import 'package:flutter/material.dart';
import 'package:serviceflow/app/app_routes.dart';
import 'package:serviceflow/app/core/mixins/loader.mixin.dart';
import 'package:serviceflow/app/core/mixins/messages.mixin.dart';
import 'package:serviceflow/app/core/services/service_locator.dart';
import 'package:serviceflow/app/modules/auth/auth_repository.dart';
import 'package:serviceflow/app/shared/widgets/custom_button.dart';
import 'package:serviceflow/app/shared/widgets/custom_text_field.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage>
    with MessagesMixin, LoaderMixin {
  final _formKey = GlobalKey<FormState>();
  final _authRepository = ServiceLocator.instance.get<AuthRepository>();
  late TextEditingController _emailController;
  bool _emailEnviado = false;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController();
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _enviarRecuperacaoSenha() async {
    if (!_formKey.currentState!.validate()) return;

    showLoading(context);
    try {
      await _authRepository.enviarResetSenha(email: _emailController.text);
      if (!mounted) return;
      hideLoading(context);
      setState(() => _emailEnviado = true);
      showSuccess(context, 'Enviamos um link de recuperação para seu e-mail.');
    } on AuthException catch (e) {
      if (!mounted) return;
      hideLoading(context);
      showError(context, e.message);
    } catch (_) {
      if (!mounted) return;
      hideLoading(context);
      showError(context, 'Erro ao enviar recuperação de senha');
    }
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
              padding: const EdgeInsets.all(24),
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
                    const Text(
                      'Recuperar senha',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Informe seu e-mail',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Enviaremos um link para redefinir sua senha.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    CustomTextField(
                      label: 'E-mail',
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Informe o e-mail';
                        if (!value.contains('@')) return 'E-mail inválido';
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    if (_emailEnviado) ...[
                      const Text(
                        'Verifique seu e-mail e abra o link recebido.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Color(0xFF2E7D32)),
                      ),
                      const SizedBox(height: 16),
                    ],
                    CustomButton(
                      label: 'Enviar link de recuperação',
                      onPressed: _enviarRecuperacaoSenha,
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () => Navigator.pushReplacementNamed(
                        context,
                        AppRoutes.login,
                      ),
                      child: const Text('Voltar para login'),
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
