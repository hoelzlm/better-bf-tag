# infra

Deployment auf dem Hetzner-VPS (noch nicht angelegt):

- `docker-compose.yml`: Caddy, Backend, PostgreSQL
- `Caddyfile`: TLS, statischer Flutter-Web-Build, Proxy für `/api` und `/ws`
- `backup.sh`: `pg_dump` + restic auf die Storage Box
- `deploy.sh`: Images ziehen, Web-Build kopieren, Neustart

Entwürfe und Härtung: [docs/07-deployment.md](../docs/07-deployment.md)
