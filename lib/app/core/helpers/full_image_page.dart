import 'package:flutter/material.dart';
import '../../shared/widgets/app_back_button.dart';
import 'image_loader.dart';

class FullImagePage extends StatelessWidget {
  final String path;
  final String title;

  const FullImagePage({super.key, required this.path, this.title = 'Visualizar Imagem'});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        leading: const AppBackButton(color: Colors.white),
        title: Text(title, style: const TextStyle(color: Colors.white)),
      ),
      body: Center(
        child: InteractiveViewer(
          minScale: 0.5,
          maxScale: 4.0,
          child: SafeImage(
            path: path,
            fit: BoxFit.contain,
            width: double.infinity,
            height: double.infinity,
          ),
        ),
      ),
    );
  }
}
