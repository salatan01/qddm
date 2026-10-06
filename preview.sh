#!/usr/bin/env bash
# preview.sh — run the qddm SDDM theme in a fullscreen window, no logout.
# Usage: ./preview.sh
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export QML2_IMPORT_PATH="$DIR/preview-imports${QML2_IMPORT_PATH:+:$QML2_IMPORT_PATH}"

pick_qml() {
    if command -v qml >/dev/null 2>&1; then echo "qml"; return 0; fi
    if command -v qmlscene >/dev/null 2>&1; then echo "qmlscene"; return 0; fi
    return 1
}

if BIN=$(pick_qml); then
    exec "$BIN" "$DIR/preview.qml"
fi

echo "preview.sh: no 'qml' on PATH, falling back to nix shell (Qt6 + GStreamer)..." >&2
exec nix shell \
    "nixpkgs#qt6.qtdeclarative" \
    "nixpkgs#qt6.qt5compat" \
    "nixpkgs#qt6.qtmultimedia" \
    "nixpkgs#qt6.qtsvg" \
    "nixpkgs#gst_all_1.gstreamer" \
    "nixpkgs#gst_all_1.gst-plugins-base" \
    "nixpkgs#gst_all_1.gst-plugins-good" \
    "nixpkgs#gst_all_1.gst-plugins-bad" \
    --command qml "$DIR/preview.qml"
