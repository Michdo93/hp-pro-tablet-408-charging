#!/usr/bin/bash
set -euo pipefail

if [[ "${EUID}" -ne 0 ]]; then
    echo "Please run as root: sudo $0" >&2
    exit 1
fi

systemctl disable --now hp-tablet-charging.service 2>/dev/null || true
rm -f /etc/systemd/system/hp-tablet-charging.service
rm -f /usr/local/sbin/hp-tablet-charging
rm -f /etc/default/hp-tablet-charging
rm -f /etc/modules-load.d/hp-pro-tablet-408.conf
systemctl daemon-reload
systemctl reset-failed hp-tablet-charging.service 2>/dev/null || true

echo "Uninstalled. Kernel modules already loaded remain loaded until reboot."
