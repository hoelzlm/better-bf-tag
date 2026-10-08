set shell := ["bash", "-euo", "pipefail", "-c"]

# List available recipes.
default:
    @just --list

# Start the full local stack (db + backend) via Docker Compose.
dev:
    docker compose up --build

# Run the backend test suite.
test:
    cd backend && npm test

# Run everything CI runs, locally: backend + Flutter.
ci:
    cd backend && npm ci
    cd backend && npm run typecheck
    cd backend && npm run lint
    cd backend && npm run openapi:check
    cd backend && npm test
    flutter pub get
    flutter analyze apps/web apps/mobile packages/core
    dart analyze packages/api_client --no-fatal-warnings
    cd packages/core && flutter test
    cd apps/web && flutter test
    cd apps/mobile && flutter test
    cd apps/web && flutter build web --release

# Regenerate backend/openapi.json and the Dart client in packages/api_client.
gen-api:
    cd backend && npm run openapi
    ./scripts/gen-api.sh

# Static analysis for the Dart packages.
analyze:
    dart analyze packages/api_client && flutter analyze apps/web apps/mobile packages/core

# Build the web app for production.
build-web:
    cd apps/web && flutter build web --release

# Run the web app locally against a local backend.
web:
    cd apps/web && flutter run -d web-server --web-port 8081 --dart-define=API_BASE_URL=http://localhost:8080

# Run the mobile app locally against a local backend (Android emulator).
mobile:
    cd apps/mobile && flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8080

# Build the production images and smoke-test the full infra/ compose stack locally.
infra-smoke:
    ./infra/smoke-test.sh

# Automated local round-trip test for the nightly backup/restore scripts.
infra-backup-test:
    ./infra/test/backup-restore.sh
