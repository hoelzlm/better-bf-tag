// apps/mobile/screenshot_test/screenshots_test.dart — mobile screenshot
// harness for `just screenshots dir=...` (docs/testing/README.md).
//
// Deliberately placed OUTSIDE apps/mobile/test/ so plain `flutter test`
// does not pick it up (verified: `flutter test` only scans test/). Run
// explicitly via:
//   flutter test screenshot_test --dart-define=SCREENSHOT_DIR=<abs path>
//
// Captures each required screen at 390x844 and 360x640 into
// SCREENSHOT_DIR/app/<screen>[-<state>]-<W>x<H>.png. Loads real Roboto /
// MaterialIcons fonts first so screenshots show real glyphs, not Ahem
// boxes. The app has no dark mode today (no ThemeMode/Brightness usage
// in lib/, see docs/testing/README.md) so no *-dark-*.png is produced.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:bftag_core/bftag_core.dart';
import 'package:bftag_mobile/alarm/alarm_sound.dart';
import 'package:bftag_mobile/alarm/pending_alarm.dart';
import 'package:bftag_mobile/main.dart';
import 'package:bftag_mobile/onboarding/device_settings.dart';
import 'package:bftag_mobile/onboarding/onboarding_screen.dart';
import 'package:bftag_mobile/onboarding/onboarding_store.dart';
import 'package:bftag_mobile/push/push_service.dart';
import 'package:bftag_mobile/router.dart';
import 'package:bftag_mobile/screens/program_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _screenshotDir = String.fromEnvironment('SCREENSHOT_DIR');

const _me = Person(
  id: 'p1',
  displayName: 'Max M.',
  personType: PersonType.youth,
  permission: Permission.crew,
);

Incident _incident({
  String id = 'i1',
  int number = 3,
  String keyword = 'B3 Großbrand Lagerhalle',
  String address = 'Industriestraße 7',
  String report = 'Starke Rauchentwicklung aus dem Dach.',
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
  String callSign = 'Florian 46/1',
  String shortName = 'HLF-1',
  String type = 'HLF',
  int status = 3,
}) {
  return Vehicle(
    id: id,
    callSign: callSign,
    shortName: shortName,
    type: type,
    status: FmsStatus.fromCode(status),
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

ProgramItem _programItem({
  required String id,
  required String title,
  required ProgramItemType type,
  required DateTime startsAt,
  required DateTime endsAt,
}) {
  return ProgramItem(
    id: id,
    bfDayId: 'day1',
    title: title,
    type: type,
    startsAt: startsAt,
    endsAt: endsAt,
  );
}

Announcement _announcement({
  required String id,
  required String text,
  required DateTime createdAt,
}) {
  return Announcement(
    id: id,
    bfDayId: 'day1',
    shiftId: null,
    text: text,
    createdBy: 'p1',
    createdAt: createdAt,
  );
}

class _FakeAlarmSound implements AlarmSound {
  @override
  Future<void> play({bool loop = false}) async {}
  @override
  Future<void> stop() async {}
}

class _FakeAlarmRepository implements AlarmRepository {
  @override
  Future<void> acknowledge(String alarmId) async {}
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
  }) => throw UnimplementedError();
  @override
  Future<Alarm> update(
    String alarmId, {
    DateTime? scheduledAt,
    int? offsetMinutes,
    List<String>? vehicleIds,
  }) => throw UnimplementedError();
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
  Future<void> logout() async {}
  @override
  Future<void> onRevoked() async {}
  @override
  void acknowledgeRevoked() {}
}

class _FakeDeviceSettings implements DeviceSettings {
  @override
  Future<bool> notificationsEnabled() async => true;
  @override
  Future<bool> bypassesDnd() async => true;
  @override
  Future<bool> batteryOptimizationIgnored() async => true;
  @override
  Future<String> manufacturer() async => 'samsung';
  @override
  Future<void> openNotificationSettings() async {}
  @override
  Future<void> openDndSettings() async {}
  @override
  Future<void> requestIgnoreBatteryOptimization() async {}
}

