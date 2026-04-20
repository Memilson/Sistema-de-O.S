import 'package:flutter/material.dart';

class AppLogo extends StatelessWidget {
  final double width;
  final double height;

  // Passando dimensões padrão que podem ser alteradas
  const AppLogo({super.key, this.width = 150, this.height = 150});

  @override
  Widget build(BuildContext context) {
    // Carrega a imagem registrada no pubspec.yaml
    return Image.asset(
      'assets/images/logo.png',
      width: width,
      height: height,
      fit: BoxFit.contain, // Garante que a imagem caiba sem distorcer
    );
  }
}
