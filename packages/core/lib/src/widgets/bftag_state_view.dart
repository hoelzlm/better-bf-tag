// BftagStateView: geteiltes Lade-/Leer-/Fehlermuster (Designsystem §5.10).
// Pure presentational widget, no Riverpod/provider dependency (ADR 0027,
// "Gemeinsame Widgets").
import 'package:flutter/material.dart';

/// Shared loading/empty/error pattern used across Web/App/Monitor
/// (Designsystem §5.10). Use the named constructors; the default
/// constructor is private so call sites always pick one of the three
/// states explicitly.
class BftagStateView extends StatelessWidget {
  const BftagStateView._({
    super.key,
    required this.kind,
    this.message,
    this.title,
    this.icon,
    this.action,
    this.onRetry,
    this.retryLabel,
  });

  /// Centered `CircularProgressIndicator` (`primary`), optional message
  /// below it.
  const BftagStateView.loading({Key? key, String? message})
    : this._(key: key, kind: _StateKind.loading, message: message);

  /// Icon (48 px) + `titleMedium` title + optional `bodyMedium` message +
  /// optional primary action.
  const BftagStateView.empty({
    Key? key,
    required String title,
    String? message,
    IconData icon = Icons.inbox_outlined,
    Widget? action,
  }) : this._(
         key: key,
         kind: _StateKind.empty,
         title: title,
         message: message,
         icon: icon,
         action: action,
       );

  /// `Icons.warning_amber_outlined` in `colorScheme.error` (the `warning`
  /// token — a load/server error is NOT an alarm, Grundprinzip 1) + text +
  /// retry button.
  const BftagStateView.error({
    Key? key,
    required String message,
    required VoidCallback onRetry,
    String retryLabel = 'Erneut versuchen',
  }) : this._(
         key: key,
         kind: _StateKind.error,
         message: message,
         onRetry: onRetry,
         retryLabel: retryLabel,
       );

  final _StateKind kind;
  final String? message;
  final String? title;
  final IconData? icon;
  final Widget? action;
  final VoidCallback? onRetry;
  final String? retryLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    switch (kind) {
      case _StateKind.loading:
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: theme.colorScheme.primary),
              if (message != null) ...[
                const SizedBox(height: 16),
                Text(
                  message!,
                  style: theme.textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        );
      case _StateKind.empty:
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 48,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(height: 16),
                Text(
                  title!,
                  style: theme.textTheme.titleMedium,
                  textAlign: TextAlign.center,
                ),
                if (message != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    message!,
                    style: theme.textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                ],
                if (action != null) ...[
                  const SizedBox(height: 16),
                  action!,
                ],
              ],
            ),
          ),
        );
      case _StateKind.error:
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.warning_amber_outlined,
                  size: 48,
                  color: theme.colorScheme.error,
                ),
                const SizedBox(height: 16),
                Text(
                  message!,
                  style: theme.textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: onRetry,
                  child: Text(retryLabel!),
                ),
              ],
            ),
          ),
        );
    }
  }
}

enum _StateKind { loading, empty, error }
