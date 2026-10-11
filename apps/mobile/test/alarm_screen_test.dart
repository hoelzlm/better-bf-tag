import 'dart:async';

import 'package:bftag_core/bftag_core.dart';
import 'package:bftag_mobile/alarm/alarm_sound.dart';
import 'package:bftag_mobile/alarm/pending_alarm.dart';
import 'package:bftag_mobile/main.dart';
import 'package:bftag_mobile/map/navigation.dart';
import 'package:bftag_mobile/map/station_provider.dart';
import 'package:bftag_mobile/onboarding/onboarding_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

const _me = Person(
  id: 'p1',
  displayName: 'Max M.',
  personType: PersonType.youth,
  permission: Permission.crew,
);

Incident _incident({
  String id = 'i1',
  int number = 3,
  String keyword = 'Brand',
  String address = 'Hauptstraße 1',
  String report = 'Rauch aus dem Dach',
  String? script,
  IncidentState state = IncidentState.running,
  double? latitude,
  double? longitude,
}) {
  final now = DateTime.parse('2026-06-01T08:00:00Z');
  return Incident(
    id: id,
    bfDayId: 'day1',
    number: number,
    keyword: keyword,
    address: address,
    report: report,
    script: script,
    state: state,
    createdAt: now,
    updatedAt: now,
    latitude: latitude,
    longitude: longitude,
  );
}

Vehicle _vehicle({
  String id = 'v1',
  String callSign = 'Florian 1',
  String shortName = 'HLF 1',
  String type = 'HLF',
}) {
  return Vehicle(
    id: id,
    callSign: callSign,
    shortName: shortName,
    type: type,
    status: FmsStatus.fromCode(2),
    statusChangedAt: null,
    sortOrder: 1,
    active: true,
  );
}

AlarmRecipient _recipient({
  required String personId,
  required String displayName,
  String vehicleId = 'v1',
  String function = 'MA',
  bool hasDevice = true,
  DateTime? acknowledgedAt,
}) {
  return AlarmRecipient(
    personId: personId,
    displayName: displayName,
    vehicleId: vehicleId,
    function: function,
    hasDevice: hasDevice,
    acknowledgedAt: acknowledgedAt,
  );
}

Alarm _alarm({
  String id = 'a1',
  String incidentId = 'i1',
  List<String> vehicleIds = const ['v1'],
  required List<AlarmRecipient> recipients,
}) {
  return Alarm(
    id: id,
    incidentId: incidentId,
    state: AlarmState.triggered,
    scheduledAt: null,
    triggeredAt: DateTime.parse('2026-06-01T08:05:00Z'),
    vehicleIds: vehicleIds,
    recipients: recipients,
  );
}

class _FakeAlarmSound implements AlarmSound {
  int playCalls = 0;
  int stopCalls = 0;
  bool? lastLoop;
  bool get playing => playCalls > stopCalls;

  @override
  Future<void> play({bool loop = false}) async {
    playCalls++;
    lastLoop = loop;
  }

  @override
  Future<void> stop() async {
    stopCalls++;
  }
}

class _FakeAlarmRepository implements AlarmRepository {
  final List<String> acknowledgeCalls = [];
  Object? acknowledgeError;
  Completer<void>? acknowledgeGate;

  @override
  Future<void> acknowledge(String alarmId) async {
    acknowledgeCalls.add(alarmId);
    if (acknowledgeGate != null) {
      await acknowledgeGate!.future;
    }
    if (acknowledgeError != null) {
      throw acknowledgeError!;
    }
  }

  @override
  Future<TriggerAlarmResult> trigger(
    String incidentId,
    List<String> vehicleIds, {
    required String id,
  }) => throw UnimplementedError();

  @override
  Future<Alarm> plan(
    String incidentId,
    List<String> vehicleIds, {
    String? id,
    DateTime? scheduledAt,
    int? offsetMinutes,
  }) =>
      throw UnimplementedError();

  @override
  Future<Alarm> update(
    String alarmId, {
    DateTime? scheduledAt,
    int? offsetMinutes,
    List<String>? vehicleIds,
  }) =>
      throw UnimplementedError();

  @override
  Future<Alarm> discard(String alarmId) => throw UnimplementedError();

