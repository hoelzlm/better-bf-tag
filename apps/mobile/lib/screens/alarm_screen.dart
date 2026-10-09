import 'dart:async';

import 'package:bftag_core/bftag_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../alarm/alarm_sound.dart';
import '../alarm/pending_alarm.dart';

Incident? _findIncident(List<Incident> incidents, String id) {
  for (final incident in incidents) {
    if (incident.id == id) return incident;
  }
  return null;
}

Alarm? _findAlarm(List<Alarm> alarms, String id) {
  for (final alarm in alarms) {
    if (alarm.id == id) return alarm;
  }
  return null;
}

Vehicle? _findVehicle(List<Vehicle> vehicles, String id) {
  for (final vehicle in vehicles) {
    if (vehicle.id == id) return vehicle;
  }
  return null;
}

/// Full-screen Alarm-Vollbild for route `/alarm/:alarmId` (ADR 0017, "App
/// im Vordergrund"): shows the Alarmierung and lets the signed-in Person
/// quittieren via the big "Quittieren" button. Shown and dismissed by
/// `AlarmNavigationListener`, which also decides whether the Ton plays
/// (only for a live `alarm.triggered`, never for one found via the
/// snapshot).
///
/// Closes itself (and stops the Ton) once this alarm is no longer the
/// signed-in Person's pending one -- whether because it was acknowledged
/// (here or on another device) or its Einsatz left `running`.
class AlarmScreen extends ConsumerStatefulWidget {
  const AlarmScreen({super.key, required this.alarmId});

  final String alarmId;

  @override
  ConsumerState<AlarmScreen> createState() => _AlarmScreenState();
}

class _AlarmScreenState extends ConsumerState<AlarmScreen> {
  bool _acknowledging = false;
  bool _closed = false;

  void _closeSelf() {
    if (_closed) return;
    _closed = true;
    unawaited(ref.read(alarmSoundProvider).stop());
    if (mounted) {
      if (context.canPop()) {
        context.pop();
      } else {
        context.go('/');
      }
    }
  }

  Future<void> _acknowledge() async {
    if (_acknowledging || _closed) return;
    setState(() => _acknowledging = true);
    try {
      await ref.read(alarmRepositoryProvider).acknowledge(widget.alarmId);
      if (!mounted) return;
      _closeSelf();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Quittierung fehlgeschlagen. Bitte erneut versuchen.'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _acknowledging = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(pairedSessionControllerProvider);
    final personId = session is Paired ? session.person.id : null;

    ref.listen<Alarm?>(myPendingAlarmProvider, (previous, next) {
      if (next?.id != widget.alarmId) {
        _closeSelf();
      }
    });

    final alarms = ref.watch(pairedAlarmsProvider).valueOrNull ?? const [];
    final alarm = _findAlarm(alarms, widget.alarmId);

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: Colors.red.shade800,
        body: alarm == null
            ? const Center(
                child: CircularProgressIndicator(color: Colors.white),
              )
            : _AlarmContent(
                alarm: alarm,
                personId: personId,
                acknowledging: _acknowledging,
                onAcknowledge: _acknowledge,
              ),
      ),
    );
  }
}

class _AlarmContent extends ConsumerWidget {
  const _AlarmContent({
    required this.alarm,
    required this.personId,
    required this.acknowledging,
    required this.onAcknowledge,
  });

  final Alarm alarm;
  final String? personId;
  final bool acknowledging;
  final Future<void> Function() onAcknowledge;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final incidents =
        ref.watch(pairedIncidentsProvider).valueOrNull ?? const [];
    final allAlarms = ref.watch(pairedAlarmsProvider).valueOrNull ?? const [];
    final vehicles = ref.watch(pairedVehiclesProvider).valueOrNull ?? const [];
    final incident = _findIncident(incidents, alarm.incidentId);
    final incidentAlarms =
        allAlarms.where((a) => a.incidentId == alarm.incidentId).toList();
    final alarmLabel = alarmSequenceLabel(alarm, incidentAlarms);

    AlarmRecipient? myRecipient;
    for (final recipient in alarm.recipients) {
      if (recipient.personId == personId) {
        myRecipient = recipient;
        break;
      }
    }
    final myVehicle =
        myRecipient == null ? null : _findVehicle(vehicles, myRecipient.vehicleId);

    const textStyle = TextStyle(color: Colors.white);

    return SafeArea(
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'ALARM',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 4,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    alarmLabel.toUpperCase(),
                    key: const Key('alarm-sequence-label'),
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (incident != null) ...[
                    Text(
                      '#${incident.number} ${incident.keyword}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(incident.address, style: textStyle.copyWith(fontSize: 20)),
                    if (incident.report.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Text(incident.report, style: textStyle.copyWith(fontSize: 18)),
                    ],
                  ],
                  const SizedBox(height: 24),
                  Text(
                    'Alarmierte Fahrzeuge',
                    style: textStyle.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  for (final vehicleId in alarm.vehicleIds)
                    Text(
                      _findVehicle(vehicles, vehicleId)?.shortName ?? vehicleId,
                      style: textStyle.copyWith(fontSize: 16),
                    ),
                  if (myRecipient != null) ...[
                    const SizedBox(height: 24),
                    Text(
                      'Dein Fahrzeug',
                      style: textStyle.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${myVehicle?.shortName ?? myRecipient.vehicleId} – ${myRecipient.function}',
                      style: textStyle.copyWith(fontSize: 16),
                    ),
                  ],
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                key: const Key('acknowledge-button'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(96),
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.red.shade800,
                  textStyle: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onPressed: acknowledging ? null : () => unawaited(onAcknowledge()),
                child: acknowledging
                    ? SizedBox(
                        width: 32,
                        height: 32,
                        child: CircularProgressIndicator(
                          color: Colors.red.shade800,
                        ),
                      )
                    : const Text('Quittieren'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
