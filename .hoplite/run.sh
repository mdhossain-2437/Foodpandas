#!/usr/bin/env bash
# Builds the Flutter web app in release mode and serves it for the Hoplite preview.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
FLUTTER_ROOT="${FLUTTER_ROOT:-/opt/flutter}"
PORT="${PORT:-3000}"

if [ ! -x "$FLUTTER_ROOT/bin/flutter" ]; then
  bash "$REPO_ROOT/.hoplite/setup.sh"
fi
export PATH="$FLUTTER_ROOT/bin:$PATH"

cd "$REPO_ROOT/myapp"
flutter build web --release

# Static server with no-cache headers so a rebuilt bundle is picked up on reload.
exec python3 - "$PORT" <<'PY'
import functools
import http.server
import sys


class NoCacheHandler(http.server.SimpleHTTPRequestHandler):
    def end_headers(self):
        self.send_header("Cache-Control", "no-cache")
        super().end_headers()


handler = functools.partial(NoCacheHandler, directory="build/web")
http.server.ThreadingHTTPServer(("0.0.0.0", int(sys.argv[1])), handler).serve_forever()
PY
