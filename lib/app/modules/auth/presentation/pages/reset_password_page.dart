import 'package:flutter/material.dart';
import 'package:serviceflow/app/app_routes.dart';
import 'package:serviceflow/app/core/mixins/loader.mixin.dart';
import 'package:serviceflow/app/core/mixins/messages.mixin.dart';
import 'package:serviceflow/app/core/services/service_locator.dart';
import 'package:serviceflow/app/modules/auth/auth_repository.dart';
import 'package:serviceflow/app/shared/widgets/custom_button.dart';
import 'package:serviceflow/app/shared/widgets/custom_text_field.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ResetPasswordPage extends StatefulWidget {
  const ResetPasswordPage({super.key});

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage>
    with MessagesMixin, LoaderMixin {
  final _formKey = GlobalKey<FormState>();
  final _authRepository = ServiceLocator.instance.get<AuthRepository>();
  late TextEditingController _passwordController;
  late TextEditingController _confirmPasswordController;

  @override
  void initState() {
    super.initState();
    _passwordController = TextEditingController();
    _confirmPasswordController = TextEditingController();
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _redefinirSenha() async {
    if (!_formKey.currentState!.validate()) return;

    showLoading(context);
    try {
      await _authRepository.redefinirSenha(novaSenha: _passwordController.text);
      if (!mounted) return;
      hideLoading(context);
      showSuccess(context, 'Senha redefinida com sucesso. Faça login novamente.');
      Navigator.pushReplacementNamed(context, AppRoutes.login);
    } on AuthException catch (e) {
      if (!mounted) return;
      hideLoading(context);
      showError(context, e.message);
    } catch (_) {
      if (!mounted) return;
      hideLoading(context);
      showError(context, 'Não foi possível redefinir a senha.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasRecoverySession = Supabase.instance.client.auth.currentSession != null;

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
              child: hasRecoverySession
                  ? Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'Redefinir senha',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Digite sua nova senha',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 20),
                          CustomTextField(
                            label: 'Nova senha',
                            controller: _passwordController,
                            isPassword: true,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Informe a nova senha';
                              }
                              if (value.length <= 6) {
                                return 'A senha deve ter mais de 6 caracteres';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          CustomTextField(
                            label: 'Confirmar nova senha',
                            controller: _confirmPasswordController,
                            isPassword: true,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Confirme a nova senha';
                              }
                              if (value != _passwordController.text) {
                                return 'As senhas não conferem';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),
                          CustomButton(
                            label: 'Salvar nova senha',
                            onPressed: _redefinirSenha,
                          ),
                        ],
                      ),
                    )
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Link de recuperação inválido ou expirado.',
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
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
    );
  }
}
