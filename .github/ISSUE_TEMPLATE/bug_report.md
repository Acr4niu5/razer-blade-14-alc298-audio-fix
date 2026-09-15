---
name: Bug report
about: Report a system where the workaround does not work
title: "[BUG] "
labels: bug
assignees: ''
---

## Hardware

- Razer model:
- Linux distribution:
- Kernel:
- BIOS version:

## Problem

What happens after boot? Does running the service manually restore audio?

## Output

```bash
uname -r
sudo dmidecode -s system-product-name
grep -E 'Codec:|Vendor Id:|Subsystem Id:|Revision Id:' /proc/asound/card*/codec*
cat /proc/asound/cards
systemctl status razer-audio-fix.service --no-pager
```

Please remove unrelated personal information.
