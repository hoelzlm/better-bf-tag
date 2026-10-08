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

# Regenerate backend/openapi.json and the Dart client in packages/api_client.
gen-api:
    cd backend && npm run openapi
    ./scripts/gen-api.sh

# Static analysis for the Dart packages.
analyze:
    dart analyze packages/api_client && flutter analyze apps/web packages/core

# Build the web app for production.
build-web:
    cd apps/web && flutter build web --release

# Run the web app locally against a local backend.
web:
    cd apps/web && flutter run -d web-server --web-port 8081 --dart-define=API_BASE_URL=http://localhost:8080
