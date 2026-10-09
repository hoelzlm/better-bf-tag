import 'package:bftag_core/bftag_core.dart';
import 'package:bftag_web/widgets/running_incidents_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Incident _incident({
  String id = 'i1',
  int number = 1,
  String keyword = 'Verkehrsunfall',
  String address = 'Hauptstraße 1',
}) {
  return Incident(
    id: id,
    bfDayId: 'd1',
    number: number,
    keyword: keyword,
    address: address,
    report: 'PKW gegen Baum',
    script: null,
    state: IncidentState.running,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );
}

Vehicle _vehicle({String id = 'v1', String shortName = 'HLF 1'}) {
  return Vehicle(
    id: id,
    callSign: 'Florian 1',
    shortName: shortName,
    type: 'HLF',
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
  String function = 'GF',
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

Future<void> _pump(
  WidgetTester tester, {
  required List<Incident> incidents,
  required List<Alarm> alarms,
  List<Vehicle> vehicles = const [],
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        incidentsProvider.overrideWith((ref) => Stream.value(incidents)),
        alarmsProvider.overrideWith((ref) => Stream.value(alarms)),
        vehiclesProvider.overrideWith((ref) => Stream.value(vehicles)),
      ],
      child: const MaterialApp(
        home: Scaffold(body: RunningIncidentsSection()),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('empty state shows "Keine laufenden Einsätze"', (tester) async {
    await _pump(tester, incidents: const [], alarms: const []);

    expect(find.text('Keine laufenden Einsätze'), findsOneWidget);
  });

  testWidgets(
      'shows the three AckStates with icons, and counts with noDevice not '
      'counted as pending', (tester) async {
    final alarm = Alarm(
      id: 'a1',
      incidentId: 'i1',
      state: AlarmState.triggered,
      triggeredAt: DateTime.now().subtract(const Duration(minutes: 5)),
      vehicleIds: const ['v1'],
      recipients: [
        _recipient(
          personId: 'p1',
          displayName: 'Max Muster',
          acknowledgedAt: DateTime.now(),
        ),
        _recipient(personId: 'p2', displayName: 'Erika Musterfrau'),
        _recipient(
          personId: 'p3',
          displayName: 'Peter Probe',
          hasDevice: false,
        ),
      ],
    );

    await _pump(
      tester,
      incidents: [_incident(id: 'i1')],
      alarms: [alarm],
      vehicles: [_vehicle(id: 'v1', shortName: 'HLF 1')],
    );

    expect(find.text('1 quittiert · 1 ausstehend · 1 kein Gerät'),
        findsOneWidget);

    expect(
      find.byKey(const Key('ack-icon-p1')),
      findsOneWidget,
      reason: 'acknowledged recipient',
    );
    expect(find.byIcon(Icons.check_circle), findsOneWidget);
    expect(find.byIcon(Icons.more_horiz), findsOneWidget);
    expect(find.byIcon(Icons.remove_circle_outline), findsOneWidget);

    expect(
      find.textContaining('Max Muster – HLF 1, GF (quittiert)'),
      findsOneWidget,
    );
    expect(
      find.textContaining('Erika Musterfrau – HLF 1, GF (ausstehend)'),
      findsOneWidget,
    );
    expect(
      find.textContaining('Peter Probe – HLF 1, GF (kein Gerät)'),
      findsOneWidget,
    );
  });

  testWidgets('shows incident number, keyword, address and elapsed time',
      (tester) async {
    final alarm = Alarm(
      id: 'a1',
      incidentId: 'i1',
      state: AlarmState.triggered,
      triggeredAt: DateTime.now().subtract(const Duration(minutes: 7)),
      vehicleIds: const ['v1'],
      recipients: const [],
    );

    await _pump(
      tester,
      incidents: [
        _incident(
          id: 'i1',
          number: 3,
          keyword: 'Zimmerbrand',
          address: 'Musterweg 5',
        ),
      ],
      alarms: [alarm],
    );

    expect(find.textContaining('#3 Zimmerbrand – Musterweg 5'), findsOneWidget);
    expect(find.textContaining('seit 7 min'), findsOneWidget);
  });
}
