/// Fahrzeugstatus (FMS): der Funkmeldesystem-Status eines Fahrzeugs.
///
/// Siehe docs/03-datenmodell.md ("Fahrzeugstatus (FMS)").
enum FmsStatus {
  s1(1, 'Einsatzbereit über Funk'),
  s2(2, 'Einsatzbereit auf Wache'),
  s3(3, 'Einsatz übernommen'),
  s4(4, 'Am Einsatzort'),
  s5(5, 'Sprechwunsch'),
  s6(6, 'Nicht einsatzbereit'),
  s7(7, 'Patient aufgenommen'),
  s8(8, 'Am Transportziel');

  const FmsStatus(this.code, this.label);

  /// The wire representation (1–8), matching the FMS convention.
  final int code;

  /// German display label.
  final String label;

  /// Parses the wire representation used by the backend API.
  static FmsStatus fromCode(int code) {
    return FmsStatus.values.firstWhere(
      (status) => status.code == code,
      orElse: () => throw ArgumentError.value(code, 'code', 'Unknown FmsStatus'),
    );
  }
}
