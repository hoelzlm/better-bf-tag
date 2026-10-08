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

# Static analysis for the Dart packages. T01-6 extends this to apps/web and packages/core.
analyze:
    dart analyze packages/api_client
