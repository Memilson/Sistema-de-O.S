import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:serviceflow/app/core/mixins/loader.mixin.dart';
import 'package:serviceflow/app/core/mixins/messages.mixin.dart';
import '../../../../shared/widgets/custom_text_field.dart';
import '../../../../shared/widgets/custom_button.dart';
import '../../cliente.model.dart';
import '../../cliente_repository.dart';

class CadastroClientePage extends StatefulWidget {
  const CadastroClientePage({super.key});

  @override
  State<CadastroClientePage> createState() => _CadastroClientePageState();
}

class _CadastroClientePageState extends State<CadastroClientePage>
    with MessagesMixin, LoaderMixin {
  final _formKey = GlobalKey<FormState>();
  final _repository = ClienteRepository();

  final nomeController = TextEditingController();
  final cpfCnpjController = TextEditingController();
  final emailController = TextEditingController();
  final telefoneController = TextEditingController();

  @override
  void dispose() {
    nomeController.dispose();
    cpfCnpjController.dispose();
    emailController.dispose();
    telefoneController.dispose();
    super.dispose();
  }

  void _salvar() async {
    if (_formKey.currentState!.validate()) {
      showLoading(context);

      try {
        final cliente = Cliente(
          nome: nomeController.text,
          cpfCnpj: cpfCnpjController.text,
          email: emailController.text,
          telefone: telefoneController.text,
        );

        await _repository.salvar(cliente);

        hideLoading(context);
        showSuccess(context, 'Cliente cadastrado com sucesso!');
        Navigator.pop(context);
      } catch (e) {
        hideLoading(context);
        showError(context, 'Erro ao salvar cliente');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cadastro de Cliente'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              CustomTextField(
                label: 'Nome / Razão Social',
                controller: nomeController,
                prefixIcon: Icons.person_outline,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Informe o nome';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: cpfCnpjController,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  _CpfCnpjMask(),
                ],
                decoration: InputDecoration(
                  labelText: 'CPF / CNPJ',
                  prefixIcon: const Icon(Icons.badge_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: theme.dividerColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        BorderSide(color: theme.primaryColor, width: 2),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        BorderSide(color: theme.colorScheme.error),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 18),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Informe o CPF ou CNPJ';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
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
              TextFormField(
                controller: telefoneController,
                keyboardType: TextInputType.phone,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  _TelefoneMask(),
                ],
                decoration: InputDecoration(
                  labelText: 'Telefone',
                  prefixIcon: const Icon(Icons.phone_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: theme.dividerColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        BorderSide(color: theme.primaryColor, width: 2),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        BorderSide(color: theme.colorScheme.error),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 18),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Informe o telefone';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),
              CustomButton(
                label: 'Salvar',
                onPressed: _salvar,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CpfCnpjMask extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    String formatted = '';

    if (digits.length <= 11) {
      for (int i = 0; i < digits.length && i < 11; i++) {
        if (i == 3 || i == 6) formatted += '.';
        if (i == 9) formatted += '-';
        formatted += digits[i];
      }
    } else {
      for (int i = 0; i < digits.length && i < 14; i++) {
        if (i == 2 || i == 5) formatted += '.';
        if (i == 8) formatted += '/';
        if (i == 12) formatted += '-';
        formatted += digits[i];
      }
    }

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

class _TelefoneMask extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    String formatted = '';

    for (int i = 0; i < digits.length && i < 11; i++) {
      if (i == 0) formatted += '(';
      if (i == 2) formatted += ') ';
      if (i == 7) formatted += '-';
      formatted += digits[i];
    }

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
