import 'package:bftag_core/bftag_core.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> _json({bool withScript = true}) {
  return {
    'id': 'i1',
    'bf_day_id': 'd1',
    'number': 1,
    'keyword': 'Verkehrsunfall',
    'address': 'Hauptstraße 1',
    'report': 'PKW gegen Baum',
    'state': 'draft',
    'created_at': '2026-10-09T08:00:00Z',
    'updated_at': '2026-10-09T08:00:00Z',
    if (withScript) 'script': 'Darsteller: 2 Personen, Material: ...',
  };
}

void main() {
  group('Incident.fromJson', () {
    test('with script key present exposes the Drehbuch', () {
      final incident = Incident.fromJson(_json(withScript: true));

      expect(incident.id, 'i1');
      expect(incident.bfDayId, 'd1');
      expect(incident.number, 1);
      expect(incident.keyword, 'Verkehrsunfall');
      expect(incident.address, 'Hauptstraße 1');
      expect(incident.report, 'PKW gegen Baum');
      expect(incident.script, 'Darsteller: 2 Personen, Material: ...');
      expect(incident.state, IncidentState.draft);
    });

    test('without script key, script is null (not inferred)', () {
      final incident = Incident.fromJson(_json(withScript: false));

      expect(incident.script, isNull);
    });

    test('toJson omits script when null', () {
      final incident = Incident.fromJson(_json(withScript: false));

      expect(incident.toJson().containsKey('script'), isFalse);
    });

    test('toJson includes script when present', () {
      final incident = Incident.fromJson(_json(withScript: true));

      expect(incident.toJson()['script'], 'Darsteller: 2 Personen, Material: ...');
    });
  });

  group('IncidentState', () {
    test('German labels', () {
      expect(IncidentState.draft.label, 'Entwurf');
      expect(IncidentState.running.label, 'laufend');
      expect(IncidentState.closed.label, 'abgeschlossen');
      expect(IncidentState.discarded.label, 'verworfen');
    });
  });
}
