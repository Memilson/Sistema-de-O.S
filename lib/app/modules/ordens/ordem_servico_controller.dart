import '../../core/view_models/base_view_model.dart';
import 'ordem_servico.model.dart';
import 'ordem_servico_repository.dart';

class OrdemServicoController extends BaseViewModel<OrdemServico> {
  final OrdemServicoRepository ordemRepository;

  OrdemServicoController(this.ordemRepository) : super(ordemRepository);

  Future<void> atualizarStatus(OrdemServico ordem, String status) async {
    isLoading = true;
    notifyListeners();
    try {
      await ordemRepository.atualizarStatus(ordem, status);
      await carregar();
      errorMessage = null;
    } catch (e) {
      errorMessage = e.toString();
      isLoading = false;
      notifyListeners();
    }
  }
}
