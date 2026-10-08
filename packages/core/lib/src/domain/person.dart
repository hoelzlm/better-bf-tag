import 'permission.dart';

/// Ein Mensch, der das System nutzt oder in einer Besatzung eingeteilt ist.
///
/// Siehe CONTEXT.md ("Person"). [active], [hasWebAccess] und [username] are
/// only populated from the Personen-admin endpoints (`GET/POST/PATCH
/// /persons`); the login/session flow leaves them at their defaults.
class Person {
  const Person({
    required this.id,
    required this.displayName,
    required this.personType,
    required this.permission,
    this.active = true,
    this.hasWebAccess = false,
    this.username,
  });

  final String id;
  final String displayName;
  final PersonType personType;
  final Permission permission;
  final bool active;
  final bool hasWebAccess;
  final String? username;

  Person copyWith({
    String? displayName,
    PersonType? personType,
    Permission? permission,
    bool? active,
    bool? hasWebAccess,
    Object? username = _unset,
  }) {
    return Person(
      id: id,
      displayName: displayName ?? this.displayName,
      personType: personType ?? this.personType,
      permission: permission ?? this.permission,
      active: active ?? this.active,
      hasWebAccess: hasWebAccess ?? this.hasWebAccess,
      username: username == _unset ? this.username : username as String?,
    );
  }

  static const _unset = Object();
}
