import 'package:flutter/material.dart';

Widget getPlatformImage(String path, {double? height, double? width, BoxFit fit = BoxFit.cover}) {
  return Container(
    height: height,
    width: width,
    color: Colors.grey[200],
    child: const Icon(Icons.broken_image, color: Colors.grey),
  );
}
