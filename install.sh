#!/bin/bash
set -euo pipefail

ROOT="$(dirname "$(readlink -f "$0")")"
SERVICE="razer-audio-fix.service"
BACKUP_DIR="/var/lib/razer-audio-fix"

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

HDA_VERB="$(command -v hda-verb || true)"
if [[ -z "$HDA_VERB" ]]; then
    echo "ERROR: hda-verb was not found."
    echo "Install the package providing hda-verb (commonly alsa-tools) and retry."
    exit 1
fi

# Find the ALC298 HDA device dynamically. ALSA card numbers can change.
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

if [[ -z "$CODEC" ]]; then
    echo "ERROR: Could not locate the ALC298 HDA device."
    exit 1
fi

mkdir -p "$BACKUP_DIR"

# Only create the original-state backup once. Re-running install must not
# overwrite the known-good pre-install state.
if [[ ! -f "$BACKUP_DIR/codec-before-install.txt" ]]; then
    card="${CODEC#/dev/snd/hwC}"
    card="${card%D0}"
    cp "/proc/asound/card${card}/codec#0"        "$BACKUP_DIR/codec-before-install.txt"

    {
        echo "CODEC=$CODEC"
        echo "PIN_WIDGET_CONTROL=$("$HDA_VERB" "$CODEC" 0x17 GET_PIN_WIDGET_CONTROL 0 | awk '/value =/ {print $3}')"
        echo "EAPD_BTLENABLE=$("$HDA_VERB" "$CODEC" 0x17 GET_EAPD_BTLENABLE 0 | awk '/value =/ {print $3}')"
        echo "CONNECT_SEL=$("$HDA_VERB" "$CODEC" 0x17 GET_CONNECT_SEL 0 | awk '/value =/ {print $3}')"
    } > "$BACKUP_DIR/state-before-install.txt"

    chmod 600 "$BACKUP_DIR/codec-before-install.txt"               "$BACKUP_DIR/state-before-install.txt"

    echo "Backed up original ALC298 state to $BACKUP_DIR"
else
    echo "Existing backup found; keeping original pre-install state."
fi

install -Dm755 "$ROOT/usr/local/libexec/razer-audio-fix.sh"     /usr/local/libexec/razer-audio-fix.sh
install -Dm644 "$ROOT/systemd/$SERVICE"     "/etc/systemd/system/$SERVICE"

systemctl daemon-reload
systemctl enable --now "$SERVICE"

echo
echo "Installed successfully."
systemctl --no-pager --full status "$SERVICE" || true
