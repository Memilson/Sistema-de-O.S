import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:signature/signature.dart';
import 'package:serviceflow/app/core/mixins/loader.mixin.dart';
import 'package:serviceflow/app/core/mixins/messages.mixin.dart';
import '../../../../shared/widgets/custom_text_field.dart';
import '../../../../shared/widgets/custom_button.dart';
import '../../../clientes/cliente.model.dart';
import '../../../clientes/cliente_repository.dart';
import '../../ordem_servico.model.dart';
import '../../ordem_servico_repository.dart';

class NovaOsPage extends StatefulWidget {
  const NovaOsPage({super.key});

  @override
  State<NovaOsPage> createState() => _NovaOsPageState();
}

class _NovaOsPageState extends State<NovaOsPage>
    with MessagesMixin, LoaderMixin {
  final _formKey = GlobalKey<FormState>();
  final _clienteRepo = ClienteRepository();
  final _osRepo = OrdemServicoRepository();

  final descricaoController = TextEditingController();
  final valorController = TextEditingController();

  List<Cliente> _clientes = [];
  Cliente? _clienteSelecionado;
  XFile? _fotoAntes;
  XFile? _fotoDepois;
  bool _carregandoClientes = true;

  final SignatureController _signatureController = SignatureController(
    penStrokeWidth: 2,
    penColor: Colors.black,
  );

  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _carregarClientes();
  }

  Future<void> _carregarClientes() async {
    try {
      final lista = await _clienteRepo.listar();
      setState(() {
        _clientes = lista;
        _carregandoClientes = false;
      });
    } catch (e) {
      setState(() => _carregandoClientes = false);
    }
  }

  @override
  void dispose() {
    descricaoController.dispose();
    valorController.dispose();
    _signatureController.dispose();
    super.dispose();
  }

  Future<void> _tirarFoto(bool isAntes) async {
    final foto = await _picker.pickImage(source: ImageSource.camera);
    if (foto != null) {
      setState(() {
        if (isAntes) {
          _fotoAntes = foto;
        } else {
          _fotoDepois = foto;
        }
      });
    }
  }

  void _salvar() async {
    if (_clienteSelecionado == null) {
      showError(context, 'Selecione um cliente');
      return;
    }

    if (_formKey.currentState!.validate()) {
      showLoading(context);

      try {
        final os = OrdemServico(
          clienteId: _clienteSelecionado!.id ?? '',
          clienteNome: _clienteSelecionado!.nome,
          descricao: descricaoController.text,
          valor: double.tryParse(valorController.text) ?? 0.0,
        );

        await _osRepo.salvar(os);

        hideLoading(context);
        showSuccess(context, 'Ordem de Serviço criada!');
        Navigator.pop(context);
      } catch (e) {
        hideLoading(context);
        showError(context, 'Erro ao salvar a OS');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nova Ordem de Serviço'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Dropdown de clientes reais
              _carregandoClientes
                  ? const Center(child: CircularProgressIndicator())
                  : DropdownButtonFormField<Cliente>(
                      value: _clienteSelecionado,
                      decoration: InputDecoration(
                        labelText: 'Cliente',
                        prefixIcon: const Icon(Icons.person_outline),
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
                      ),
                      hint: const Text('Selecione um cliente'),
                      items: _clientes
                          .map((c) => DropdownMenuItem<Cliente>(
                                value: c,
                                child: Text(c.nome),
                              ))
                          .toList(),
                      onChanged: (value) {
                        setState(() => _clienteSelecionado = value);
                      },
                    ),
              const SizedBox(height: 16),

              // Descrição multi-linha
              TextFormField(
                controller: descricaoController,
                maxLines: 4,
                decoration: InputDecoration(
                  labelText: 'Descrição do Serviço',
                  alignLabelWithHint: true,
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
                    borderSide: BorderSide(color: theme.colorScheme.error),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 18),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Informe a descrição';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Valor
              CustomTextField(
                label: 'Valor (R\$)',
                controller: valorController,
                prefixIcon: Icons.attach_money,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Informe o valor';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Fotos
              Text('Fotos', style: theme.textTheme.titleMedium),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _FotoBotao(
                      label: 'Foto Antes',
                      foto: _fotoAntes,
                      onTap: () => _tirarFoto(true),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _FotoBotao(
                      label: 'Foto Depois',
                      foto: _fotoDepois,
                      onTap: () => _tirarFoto(false),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Assinatura
              Text('Assinatura', style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: theme.dividerColor),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Signature(
                  controller: _signatureController,
                  height: 150,
                  backgroundColor: Colors.grey[50]!,
                ),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () => _signatureController.clear(),
                  icon: const Icon(Icons.clear),
                  label: const Text('Limpar assinatura'),
                ),
              ),
              const SizedBox(height: 24),

              CustomButton(
                label: 'Salvar Ordem de Serviço',
                onPressed: _salvar,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FotoBotao extends StatelessWidget {
  final String label;
  final XFile? foto;
  final VoidCallback onTap;

  const _FotoBotao({
    required this.label,
    required this.foto,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 100,
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Theme.of(context).dividerColor),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              foto != null ? Icons.check_circle : Icons.camera_alt_outlined,
              color: foto != null ? Colors.green : Colors.grey,
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              foto != null ? 'Foto adicionada' : label,
              style: TextStyle(
                color: foto != null ? Colors.green : Colors.grey[600],
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
