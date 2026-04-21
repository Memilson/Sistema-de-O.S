import 'package:flutter/material.dart';

mixin LoaderMixin {
  bool _isLoaderOpen = false;

  void showLoading(BuildContext context) {
    if (_isLoaderOpen) return;
    _isLoaderOpen = true;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return PopScope(
          canPop: false,
          child: Center(
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const SizedBox(
                width: 42,
                height: 42,
                child: CircularProgressIndicator(strokeWidth: 3),
              ),
            ),
          ),
        );
      },
    );
  }

  void hideLoading(BuildContext context) {
    if (_isLoaderOpen) {
      final navigator = Navigator.of(context, rootNavigator: true);
      if (navigator.canPop()) {
        navigator.pop();
      }
      _isLoaderOpen = false;
    }
  }
}
