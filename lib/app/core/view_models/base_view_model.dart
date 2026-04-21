import 'package:flutter/foundation.dart';

import '../base/base.model.dart';
import '../repositories/base_repository.dart';

class BaseViewModel<T extends BaseModel> extends ChangeNotifier {
  final BaseRepository<T> repository;

  BaseViewModel(this.repository);

  bool isLoading = false;
  String? errorMessage;
  List<T> items = [];

  Future<void> carregar() async {
    _setLoading(true);
    try {
      items = await repository.listar();
      errorMessage = null;
    } catch (e) {
      errorMessage = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> salvar(T item) async {
    _setLoading(true);
    try {
      await repository.salvar(item);
      await carregar();
      errorMessage = null;
    } catch (e) {
      errorMessage = e.toString();
      _setLoading(false);
    }
  }

  Future<void> excluir(String id) async {
    _setLoading(true);
    try {
      await repository.excluir(id);
      await carregar();
      errorMessage = null;
    } catch (e) {
      errorMessage = e.toString();
      _setLoading(false);
    }
  }

  void _setLoading(bool value) {
    isLoading = value;
    notifyListeners();
  }
}
