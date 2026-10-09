import 'dart:async';

import 'package:bftag_core/bftag_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'alarm_sound.dart';
import 'pending_alarm.dart';

/// Wraps the app's `GoRouter`-driven widget tree: watches
/// [myPendingAlarmProvider] and navigates to `/alarm/:alarmId` whenever it
/// becomes a not-yet-shown Alarmierung (ADR 0017, "App im Vordergrund").
///
/// Starts the looping Ton only when the Alarmierung was learned about via
/// a live `alarm.triggered` ([pairedLiveAlarmTriggeredProvider]) -- one
/// found only via the snapshot (e.g. right after app start/reconnect)
/// shows the screen silently, so a reload never re-triggers the sound.
///
/// `AlarmScreen` itself is responsible for closing itself and stopping the
/// Ton once an Alarmierung stops being the Person's pending one
/// (acknowledged here/elsewhere, or its Einsatz left `running`).
class AlarmNavigationListener extends ConsumerStatefulWidget {
  const AlarmNavigationListener({
    super.key,
    required this.router,
    required this.child,
  });

  final GoRouter router;
  final Widget child;

  @override
  ConsumerState<AlarmNavigationListener> createState() =>
      _AlarmNavigationListenerState();
}

class _AlarmNavigationListenerState
    extends ConsumerState<AlarmNavigationListener> {
  final Set<String> _liveTriggeredAlarmIds = {};
  String? _shownAlarmId;

  void _syncPending(Alarm? pending) {
    if (!mounted) return;
    if (pending == null) {
      _shownAlarmId = null;
      return;
    }
    if (_shownAlarmId == pending.id) return;
    _shownAlarmId = pending.id;
    if (_liveTriggeredAlarmIds.remove(pending.id)) {
      unawaited(ref.read(alarmSoundProvider).play(loop: true));
    }
    widget.router.push('/alarm/${pending.id}');
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<Alarm>>(pairedLiveAlarmTriggeredProvider, (
      previous,
      next,
    ) {
      next.whenData((alarm) => _liveTriggeredAlarmIds.add(alarm.id));
    });

    final pending = ref.watch(myPendingAlarmProvider);
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncPending(pending));

    return widget.child;
  }
}