  @override
  Future<TriggerAlarmResult> triggerNow(String alarmId) =>
      throw UnimplementedError();
}

class _FakePairedSessionController extends PairedSessionController {
  _FakePairedSessionController(this._initial);

  final PairedSessionState _initial;

  @override
  PairedSessionState build() => _initial;

  @override
  Future<void> restore() async {}

  @override
  Future<void> logout() async {
    state = const PairedUnpaired();
  }

  @override
  Future<void> onRevoked() async {
    state = const PairedUnpaired(revoked: true);
  }

  @override
  void acknowledgeRevoked() {}
}

Future<void> _pumpApp(
  WidgetTester tester, {
  required List<Alarm> alarms,
  Stream<Alarm>? liveAlarmTriggered,
  required List<Incident> incidents,
  required List<Vehicle> vehicles,
  required _FakeAlarmSound sound,
  required _FakeAlarmRepository repository,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        pairedSessionControllerProvider.overrideWith(
          () => _FakePairedSessionController(
            const Paired(_me, 'fake-access-token', 'dev1'),
          ),
        ),
        // Not under test here; keep a freshly-Paired session off the
        // Onboarding (ADR 0021) redirect.
        onboardingStoreProvider.overrideWithValue(
          InMemoryOnboardingStore(completed: true),
        ),
        pairedRealtimeClientProvider.overrideWith((ref) => null),
        pairedAlarmsProvider.overrideWith((ref) => Stream.value(alarms)),
        pairedLiveAlarmTriggeredProvider.overrideWith(
          (ref) => liveAlarmTriggered ?? const Stream<Alarm>.empty(),
        ),
        pairedIncidentsProvider.overrideWith((ref) => Stream.value(incidents)),
        pairedVehiclesProvider.overrideWith((ref) => Stream.value(vehicles)),
        myCrewAssignmentsProvider.overrideWithValue(const []),
        alarmSoundProvider.overrideWithValue(sound),
        alarmRepositoryProvider.overrideWithValue(repository),
      ],
      child: const BftagMobileApp(),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'a live alarm for me shows the alarm screen and plays the sound',
    (tester) async {
      final alarm = _alarm(
        recipients: [_recipient(personId: 'p1', displayName: 'Max M.')],
      );
      final sound = _FakeAlarmSound();
      final repository = _FakeAlarmRepository();

      await _pumpApp(
        tester,
        alarms: [alarm],
        liveAlarmTriggered: Stream.value(alarm),
        incidents: [_incident()],
        vehicles: [_vehicle()],
        sound: sound,
        repository: repository,
      );

      expect(find.text('ALARM'), findsOneWidget);
      expect(find.text('#3 Brand'), findsOneWidget);
      expect(find.text('Hauptstraße 1'), findsOneWidget);
      expect(find.text('Rauch aus dem Dach'), findsOneWidget);
      expect(find.byKey(const Key('acknowledge-button')), findsOneWidget);
      expect(sound.playCalls, 1);
      expect(sound.lastLoop, true);
    },
  );

  testWidgets('an alarm where I am not a recipient shows nothing', (
    tester,
  ) async {
    final alarm = _alarm(
      recipients: [_recipient(personId: 'p2', displayName: 'Erika M.')],
    );
    final sound = _FakeAlarmSound();
    final repository = _FakeAlarmRepository();

    await _pumpApp(
      tester,
      alarms: [alarm],
      liveAlarmTriggered: Stream.value(alarm),
      incidents: [_incident()],
      vehicles: [_vehicle()],
      sound: sound,
      repository: repository,
    );

    expect(find.text('ALARM'), findsNothing);
    expect(sound.playCalls, 0);
  });

  testWidgets(
    'tapping Quittieren acknowledges exactly once, stops the sound and '
    'closes the screen',
    (tester) async {
      final alarm = _alarm(
        recipients: [_recipient(personId: 'p1', displayName: 'Max M.')],
      );
      final sound = _FakeAlarmSound();
      final repository = _FakeAlarmRepository()
        ..acknowledgeGate = Completer<void>();

      await _pumpApp(
        tester,
        alarms: [alarm],
        liveAlarmTriggered: Stream.value(alarm),
        incidents: [_incident()],
        vehicles: [_vehicle()],
        sound: sound,
        repository: repository,
      );

      expect(find.text('ALARM'), findsOneWidget);

      await tester.tap(find.byKey(const Key('acknowledge-button')));
      await tester.pump();
      // While in flight: double tap is guarded (button disabled / gated).
      await tester.tap(find.byKey(const Key('acknowledge-button')));
      await tester.pump();

      expect(repository.acknowledgeCalls, ['a1']);

      repository.acknowledgeGate!.complete();
      await tester.pumpAndSettle();

      expect(find.text('ALARM'), findsNothing);
      expect(sound.stopCalls, greaterThanOrEqualTo(1));
    },
  );

  testWidgets(
    'a pending alarm found via the snapshot shows the screen without sound',
    (tester) async {
      final alarm = _alarm(
        recipients: [_recipient(personId: 'p1', displayName: 'Max M.')],
      );
      final sound = _FakeAlarmSound();
      final repository = _FakeAlarmRepository();

      await _pumpApp(
        tester,
        alarms: [alarm],
        // No live trigger: this alarm was only found via the snapshot.
        liveAlarmTriggered: null,
        incidents: [_incident()],
        vehicles: [_vehicle()],
        sound: sound,
        repository: repository,
      );

      expect(find.text('ALARM'), findsOneWidget);
      expect(sound.playCalls, 0);
    },
  );

  testWidgets('no Drehbuch text is visible even if the incident has a script', (
    tester,
  ) async {
    final alarm = _alarm(
      recipients: [_recipient(personId: 'p1', displayName: 'Max M.')],
    );
    final sound = _FakeAlarmSound();
    final repository = _FakeAlarmRepository();

    await _pumpApp(
      tester,
      alarms: [alarm],
      liveAlarmTriggered: Stream.value(alarm),
      incidents: [_incident(script: 'Übung: Simulierter Dachstuhlbrand.')],
      vehicles: [_vehicle()],
      sound: sound,
      repository: repository,
    );

    expect(find.text('ALARM'), findsOneWidget);
    expect(find.text('Übung: Simulierter Dachstuhlbrand.'), findsNothing);
    expect(find.textContaining('Drehbuch'), findsNothing);
  });

  testWidgets(
    'a live alarm.triggered Nachalarmierung without me as recipient keeps '
    'the app on the Einsätze screen (no alarm screen, no sound)',
    (tester) async {
      final nachalarmierung = _alarm(
        id: 'a2',
        vehicleIds: ['v2'],
        recipients: [_recipient(personId: 'p2', displayName: 'Erika M.')],
      );
      final sound = _FakeAlarmSound();
      final repository = _FakeAlarmRepository();

      await _pumpApp(
        tester,
        alarms: [nachalarmierung],
        liveAlarmTriggered: Stream.value(nachalarmierung),
        incidents: [_incident()],
        vehicles: [_vehicle()],
        sound: sound,
        repository: repository,
      );

      expect(find.text('ALARM'), findsNothing);
      expect(sound.playCalls, 0);
    },
  );

  testWidgets(
    'an incident with coordinates shows the map and "Navigation starten"',
    (tester) async {
      final alarm = _alarm(
        recipients: [_recipient(personId: 'p1', displayName: 'Max M.')],
      );
      final sound = _FakeAlarmSound();
      final repository = _FakeAlarmRepository();

      await _pumpApp(
        tester,
        alarms: [alarm],
        liveAlarmTriggered: Stream.value(alarm),
        incidents: [_incident(latitude: 48.1, longitude: 11.5)],
        vehicles: [_vehicle()],
        sound: sound,
        repository: repository,
      );

      expect(find.byType(IncidentMap), findsOneWidget);
      expect(find.byKey(const Key('start-navigation')), findsOneWidget);
    },
  );

  testWidgets(
    'an incident without coordinates shows no map and no navigation button',
    (tester) async {
      final alarm = _alarm(
        recipients: [_recipient(personId: 'p1', displayName: 'Max M.')],
      );
      final sound = _FakeAlarmSound();
      final repository = _FakeAlarmRepository();

      await _pumpApp(
        tester,
        alarms: [alarm],
        liveAlarmTriggered: Stream.value(alarm),
        incidents: [_incident()],
        vehicles: [_vehicle()],
        sound: sound,
        repository: repository,
      );

      expect(find.byType(IncidentMap), findsNothing);
      expect(find.byKey(const Key('start-navigation')), findsNothing);
    },
  );

  testWidgets(
    'tapping "Navigation starten" calls the fake launcher with the '
    'expected Uri',
    (tester) async {
      final alarm = _alarm(
        recipients: [_recipient(personId: 'p1', displayName: 'Max M.')],
      );
      final sound = _FakeAlarmSound();
      final repository = _FakeAlarmRepository();
      Uri? launched;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            pairedSessionControllerProvider.overrideWith(
              () => _FakePairedSessionController(
                const Paired(_me, 'fake-access-token', 'dev1'),
              ),
            ),
            onboardingStoreProvider.overrideWithValue(
              InMemoryOnboardingStore(completed: true),
            ),
            pairedRealtimeClientProvider.overrideWith((ref) => null),
            pairedAlarmsProvider.overrideWith((ref) => Stream.value([alarm])),
            pairedLiveAlarmTriggeredProvider.overrideWith(
              (ref) => Stream.value(alarm),
            ),
            pairedIncidentsProvider.overrideWith(
              (ref) => Stream.value([_incident(latitude: 48.1, longitude: 11.5)]),
            ),
            pairedVehiclesProvider.overrideWith(
              (ref) => Stream.value([_vehicle()]),
            ),
            myCrewAssignmentsProvider.overrideWithValue(const []),
            alarmSoundProvider.overrideWithValue(sound),
            alarmRepositoryProvider.overrideWithValue(repository),
            uriLauncherProvider.overrideWithValue((uri) async {
              launched = uri;
              return true;
            }),
          ],
          child: const BftagMobileApp(),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('start-navigation')));
      await tester.pumpAndSettle();

      expect(launched.toString(), 'geo:48.1,11.5?q=48.1,11.5');
    },
  );

  testWidgets(
    'wires the paired station into the map as the Wache pin',
    (tester) async {
      final alarm = _alarm(
        recipients: [_recipient(personId: 'p1', displayName: 'Max M.')],
      );
      final sound = _FakeAlarmSound();
      final repository = _FakeAlarmRepository();
      // A single shared source (like the one `RealtimeState` event that
      // carries both `incidents` and `station` together) so both
      // providers resolve from the exact same completion -- two
      // independent `Stream.value(...)` overrides, or a single-listener
      // stream turned broadcast (only the first subscriber gets the
      // value), can resolve inconsistently and leave `station` null.
      final shared = Future<void>.value();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            pairedSessionControllerProvider.overrideWith(
              () => _FakePairedSessionController(
                const Paired(_me, 'fake-access-token', 'dev1'),
              ),
            ),
            onboardingStoreProvider.overrideWithValue(
              InMemoryOnboardingStore(completed: true),
            ),
            pairedRealtimeClientProvider.overrideWith((ref) => null),
            pairedAlarmsProvider.overrideWith((ref) => Stream.value([alarm])),
            pairedLiveAlarmTriggeredProvider.overrideWith(
              (ref) => Stream.value(alarm),
            ),
            pairedIncidentsProvider.overrideWith(
              (ref) => shared.asStream().map(
                (_) => [_incident(latitude: 48.1, longitude: 11.5)],
              ),
            ),
            pairedVehiclesProvider.overrideWith(
              (ref) => Stream.value([_vehicle()]),
            ),
            pairedStationProvider.overrideWith(
              (ref) => shared.asStream().map((_) => const LatLng(48.2, 11.6)),
            ),
            myCrewAssignmentsProvider.overrideWithValue(const []),
            alarmSoundProvider.overrideWithValue(sound),
            alarmRepositoryProvider.overrideWithValue(repository),
          ],
          child: const BftagMobileApp(),
        ),
      );
      await tester.pumpAndSettle();

      final map = tester.widget<IncidentMap>(find.byType(IncidentMap));
      expect(map.station, const LatLng(48.2, 11.6));
    },
  );
}
