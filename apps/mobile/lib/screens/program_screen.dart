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
/// highlighted with a "Jetzt" chip, past items (`isPastProgramItem`) are
/// greyed out. The highlight is driven by [programNowProvider], ticking
/// every 30 s.
class ProgramScreen extends ConsumerWidget {
  const ProgramScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items =
        ref.watch(pairedProgramItemsProvider).valueOrNull ??
        const <ProgramItem>[];
    final now = ref.watch(programNowProvider).valueOrNull ?? DateTime.now();

    return Scaffold(
      appBar: AppBar(title: const Text('Tagesablauf')),
      body: items.isEmpty
          ? const Center(child: Text('Kein Tagesablauf vorhanden.'))
          : ListView.builder(
              key: const Key('program-list'),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                final isCurrent = isCurrentProgramItem(item, now);
                final isPast = !isCurrent && isPastProgramItem(item, now);

                final tile = ListTile(
                  leading: Icon(_iconForType(item.type)),
                  title: Text(item.title),
                  subtitle: Text(
                    '${_formatTime(item.startsAt)}–${_formatTime(item.endsAt)} · ${item.type.label}',
                  ),
                  trailing: isCurrent ? const Chip(label: Text('Jetzt')) : null,
                );

                if (isCurrent) {
                  return Card(
                    key: Key('program-current-${item.id}'),
                    color: Theme.of(context).colorScheme.primaryContainer,
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
