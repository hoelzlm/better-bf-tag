import 'package:bftag_core/bftag_core.dart';
import 'package:bftag_web/screens/persons_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Person _person({
  String id = 'p1',
  String displayName = 'Max Mustermann',
  PersonType personType = PersonType.supervisor,
  Permission permission = Permission.dispatch,
  bool active = true,
  bool hasWebAccess = false,
  String? username,
}) {
  return Person(
    id: id,
    displayName: displayName,
    personType: personType,
    permission: permission,
    active: active,
    hasWebAccess: hasWebAccess,
    username: username,
  );
}

Device _device({
  String id = 'd1',
  DevicePlatform platform = DevicePlatform.android,
  String? deviceName = 'Pixel 7',
  String appVersion = '1.0.0',
  DateTime? createdAt,
  DateTime? lastSeenAt,
  DateTime? revokedAt,
}) {
  final now = DateTime.utc(2026, 10, 8, 10, 0);
  return Device(
    id: id,
    platform: platform,
    deviceName: deviceName,
    appVersion: appVersion,
    createdAt: createdAt ?? now,
    lastSeenAt: lastSeenAt ?? now,
    revokedAt: revokedAt,
  );
}

class _FakePersonAdminRepository implements PersonAdminRepository {
  _FakePersonAdminRepository({
    List<Person>? persons,
    Map<String, List<Device>>? devices,
  })  : persons = persons ?? [],
        devices = devices ?? {};

  List<Person> persons;
  Map<String, List<Device>> devices;
  final List<(String, PersonType, Permission)> createCalls = [];
  final List<String> revokeDeviceCalls = [];
  final List<String> createPairingCodeCalls = [];

  @override
  Future<List<Person>> listPersons() async => List.of(persons);

  @override
  Future<Person> createPerson({
    required String displayName,
    required PersonType personType,
    required Permission permission,
  }) async {
    createCalls.add((displayName, personType, permission));
    final created = _person(
      id: 'new-${persons.length}',
      displayName: displayName,
      personType: personType,
      permission: permission,
    );
    persons = [...persons, created];
    return created;
  }

  @override
  Future<Person> updatePerson(
    String id, {
    String? displayName,
    PersonType? personType,
    Permission? permission,
    bool? active,
  }) async {
    final index = persons.indexWhere((p) => p.id == id);
    final updated = persons[index].copyWith(
      displayName: displayName,
      personType: personType,
      permission: permission,
      active: active,
    );
    persons = List.of(persons)..[index] = updated;
    return updated;
  }

  @override
  Future<Person> setWebAccess(
    String id, {
    required String username,
    required String password,
  }) async {
    final index = persons.indexWhere((p) => p.id == id);
    final updated = persons[index].copyWith(
      hasWebAccess: true,
      username: username,
    );
    persons = List.of(persons)..[index] = updated;
    return updated;
  }

  @override
  Future<void> removeWebAccess(String id) async {
    final index = persons.indexWhere((p) => p.id == id);
    final updated = persons[index].copyWith(hasWebAccess: false, username: null);
    persons = List.of(persons)..[index] = updated;
  }

  @override
  Future<PairingCodeItem> createPairingCode(String id) async {
    createPairingCodeCalls.add(id);
    final person = persons.firstWhere((p) => p.id == id);
    return PairingCodeItem(
      personId: id,
      displayName: person.displayName,
      code: 'ABCD-EFGH',
      expiresAt: DateTime.utc(2026, 10, 9, 12, 0),
    );
  }

  @override
  Future<List<PairingCodeItem>> createPairingCodes({
    List<String>? personIds,
  }) async =>
      [];

  @override
  Future<List<Device>> listPersonDevices(String id) async =>
      List.of(devices[id] ?? const []);

  @override
  Future<void> revokeDevice(String id) async {
    revokeDeviceCalls.add(id);
    for (final entry in devices.entries) {
      final index = entry.value.indexWhere((d) => d.id == id);
      if (index != -1) {
        final device = entry.value[index];
        devices[entry.key] = List.of(entry.value)
          ..[index] = Device(
            id: device.id,
            platform: device.platform,
            deviceName: device.deviceName,
            appVersion: device.appVersion,
            createdAt: device.createdAt,
            lastSeenAt: device.lastSeenAt,
            revokedAt: DateTime.utc(2026, 10, 8, 11, 0),
          );
      }
    }
  }
}

Future<_FakePersonAdminRepository> _pump(
  WidgetTester tester, {
  List<Person>? persons,
  Map<String, List<Device>>? devices,
}) async {
  final repository = _FakePersonAdminRepository(
    persons: persons,
    devices: devices,
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        personAdminRepositoryProvider.overrideWithValue(repository),
      ],
      child: const MaterialApp(home: PersonsScreen()),
    ),
  );
  await tester.pumpAndSettle();
  return repository;
}

void main() {
  testWidgets('lists persons from the fake response', (tester) async {
    await _pump(
      tester,
      persons: [
        _person(id: 'p1', displayName: 'Max Mustermann'),
        _person(id: 'p2', displayName: 'Erika Musterfrau'),
      ],
    );

    expect(find.textContaining('Max Mustermann'), findsOneWidget);
    expect(find.textContaining('Erika Musterfrau'), findsOneWidget);
  });

  testWidgets(
    'Administrator option is hidden for Personentyp Jugendlicher',
    (tester) async {
      await _pump(tester, persons: []);

      await tester.tap(find.byKey(const Key('create-person')));
      await tester.pumpAndSettle();

      // Default personType is youth: no admin chip offered.
      expect(find.byKey(const Key('permission-admin')), findsNothing);

      await tester.tap(find.byKey(const Key('person-type-supervisor')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('permission-admin')), findsOneWidget);

      await tester.tap(find.byKey(const Key('person-type-youth')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('permission-admin')), findsNothing);
    },
  );

  testWidgets(
    'creating a person calls createPerson with the entered fields',
    (tester) async {
      final repository = await _pump(tester, persons: []);

      await tester.tap(find.byKey(const Key('create-person')));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('person-form-display-name')),
        'Neue Person',
      );
      await tester.tap(find.byKey(const Key('person-type-supervisor')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('permission-admin')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('person-form-submit')));
      await tester.pumpAndSettle();

      expect(repository.createCalls, hasLength(1));
      final call = repository.createCalls.single;
      expect(call.$1, 'Neue Person');
      expect(call.$2, PersonType.supervisor);
      expect(call.$3, Permission.admin);
    },
  );

  testWidgets(
    'revoke device calls revokeDevice only after confirm',
    (tester) async {
      final person = _person(id: 'p1');
      final repository = await _pump(
        tester,
        persons: [person],
        devices: {
          'p1': [_device(id: 'd1')],
        },
      );

      await tester.tap(find.byKey(const Key('devices-p1')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('revoke-device-d1')));
      await tester.pumpAndSettle();

      // Confirm dialog shown, not yet called.
      expect(repository.revokeDeviceCalls, isEmpty);

      await tester.tap(find.byKey(const Key('confirm-dialog-confirm')));
      await tester.pumpAndSettle();

      expect(repository.revokeDeviceCalls, ['d1']);
    },
  );

  testWidgets(
    'pairing code dialog shows the formatted code',
    (tester) async {
      final person = _person(id: 'p1');
      await _pump(tester, persons: [person], devices: {'p1': []});

      await tester.tap(find.byKey(const Key('devices-p1')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('create-pairing-code')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('pairing-code-text')), findsOneWidget);
      expect(find.text('ABCD-EFGH'), findsOneWidget);
    },
  );
}
