import 'dart:io';
import 'package:flutter/material.dart';

Widget getPlatformImage(String path, {double? height, double? width, BoxFit fit = BoxFit.cover}) {
  final file = File(path);
  if (file.existsSync()) {
    return Image.file(
      file,
      height: height,
      width: width,
      fit: fit,
      errorBuilder: (_, __, ___) => Container(
        height: height,
        width: width,
        color: Colors.grey[200],
        child: const Icon(Icons.broken_image, color: Colors.grey),
      ),
    );
  }
  return Container(
    height: height,
    width: width,
    color: Colors.grey[200],
    child: const Icon(Icons.broken_image, color: Colors.grey),
  );
}
