// FmsBadge: Status-Chip / FMS-Badge (Designsystem §5.5, Tabelle 2.4).
// Pure presentational widget, no Riverpod/provider dependency (ADR 0027,
// "Gemeinsame Widgets").
import 'package:flutter/material.dart';

import '../domain/fms_status.dart';
import '../theme.dart';

/// Renders a vehicle's FMS status as a pill: number + German label, always
/// (never color-only, Designsystem §5.5 / WCAG 1.4.1). Optionally prefixed
/// by the vehicle name in `onSurface`.
class FmsBadge extends StatelessWidget {
  const FmsBadge({
    super.key,
    required this.status,
    this.vehicleName,
    this.large = false,
  });

  /// The FMS status to display.
  final FmsStatus status;

  /// Optional vehicle name, rendered before the pill in `onSurface`.
  final String? vehicleName;

  /// Monitor sizing (56 px min height) instead of the Web/App default
  /// (24 dp min height), Designsystem §5.5.
  final bool large;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusColors = theme.extension<BftagStatusColors>()!;
    final radii = theme.extension<BftagRadii>() ?? const BftagRadii();
    final background = statusColors.colorFor(status);
    final onBackground = statusColors.onColorFor(status);
    final isDark = theme.brightness == Brightness.dark;
    final text = '${status.code} ${status.label}';
    final semanticsLabel = vehicleName != null && vehicleName!.isNotEmpty
        ? '$vehicleName Status ${status.code} ${status.label}'
        : 'Status ${status.code} ${status.label}';

    final pill = Container(
      constraints: BoxConstraints(minHeight: large ? 56 : 24),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(radii.full),
        border: isDark
            ? Border.all(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.24),
                width: 1,
              )
            : null,
      ),
      alignment: Alignment.center,
      child: Text(
        text,
        style:
            (large ? theme.textTheme.titleMedium : theme.textTheme.labelLarge)
                ?.copyWith(color: onBackground),
      ),
    );

    final content = vehicleName != null && vehicleName!.isNotEmpty
        ? Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                vehicleName!,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(width: 8),
              pill,
            ],
          )
        : pill;

    return Semantics(
      label: semanticsLabel,
      child: ExcludeSemantics(child: content),
    );
  }
}
