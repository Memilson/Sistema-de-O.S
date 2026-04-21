import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:signature/signature.dart';
import 'package:serviceflow/app/core/mixins/loader.mixin.dart';
import 'package:serviceflow/app/core/mixins/messages.mixin.dart';
import 'package:serviceflow/app/core/services/service_locator.dart';
import 'package:serviceflow/app/core/theme/app_icons.dart';
import 'package:serviceflow/app/shared/widgets/app_back_button.dart';
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
class _NovaOsPageState extends State<NovaOsPage> with MessagesMixin, LoaderMixin {
  final _formKey = GlobalKey<FormState>();
  final _clienteRepo = ServiceLocator.instance.get<ClienteRepository>();
  final _osRepo = ServiceLocator.instance.get<OrdemServicoRepository>();
  final descricaoController = TextEditingController();
  final valorController = TextEditingController();
  List<Cliente> _clientes = [];
  Cliente? _clienteSelecionado;
  XFile? _fotoAntes;
  XFile? _fotoDepois;
  bool _carregandoClientes = true;
  final SignatureController _signatureController = SignatureController(penStrokeWidth: 2, penColor: Colors.black);
  final _picker = ImagePicker();
  @override
  void initState() {
    super.initState();
    _carregarClientes();
  }
  Future<void> _carregarClientes() async {
    try {
      final lista = await _clienteRepo.listar();
      setState(() { _clientes = lista; _carregandoClientes = false; });
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
      setState(() { if (isAntes) { _fotoAntes = foto; } else { _fotoDepois = foto; } });
    }
  }
  void _salvar() async {
    if (_clienteSelecionado == null) { showError(context, 'Selecione um cliente'); return; }
    if (_formKey.currentState!.validate()) {
      showLoading(context);
      try {
        final assinatura = await _signatureController.toPngBytes();
        final os = OrdemServico(
          clienteId: _clienteSelecionado!.id ?? '',
          clienteNome: _clienteSelecionado!.nome,
          descricao: descricaoController.text,
          valor: double.tryParse(valorController.text) ?? 0.0,
          fotoAntesPath: _fotoAntes?.path,
          fotoDepoisPath: _fotoDepois?.path,
          assinaturaBase64: assinatura == null ? null : base64Encode(assinatura),
        );
        await _osRepo.salvarComEvidencias(
          os,
          fotoAntes: await _fotoAntes?.readAsBytes(),
          fotoDepois: await _fotoDepois?.readAsBytes(),
          assinatura: assinatura,
        );
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
      appBar: AppBar(leading: const AppBackButton(), title: const Text('Nova Ordem de Serviço')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _carregandoClientes
                    ? const Center(child: CircularProgressIndicator())
                    : DropdownButtonFormField<Cliente>(
                        initialValue: _clienteSelecionado,
                        decoration: const InputDecoration(labelText: 'Cliente', prefixIcon: Icon(AppIcons.person)),
                        hint: const Text('Selecione um cliente'),
                        items: _clientes.map((c) => DropdownMenuItem<Cliente>(value: c, child: Text(c.nome))).toList(),
                        onChanged: (value) => setState(() => _clienteSelecionado = value),
                      ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: descricaoController,
                  maxLines: 4,
                  decoration: const InputDecoration(labelText: 'Descrição do Serviço', alignLabelWithHint: true),
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Informe a descrição';
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                CustomTextField(
                  label: 'Valor (R\$)',
                  controller: valorController,
                  prefixIcon: AppIcons.currency,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Informe o valor';
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                Text('Evidências', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700, color: const Color(0xFF616161))),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(child: _FotoBotao(label: 'Foto Antes', foto: _fotoAntes, onTap: () => _tirarFoto(true))),
                  const SizedBox(width: 12),
                  Expanded(child: _FotoBotao(label: 'Foto Depois', foto: _fotoDepois, onTap: () => _tirarFoto(false))),
                ]),
                const SizedBox(height: 24),
                Text('Assinatura', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700, color: const Color(0xFF616161))),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xFFE0E0E0)),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: Signature(controller: _signatureController, height: 150, backgroundColor: const Color(0xFFFAFAFA)),
                  ),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(onPressed: () => _signatureController.clear(), icon: const Icon(AppIcons.close, size: 16), label: const Text('Limpar')),
                ),
                const SizedBox(height: 24),
                CustomButton(label: 'Salvar Ordem de Serviço', onPressed: _salvar),
              ],
            ),
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
  const _FotoBotao({required this.label, required this.foto, required this.onTap});
  @override
  Widget build(BuildContext context) {
    final hasPhoto = foto != null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 90,
        decoration: BoxDecoration(
          color: hasPhoto ? const Color(0xFF2E7D32).withAlpha(15) : const Color(0xFFFAFAFA),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: hasPhoto ? const Color(0xFF2E7D32) : const Color(0xFFE0E0E0)),
        ),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(hasPhoto ? AppIcons.checkCircle : AppIcons.camera, color: hasPhoto ? const Color(0xFF2E7D32) : const Color(0xFF616161), size: 28),
          const SizedBox(height: 6),
          Text(hasPhoto ? 'Foto adicionada' : label, style: TextStyle(color: hasPhoto ? const Color(0xFF2E7D32) : const Color(0xFF616161), fontSize: 12)),
        ]),
      ),
    );
  }
}
