# Disclaimer

This project is provided **as-is and without warranty**.

It contains low-level Linux HDA codec commands intended for the Razer Blade 14 RZ09-0508 with Realtek ALC298.

The commands are not guaranteed to work on other Razer models, other ALC298 implementations, other codecs, or different firmware/kernel combinations.

Use this software at your own risk.

The author and contributors are not responsible for loss of audio functionality, hardware or software damage, data loss, system instability, or incompatibilities caused by kernel, firmware, distribution, ALSA, PipeWire, or other updates.

The workaround changes the runtime state of the audio codec. The installer backs up the pre-install codec dump and relevant Node 0x17 values under `/var/lib/razer-audio-fix/` and the uninstaller attempts to restore those values. It does not intentionally write firmware or permanently modify the hardware, but users should understand that these are low-level codec commands.

If this workaround does not work on your hardware, do not assume that the same HDA verbs are appropriate for it.

This project is an unofficial community workaround and is not affiliated with or endorsed by Razer or Realtek.
