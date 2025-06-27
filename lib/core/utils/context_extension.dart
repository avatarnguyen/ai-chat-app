import 'package:flutter/material.dart';

extension BuildContextX on BuildContext {
  void showPopup(String message, {IconData? iconData}) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            if (iconData != null) ...[
              Icon(iconData, color: Colors.white),
              SizedBox(width: 8),
            ],
            Expanded(
              child: Text('Please check your email to verify your account'),
            ),
          ],
        ),
        backgroundColor: Colors.orange,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 5),
      ),
    );
  }

  double screenHeight([double factor = 1]) =>
      MediaQuery.sizeOf(this).height * factor;
  double screenWidth([double factor = 1]) =>
      MediaQuery.sizeOf(this).width * factor;
}
