import 'package:flutter/material.dart';
import '../../../../app_routes.dart';
import '../../../../core/services/service_locator.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../shared/widgets/app_back_button.dart';
import '../../cliente.model.dart';
import '../../cliente_controller.dart';
import '../../cliente_repository.dart';
class ClientesPage extends StatefulWidget {
  const ClientesPage({super.key});
  @override
  State<ClientesPage> createState() => _ClientesPageState();
}
class _ClientesPageState extends State<ClientesPage> {
  late final ClienteController _controller;
  @override
  void initState() {
    super.initState();
    _controller = ClienteController(ServiceLocator.instance.get<ClienteRepository>());
    _controller.carregar();
  }
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  Future<void> _abrirCadastro([Cliente? cliente]) async {
    await Navigator.pushNamed(context, AppRoutes.cadastroCliente, arguments: cliente);
    _controller.carregar();
  }
  Future<void> _confirmarExclusao(Cliente cliente) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir cliente'),
        content: Text('Deseja excluir ${cliente.nome}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Excluir')),
        ],
      ),
    );
    if (confirmed == true && cliente.id != null) {
      await _controller.excluir(cliente.id!);
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const AppBackButton(),
        title: const Text('Clientes'),
        actions: [
          IconButton(tooltip: 'Novo cliente', onPressed: () => _abrirCadastro(), icon: const Icon(AppIcons.addCustomer)),
        ],
      ),
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          if (_controller.isLoading && _controller.items.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (_controller.errorMessage != null) {
            return _ErrorState(message: 'Nao foi possivel carregar clientes.', onRetry: _controller.carregar);
          }
          if (_controller.items.isEmpty) {
            return _EmptyState(onAdd: () => _abrirCadastro());
          }
          return RefreshIndicator(
            onRefresh: _controller.carregar,
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _controller.items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final cliente = _controller.items[index];
                return Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: const Color(0xFFE0E0E0)),
                  ),
                  child: ListTile(
                    leading: Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(color: const Color(0xFF0078D4).withAlpha(20), borderRadius: BorderRadius.circular(4)),
                      child: const Icon(AppIcons.person, color: Color(0xFF0078D4), size: 20),
                    ),
                    title: Text(cliente.nome, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    subtitle: Text(
                      [cliente.cpfCnpj, cliente.email, cliente.telefone].where((v) => v.isNotEmpty).join(' | '),
                      style: const TextStyle(fontSize: 12),
                    ),
                    onTap: () => _abrirCadastro(cliente),
                    trailing: IconButton(tooltip: 'Excluir', onPressed: () => _confirmarExclusao(cliente), icon: const Icon(AppIcons.delete, size: 20)),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
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
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(AppIcons.customers, size: 48, color: Color(0xFF616161)),
          const SizedBox(height: 12),
          const Text('Nenhum cliente cadastrado.'),
          const SizedBox(height: 16),
          FilledButton.icon(onPressed: onAdd, icon: const Icon(AppIcons.add), label: const Text('Novo cliente')),
        ]),
      ),
    );
  }
}
class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorState({required this.message, required this.onRetry});
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          OutlinedButton.icon(onPressed: onRetry, icon: const Icon(AppIcons.refresh), label: const Text('Tentar novamente')),
        ]),
      ),
    );
  }
}
