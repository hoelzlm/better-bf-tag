import 'package:bftag_api_client/bftag_api_client.dart';
import 'package:bftag_core/bftag_core.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('every Login permission wire value maps to its own Permission', () {
    for (final value in Login200ResponsePersonPermissionEnum.values) {
      expect(Permission.fromApi(value.name).name, value.name);
    }
  });

  test('radio is the Funktisch', () {
    expect(Permission.fromApi('radio'), Permission.radio);
    expect(Permission.radio.label, 'Funktisch');
    expect(Permission.radio.canRunIncidents, isTrue);
    expect(Permission.preparation.canRunIncidents, isFalse);
  });
}
