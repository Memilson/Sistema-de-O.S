import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../helpers/app.config.dart';
import '../services/evidence_storage_service.dart';
import 'image_platform_loader.dart';
import 'full_image_page.dart';

/// A widget that safely displays images from various sources (Base64, URL, Supabase path, or Local File).
/// It handles the 'dart:io' limitation on Web.
class SafeImage extends StatelessWidget {
  final String path;
  final double? height;
  final double? width;
  final BoxFit fit;
  final bool clickable;

  const SafeImage({
    super.key,
    required this.path,
    this.height,
    this.width,
    this.fit = BoxFit.cover,
    this.clickable = false,
  });

  @override
  Widget build(BuildContext context) {
    Widget image;
    if (path.isEmpty) {
      image = _errorWidget();
    } else if (path.startsWith('data:image')) {
      try {
        final base64String = path.split(',').last;
        image = Image.memory(
          base64Decode(base64String),
          height: height,
          width: width,
          fit: fit,
          errorBuilder: (_, __, ___) => _errorWidget(),
        );
      } catch (_) {
        image = _errorWidget();
      }
    } else if (path.startsWith('http')) {
      image = Image.network(
        path,
        height: height,
        width: width,
        fit: fit,
        errorBuilder: (_, __, ___) => _errorWidget(),
      );
    } else if (_isRawBase64(path)) {
      try {
        image = Image.memory(
          base64Decode(path),
          height: height,
          width: width,
          fit: fit,
          errorBuilder: (_, __, ___) => _errorWidget(),
        );
      } catch (_) {
        image = _errorWidget();
      }
    } else if (path.contains('/') && !path.startsWith('/') && !path.startsWith('assets/') && !path.contains('\\')) {
      // Supabase path
      image = FutureBuilder<String>(
        future: _getSupabaseUrl(path),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return SizedBox(
              height: height,
              width: width,
              child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
            );
          }
          if (snapshot.hasData && snapshot.data != null) {
            return Image.network(
              snapshot.data!,
              height: height,
              width: width,
              fit: fit,
              errorBuilder: (context, error, stackTrace) {
                if (!kIsWeb) return getPlatformImage(path, height: height, width: width, fit: fit);
                return _errorWidget();
              },
            );
          }
          if (!kIsWeb) return getPlatformImage(path, height: height, width: width, fit: fit);
          return _errorWidget();
        },
      );
    } else {
      // Local path
      image = getPlatformImage(path, height: height, width: width, fit: fit);
    }

    if (clickable && path.isNotEmpty) {
      return GestureDetector(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => FullImagePage(path: path)),
        ),
        child: image,
      );
    }

    return image;
  }

  Future<String> _getSupabaseUrl(String path) async {
    try {
      final client = Supabase.instance.client;
      // Since bucket is private, we need a signed URL
      return await client.storage.from(EvidenceStorageService.bucketName).createSignedUrl(path, 3600);
    } catch (e) {
      // Fallback to public URL if signed fails (though migration says it's private)
      return '${AppConfig.supabaseUrl}/storage/v1/object/public/${EvidenceStorageService.bucketName}/$path';
    }
  }

  bool _isRawBase64(String str) {
    if (str.length < 20) return false; // Too short for a typical image
    if (str.contains(' ') || str.contains('\n') || str.contains('\r')) return false;
    // Common start for PNG/JPG in base64
    if (str.startsWith('iVBOR') || str.startsWith('/9j/')) return true;
    
    // Generic check
    final RegExp base64RegExp = RegExp(r'^[a-zA-Z0-9+/]*={0,2}$');
    return str.length % 4 == 0 && base64RegExp.hasMatch(str);
  }

  Widget _errorWidget() {
    return Container(
      height: height,
      width: width,
      color: Colors.grey[200],
      child: const Icon(Icons.broken_image, color: Colors.grey),
    );
  }
}
