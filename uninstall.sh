#!/bin/bash
set -euo pipefail

SERVICE="razer-audio-fix.service"
BACKUP_DIR="/var/lib/razer-audio-fix"

if [[ $EUID -ne 0 ]]; then
    echo "Please run: sudo ./uninstall.sh"
    exit 1
fi

systemctl disable --now "$SERVICE" 2>/dev/null || true

# Restore the exact pre-install values when possible.
if [[ -f "$BACKUP_DIR/state-before-install.txt" ]]; then
    # The saved CODEC path may no longer be valid if ALSA card numbering changed.
    # Locate the current ALC298 device instead.
    HDA_VERB="$(command -v hda-verb || true)"
    CODEC=""

    for dev in /dev/snd/hwC*D0; do
        [[ -e "$dev" ]] || continue
        card="${dev#/dev/snd/hwC}"
        card="${card%D0}"
        codec_file="/proc/asound/card${card}/codec#0"

        if [[ -r "$codec_file" ]] && grep -q "Codec: Realtek ALC298" "$codec_file"; then
            CODEC="$dev"
            break
        fi
    done

    if [[ -n "$CODEC" && -n "$HDA_VERB" ]]; then
        PIN="$(awk -F= '/^PIN_WIDGET_CONTROL=/ {gsub(/[[:space:]]/, "", $2); print $2}' "$BACKUP_DIR/state-before-install.txt")"
        EAPD="$(awk -F= '/^EAPD_BTLENABLE=/ {gsub(/[[:space:]]/, "", $2); print $2}' "$BACKUP_DIR/state-before-install.txt")"
        SEL="$(awk -F= '/^CONNECT_SEL=/ {gsub(/[[:space:]]/, "", $2); print $2}' "$BACKUP_DIR/state-before-install.txt")"

        [[ -n "$PIN" ]] && "$HDA_VERB" "$CODEC" 0x17 SET_PIN_WIDGET_CONTROL "0x$PIN"
        [[ -n "$EAPD" ]] && "$HDA_VERB" "$CODEC" 0x17 SET_EAPD_BTLENABLE "0x$EAPD"
        [[ -n "$SEL" ]] && "$HDA_VERB" "$CODEC" 0x17 SET_CONNECT_SEL "0x$SEL"

        echo "Restored original ALC298 Node 0x17 state."
    else
        echo "WARNING: Could not locate the ALC298 codec for runtime restore."
    fi
else
    echo "No backup found; nothing to restore."
fi

rm -f "/etc/systemd/system/$SERVICE"
rm -f /usr/local/libexec/razer-audio-fix.sh
systemctl daemon-reload
systemctl reset-failed "$SERVICE" 2>/dev/null || true

# Keep the backup after uninstall so it can be inspected or used manually.
echo "Removed Razer Blade 14 ALC298 audio fix."
echo "Original-state backup retained at: $BACKUP_DIR"
