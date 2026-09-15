#!/bin/bash
set -euo pipefail

# Razer Blade 14 RZ09-0508 / Realtek ALC298 speaker workaround.
# The ALSA card number is not assumed to be fixed.

CODEC=""

for i in {1..30}; do
    for dev in /dev/snd/hwC*D0; do
        [[ -e "$dev" ]] || continue

        card="${dev#/dev/snd/hwC}"
        card="${card%D0}"
        codec_file="/proc/asound/card${card}/codec#0"

        if [[ -r "$codec_file" ]] && grep -q "Codec: Realtek ALC298" "$codec_file"; then
            CODEC="$dev"
            break 2
        fi
    done
    sleep 1
done

if [[ -z "$CODEC" ]]; then
    echo "Realtek ALC298 HDA codec device not found."
    exit 1
fi

# Node 0x17 is the internal speaker pin.
# 0x40 = enable output
# 0x02 = enable EAPD
# 0x01 = select the working 0x0d connection
/usr/bin/hda-verb "$CODEC" 0x17 SET_PIN_WIDGET_CONTROL 0x40
/usr/bin/hda-verb "$CODEC" 0x17 SET_EAPD_BTLENABLE 0x02
/usr/bin/hda-verb "$CODEC" 0x17 SET_CONNECT_SEL 0x01

echo "Applied ALC298 speaker fix using $CODEC"
