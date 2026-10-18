import 'package:bftag_core/bftag_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// FMS-Bedienteil (ADR 0015): one tile per `offeredStatuses(vehicle.type)`
/// (so 7/8 only show for RTW/KTW). Tapping a tile shows a pending spinner
/// on it and calls [VehicleAdminRepository.setStatus]; no optimistic
/// update -- the highlighted tile only changes via the realtime
/// `vehicle.status_changed` event reflected in [vehicle]. Errors show a
/// [SnackBar] with [describeSetStatusError]. Token styling per
/// `docs/design/screens/app-mein-fahrzeug.md` §3/§4: inactive tiles
/// `surfaceContainer`/`onSurface`, the active tile uses the fixed FMS
/// token colour (`BftagStatusColors`), min height 96dp, `lg` (16px)
/// spacing both axes, and a 1px `onSurface`-at-24%-opacity border on
/// dark mode (Designsystem §2.4/§5.5).
class FmsPanel extends ConsumerStatefulWidget {
  const FmsPanel({super.key, required this.vehicle});

  final Vehicle vehicle;

  @override
  ConsumerState<FmsPanel> createState() => _FmsPanelState();
}

class _FmsPanelState extends ConsumerState<FmsPanel> {
  int? _pendingCode;

  Future<void> _tap(int code) async {
    setState(() => _pendingCode = code);
    try {
      await ref
          .read(vehicleAdminRepositoryProvider)
          .setStatus(widget.vehicle.id, code);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(describeSetStatusError(error))),
      );
    } finally {
      if (mounted) {
        setState(() => _pendingCode = null);
      }
    }
  }

  Widget _buildTile(FmsStatus status, ThemeData theme) {
    final statusColors = theme.extension<BftagStatusColors>()!;
    final isCurrent = status == widget.vehicle.status;
    final isPending = _pendingCode == status.code;
    final isDark = theme.brightness == Brightness.dark;

    final background = isCurrent
        ? statusColors.colorFor(status)
        : theme.colorScheme.surfaceContainerHighest;
    final foreground = isCurrent
        ? statusColors.onColorFor(status)
        : theme.colorScheme.onSurface;

    return Material(
      color: background,
      borderRadius: BorderRadius.circular(theme.extension<BftagRadii>()!.medium),
      child: InkWell(
        key: Key('fms-${status.code}'),
        borderRadius: BorderRadius.circular(
          theme.extension<BftagRadii>()!.medium,
        ),
        onTap: isPending ? null : () => _tap(status.code),
        child: Container(
          decoration: isDark
              ? BoxDecoration(
                  borderRadius: BorderRadius.circular(
                    theme.extension<BftagRadii>()!.medium,
                  ),
                  border: Border.all(
                    color: theme.colorScheme.onSurface.withValues(
                      alpha: 0.24,
                    ),
                    width: 1,
                  ),
                )
              : null,
          alignment: Alignment.center,
          child: isPending
              ? SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: foreground,
                  ),
                )
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${status.code}',
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: foreground,
                      ),
                    ),
                    Text(
                      status.label,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: foreground,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final spacing = theme.extension<BftagSpacing>()!;
    final statuses = offeredStatuses(widget.vehicle.type);
    return Container(
      key: const Key('fms-panel'),
      child: GridView(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: spacing.lg,
          crossAxisSpacing: spacing.lg,
          mainAxisExtent: 96,
        ),
        children: [for (final status in statuses) _buildTile(status, theme)],
      ),
    );
  }
}
