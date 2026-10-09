import 'package:bftag_core/bftag_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The `triggered` Alarmierungen of the currently paired session's
/// realtime state (ADR 0017), mirroring [alarmsProvider] but bound to
/// [pairedRealtimeClientProvider] like [pairedIncidentsProvider] --
/// `alarmsProvider`/`liveAlarmTriggeredProvider` in `bftag_core` are tied
/// to the web admin session and don't apply to a paired mobile device.
final pairedAlarmsProvider = StreamProvider<List<Alarm>>((ref) {
  final client = ref.watch(pairedRealtimeClientProvider);
  if (client == null) {
    return Stream.value(const <Alarm>[]);
  }
  return client.states.map((state) => state.alarms);
});

/// Emits an [Alarm] only for `alarm.triggered` events received live over
/// the paired session's WebSocket (ADR 0017) -- never for Alarmierungen
/// loaded via the snapshot. Drives whether [myPendingAlarmProvider]
/// becoming non-null should also start the Ton. Mirrors
/// [liveAlarmTriggeredProvider] for the paired session.
final pairedLiveAlarmTriggeredProvider = StreamProvider<Alarm>((ref) {
  final client = ref.watch(pairedRealtimeClientProvider);
  if (client == null) {
    return const Stream<Alarm>.empty();
  }
  return client.liveAlarmTriggered;
});

/// The oldest Alarmierung of a `running` Einsatz in which the signed-in
/// Person is a recipient who hasn't acknowledged yet (ADR 0017, "App im
/// Vordergrund"). `null` while unpaired or when there is none.
///
/// Purely derived from [pairedAlarmsProvider] (itself derived from
/// snapshot + realtime events), so it keeps working across app
/// restart/reconnect without any extra request. [pairedAlarmsProvider]
/// already only contains Alarmierungen of `running` Einsätze (ADR 0017:
/// the realtime client drops an Einsatz's Alarmierungen once it leaves
/// `running`) and is sorted by `triggered_at`, so the first match here is
/// the oldest.
final myPendingAlarmProvider = Provider<Alarm?>((ref) {
  final session = ref.watch(pairedSessionControllerProvider);
  if (session is! Paired) {
    return null;
  }
  final personId = session.person.id;
  final alarms = ref.watch(pairedAlarmsProvider).valueOrNull ?? const [];
  for (final alarm in alarms) {
    final isPendingForMe = alarm.recipients.any(
      (recipient) =>
          recipient.personId == personId && recipient.acknowledgedAt == null,
    );
    if (isPendingForMe) {
      return alarm;
    }
  }
  return null;
});
