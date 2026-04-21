import 'package:flutter/material.dart';
class AppLogo extends StatelessWidget {
  final double width;
  final double height;
  const AppLogo({super.key, this.width = 150, this.height = 150});
  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/logo.png',
      width: width,
      height: height,
      fit: BoxFit.contain,);}}