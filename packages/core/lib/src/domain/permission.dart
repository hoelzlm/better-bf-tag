/// Berechtigung: was eine Person im System tun darf.
///
/// Siehe CONTEXT.md ("Berechtigung"). Nicht mit [PersonType] verwechseln.
enum Permission {
  crew,
  preparation,
  dispatch,
  admin;

  /// Parses the wire representation used by the backend API.
  static Permission fromApi(String value) {
    switch (value) {
      case 'crew':
        return Permission.crew;
      case 'preparation':
        return Permission.preparation;
      case 'dispatch':
        return Permission.dispatch;
      case 'admin':
        return Permission.admin;
      default:
        throw ArgumentError.value(value, 'value', 'Unknown Permission');
    }
  }

  /// German display label.
  String get label {
    switch (this) {
      case Permission.crew:
        return 'Mannschaft';
      case Permission.preparation:
        return 'Einsatzvorbereitung';
      case Permission.dispatch:
        return 'Leitstelle';
      case Permission.admin:
        return 'Administrator';
    }
  }
}

/// Personentyp: ob eine Person Jugendlicher oder Betreuer ist.
///
/// Unabhängig von der [Permission]. Siehe CONTEXT.md ("Personentyp").
enum PersonType {
  youth,
  supervisor;

  /// German display label.
  String get label {
    switch (this) {
      case PersonType.youth:
        return 'Jugendlicher';
      case PersonType.supervisor:
        return 'Betreuer';
    }
  }
}