class _FakePushService implements PushService {
  @override
  Future<void> init() async {}
  @override
  Future<String?> getToken() async => null;
  @override
  Stream<String> get onTokenRefresh => const Stream<String>.empty();
  @override
  Future<String?> initialAlarmId() async => null;
  @override
  Stream<String> get onAlarmOpened => const Stream<String>.empty();
  @override
  Stream<void> get onTestAlarmReceived => const Stream<void>.empty();
  @override
  Stream<void> get onAnnouncementOpened => const Stream<void>.empty();
}

const _paired = Paired(_me, 'fake-access-token', 'dev1');

/// Loads real Roboto + MaterialIcons fonts (instead of the test
/// framework's default Ahem boxes) so screenshots show real glyphs.
/// Looks under $FLUTTER_ROOT/bin/cache/artifacts/material_fonts/.
Future<void> _loadRealFonts() async {
  final flutterRoot =
      Platform.environment['FLUTTER_ROOT'] ?? await _flutterRootFromWhich();
  if (flutterRoot == null) {
    // ignore: avoid_print
    print('NOTE: FLUTTER_ROOT not found, screenshots will use Ahem boxes.');
    return;
  }
  final fontsDir = Directory(
    '$flutterRoot/bin/cache/artifacts/material_fonts',
  );
  if (!fontsDir.existsSync()) {
    // ignore: avoid_print
    print('NOTE: $fontsDir missing, screenshots will use Ahem boxes.');
    return;
  }
  for (final file in fontsDir.listSync()) {
    if (file is! File || !file.path.endsWith('.ttf')) continue;
    final bytes = await file.readAsBytes();
    final loader = FontLoader(
      file.path.contains('MaterialIcons') ? 'MaterialIcons' : 'Roboto',
    );
    loader.addFont(Future.value(ByteData.view(bytes.buffer)));
    await loader.load();
  }
}

Future<String?> _flutterRootFromWhich() async {
  try {
    final which = await Process.run('which', ['flutter']);
    final flutterBin = (which.stdout as String).trim();
    if (flutterBin.isEmpty) return null;
    final resolved = await Process.run('readlink', ['-f', flutterBin]);
    final realBin = (resolved.stdout as String).trim();
    if (realBin.isEmpty) return null;
    // realBin is .../flutter/bin/flutter
    return Directory(realBin).parent.parent.path;
  } catch (_) {
    return null;
  }
}

final _repaintKey = GlobalKey();

Future<void> _capture(
  WidgetTester tester,
  String name,
  Size size,
) async {
  if (_screenshotDir.isEmpty) {
    fail('SCREENSHOT_DIR dart-define is required for screenshot_test.');
  }
  await tester.binding.setSurfaceSize(size);
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(() async {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
    await tester.binding.setSurfaceSize(null);
  });
  await tester.pumpAndSettle();

  final boundary = _repaintKey.currentContext!.findRenderObject()
      as RenderRepaintBoundary;
  await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 1);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    final dir = Directory('$_screenshotDir/app');
    dir.createSync(recursive: true);
    final w = size.width.round();
    final h = size.height.round();
    File('${dir.path}/$name-${w}x$h.png').writeAsBytesSync(
      bytes!.buffer.asUint8List(),
    );
  });
}

