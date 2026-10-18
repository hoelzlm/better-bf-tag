import 'package:bftag_core/bftag_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../widgets/main_nav_bar.dart';

/// Ticks every 30 seconds, starting with [DateTime.now()], to drive the
/// "aktuell"/"vergangen" highlighting on [ProgramScreen] (ADR 0025).
/// Tests override this provider with a fixed/controlled stream to make
/// the highlight deterministic.
final programNowProvider = StreamProvider<DateTime>((ref) async* {
  yield DateTime.now();
  yield* Stream.periodic(const Duration(seconds: 30), (_) => DateTime.now());
});

/// Icon for a [ProgramItemType] (ADR 0025).
IconData _iconForType(ProgramItemType type) {
  switch (type) {
    case ProgramItemType.meal:
      return Icons.restaurant;
    case ProgramItemType.training:
      return Icons.school;
    case ProgramItemType.maintenance:
      return Icons.build;
    case ProgramItemType.rest:
      return Icons.bedtime;
    case ProgramItemType.other:
      return Icons.event;
  }
}

String _formatTime(DateTime time) {
  final local = time.toLocal();
  final hh = local.hour.toString().padLeft(2, '0');
  final mm = local.minute.toString().padLeft(2, '0');
  return '$hh:$mm';
}

/// Tagesablauf screen for `/tagesablauf` (ADR 0025): the sorted
/// Programmpunkte of the running BF-Tag from [pairedProgramItemsProvider]
/// (no own fetch); the current item(s) (`isCurrentProgramItem`) are
/// highlighted with a `primaryContainer` card + "Jetzt" chip, past items
/// (`isPastProgramItem`) are greyed out at 50% opacity. The highlight is
/// driven by [programNowProvider], ticking every 30 s.
///
/// Layout/states per `docs/design/screens/app-tagesablauf.md` §3/§4
/// (ADR 0027): theme tokens only, no hardcoded colours.
class ProgramScreen extends ConsumerWidget {
  const ProgramScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items =
        ref.watch(pairedProgramItemsProvider).valueOrNull ??
        const <ProgramItem>[];
    final now = ref.watch(programNowProvider).valueOrNull ?? DateTime.now();
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final radii = theme.extension<BftagRadii>()!;

    return Scaffold(
      appBar: AppBar(title: const Text('Tagesablauf')),
      body: items.isEmpty
          ? const BftagStateView.empty(
              icon: Icons.event_note_outlined,
              title: 'Kein Tagesablauf vorhanden.',
            )
          : ListView.separated(
              key: const Key('program-list'),
              itemCount: items.length,
              separatorBuilder: (context, index) =>
                  Divider(height: 1, color: colorScheme.outline),
              itemBuilder: (context, index) {
                final item = items[index];
                final isCurrent = isCurrentProgramItem(item, now);
                final isPast = !isCurrent && isPastProgramItem(item, now);

                final tile = ListTile(
                  minVerticalPadding: 12,
                  leading: Icon(
                    _iconForType(item.type),
                    color: isCurrent ? colorScheme.onPrimaryContainer : null,
                  ),
                  title: Text(
                    item.title,
                    style: isCurrent
                        ? TextStyle(color: colorScheme.onPrimaryContainer)
                        : null,
                  ),
                  subtitle: Text(
                    '${_formatTime(item.startsAt)}–${_formatTime(item.endsAt)} · ${item.type.label}',
                    style: isCurrent
                        ? TextStyle(color: colorScheme.onPrimaryContainer)
                        : null,
                  ),
                  trailing: isCurrent
                      ? Chip(
                          label: Text(
                            'Jetzt',
                            style: TextStyle(color: colorScheme.onPrimary),
                          ),
                          backgroundColor: colorScheme.primary,
                          side: BorderSide.none,
                        )
                      : null,
                );

                if (isCurrent) {
                  return Card(
                    key: Key('program-current-${item.id}'),
                    color: colorScheme.primaryContainer,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(radii.large),
                    ),
                    child: tile,
                  );
                }
                if (isPast) {
                  return Opacity(
                    key: Key('program-past-${item.id}'),
                    opacity: 0.5,
                    child: tile,
                  );
                }
                return KeyedSubtree(
                  key: Key('program-item-${item.id}'),
                  child: tile,
                );
              },
            ),
      bottomNavigationBar: const MainNavBar(currentIndex: 3),
    );
  }
}
