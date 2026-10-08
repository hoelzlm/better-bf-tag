#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."
ROOT="$PWD"

OPENAPI_GENERATOR_IMAGE="openapitools/openapi-generator-cli:v7.16.0"

docker run --rm -u "$(id -u):$(id -g)" -v "$ROOT:/local" "$OPENAPI_GENERATOR_IMAGE" generate \
  -i /local/backend/openapi.json \
  -g dart-dio \
  -o /local/packages/api_client \
  --additional-properties=pubName=bftag_api_client,pubLibrary=bftag_api_client

# Post-process the generated pubspec.yaml so the package joins the root Pub
# workspace and resolves against the SDK/deps actually installed here.
# Idempotent: re-running after a fresh generator output produces the same
# result every time.
dart run "$ROOT/scripts/postprocess_api_client_pubspec.dart" "$ROOT/packages/api_client/pubspec.yaml"

cd "$ROOT"
dart pub get
(cd packages/api_client && dart run build_runner build --delete-conflicting-outputs)
