import 'permission.dart';

/// Ein Mensch, der das System nutzt oder in einer Besatzung eingeteilt ist.
///
/// Siehe CONTEXT.md ("Person").
class Person {
  const Person({
    required this.id,
    required this.displayName,
    required this.personType,
    required this.permission,
  });

  final String id;
  final String displayName;
  final PersonType personType;
  final Permission permission;
}
