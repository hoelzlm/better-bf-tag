# 02 — Fahrzeuge verwalten, Fahrzeugstatus live

**What to build:** Der Administrator pflegt Fahrzeuge im Web. Die Leitstelle setzt bzw. überschreibt den Fahrzeugstatus in der Lage, und jede Änderung erscheint in unter einer Sekunde in allen offenen Clients, ohne Neuladen. Damit steht die Echtzeit-Schicht (WebSocket mit `seq` und Snapshot).

**Blocked by:** 01

**Status:** done

- [x] Fahrzeuge anlegen, bearbeiten, sortieren, deaktivieren (nicht löschen); Funkrufname, Kurzname, Typ
- [x] Fahrzeuge gehören zur eigenen Feuerwehr (eine Zeile mit `is_own`, nicht im UI sichtbar)
- [x] Leitstelle setzt den Fahrzeugstatus (1–8); jede Änderung landet in der Statushistorie mit Quelle
- [x] WebSocket `/ws` mit Authentifizierung, Heartbeat und fortlaufender `seq`; Events `vehicle.status_changed`, `vehicle.updated`
- [x] Snapshot-Endpunkt liefert Fahrzeuge mit Status und aktuelle `seq`
- [x] Das gemeinsame Flutter-Paket enthält den Echtzeit-Client: Reconnect mit Backoff, Snapshot-Reload bei Lücke in `seq`
- [x] Lage zeigt die Fahrzeugstatus-Leiste live
- [x] Tests: Berechtigung (nur Admin pflegt Fahrzeuge, nur Leitstelle/Admin setzt Status im Web), Events kommen bei allen verbundenen Clients an, Snapshot und `seq` sind konsistent

Spec: `.scratch/mvp/spec.md` · Glossar: `CONTEXT.md`
