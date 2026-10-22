import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';

/// Shared dialogs and snackbars so confirmations look the same everywhere.
abstract final class AppFeedback {
  static void success(BuildContext context, String message) {
    _show(context, message, Icons.check_circle_outline, AppColors.forest);
  }

  static void error(BuildContext context, String message) {
    _show(context, message, Icons.error_outline, AppColors.criticalFg);
  }

  static void _show(
    BuildContext context,
    String message,
    IconData icon,
    Color color,
  ) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          backgroundColor: color,
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

  /// Returns true only when the user explicitly confirms.
  static Future<bool> confirm(
    BuildContext context, {
    required String title,
    required String message,
    required String confirmLabel,
    bool destructive = true,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: destructive
                ? FilledButton.styleFrom(backgroundColor: AppColors.criticalFg)
                : null,
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  static Future<bool> confirmDiscard(BuildContext context) => confirm(
    context,
    title: 'Discard changes?',
    message: 'You have unsaved changes. If you leave now they will be lost.',
    confirmLabel: 'Discard',
  );
}
