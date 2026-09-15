# Razer Blade 14 RZ09-0508 — ALC298 Speaker Fix

A small Linux workaround for the Razer Blade 14 RZ09-0508 where the built-in speakers are detected and ALSA playback works, but the internal speakers produce no sound after boot.

Tested on a Razer Blade 14 RZ09-0508 with Realtek ALC298 and CachyOS kernel 7.2.5-1-cachyos.

## What it does

The workaround configures the Realtek ALC298 internal speaker pin (Node 0x17):

```text
SET_PIN_WIDGET_CONTROL 0x40
SET_EAPD_BTLENABLE     0x02
SET_CONNECT_SEL        0x01
```

The included script finds the ALC298 codec dynamically instead of assuming a fixed ALSA card number.

## Requirements

- Razer Blade 14 RZ09-0508
- Realtek ALC298
- systemd
- `hda-verb` (commonly provided by `alsa-tools`)

Check:

```bash
command -v hda-verb
```

## Installation

```bash
git clone https://github.com/Acr4niu5/razer-blade-14-alc298-audio-fix.git
cd razer-blade-14-alc298-audio-fix
sudo ./install.sh
```

The installer verifies the laptop model and ALC298 before installing the workaround.

Reboot and test the internal speakers. You can also test immediately:

```bash
sudo systemctl restart razer-audio-fix.service
speaker-test -c 2 -t wav
```

## Verify the codec

```bash
grep -E 'Codec:|Vendor Id:|Subsystem Id:|Revision Id:' /proc/asound/card*/codec*
```

The tested machine reported:

```text
Codec: Realtek ALC298
Vendor Id: 0x10ec0298
Subsystem Id: 0x1a582022
Revision Id: 0x100103
```

## Verify the speaker node

A working configuration should show Node 0x17 with approximately:

```text
EAPD 0x2: EAPD
Pin-ctls: 0x40: OUT
Connection: 3
    0x0c 0x0d* 0x06
```

The `*` indicates selector 1 (`0x0d`) is selected.

You can query the live values with:

```bash
sudo hda-verb /dev/snd/hwC3D0 0x17 GET_PIN_WIDGET_CONTROL 0
sudo hda-verb /dev/snd/hwC3D0 0x17 GET_EAPD_BTLENABLE 0
sudo hda-verb /dev/snd/hwC3D0 0x17 GET_CONNECT_SEL 0
sudo hda-verb /dev/snd/hwC3D0 0x17 GET_POWER_STATE 0
```

The device path can differ between systems.

## Why this workaround exists

During troubleshooting, the following was established:

- The ALC298 was detected correctly.
- ALSA exposed the playback device.
- The Speaker mixer was enabled at 100%.
- `speaker-test -D hw:3,0` opened the hardware successfully.
- Node 0x17 was identified as the internal speaker pin.
- Connection selector 0 produced quieter audio.
- Connection selector 1 produced normal-volume audio.
- Connection selector 2 produced no audio.
- Pin control 0x40 + EAPD 0x02 + selector 1 restored normal speaker output.

The repository deliberately uses only these three verbs rather than replaying a large vendor-specific codec dump.

## Troubleshooting

Service status:

```bash
systemctl status razer-audio-fix.service
```

Logs:

```bash
journalctl -u razer-audio-fix.service
```

Hardware information:

```bash
uname -r
sudo dmidecode -s system-product-name
cat /proc/asound/cards
```

If it does not work, open an issue and include the output above plus the codec information. Remove unrelated personal information.

## Backup and uninstall

The installer creates a one-time backup of the ALC298 codec state **before the workaround is enabled**:

```text
/var/lib/razer-audio-fix/
├── codec-before-install.txt
└── state-before-install.txt
```

The backup is deliberately not overwritten when `install.sh` is run again. This preserves the original pre-install state.

When uninstalling:

```bash
sudo ./uninstall.sh
```

the service is disabled and the saved Node 0x17 values are restored to the currently detected ALC298 codec.

The backup is retained after uninstall so it can be inspected or used for manual recovery.

The workaround does not change firmware, kernel configuration, PipeWire configuration, or persistent ALSA configuration.

## Disclaimer

This is an unofficial community workaround. It is not an official Razer or Realtek driver.

See [DISCLAIMER.md](DISCLAIMER.md).

## License

MIT. See [LICENSE](LICENSE).
