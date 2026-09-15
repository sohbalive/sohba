#!/usr/bin/env bash
#
# Repackage the extracted APK tree in this repository back into an aligned,
# signed, installable APK.
#
# This repo holds the *unzipped* contents of a release APK (compiled
# classes*.dex, binary AndroidManifest.xml, resources.arsc, native lib/*.so,
# assets, res). Rebuilding therefore means re-zipping those artifacts with the
# alignment Android requires, then signing the archive.
#
# Requirements (installed by .cursor/install.sh):
#   - Android build-tools (zipalign, apksigner)
#   - a debug keystore at ~/.android/debug.keystore
#
# Usage: scripts/rebuild-apk.sh
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

ANDROID_HOME="${ANDROID_HOME:-$HOME/android-sdk}"
BUILD_TOOLS_VERSION="${BUILD_TOOLS_VERSION:-34.0.0}"
BT="$ANDROID_HOME/build-tools/$BUILD_TOOLS_VERSION"
KEYSTORE="${KEYSTORE:-$HOME/.android/debug.keystore}"

ZIPALIGN="$BT/zipalign"
APKSIGNER="$BT/apksigner"

for tool in "$ZIPALIGN" "$APKSIGNER"; do
  if [ ! -x "$tool" ]; then
    echo "ERROR: required tool not found: $tool" >&2
    echo "Run .cursor/install.sh first to install the Android build-tools." >&2
    exit 1
  fi
done

OUT_DIR="$ROOT/dist"
UNSIGNED="$OUT_DIR/app-unsigned.apk"
ALIGNED="$OUT_DIR/app-aligned.apk"
SIGNED="$OUT_DIR/app-signed.apk"

mkdir -p "$OUT_DIR"
rm -f "$UNSIGNED" "$ALIGNED" "$SIGNED"

log() { printf '\n\033[1;34m==> %s\033[0m\n' "$*"; }

# ---------------------------------------------------------------------------
# 1. Build the zip. resources.arsc and native libraries are STORED (not
#    deflated) so that Android 11+ accepts them and zipalign can page-align.
# ---------------------------------------------------------------------------
log "Packaging APK entries (stored: resources.arsc, lib/*.so)"
zip -q -X -0 "$UNSIGNED" resources.arsc
find lib -type f -print | zip -q -X -0 "$UNSIGNED" -@

log "Packaging remaining entries (deflated)"
zip -q -X -9 -r "$UNSIGNED" . \
  -x 'resources.arsc' \
  -x 'lib/*' \
  -x '.git/*' \
  -x '.github/*' \
  -x '.cursor/*' \
  -x 'scripts/*' \
  -x 'dist/*' \
  -x '*.md'

# ---------------------------------------------------------------------------
# 2. Align. -p page-aligns stored .so files; 4 = 4-byte alignment otherwise.
# ---------------------------------------------------------------------------
log "Aligning with zipalign"
"$ZIPALIGN" -p -f 4 "$UNSIGNED" "$ALIGNED"
"$ZIPALIGN" -c -p -v 4 "$ALIGNED" >/dev/null && echo "zipalign verification: OK"

# ---------------------------------------------------------------------------
# 3. Sign (v1 + v2 + v3) with the debug keystore.
# ---------------------------------------------------------------------------
log "Signing with apksigner"
"$APKSIGNER" sign \
  --ks "$KEYSTORE" \
  --ks-key-alias androiddebugkey \
  --ks-pass pass:android \
  --key-pass pass:android \
  --v1-signing-enabled true \
  --v2-signing-enabled true \
  --v3-signing-enabled true \
  --out "$SIGNED" \
  "$ALIGNED"

# ---------------------------------------------------------------------------
# 4. Verify.
# ---------------------------------------------------------------------------
log "Verifying signature"
"$APKSIGNER" verify --verbose "$SIGNED" | sed 's/^/    /'

log "Done"
ls -lh "$SIGNED"
echo "Signed APK: $SIGNED"
