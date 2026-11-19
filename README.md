# HP Pro Tablet 408 – AXP288 charging configuration

This repository configures the AXP288 power-supply driver on HP Pro Tablet 408
systems running Linux (tested by the author on Lubuntu 26.04 / kernel 7.0.0-43).

It installs:
- a systemd oneshot service that applies an input-current limit at boot;
- a `modules-load.d` file that requests the AXP288-related modules at boot;
- a configurable setting in `/etc/default/hp-tablet-charging`.

## Important electrical safety note

The configured value is a **software input-current limit**, not a measurement
of current actually drawn by the tablet. Setting it to `2000000` (2 A) does not
prove that the power supply, cable, Micro-USB connector, tablet input circuitry,
or connector contacts are rated for continuous 2 A operation.

The tablet previously reported USB charger detection as `SDP=1`, not `DCP`.
Raising the limit bypasses the conservative limit implied by that detection.
Validate each hardware/charger/cable combination under sustained load before
deploying this setting to other tablets. Monitor connector, cable and PSU
temperature and stop if anything becomes unusually hot, unstable, or smells.
A USB power meter can help measure VBUS and current, but some meters interfere
with USB charger detection.

The repository default is deliberately **1.5 A**. Change it to `2000000`
only after independently validating the complete power path. Do not assume
that a Raspberry Pi 5.1 V / 2.5 A supply makes every cable and tablet port safe
at 2 A.

## Supported hardware and assumptions

- HP Pro Tablet 408 with X-Powers AXP288
- Linux exposes:
  - `/sys/class/power_supply/axp288_charger`
  - `/sys/class/power_supply/axp288_fuel_gauge`
- `input_current_limit` is writable

The script exits successfully without changing anything when no external
charger is detected. It applies the setting at boot only; it does **not**
currently react to plugging in a charger after boot.

## Install

Clone the repository, then run:

```bash
sudo ./install.sh
```

Default limit is 1.5 A (`1500000` µA). To use a different value, edit:

```bash
sudo nano /etc/default/hp-tablet-charging
```

For example, after validating the hardware, set:

```bash
INPUT_CURRENT_LIMIT_UA=2000000
```

Then apply immediately:

```bash
sudo systemctl restart hp-tablet-charging.service
```

Check the service and configured value:

```bash
systemctl status hp-tablet-charging.service --no-pager -l
cat /sys/class/power_supply/axp288_charger/input_current_limit
```

The expected service state after a successful run is `active (exited)`.

## Kernel modules

The installed file `/etc/modules-load.d/hp-pro-tablet-408.conf` requests:

- `axp288_charger`
- `axp288_fuel_gauge`
- `axp288_adc`
- `extcon_axp288`

On this hardware these modules may already be loaded automatically by the
kernel when the AXP288 platform devices are discovered. The file makes the
request explicit; it does not replace correct ACPI/platform-device discovery.
If a module is unavailable in a particular kernel, inspect `modprobe` and
`dmesg` output rather than forcing a different driver.

## Diagnostics

```bash
lsmod | grep -E 'axp288|extcon_axp288'
modinfo axp288_charger
modinfo axp288_fuel_gauge
modinfo axp288_adc
cat /sys/class/power_supply/axp288_charger/online
cat /sys/class/power_supply/axp288_charger/input_current_limit
cat /sys/class/power_supply/axp288_fuel_gauge/status
cat /sys/class/power_supply/axp288_fuel_gauge/current_now
```

Battery `current_now` is battery current, not USB input current. Positive
values usually indicate charging and negative values discharging, but readings
vary with workload and battery-management behavior.

## Uninstall

```bash
sudo ./uninstall.sh
```

This removes only the files installed by this repository. It does not unload
kernel modules or alter firmware settings.
