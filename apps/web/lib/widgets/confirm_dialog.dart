import 'package:flutter/material.dart';

/// Shows a yes/no [AlertDialog] and returns whether the user confirmed
/// (`true`), cancelled (`false`), or dismissed it (`null` -- treated like
/// cancel by callers). Used by every "really do X?" confirmation in the
/// Lage (ADR 0022: Auslösen/Verwerfen von geplanten/verpassten
/// Alarmierungen).
Future<bool?> showConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
  Key confirmKey = const Key('confirm-dialog-confirm'),
}) {
  return showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Abbrechen'),
        ),
        FilledButton(
          key: confirmKey,
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
}
