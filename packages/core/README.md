# packages/core

Gemeinsame Dart-Logik für `apps/web` und `apps/mobile` (noch nicht angelegt):

- Domain-Typen (`FmsStatus`, `Role`, `IncidentState`)
- `RealtimeClient` (WebSocket, Reconnect, `seq`-Prüfung, Snapshot)
- Repositories und Riverpod-Provider
- Gemeinsames Theme

Siehe [docs/06-clients.md](../../docs/06-clients.md#gemeinsamer-code-packagescore).
