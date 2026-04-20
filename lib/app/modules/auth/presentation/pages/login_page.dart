import 'package:flutter/material.dart';
import 'package:serviceflow/app/core/mixins/loader.mixin.dart';
import 'package:serviceflow/app/core/mixins/messages.mixin.dart';
import 'package:serviceflow/app/app_routes.dart';
import '../../../../shared/widgets/custom_text_field.dart';
import '../../../../shared/widgets/app_logo.dart';
import '../../../../shared/widgets/custom_button.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with MessagesMixin, LoaderMixin {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController emailController;
  late TextEditingController senhaController;

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

  void _fazerLogin() {
    if (_formKey.currentState!.validate()) {
      showLoading(context);

      Future.delayed(const Duration(seconds: 2), () {
        hideLoading(context);
        Navigator.pushNamed(context, AppRoutes.dashboard);
      });
    }
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
                  prefixIcon: Icons.email_outlined,
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
                  prefixIcon: Icons.lock_outline,
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
                  label: 'Entrar',
                  onPressed: _fazerLogin,
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () {
                    Navigator.pushNamed(context, AppRoutes.cadastroCliente);
                  },
                  child: const Text('Criar nova conta'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
