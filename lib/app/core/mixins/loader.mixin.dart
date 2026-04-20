import 'package:flutter/material.dart';

mixin LoaderMixin {
  bool _isLoaderOpen = false;

  void showLoading(BuildContext context) {
    if (_isLoaderOpen) return;
    _isLoaderOpen = true;

    showDialog(
      context: context,
      barrierDismissible: false, // Impede fechar ao clicar fora
      builder: (context) {
        return PopScope(
          canPop: false, // Impede fechar pelo botão voltar do Android
          child: Center(
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  const CircularProgressIndicator(),
                  ElevatedButton(
                    onPressed: () => hideLoading(context),
                    child: const Text("Para o Loader"),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void hideLoading(BuildContext context) {
    if (_isLoaderOpen) {
      Navigator.of(context, rootNavigator: true).pop();
      _isLoaderOpen = false;
    }
  }
}
