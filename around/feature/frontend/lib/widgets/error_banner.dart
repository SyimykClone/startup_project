import 'package:flutter/material.dart';

import '../utils/app_error_text.dart';

class ErrorBanner {
  static MaterialBanner build(
    BuildContext context, {
    required String message,
    VoidCallback? onDismiss,
  }) {
    const base = Color(0xFF071C36);
    const danger = Color(0xFFD94848);

    return MaterialBanner(
      elevation: 0,
      backgroundColor: Colors.white,
      leading: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: danger.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.error_outline_rounded,
          color: danger,
          size: 22,
        ),
      ),
      content: Text(
        AppErrorText.fromMessage(context, message),
        style: const TextStyle(
          color: base,
          fontSize: 14,
          fontWeight: FontWeight.w700,
          height: 1.25,
        ),
      ),
      actions: [
        TextButton(
          onPressed: onDismiss ??
              () => ScaffoldMessenger.of(context).hideCurrentMaterialBanner(),
          style: TextButton.styleFrom(
            foregroundColor: base,
            textStyle: const TextStyle(fontWeight: FontWeight.w800),
          ),
          child: const Text('OK'),
        ),
      ],
    );
  }
}
