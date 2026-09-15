#!/bin/bash
set -euo pipefail

SERVICE="razer-audio-fix.service"

if [[ $EUID -ne 0 ]]; then
    echo "Please run: sudo ./uninstall.sh"
    exit 1
fi

systemctl disable --now "$SERVICE" 2>/dev/null || true
rm -f "/etc/systemd/system/$SERVICE"
rm -f /usr/local/libexec/razer-audio-fix.sh
systemctl daemon-reload
systemctl reset-failed "$SERVICE" 2>/dev/null || true

echo "Razer Blade 14 ALC298 audio fix removed."
