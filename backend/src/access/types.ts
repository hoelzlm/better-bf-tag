export type PersonType = 'youth' | 'supervisor';
/**
 * `radio` = Funktisch (BF-Tag ohne Handys): setzt Fahrzeugstatus, sieht nur
 * laufende/abgeschlossene Einsätze (kein Drehbuch, keine Entwürfe, keine
 * geplanten Alarmierungen), darf nachalarmieren und Einsätze schließen, aber
 * keine Einsätze anlegen oder Alarmierungen planen.
 */
export type Permission = 'crew' | 'preparation' | 'dispatch' | 'radio' | 'admin';
