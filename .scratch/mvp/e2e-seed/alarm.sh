#!/usr/bin/env bash
set -euo pipefail
cd /home/markus/.hermes/cache/scratch/e2e
AP=$(grep BOOTSTRAP_ADMIN_PASSWORD prod.env | cut -d= -f2); B=https://localhost:18443/api/v1
j() { python3 -c "import sys,json;d=json.load(sys.stdin);print($1)"; }
T=$(curl -sk $B/auth/login -H 'content-type: application/json' -d "{\"username\":\"e2e-admin\",\"password\":\"$AP\"}" | j 'd["access_token"]')
H=(-H "authorization: Bearer $T" -H 'content-type: application/json')
V=$(curl -sk $B/vehicles "${H[@]}" | j '[v["id"] for v in (d if isinstance(d,list) else d.get("vehicles",d.get("items")))][0]')
S=$(date -u -d '-1 hour' +%FT%TZ); E=$(date -u -d '+8 hour' +%FT%TZ)
D=$(curl -sk $B/bf-days "${H[@]}" -d "{\"name\":\"UI Alarm Tag\",\"starts_at\":\"$S\",\"ends_at\":\"$E\"}" | j 'd["id"]')
curl -sk -X POST $B/bf-days/$D/start -H "authorization: Bearer $T" -o /dev/null -w 'start=%{http_code}\n'
I=$(curl -sk $B/bf-days/$D/incidents "${H[@]}" -d '{"keyword":"B3 Großbrand Lagerhalle","address":"Industriestr. 7","report":"Starke Rauchentwicklung","script":"GEHEIM-DREHBUCH"}' | j 'd["id"]')
curl -sk $B/incidents/$I/alarms "${H[@]}" -d "{\"vehicle_ids\":[\"$V\"]}" -o /dev/null -w 'alarm=%{http_code}\n'
