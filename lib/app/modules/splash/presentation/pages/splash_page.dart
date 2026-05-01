import 'dart:async';
import 'package:flutter/material.dart';
import 'package:serviceflow/app/shared/widgets/app_logo.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../app_routes.dart';
class SplashPage extends StatefulWidget {
  final int maxSeconds;
  const SplashPage({super.key, this.maxSeconds = 2});
  @override
  State<SplashPage> createState() => _SplashPageState();
}
class _SplashPageState extends State<SplashPage> with SingleTickerProviderStateMixin {
  Timer? _timer;
  late final AnimationController _fadeController;
  late final Animation<double> _fadeAnimation;
  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _fadeAnimation = CurvedAnimation(parent: _fadeController, curve: Curves.easeIn);
    _fadeController.forward();
    _timer = Timer(Duration(seconds: widget.maxSeconds), () {
      if (!mounted) return;
      final route = Supabase.instance.client.auth.currentSession == null
          ? AppRoutes.login
          : AppRoutes.dashboard;
      Navigator.of(context).pushReplacementNamed(route);
    });
  }
  @override
  void dispose() {
    _timer?.cancel();
    _fadeController.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0078D4), Color(0xFF005A9E)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const AppLogo(width: 120, height: 120),
                  const SizedBox(height: 32),
                  const Text('ServiceFlow', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: Colors.white)),
                  const SizedBox(height: 8),
                  Text('Gestão de Ordens de Serviço', style: TextStyle(fontSize: 14, color: Colors.white.withAlpha(200))),
                  const SizedBox(height: 40),
                  const SizedBox(width: 28, height: 28, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
