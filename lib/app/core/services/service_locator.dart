class ServiceLocator {
  static final ServiceLocator instance = ServiceLocator._();
  final Map<Type, Object> _instances = {};
  ServiceLocator._();
  void registerSingleton<T extends Object>(T instance) {
    _instances[T] = instance;
  }
  T get<T extends Object>() {
    final instance = _instances[T];
    if (instance == null) throw StateError('Dependencia $T nao registrada');
    return instance as T;
  }
}
