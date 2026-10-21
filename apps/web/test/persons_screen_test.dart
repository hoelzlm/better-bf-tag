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

class _ThrowingPersonAdminRepository extends _FakePersonAdminRepository {
  @override
  Future<List<Person>> listPersons() async {
    throw StateError('boom');
  }
}

Future<_FakePersonAdminRepository> _pump(
  WidgetTester tester, {
  List<Person>? persons,
  Map<String, List<Device>>? devices,
}) async {
  tester.view.physicalSize = const Size(1600, 900);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  final repository = _FakePersonAdminRepository(
    persons: persons,
    devices: devices,
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        personAdminRepositoryProvider.overrideWithValue(repository),
      ],
      child: MaterialApp(theme: bftagLightTheme(), home: const PersonsScreen()),
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

  testWidgets('BF-Tag ohne Handys: no pairing codes and no device management',
      (tester) async {
    await _pump(tester, persons: [_person(id: 'p1', displayName: 'Max')]);

    expect(find.byKey(const Key('print-pairing-codes')), findsNothing);
    expect(find.byKey(const Key('devices-p1')), findsNothing);
    expect(find.text('Codes drucken'), findsNothing);
    expect(find.text('Geräte'), findsNothing);
    expect(find.byKey(const Key('create-person')), findsOneWidget);
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
    'editing a person calls updatePerson with the entered fields',
    (tester) async {
      final person = _person(
        id: 'p1',
        displayName: 'Max Mustermann',
        personType: PersonType.youth,
        permission: Permission.crew,
      );
      final repository = await _pump(tester, persons: [person]);

      await tester.tap(find.byKey(const Key('person-p1')));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('person-form-display-name')),
        'Max Geändert',
      );
      await tester.tap(find.byKey(const Key('person-form-submit')));
      await tester.pumpAndSettle();

      expect(repository.persons.single.displayName, 'Max Geändert');
      expect(find.textContaining('Max Geändert'), findsOneWidget);
    },
  );

  testWidgets(
    'toggling active calls updatePerson with active after confirm',
    (tester) async {
      final person = _person(id: 'p1', active: true);
      final repository = await _pump(tester, persons: [person]);

      await tester.tap(find.byKey(const Key('active-switch-p1')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('confirm-dialog-confirm')));
      await tester.pumpAndSettle();

      expect(repository.persons.single.active, isFalse);
    },
  );

  testWidgets(
    'load error shows the error message instead of the list',
    (tester) async {
      tester.view.physicalSize = const Size(1600, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            personAdminRepositoryProvider.overrideWithValue(
              _ThrowingPersonAdminRepository(),
            ),
          ],
          child:
              MaterialApp(theme: bftagLightTheme(), home: const PersonsScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.text('Personen konnten nicht geladen werden.'),
        findsOneWidget,
      );
      expect(find.byKey(const Key('persons-list')), findsNothing);
    },
  );

  testWidgets(
    'load error shows a retry button that calls the same load path',
    (tester) async {
      tester.view.physicalSize = const Size(1600, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      final repository = _ThrowingPersonAdminRepository();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            personAdminRepositoryProvider.overrideWithValue(repository),
          ],
          child:
              MaterialApp(theme: bftagLightTheme(), home: const PersonsScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Erneut versuchen'), findsOneWidget);

      await tester.tap(find.text('Erneut versuchen'));
      await tester.pumpAndSettle();

      // Still errors (fake always throws), but the retry path (same
      // `_reload()` that initState used) was exercised without crashing.
      expect(
        find.text('Personen konnten nicht geladen werden.'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'empty list shows "Noch keine Personen" and a working create action',
    (tester) async {
      final repository = await _pump(tester, persons: []);

      expect(find.textContaining('Noch keine Personen'), findsOneWidget);

      await tester.tap(find.byKey(const Key('persons-empty-create')));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('person-form-display-name')),
        'Erste Person',
      );
      await tester.tap(find.byKey(const Key('person-form-submit')));
      await tester.pumpAndSettle();

      expect(repository.createCalls, hasLength(1));
      expect(repository.createCalls.single.$1, 'Erste Person');
    },
  );

  testWidgets(
    'each person row shows Personentyp and Berechtigung as separate chips',
    (tester) async {
      await _pump(
        tester,
        persons: [
          _person(
            id: 'p1',
            displayName: 'Max Mustermann',
            personType: PersonType.youth,
            permission: Permission.crew,
          ),
        ],
      );

      expect(find.text('Jugendlicher'), findsOneWidget);
      expect(find.text('Mannschaft'), findsOneWidget);
      // No more "·"-separated free text for type/permission.
      expect(find.textContaining('Jugendlicher · Mannschaft'), findsNothing);
    },
  );

  testWidgets(
    'web-access-{id} is only shown for permission != crew',
    (tester) async {
      await _pump(
        tester,
        persons: [
          _person(id: 'p1', permission: Permission.crew),
          _person(id: 'p2', permission: Permission.dispatch),
        ],
      );

      expect(find.byKey(const Key('web-access-p1')), findsNothing);
      expect(find.byKey(const Key('web-access-p2')), findsOneWidget);
    },
  );

}
