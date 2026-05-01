import 'package:flutter/material.dart';
import '../../core/theme/app_icons.dart';
class AppBackButton extends StatelessWidget {
  final Color? color;
  const AppBackButton({super.key, this.color});
  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Voltar',
      onPressed: () => Navigator.of(context).maybePop(),
      icon: Icon(AppIcons.back, color: color),
    );
  }
}
