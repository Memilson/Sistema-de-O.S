import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/services/service_locator.dart';
import '../../../../core/services/whatsapp_service.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../shared/widgets/app_back_button.dart';
import '../../ordem_servico.model.dart';
import '../../ordem_servico_repository.dart';

class OrdemDetalhePage extends StatefulWidget {
  const OrdemDetalhePage({super.key});

  @override
  State<OrdemDetalhePage> createState() => _OrdemDetalhePageState();
}

class _OrdemDetalhePageState extends State<OrdemDetalhePage> {
  static final _currencyFormat = NumberFormat.currency(
    locale: 'pt_BR',
    symbol: 'R\$',
  );

  final _repository = ServiceLocator.instance.get<OrdemServicoRepository>();
  final _whatsappService = ServiceLocator.instance.get<WhatsappService>();

  OrdemServico? _ordem;
  bool _saving = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (_ordem == null && args is OrdemServico) {
      _ordem = args;
    }
  }

  Future<void> _alterarStatus(String status) async {
    final ordem = _ordem;
    if (ordem == null) return;

    setState(() => _saving = true);
    try {
      final atualizada = ordem.copyWith(status: status);
      await _repository.salvar(atualizada);
      if (!mounted) return;
      setState(() {
        _ordem = atualizada;
        _saving = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Status atualizado.')),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erro ao atualizar status.')),
      );
    }
  }

  Future<void> _abrirWhatsapp() async {
    final ordem = _ordem;
    final opened = await _whatsappService.abrirSuporte(
      mensagem: ordem == null
          ? null
          : 'Ola, preciso de suporte na O.S. ${ordem.id ?? ''} '
              'do cliente ${ordem.clienteNome}.',
    );

    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Configure SUPPORT_WHATSAPP no .env.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final ordem = _ordem;
    if (ordem == null) {
      return const Scaffold(
        body: Center(child: Text('Ordem de serviço não informada.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        leading: const AppBackButton(),
        title: const Text('Detalhe da O.S.'),
        actions: [
          IconButton(
            tooltip: 'WhatsApp',
            onPressed: _abrirWhatsapp,
            icon: const Icon(AppIcons.support),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            ordem.clienteNome,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 8),
          Text(_currencyFormat.format(ordem.valor)),
          const SizedBox(height: 20),
          DropdownButtonFormField<String>(
            initialValue: ordem.status,
            decoration: const InputDecoration(
              labelText: 'Status',
              prefixIcon: Icon(AppIcons.flag),
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(value: 'Em aberto', child: Text('Em aberto')),
              DropdownMenuItem(
                value: 'Em execução',
                child: Text('Em execução'),
              ),
              DropdownMenuItem(value: 'Executada', child: Text('Executada')),
            ],
            onChanged: _saving || _ordem == null
                ? null
                : (value) {
                    if (value != null) _alterarStatus(value);
                  },
          ),
          const SizedBox(height: 20),
          _InfoTile(
            icon: AppIcons.description,
            title: 'Descrição',
            value: ordem.descricao,
          ),
          _InfoTile(
            icon: AppIcons.evidenceImage,
            title: 'Foto antes',
            value: ordem.fotoAntesPath ?? 'Não anexada',
          ),
          _InfoTile(
            icon: AppIcons.evidenceImage,
            title: 'Foto depois',
            value: ordem.fotoDepoisPath ?? 'Não anexada',
          ),
          _InfoTile(
            icon: AppIcons.signature,
            title: 'Assinatura',
            value: ordem.assinaturaBase64 == null
                ? 'Não anexada'
                : 'Assinatura registrada',
          ),
          if (_saving)
            const Padding(
              padding: EdgeInsets.only(top: 16),
              child: LinearProgressIndicator(),
            ),
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _InfoTile({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        subtitle: Text(value),
      ),
    );
  }
}
