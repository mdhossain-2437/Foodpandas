#!/usr/bin/env bash
# Installs the Food-Pandas toolchain: Flutter (web) and the Cloud Functions packages.
set -euo pipefail

FLUTTER_VERSION="3.47.9"
FLUTTER_ROOT="${FLUTTER_ROOT:-/opt/flutter}"
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

if ! "$FLUTTER_ROOT/bin/flutter" --version 2>/dev/null | grep -q "Flutter $FLUTTER_VERSION "; then
  echo "Installing Flutter $FLUTTER_VERSION into $FLUTTER_ROOT"
  rm -rf "$FLUTTER_ROOT"
  mkdir -p "$FLUTTER_ROOT"
  curl -fsSL "https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_${FLUTTER_VERSION}-stable.tar.xz" \
    | tar -xJ -C "$FLUTTER_ROOT" --strip-components=1
fi
# The Flutter tool reads its version from git, which rejects repositories owned by another user.
if ! git config --global --get-all safe.directory 2>/dev/null | grep -qxF "$FLUTTER_ROOT"; then
  git config --global --add safe.directory "$FLUTTER_ROOT"
fi
export PATH="$FLUTTER_ROOT/bin:$PATH"
flutter config --no-analytics >/dev/null 2>&1 || true

cd "$REPO_ROOT/myapp"
flutter pub get
cd functions
npm ci --no-audit --no-fund
