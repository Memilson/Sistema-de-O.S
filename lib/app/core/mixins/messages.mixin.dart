import 'package:flutter/material.dart';

mixin MessagesMixin {
  void showSuccess(BuildContext context, String message) {
    _showSnackBar(context, message, Colors.green, Icons.check_circle);
  }

  void showError(BuildContext context, String message) {
    _showSnackBar(context, message, Colors.redAccent, Icons.error);
  }

  void _showSnackBar(
      BuildContext context, String message, Color color, IconData icon) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        content: Row(
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
      ),
    );
  }
}
