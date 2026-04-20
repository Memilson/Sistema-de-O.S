import 'dart:async';
import 'package:flutter/material.dart';

import '../../../../app_routes.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
  }

  void iniciaTimer(int maxSeconds) {
    _timer = Timer(Duration(seconds: maxSeconds), () {
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed(AppRoutes.login);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Recuperamos o objeto e avisamos ao Flutter: "Trate isso como um OrdemServico"
    final maxSeconds = ModalRoute.of(context)!.settings.arguments as int? ?? 7;
    iniciaTimer(maxSeconds);

    return const Scaffold(
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('ServiceFlow', style: TextStyle(fontSize: 20)),
              SizedBox(height: 8),
              Text('Carregando...'),
            ],
          ),
        ),
      ),
    );
  }
}
