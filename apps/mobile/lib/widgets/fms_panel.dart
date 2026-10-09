import 'package:bftag_core/bftag_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// FMS-Bedienteil (ADR 0015): dark Funkgerät-Optik housing with one key
/// per `offeredStatuses(vehicle.type)` (so 7/8 only show for RTW/KTW).
/// Tapping a key shows a pending spinner on it and calls
/// [VehicleAdminRepository.setStatus]; no optimistic update -- the
/// highlighted key only changes via the realtime `vehicle.status_changed`
/// event reflected in [vehicle]. Errors show a [SnackBar] with
/// [describeSetStatusError].
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

  Widget _buildKey(FmsStatus status) {
    final isCurrent = status == widget.vehicle.status;
    final isPending = _pendingCode == status.code;
    return Material(
      color: isCurrent ? Colors.amber : const Color(0xFF2A2A2A),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        key: Key('fms-${status.code}'),
        borderRadius: BorderRadius.circular(8),
        onTap: isPending ? null : () => _tap(status.code),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 72),
          child: Center(
            child: isPending
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${status.code}',
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        status.label,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final statuses = offeredStatuses(widget.vehicle.type);
    return Container(
      key: const Key('fms-panel'),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        borderRadius: BorderRadius.circular(16),
      ),
      child: GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 1.4,
        children: [for (final status in statuses) _buildKey(status)],
      ),
    );
  }
}
