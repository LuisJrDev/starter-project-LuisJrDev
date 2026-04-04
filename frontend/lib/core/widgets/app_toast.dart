import 'package:flutter/material.dart';

class AppToast {
  static void showError(BuildContext context, String message) {
    final scheme = Theme.of(context).colorScheme;

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: scheme.errorContainer,
        content: Text(
          message,
          style: TextStyle(color: scheme.onErrorContainer),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.all(12),
      ),
    );
  }

  static void showSuccess(BuildContext context, String message) {
    final scheme = Theme.of(context).colorScheme;

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: scheme.primaryContainer,
        content: Text(
          message,
          style: TextStyle(color: scheme.onPrimaryContainer),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.all(12),
      ),
    );
  }
}
