/// German Hersteller-Hinweis für den Akku-Optimierung-Schritt im
/// Onboarding (ADR 0021): viele Android-Hersteller killen Apps im
/// Hintergrund trotz deaktivierter Akku-Optimierung aggressiv weiter;
/// dontkillmyapp.com dokumentiert je Hersteller die nötigen
/// Zusatzschritte.
String batteryHintFor(String manufacturer) {
  final normalized = manufacturer.toLowerCase();
  if (normalized.contains('samsung')) {
    return 'Samsung schränkt Apps im Hintergrund zusätzlich über "Nicht '
        'überwachte Apps" bzw. den Akku-Schutz ein. Öffne die '
        'Akku-Einstellungen von BF-Tag und erlaube uneingeschränkten '
        'Hintergrundbetrieb. Details: dontkillmyapp.com/samsung';
  }
  if (normalized.contains('xiaomi') ||
      normalized.contains('redmi') ||
      normalized.contains('poco')) {
    return 'Xiaomi/Redmi/POCO (MIUI) benötigt zusätzlich "Autostart" und '
        '"Keine Einschränkungen" im Akku-Sparer für BF-Tag, sonst werden '
        'Benachrichtigungen im Hintergrund unterdrückt. Details: '
        'dontkillmyapp.com/xiaomi';
  }
  if (normalized.contains('huawei') || normalized.contains('honor')) {
    return 'Huawei/Honor benötigt zusätzlich einen Eintrag in den '
        '"Geschützten Apps" sowie "Manuelle Verwaltung" mit aktivierten '
        'Hintergrund-Berechtigungen für BF-Tag. Details: '
        'dontkillmyapp.com/huawei';
  }
  if (normalized.contains('oneplus') ||
      normalized.contains('oppo') ||
      normalized.contains('realme')) {
    return 'OnePlus/Oppo/Realme (ColorOS/OxygenOS) benötigt zusätzlich '
        '"Keine Aktivitätsbeschränkung" bzw. "Autostart erlauben" für '
        'BF-Tag, damit der Alarm im Hintergrund ankommt. Details: '
        'dontkillmyapp.com/oneplus';
  }
  if (normalized.contains('vivo')) {
    return 'Vivo (Funtouch OS) benötigt zusätzlich "Hintergrund hochfrequente '
        'Aktivität erlauben" und Autostart für BF-Tag in den '
        'Akku-Einstellungen. Details: dontkillmyapp.com/vivo';
  }
  return 'Manche Hersteller schränken Apps im Hintergrund trotz '
      'deaktivierter Akku-Optimierung zusätzlich ein. Prüfe die '
      'Akku-/Autostart-Einstellungen deines Geräts für BF-Tag. Details: '
      'dontkillmyapp.com';
}
