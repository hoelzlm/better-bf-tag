/// A one-time pairing code for a Person (ADR 0010), as returned by
/// `POST /persons/{id}/pairing-code` / `POST /persons/pairing-codes`.
///
/// [code] is the full `ABCD-EFGH` formatted code; the plaintext is only ever
/// delivered in this response and must be shown to the admin immediately.
class PairingCodeItem {
  const PairingCodeItem({
    required this.personId,
    required this.displayName,
    required this.code,
    required this.expiresAt,
  });

  final String personId;
  final String displayName;
  final String code;
  final DateTime expiresAt;

  /// The 8 code characters without the hyphen, as used for the QR content
  /// (ADR 0010: "Der QR-Code enthält nur die 8 Zeichen").
  String get rawCode => code.replaceAll('-', '');
}
