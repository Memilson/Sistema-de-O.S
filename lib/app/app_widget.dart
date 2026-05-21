import 'package:flutter/material.dart';
import 'app_routes.dart';
import 'core/theme/app_theme.dart';

class AppWidget extends StatelessWidget {
  const AppWidget({super.key});

  String _resolveInitialRoute() {
    final path = Uri.base.path;
    if (AppRoutes.routes.containsKey(path)) return path;
    return AppRoutes.splash;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ServiceFlow',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      initialRoute: _resolveInitialRoute(),
      routes: AppRoutes.routes,
    );
  }
}
