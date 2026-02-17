import 'package:flutter/material.dart';

class ErrorBanner {
  static MaterialBanner build(
    BuildContext context, {
    required String message,
    VoidCallback? onDismiss,
  }) {
    return MaterialBanner(
      backgroundColor: Colors.red.withOpacity(0.08),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: onDismiss ??
              () => ScaffoldMessenger.of(context).hideCurrentMaterialBanner(),
          child: const Text("OK"),
        ),
      ],
    );
  }
}
