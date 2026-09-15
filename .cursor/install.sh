#!/usr/bin/env bash
#
# Idempotent environment bootstrap for the sohba Android APK workspace.
#
# This repository is the *extracted* contents of a release APK (compiled
# classes*.dex, binary AndroidManifest.xml, resources.arsc, native libs, etc.),
# not a Gradle source project. The development experience is therefore centred
# on Android SDK tooling: inspect / decompile the artifacts and repackage them
# into an aligned, signed, installable APK.
#
# This script installs that toolchain and is safe to re-run: every step checks
# for an existing install before downloading anything.
set -euo pipefail

log() { printf '\n\033[1;34m==> %s\033[0m\n' "$*"; }

ANDROID_HOME="${ANDROID_HOME:-$HOME/android-sdk}"
CMDLINE_TOOLS_VERSION="11076708"
BUILD_TOOLS_VERSION="34.0.0"
APKTOOL_VERSION="2.10.0"
JADX_VERSION="1.5.0"
TOOLS_BIN="$HOME/.local/bin"

mkdir -p "$ANDROID_HOME" "$TOOLS_BIN"

# ---------------------------------------------------------------------------
# 1. Android command-line tools + build-tools + platform-tools
# ---------------------------------------------------------------------------
if [ ! -x "$ANDROID_HOME/cmdline-tools/latest/bin/sdkmanager" ]; then
  log "Installing Android command-line tools ($CMDLINE_TOOLS_VERSION)"
  tmp="$(mktemp -d)"
  curl -fsSL -o "$tmp/cmdline-tools.zip" \
    "https://dl.google.com/android/repository/commandlinetools-linux-${CMDLINE_TOOLS_VERSION}_latest.zip"
  unzip -q "$tmp/cmdline-tools.zip" -d "$tmp"
  mkdir -p "$ANDROID_HOME/cmdline-tools/latest"
  # The zip extracts to a top-level "cmdline-tools" dir; move its contents into "latest".
  cp -r "$tmp/cmdline-tools/." "$ANDROID_HOME/cmdline-tools/latest/"
  rm -rf "$tmp"
else
  log "Android command-line tools already present"
fi

export ANDROID_HOME
export ANDROID_SDK_ROOT="$ANDROID_HOME"
export PATH="$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools:$ANDROID_HOME/build-tools/$BUILD_TOOLS_VERSION:$PATH"

if [ ! -d "$ANDROID_HOME/build-tools/$BUILD_TOOLS_VERSION" ] || [ ! -d "$ANDROID_HOME/platform-tools" ]; then
  log "Accepting SDK licenses and installing build-tools $BUILD_TOOLS_VERSION + platform-tools"
  yes | sdkmanager --licenses >/dev/null 2>&1 || true
  sdkmanager --install "build-tools;${BUILD_TOOLS_VERSION}" "platform-tools" >/dev/null
else
  log "Android build-tools $BUILD_TOOLS_VERSION + platform-tools already present"
fi

# ---------------------------------------------------------------------------
# 2. apktool (decode / rebuild resources)
# ---------------------------------------------------------------------------
if [ ! -f "$TOOLS_BIN/apktool.jar" ]; then
  log "Installing apktool $APKTOOL_VERSION"
  curl -fsSL -o "$TOOLS_BIN/apktool.jar" \
    "https://github.com/iBotPeaches/Apktool/releases/download/v${APKTOOL_VERSION}/apktool_${APKTOOL_VERSION}.jar"
  cat > "$TOOLS_BIN/apktool" <<EOF
#!/usr/bin/env bash
exec java -jar "$TOOLS_BIN/apktool.jar" "\$@"
EOF
  chmod +x "$TOOLS_BIN/apktool"
else
  log "apktool already present"
fi

# ---------------------------------------------------------------------------
# 3. jadx (dex -> Java decompiler for source inspection)
# ---------------------------------------------------------------------------
if [ ! -x "$TOOLS_BIN/jadx" ]; then
  log "Installing jadx $JADX_VERSION"
  tmp="$(mktemp -d)"
  curl -fsSL -o "$tmp/jadx.zip" \
    "https://github.com/skylot/jadx/releases/download/v${JADX_VERSION}/jadx-${JADX_VERSION}.zip"
  mkdir -p "$HOME/.local/jadx"
  unzip -oq "$tmp/jadx.zip" -d "$HOME/.local/jadx"
  ln -sf "$HOME/.local/jadx/bin/jadx" "$TOOLS_BIN/jadx"
  ln -sf "$HOME/.local/jadx/bin/jadx-gui" "$TOOLS_BIN/jadx-gui" 2>/dev/null || true
  rm -rf "$tmp"
else
  log "jadx already present"
fi

# ---------------------------------------------------------------------------
# 4. Debug keystore for signing rebuilt APKs
# ---------------------------------------------------------------------------
KEYSTORE="$HOME/.android/debug.keystore"
if [ ! -f "$KEYSTORE" ]; then
  log "Generating debug keystore"
  mkdir -p "$HOME/.android"
  keytool -genkeypair -v \
    -keystore "$KEYSTORE" \
    -alias androiddebugkey \
    -keyalg RSA -keysize 2048 -validity 10000 \
    -storepass android -keypass android \
    -dname "CN=Android Debug,O=Android,C=US" >/dev/null 2>&1
else
  log "Debug keystore already present"
fi

log "Toolchain summary"
java -version 2>&1 | head -1
echo "sdkmanager: $("$ANDROID_HOME/cmdline-tools/latest/bin/sdkmanager" --version 2>/dev/null || echo n/a)"
echo "apksigner:  $("$ANDROID_HOME/build-tools/$BUILD_TOOLS_VERSION/apksigner" --version 2>/dev/null || echo n/a)"
echo "zipalign:   $ANDROID_HOME/build-tools/$BUILD_TOOLS_VERSION/zipalign"
echo "apktool:    $(java -jar "$TOOLS_BIN/apktool.jar" --version 2>/dev/null || echo n/a)"
echo "jadx:       $("$TOOLS_BIN/jadx" --version 2>/dev/null || echo n/a)"

log "Environment ready. See scripts/rebuild-apk.sh to repackage the APK."
