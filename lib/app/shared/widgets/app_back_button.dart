import 'package:flutter/material.dart';

import '../../core/theme/app_icons.dart';

class AppBackButton extends StatelessWidget {
  const AppBackButton({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Voltar',
      onPressed: () => Navigator.of(context).maybePop(),
      icon: const Icon(AppIcons.back),
    );
  }
}
