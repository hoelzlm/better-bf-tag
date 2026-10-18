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

/// WCAG contrast ratio between two colours, via relative luminance,
/// matching `docs/design/tools/contrast.py`.
double _contrast(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  final lighter = la > lb ? la : lb;
  final darker = la > lb ? lb : la;
  return (lighter + 0.05) / (darker + 0.05);
}

/// Forces the platform brightness for the duration of the test, so
/// `BftagMobileApp`'s `ThemeMode.system` renders `bftagDarkTheme()`.
void _setBrightness(WidgetTester tester, Brightness brightness) {
  tester.platformDispatcher.platformBrightnessTestValue = brightness;
  addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
}

/// Resizes the test surface for the duration of the test, matching the
/// 390x844/360x640 sizes the concept tests.
void _setSurfaceSize(WidgetTester tester, Size size) {
  final originalSize = tester.view.physicalSize;
  final originalDpr = tester.view.devicePixelRatio;
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(() {
    tester.view.physicalSize = originalSize;
    tester.view.devicePixelRatio = originalDpr;
  });
}

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

      // The new layout (concept `app-alarm.md` §3: "Dein Fahrzeug"-Karte
      // moved above the address) pushes the map further down the scroll
      // area, so it may start outside the initial viewport.
      await tester.ensureVisible(find.byKey(const Key('start-navigation')));
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

  // -- app-alarm.md AC 1/8: background is exactly the `alarm`/`onAlarm`
  // token (not `Colors.red.shade800`), contrast meets at least AA in both
  // modes (Designsystem table 2.3: 4.98:1 light, 6.34:1 dark). -----------
  for (final entry in {
    Brightness.light: bftagLightTheme(),
    Brightness.dark: bftagDarkTheme(),
  }.entries) {
    testWidgets(
      'AC1/AC8: background is exactly the alarm token with AA contrast '
      '(${entry.key.name})',
      (tester) async {
        _setBrightness(tester, entry.key);
        final alarmColors = entry.value.extension<BftagAlarmColors>()!;
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

        final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
        expect(scaffold.backgroundColor, alarmColors.alarm);
        expect(
          _contrast(alarmColors.onAlarm, alarmColors.alarm),
          greaterThanOrEqualTo(4.5),
        );
      },
    );
  }

  // -- app-alarm.md AC2: Erstalarm / N. Nachalarmierung / Alarmierung
  // differ only by label text + icon, with identical surface colour. ----
  final acStates = <String, ({Alarm Function() build, String label, IconData icon})>{
    'Erstalarm': (
      build: () => _alarm(
        recipients: [_recipient(personId: 'p1', displayName: 'Max M.')],
      ),
      label: 'ERSTALARM',
      icon: Icons.notifications_active_outlined,
    ),
    '1. Nachalarmierung': (
      build: () {
        final nach = _alarm(
          id: 'a1',
          recipients: [_recipient(personId: 'p1', displayName: 'Max M.')],
        );
        return nach;
      },
      label: '1. NACHALARMIERUNG',
      icon: Icons.add_alert_outlined,
    ),
    'Alarmierung': (
      build: () => Alarm(
        id: 'a1',
        incidentId: 'i1',
        state: AlarmState.planned,
        scheduledAt: DateTime.parse('2026-06-01T09:00:00Z'),
        triggeredAt: null,
        vehicleIds: const ['v1'],
        recipients: [_recipient(personId: 'p1', displayName: 'Max M.')],
      ),
      label: 'ALARMIERUNG',
      icon: Icons.notifications_outlined,
    ),
  };

  for (final brightness in [Brightness.light, Brightness.dark]) {
    for (final entry in acStates.entries) {
      testWidgets(
        'AC2: ${entry.key} shows its own label + icon on the same surface '
        'colour (${brightness.name})',
        (tester) async {
          _setBrightness(tester, brightness);
          final theme = brightness == Brightness.light
              ? bftagLightTheme()
              : bftagDarkTheme();
          final alarmColors = theme.extension<BftagAlarmColors>()!;
          final alarm = entry.value.build();
          final sound = _FakeAlarmSound();
          final repository = _FakeAlarmRepository();

          await _pumpApp(
            tester,
            alarms: entry.key == '1. Nachalarmierung'
                ? [
                    _alarm(
                      id: 'a0',
                      recipients: [
                        _recipient(personId: 'p2', displayName: 'Erika M.'),
                      ],
                    ),
                    alarm,
                  ]
                : [alarm],
            liveAlarmTriggered: Stream.value(alarm),
            incidents: [_incident()],
            vehicles: [_vehicle()],
            sound: sound,
            repository: repository,
          );

          expect(find.text(entry.value.label), findsOneWidget);
          expect(find.byIcon(entry.value.icon), findsOneWidget);

          final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
          expect(scaffold.backgroundColor, alarmColors.alarm);
        },
      );
    }
  }

  // -- app-alarm.md AC3: Quittieren bleibt bei jeder Scrollposition
  // sichtbar -- 360x640 ist der kritische Fall aus dem Konzept. ---------
  testWidgets(
    'AC3: acknowledge button stays visible at max scroll on 360x640',
    (tester) async {
      _setSurfaceSize(tester, const Size(360, 640));
      final alarm = _alarm(
        recipients: [_recipient(personId: 'p1', displayName: 'Max M.')],
      );
      final sound = _FakeAlarmSound();
      final repository = _FakeAlarmRepository();

      await _pumpApp(
        tester,
        alarms: [alarm],
        liveAlarmTriggered: Stream.value(alarm),
        incidents: [
          _incident(
            address: 'Eine sehr lange Adresse mitten in der Industriestraße 7',
            report:
                'Eine sehr lange, ausführliche Lagebeschreibung mit starker '
                'Rauchentwicklung aus dem Dach und mehreren betroffenen '
                'Gebäudeteilen, die den Scrollbereich deutlich verlängert.',
          ),
        ],
        vehicles: [_vehicle()],
        sound: sound,
        repository: repository,
      );

      final scrollable = find.byType(Scrollable);
      await tester.drag(scrollable, const Offset(0, -2000));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(
        tester.getRect(find.byKey(const Key('acknowledge-button'))).bottom,
        lessThanOrEqualTo(640),
      );
      expect(find.byKey(const Key('acknowledge-button')), findsOneWidget);
    },
  );

  // -- app-alarm.md AC4: spinner + disabled while acknowledging. --------
  testWidgets(
    'AC4: shows a spinner and disables the button while acknowledging',
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

      await tester.tap(find.byKey(const Key('acknowledge-button')));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      final button = tester.widget<ElevatedButton>(
        find.byKey(const Key('acknowledge-button')),
      );
      expect(button.onPressed, isNull);

      repository.acknowledgeGate!.complete();
      await tester.pumpAndSettle();
    },
  );

  // -- app-alarm.md AC5: "Dein Fahrzeug" appears before address/
  // Lagebeschreibung. -----------------------------------------------------
  testWidgets(
    'AC5: "Dein Fahrzeug" appears before the address/Lagebeschreibung',
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

      final deinFahrzeugTop = tester
          .getTopLeft(find.text('DEIN FAHRZEUG'))
          .dy;
      final addressTop = tester.getTopLeft(find.text('Hauptstraße 1')).dy;
      expect(deinFahrzeugTop, lessThan(addressTop));
    },
  );

  // -- app-alarm.md AC9: einmaliger Fade-in <= 250ms, keine Wiederholung,
  // keine Animation bei Reduced-Motion. -----------------------------------
  testWidgets(
    'AC9: fades the screen in once within <= 250ms',
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

      final opacityWidgets = tester.widgetList<AnimatedOpacity>(
        find.byType(AnimatedOpacity),
      );
      expect(opacityWidgets, isNotEmpty);
      for (final widget in opacityWidgets) {
        expect(widget.duration, lessThanOrEqualTo(const Duration(milliseconds: 250)));
        expect(widget.opacity, 1.0);
      }

      // No further frames are scheduled -- a single fade-in, no repeat.
      expect(tester.hasRunningAnimations, isFalse);
    },
  );

  testWidgets(
    'AC9: no fade animation at all when MediaQuery.disableAnimations is set',
    (tester) async {
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(
        tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
      );

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

      expect(find.byType(AnimatedOpacity), findsNothing);
      expect(find.text('ALARM'), findsOneWidget);
    },
  );

  // -- meetsGuideline + no overflow, light and dark, 390x844 and 360x640. --
  for (final brightness in [Brightness.light, Brightness.dark]) {
    for (final size in [const Size(390, 844), const Size(360, 640)]) {
      testWidgets(
        'meetsGuideline passes and there is no overflow '
        '(${brightness.name}, ${size.width.toInt()}x${size.height.toInt()})',
        (tester) async {
          _setBrightness(tester, brightness);
          _setSurfaceSize(tester, size);
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

          expect(tester.takeException(), isNull);
          await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
          await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
          await expectLater(tester, meetsGuideline(textContrastGuideline));
        },
      );
    }
  }
}
