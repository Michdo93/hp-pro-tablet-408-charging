#!/usr/bin/bash
set -euo pipefail

REPO_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

if [[ "${EUID}" -ne 0 ]]; then
    echo "Please run as root: sudo $0" >&2
    exit 1
fi

install -D -m 0755 "$REPO_DIR/scripts/hp-tablet-charging" \
    /usr/local/sbin/hp-tablet-charging
install -D -m 0644 "$REPO_DIR/config/hp-tablet-charging" \
    /etc/default/hp-tablet-charging
install -D -m 0644 "$REPO_DIR/systemd/hp-tablet-charging.service" \
    /etc/systemd/system/hp-tablet-charging.service

cat > /etc/modules-load.d/hp-pro-tablet-408.conf <<'EOF'
# X-Powers AXP288 power-management IC
axp288_adc
axp288_fuel_gauge
axp288_charger
extcon_axp288
EOF

systemctl daemon-reload
systemctl enable hp-tablet-charging.service
systemctl restart hp-tablet-charging.service

echo
echo "Installation completed."
echo "Service status:"
systemctl --no-pager --full status hp-tablet-charging.service || true
if [[ -r /sys/class/power_supply/axp288_charger/input_current_limit ]]; then
    printf 'Current input limit: '
    cat /sys/class/power_supply/axp288_charger/input_current_limit
fi
echo
echo "Review README.md for electrical safety notes and deployment limitations."
