# infra/web.Dockerfile — Caddy + prebuilt Flutter web app + static /datenschutz page.
# Build context MUST be the repo root: docker build -f infra/web.Dockerfile .
# Expects apps/web/build/web to already exist (flutter build web --release --base-href /).
FROM caddy:2-alpine

RUN addgroup -g 1000 bftag && adduser -D -u 1000 -G bftag bftag

COPY apps/web/build/web /srv/web
COPY infra/Caddyfile /etc/caddy/Caddyfile
COPY infra/static /srv/static

RUN mkdir -p /data /config && chown -R bftag:bftag /data /config /srv

USER 1000

EXPOSE 80 443
