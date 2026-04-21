import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../app_routes.dart';
import '../../../../core/services/offline_sync_service.dart';
import '../../../../core/services/service_locator.dart';
import '../../../../core/services/whatsapp_service.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../auth/auth_repository.dart';
import '../../../ordens/ordem_servico.model.dart';
import '../../../ordens/ordem_servico_repository.dart';
class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});
  @override
  State<DashboardPage> createState() => _DashboardPageState();
}
class _DashboardPageState extends State<DashboardPage> {
  static final _currencyFormat = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
  final _authRepository = ServiceLocator.instance.get<AuthRepository>();
  final _ordemServicoRepository = ServiceLocator.instance.get<OrdemServicoRepository>();
  final _syncService = ServiceLocator.instance.get<OfflineSyncService>();
  final _whatsappService = ServiceLocator.instance.get<WhatsappService>();
  List<_DashboardOrder> _orders = [];
  _OrderStatus? _selectedStatus;
  bool _loading = true;
  String? _error;
  int _syncPending = 0;
  @override
  void initState() {
    super.initState();
    _loadOrders();
  }
  List<_DashboardOrder> get _filteredOrders {
    if (_selectedStatus == null) return _orders;
    return _orders.where((order) => order.status == _selectedStatus).toList();
  }
  double _totalFor(_OrderStatus? status) {
    return _orders.where((order) => status == null || order.status == status).fold(0, (total, order) => total + order.value);
  }
  int _countFor(_OrderStatus? status) {
    if (status == null) return _orders.length;
    return _orders.where((order) => order.status == status).length;
  }
  void _selectStatus(_OrderStatus? status) {
    setState(() => _selectedStatus = _selectedStatus == status ? null : status);
  }
  Future<void> _loadOrders() async {
    setState(() { _loading = true; _error = null; });
    try {
      await _syncService.syncPending();
      final ordens = await _ordemServicoRepository.listar();
      final pending = await _syncService.countPending();
      if (!mounted) return;
      setState(() { _orders = ordens.map(_DashboardOrder.fromOrdemServico).toList(); _syncPending = pending; _loading = false; });
    } catch (_) {
      if (!mounted) return;
      setState(() { _loading = false; _error = 'Não foi possível carregar as ordens de serviço.'; });
    }
  }
  Future<void> _openAndReload(String routeName) async {
    await Navigator.pushNamed(context, routeName);
    if (!mounted) return;
    _loadOrders();
  }
  Future<void> _logout() async {
    await _authRepository.logout();
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, AppRoutes.login);
  }
  Future<void> _abrirWhatsapp() async {
    final opened = await _whatsappService.abrirSuporte();
    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Configure SUPPORT_WHATSAPP no .env.')));
    }
  }
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          if (_syncPending > 0)
            Center(child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: Colors.orange, borderRadius: BorderRadius.circular(4)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(AppIcons.sync, size: 14, color: Colors.white),
                const SizedBox(width: 4),
                Text('$_syncPending', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white)),
              ]),
            )),
          IconButton(tooltip: 'Clientes', onPressed: () => _openAndReload(AppRoutes.clientes), icon: const Icon(AppIcons.customers)),
          IconButton(tooltip: 'Ordens', onPressed: () => _openAndReload(AppRoutes.ordens), icon: const Icon(AppIcons.orders)),
          IconButton(tooltip: 'Nova O.S.', onPressed: () => _openAndReload(AppRoutes.novaOs), icon: const Icon(AppIcons.taskAdd)),
          IconButton(tooltip: 'WhatsApp', onPressed: _abrirWhatsapp, icon: const Icon(AppIcons.support)),
          IconButton(tooltip: 'Sair', onPressed: _logout, icon: const Icon(AppIcons.logout)),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Gestão de O.S.', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text(
                _syncPending == 0
                    ? 'Resumo financeiro das ordens cadastradas.'
                    : '$_syncPending item(ns) aguardando sincronização.',
                style: theme.textTheme.bodyMedium?.copyWith(color: const Color(0xFF616161)),
              ),
              const SizedBox(height: 20),
              if (_loading)
                const Padding(padding: EdgeInsets.symmetric(vertical: 32), child: Center(child: CircularProgressIndicator()))
              else if (_error != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Column(children: [
                    Text(_error!, textAlign: TextAlign.center),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(onPressed: _loadOrders, icon: const Icon(AppIcons.refresh), label: const Text('Tentar novamente')),
                  ]),
                )
              else ...[
                LayoutBuilder(builder: (context, constraints) {
                  final columns = constraints.maxWidth >= 720 ? 4 : 2;
                  return GridView.count(
                    crossAxisCount: columns,
                    childAspectRatio: constraints.maxWidth >= 720 ? 1.4 : 1.15,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      _KpiCard(title: 'Total de OS', count: _countFor(null), value: _totalFor(null), icon: AppIcons.orders, color: const Color(0xFF0078D4), selected: _selectedStatus == null, formatter: _currencyFormat, onTap: () => _selectStatus(null)),
                      _KpiCard(title: 'Em aberto', count: _countFor(_OrderStatus.open), value: _totalFor(_OrderStatus.open), icon: AppIcons.pending, color: const Color(0xFFE8A317), selected: _selectedStatus == _OrderStatus.open, formatter: _currencyFormat, onTap: () => _selectStatus(_OrderStatus.open)),
                      _KpiCard(title: 'Em execução', count: _countFor(_OrderStatus.running), value: _totalFor(_OrderStatus.running), icon: AppIcons.tools, color: const Color(0xFF7B61FF), selected: _selectedStatus == _OrderStatus.running, formatter: _currencyFormat, onTap: () => _selectStatus(_OrderStatus.running)),
                      _KpiCard(title: 'Executada', count: _countFor(_OrderStatus.done), value: _totalFor(_OrderStatus.done), icon: AppIcons.checkCircle, color: const Color(0xFF2E7D32), selected: _selectedStatus == _OrderStatus.done, formatter: _currencyFormat, onTap: () => _selectStatus(_OrderStatus.done)),
                    ],
                  );
                }),
                const SizedBox(height: 24),
                Row(children: [
                  Expanded(child: Text(
                    _selectedStatus == null ? 'Ordens recentes' : 'Ordens ${_selectedStatus!.label.toLowerCase()}',
                    style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                  )),
                  if (_selectedStatus != null)
                    TextButton.icon(onPressed: () => _selectStatus(null), icon: const Icon(AppIcons.close, size: 18), label: const Text('Limpar')),
                ]),
                const SizedBox(height: 8),
                if (_filteredOrders.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Center(child: Text('Nenhuma ordem de serviço cadastrada.', style: theme.textTheme.bodyMedium?.copyWith(color: const Color(0xFF616161)))),
                  )
                else
                  ..._filteredOrders.map((order) => _OrderTile(order: order, formatter: _currencyFormat)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
class _KpiCard extends StatelessWidget {
  final String title;
  final int count;
  final double value;
  final IconData icon;
  final Color color;
  final bool selected;
  final NumberFormat formatter;
  final VoidCallback onTap;
  const _KpiCard({required this.title, required this.count, required this.value, required this.icon, required this.color, required this.selected, required this.formatter, required this.onTap});
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(4),
        side: BorderSide(color: selected ? color : const Color(0xFFE0E0E0), width: selected ? 2 : 1),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(4),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            border: Border(left: BorderSide(color: color, width: 4)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Icon(icon, color: color, size: 20),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(color: color.withAlpha(25), borderRadius: BorderRadius.circular(4)),
                  child: Text('$count', style: TextStyle(fontWeight: FontWeight.w700, color: color, fontSize: 14)),
                ),
              ]),
              const Spacer(),
              Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.textTheme.bodySmall?.copyWith(color: const Color(0xFF616161))),
              const SizedBox(height: 4),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(formatter.format(value), style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
class _OrderTile extends StatelessWidget {
  final _DashboardOrder order;
  final NumberFormat formatter;
  const _OrderTile({required this.order, required this.formatter});
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      child: ListTile(
        leading: Container(
          width: 40, height: 40,
          decoration: BoxDecoration(color: order.status.color.withAlpha(20), borderRadius: BorderRadius.circular(4)),
          child: Icon(order.status.icon, color: order.status.color, size: 20),
        ),
        title: Text('${order.code} - ${order.customer}', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        subtitle: Text(order.status.label, style: const TextStyle(fontSize: 12)),
        trailing: Text(formatter.format(order.value), style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
      ),
    );
  }
}
class _DashboardOrder {
  final String code;
  final String customer;
  final _OrderStatus status;
  final double value;
  const _DashboardOrder({required this.code, required this.customer, required this.status, required this.value});
  factory _DashboardOrder.fromOrdemServico(OrdemServico ordem) {
    final id = ordem.id ?? '';
    return _DashboardOrder(
      code: id.length >= 8 ? 'OS-${id.substring(0, 8)}' : 'OS-$id',
      customer: ordem.clienteNome,
      status: _OrderStatus.fromLabel(ordem.status),
      value: ordem.valor,
    );
  }
}
enum _OrderStatus {
  open('Em aberto', AppIcons.pending, Color(0xFFE8A317)),
  running('Em execução', AppIcons.tools, Color(0xFF7B61FF)),
  done('Executada', AppIcons.checkCircle, Color(0xFF2E7D32));
  final String label;
  final IconData icon;
  final Color color;
  const _OrderStatus(this.label, this.icon, this.color);
  static _OrderStatus fromLabel(String label) {
    return _OrderStatus.values.firstWhere(
      (status) => status.label.toLowerCase() == label.toLowerCase(),
      orElse: () => _OrderStatus.open,
    );
  }
}