Future<void> _pumpApp(
  WidgetTester tester, {
  required List<Override> overrides,
}) async {
  await tester.pumpWidget(
    RepaintBoundary(
      key: _repaintKey,
      child: ProviderScope(
        overrides: overrides,
        child: const BftagMobileApp(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

const _sizes = [Size(390, 844), Size(360, 640)];

void main() {
  setUpAll(_loadRealFonts);

  for (final size in _sizes) {
    testWidgets('Onboarding ($size)', (tester) async {
      await _pumpApp(
        tester,
        overrides: [
          pairedSessionControllerProvider.overrideWith(
            () => _FakePairedSessionController(_paired),
          ),
          onboardingStoreProvider.overrideWithValue(
            InMemoryOnboardingStore(completed: false),
          ),
          deviceSettingsProvider.overrideWithValue(_FakeDeviceSettings()),
          pushServiceProvider.overrideWithValue(_FakePushService()),
          pairedRealtimeClientProvider.overrideWith((ref) => null),
          myCrewAssignmentsProvider.overrideWithValue(const []),
          pairedAlarmsProvider.overrideWith((ref) => Stream.value(const [])),
          pairedIncidentsProvider.overrideWith(
            (ref) => Stream.value(const []),
          ),
          pairedVehiclesProvider.overrideWith((ref) => Stream.value(const [])),
          alarmSoundProvider.overrideWithValue(_FakeAlarmSound()),
        ],
      );
      expect(find.byType(OnboardingScreen), findsOneWidget);
      await _capture(tester, 'onboarding', size);
    });

    testWidgets('Kopplung ($size)', (tester) async {
      await _pumpApp(
        tester,
        overrides: [
          pairedSessionControllerProvider.overrideWith(
            () => _FakePairedSessionController(const PairedUnpaired()),
          ),
          onboardingStoreProvider.overrideWithValue(
            InMemoryOnboardingStore(completed: false),
          ),
          deviceSettingsProvider.overrideWithValue(_FakeDeviceSettings()),
          pushServiceProvider.overrideWithValue(_FakePushService()),
          alarmSoundProvider.overrideWithValue(_FakeAlarmSound()),
        ],
      );
      await _capture(tester, 'kopplung', size);
    });

    testWidgets('Mein Fahrzeug ($size)', (tester) async {
      final vehicle = _vehicle();
      await _pumpApp(
        tester,
        overrides: [
          pairedSessionControllerProvider.overrideWith(
            () => _FakePairedSessionController(_paired),
          ),
          onboardingStoreProvider.overrideWithValue(
            InMemoryOnboardingStore(completed: true),
          ),
          pairedRealtimeClientProvider.overrideWith((ref) => null),
          pairedAlarmsProvider.overrideWith((ref) => Stream.value(const [])),
          pairedIncidentsProvider.overrideWith(
            (ref) => Stream.value(const []),
          ),
          pairedVehiclesProvider.overrideWith(
            (ref) => Stream.value([vehicle]),
          ),
          myCrewAssignmentsProvider.overrideWithValue([
            MyCrewAssignment(
              shift: Shift(
                id: 'shift1',
                bfDayId: 'day1',
                name: 'Schicht 1',
                startsAt: DateTime(2026, 6, 1, 8),
                endsAt: DateTime(2026, 6, 1, 20),
                crew: const [],
              ),
              vehicle: vehicle,
              function: 'GF',
              crew: [
                CrewAssignment(
                  vehicleId: vehicle.id,
                  personId: 'p1',
                  displayName: 'Max M.',
                  function: 'GF',
                ),
                CrewAssignment(
                  vehicleId: vehicle.id,
                  personId: 'p2',
                  displayName: 'Erika M.',
                  function: 'MA',
                ),
              ],
            ),
          ]),
          alarmSoundProvider.overrideWithValue(_FakeAlarmSound()),
          alarmRepositoryProvider.overrideWithValue(_FakeAlarmRepository()),
        ],
      );
      expect(find.text('Mein Fahrzeug'), findsOneWidget);
      await _capture(tester, 'mein-fahrzeug', size);
    });

    testWidgets('Einsätze ($size)', (tester) async {
      await _pumpApp(
        tester,
        overrides: [
          pairedSessionControllerProvider.overrideWith(
            () => _FakePairedSessionController(_paired),
          ),
          onboardingStoreProvider.overrideWithValue(
            InMemoryOnboardingStore(completed: true),
          ),
          pairedRealtimeClientProvider.overrideWith((ref) => null),
          pairedAlarmsProvider.overrideWith((ref) => Stream.value(const [])),
          pairedIncidentsProvider.overrideWith(
            (ref) => Stream.value([
              _incident(),
              _incident(
                id: 'i2',
                number: 2,
                keyword: 'B1 Kleinbrand',
                address: 'Nebenstraße 2',
                report: 'Mülltonnenbrand.',
                state: IncidentState.closed,
              ),
            ]),
          ),
          pairedVehiclesProvider.overrideWith(
            (ref) => Stream.value([_vehicle()]),
          ),
          myCrewAssignmentsProvider.overrideWithValue(const []),
          alarmSoundProvider.overrideWithValue(_FakeAlarmSound()),
        ],
      );
      tester
          .element(find.byType(BftagMobileApp))
          .findAncestorStateOfType<State>();
      // Navigate to /einsaetze via the router owned by the pumped app.
      final container = ProviderScope.containerOf(
        tester.element(find.byType(BftagMobileApp)),
      );
      container.read(mobileGoRouterProvider).go('/einsaetze');
      await tester.pumpAndSettle();
      await _capture(tester, 'einsaetze', size);
    });

    testWidgets('Einsatzdetail ($size)', (tester) async {
      final incident = _incident(latitude: 48.137, longitude: 11.575);
      await _pumpApp(
        tester,
        overrides: [
          pairedSessionControllerProvider.overrideWith(
            () => _FakePairedSessionController(_paired),
          ),
          onboardingStoreProvider.overrideWithValue(
            InMemoryOnboardingStore(completed: true),
          ),
          pairedRealtimeClientProvider.overrideWith((ref) => null),
          pairedAlarmsProvider.overrideWith((ref) => Stream.value(const [])),
          pairedIncidentsProvider.overrideWith(
            (ref) => Stream.value([incident]),
          ),
          pairedVehiclesProvider.overrideWith(
            (ref) => Stream.value([_vehicle()]),
          ),
          myCrewAssignmentsProvider.overrideWithValue(const []),
          alarmSoundProvider.overrideWithValue(_FakeAlarmSound()),
        ],
      );
      final container = ProviderScope.containerOf(
        tester.element(find.byType(BftagMobileApp)),
      );
      container.read(mobileGoRouterProvider).go('/einsaetze/i1');
      await tester.pumpAndSettle();
      await _capture(tester, 'einsatzdetail', size);
    });

    testWidgets('Alarm-Screen ($size)', (tester) async {
      final alarm = _alarm(
        recipients: [_recipient(personId: 'p1', displayName: 'Max M.')],
      );
      await _pumpApp(
        tester,
        overrides: [
          pairedSessionControllerProvider.overrideWith(
            () => _FakePairedSessionController(_paired),
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
            (ref) => Stream.value([_incident()]),
          ),
          pairedVehiclesProvider.overrideWith(
            (ref) => Stream.value([_vehicle()]),
          ),
          myCrewAssignmentsProvider.overrideWithValue(const []),
          alarmSoundProvider.overrideWithValue(_FakeAlarmSound()),
          alarmRepositoryProvider.overrideWithValue(_FakeAlarmRepository()),
        ],
      );
      expect(find.text('ALARM'), findsOneWidget);
      await _capture(tester, 'alarm-screen', size);
    });

    testWidgets('Tagesablauf ($size)', (tester) async {
      await _pumpApp(
        tester,
        overrides: [
          pairedSessionControllerProvider.overrideWith(
            () => _FakePairedSessionController(_paired),
          ),
          onboardingStoreProvider.overrideWithValue(
            InMemoryOnboardingStore(completed: true),
          ),
          pairedRealtimeClientProvider.overrideWith((ref) => null),
          pairedAlarmsProvider.overrideWith((ref) => Stream.value(const [])),
          pairedIncidentsProvider.overrideWith(
            (ref) => Stream.value(const []),
          ),
          pairedVehiclesProvider.overrideWith(
            (ref) => Stream.value([_vehicle()]),
          ),
          myCrewAssignmentsProvider.overrideWithValue(const []),
          alarmSoundProvider.overrideWithValue(_FakeAlarmSound()),
          pairedProgramItemsProvider.overrideWith(
            (ref) => Stream.value([
              _programItem(
                id: 'pi1',
                title: 'Mittagessen',
                type: ProgramItemType.meal,
                startsAt: DateTime(2026, 6, 1, 12),
                endsAt: DateTime(2026, 6, 1, 13),
              ),
              _programItem(
                id: 'pi2',
                title: 'Ausbildung Löschtechnik',
                type: ProgramItemType.training,
                startsAt: DateTime(2026, 6, 1, 14),
                endsAt: DateTime(2026, 6, 1, 16),
              ),
            ]),
          ),
          programNowProvider.overrideWith(
            (ref) => Stream.value(DateTime(2026, 6, 1, 10)),
          ),
        ],
      );
      final container = ProviderScope.containerOf(
        tester.element(find.byType(BftagMobileApp)),
      );
      container.read(mobileGoRouterProvider).go('/tagesablauf');
      await tester.pumpAndSettle();
      await _capture(tester, 'tagesablauf', size);
    });

    testWidgets('Durchsagen ($size)', (tester) async {
      await _pumpApp(
        tester,
        overrides: [
          pairedSessionControllerProvider.overrideWith(
            () => _FakePairedSessionController(_paired),
          ),
          onboardingStoreProvider.overrideWithValue(
            InMemoryOnboardingStore(completed: true),
          ),
          pairedRealtimeClientProvider.overrideWith((ref) => null),
          pairedAlarmsProvider.overrideWith((ref) => Stream.value(const [])),
          pairedIncidentsProvider.overrideWith(
            (ref) => Stream.value(const []),
          ),
          pairedVehiclesProvider.overrideWith(
            (ref) => Stream.value([_vehicle()]),
          ),
          myCrewAssignmentsProvider.overrideWithValue(const []),
          alarmSoundProvider.overrideWithValue(_FakeAlarmSound()),
          pairedAnnouncementsProvider.overrideWith(
            (ref) => Stream.value([
              _announcement(
                id: 'an1',
                text: 'Abendessen ist in 10 Minuten fertig.',
                createdAt: DateTime(2026, 6, 1, 18),
              ),
            ]),
          ),
        ],
      );
      final container = ProviderScope.containerOf(
        tester.element(find.byType(BftagMobileApp)),
      );
      container.read(mobileGoRouterProvider).go('/durchsagen');
      await tester.pumpAndSettle();
      await _capture(tester, 'durchsagen', size);
    });

    testWidgets('Einstellungen ($size)', (tester) async {
      await _pumpApp(
        tester,
        overrides: [
          pairedSessionControllerProvider.overrideWith(
            () => _FakePairedSessionController(_paired),
          ),
          onboardingStoreProvider.overrideWithValue(
            InMemoryOnboardingStore(completed: true),
          ),
          pairedRealtimeClientProvider.overrideWith((ref) => null),
          pairedAlarmsProvider.overrideWith((ref) => Stream.value(const [])),
          pairedIncidentsProvider.overrideWith(
            (ref) => Stream.value(const []),
          ),
          pairedVehiclesProvider.overrideWith(
            (ref) => Stream.value([_vehicle()]),
          ),
          myCrewAssignmentsProvider.overrideWithValue(const []),
          alarmSoundProvider.overrideWithValue(_FakeAlarmSound()),
        ],
      );
      final container = ProviderScope.containerOf(
        tester.element(find.byType(BftagMobileApp)),
      );
      container.read(mobileGoRouterProvider).go('/settings');
      await tester.pumpAndSettle();
      await _capture(tester, 'einstellungen', size);
    });
  }
}
