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
    final maxSeconds = ModalRoute.of(context)!.settings.arguments as int? ?? 7;
    iniciaTimer(maxSeconds);
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0078D4), Color(0xFF005A9E)],
          ),
        ),
        child: const SafeArea(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(width: 28, height: 28, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
                SizedBox(height: 16),
                Text('ServiceFlow', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: Colors.white)),
                SizedBox(height: 8),
                Text('Carregando...', style: TextStyle(color: Colors.white70)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
