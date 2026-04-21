import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../app_routes.dart';
import '../../../../core/services/offline_sync_service.dart';
import '../../../../core/services/service_locator.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../shared/widgets/app_back_button.dart';
import '../../ordem_servico.model.dart';
import '../../ordem_servico_controller.dart';
import '../../ordem_servico_repository.dart';

class OrdensPage extends StatefulWidget {
  const OrdensPage({super.key});

  @override
  State<OrdensPage> createState() => _OrdensPageState();
}

class _OrdensPageState extends State<OrdensPage> {
  static final _currencyFormat = NumberFormat.currency(
    locale: 'pt_BR',
    symbol: 'R\$',
  );

  late final OrdemServicoController _controller;
  final _syncService = ServiceLocator.instance.get<OfflineSyncService>();
  int _pendentes = 0;

  @override
  void initState() {
    super.initState();
    _controller = OrdemServicoController(
      ServiceLocator.instance.get<OrdemServicoRepository>(),
    );
    _carregar();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _carregar() async {
    await _syncService.syncPending();
    await _controller.carregar();
    final pendentes = await _syncService.countPending();
    if (!mounted) return;
    setState(() => _pendentes = pendentes);
  }

  Future<void> _novaOrdem() async {
    await Navigator.pushNamed(context, AppRoutes.novaOs);
    _carregar();
  }

  Future<void> _abrirDetalhe(OrdemServico ordem) async {
    await Navigator.pushNamed(
      context,
      AppRoutes.ordemDetalhe,
      arguments: ordem,
    );
    _carregar();
  }

  Future<void> _confirmarExclusao(OrdemServico ordem) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir O.S.'),
        content: Text('Deseja excluir a O.S. de ${ordem.clienteNome}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirmed == true && ordem.id != null) {
      await _controller.excluir(ordem.id!);
      _carregar();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const AppBackButton(),
        title: const Text('Ordens de Serviço'),
        actions: [
          if (_pendentes > 0)
            Center(
              child: Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Text('$_pendentes pendente(s)'),
              ),
            ),
          IconButton(
            tooltip: 'Sincronizar',
            onPressed: _carregar,
            icon: const Icon(AppIcons.sync),
          ),
          IconButton(
            tooltip: 'Nova O.S.',
            onPressed: _novaOrdem,
            icon: const Icon(AppIcons.taskAdd),
          ),
        ],
      ),
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          if (_controller.isLoading && _controller.items.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (_controller.errorMessage != null) {
            return _ErrorState(
              message: 'Nao foi possivel carregar as ordens.',
              onRetry: _carregar,
            );
          }

          if (_controller.items.isEmpty) {
            return _EmptyState(onAdd: _novaOrdem);
          }

          return RefreshIndicator(
            onRefresh: _carregar,
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _controller.items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final ordem = _controller.items[index];
                return Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(color: Colors.grey.shade200),
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: _statusColor(ordem.status).withAlpha(28),
                      child: Icon(
                        _statusIcon(ordem.status),
                        color: _statusColor(ordem.status),
                      ),
                    ),
                    title: Text(
                      ordem.clienteNome,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text('${ordem.status} | ${ordem.descricao}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _currencyFormat.format(ordem.valor),
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        IconButton(
                          tooltip: 'Excluir',
                          onPressed: () => _confirmarExclusao(ordem),
                          icon: const Icon(AppIcons.delete),
                        ),
                      ],
                    ),
                    onTap: () => _abrirDetalhe(ordem),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'em execução':
        return Colors.deepPurple;
      case 'executada':
        return Colors.green;
      default:
        return Colors.amber.shade800;
    }
  }

  IconData _statusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'em execução':
        return AppIcons.tools;
      case 'executada':
        return AppIcons.checkCircle;
      default:
        return AppIcons.pending;
    }
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onAdd;

  const _EmptyState({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(AppIcons.orders, size: 48),
            const SizedBox(height: 12),
            const Text('Nenhuma ordem cadastrada.'),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onAdd,
              icon: const Icon(AppIcons.add),
              label: const Text('Nova O.S.'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(AppIcons.refresh),
              label: const Text('Tentar novamente'),
            ),
          ],
        ),
      ),
    );
  }
}
