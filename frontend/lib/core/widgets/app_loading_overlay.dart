import 'package:flutter/material.dart';

class AppLoadingOverlay {
  static bool _isShowing = false;

  static void show(BuildContext context, {String message = 'Cargando…'}) {
    if (_isShowing) return;
    _isShowing = true;

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _LoadingDialog(message: message),
    );
  }

  static void hide(BuildContext context) {
    if (!_isShowing) return;
    _isShowing = false;

    final nav = Navigator.of(context, rootNavigator: true);
    if (nav.canPop()) nav.pop();
  }
}

class _LoadingDialog extends StatelessWidget {
  final String message;
  const _LoadingDialog({required this.message});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Dialog(
      backgroundColor: scheme.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2.6),
            ),
            const SizedBox(width: 14),
            Flexible(
              child: Text(
                message,
                style: TextStyle(
                  color: scheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
