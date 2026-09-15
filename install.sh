#!/bin/bash
set -euo pipefail

ROOT="$(dirname "$(readlink -f "$0")")"
SERVICE="razer-audio-fix.service"

if [[ $EUID -ne 0 ]]; then
    echo "Please run: sudo ./install.sh"
    exit 1
fi

PRODUCT="$(dmidecode -s system-product-name 2>/dev/null || true)"
if [[ "$PRODUCT" != "Blade 14 - RZ09-0508" ]]; then
    echo "ERROR: This installer targets Blade 14 - RZ09-0508."
    echo "Detected: ${PRODUCT:-unknown}"
    exit 1
fi

if ! grep -Rqs "Codec: Realtek ALC298" /proc/asound/card*/codec* 2>/dev/null; then
    echo "ERROR: Realtek ALC298 was not detected."
    exit 1
fi

if ! command -v hda-verb >/dev/null 2>&1; then
    echo "ERROR: hda-verb was not found."
    echo "Install the package providing hda-verb (commonly alsa-tools) and retry."
    exit 1
fi

install -Dm755 "$ROOT/usr/local/libexec/razer-audio-fix.sh"     /usr/local/libexec/razer-audio-fix.sh
install -Dm644 "$ROOT/systemd/$SERVICE"     "/etc/systemd/system/$SERVICE"

systemctl daemon-reload
systemctl enable --now "$SERVICE"

echo
echo "Installed successfully."
systemctl --no-pager --full status "$SERVICE" || true
