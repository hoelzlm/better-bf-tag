# backend

API-Server: REST (`/api/v1`), WebSocket (`/ws`), Push-Versand und geplante Alarme (noch nicht angelegt).

- Sprache: Node.js/TypeScript mit Fastify, Drizzle und pg-boss ([ADR 0002](../docs/adr/0002-backend-sprache.md))
- API-Entwurf: [docs/04-api.md](../docs/04-api.md)
- Datenmodell: [docs/03-datenmodell.md](../docs/03-datenmodell.md)
- Push: [docs/05-alarmierung-push.md](../docs/05-alarmierung-push.md)
