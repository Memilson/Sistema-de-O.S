import '../../core/view_models/base_view_model.dart';
import 'cliente.model.dart';
import 'cliente_repository.dart';
  // Gerencia o estado da UI para o módulo de clientes
class ClienteController extends BaseViewModel<Cliente> {
  ClienteController(ClienteRepository super.repository);
}
