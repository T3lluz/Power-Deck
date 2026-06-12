# Power Deck

KDE Plasma widget for ASUS ROG laptops — switch power modes, AniMe, keyboard lighting, FN-lock, charge limit, and temperatures from the panel.

Power Deck brings GHelper-style laptop controls to KDE Plasma. Scroll the panel icon to cycle profiles, hover it for live temperatures, or open the popup for full control.

## Features

- **Power modes** — Extreme Saver, Power Saver, Balanced, and Performance
- **Scroll to switch** — mouse wheel on the panel icon cycles modes
- **CPU & GPU temperatures** — live readouts in the popup and in the panel-icon tooltip, color-coded by heat
- **Battery charge limit** — slider from 80% to 100% (in 5% steps) to extend battery lifespan
- **AniMe Matrix** — toggle display, pick Banner or Logo, auto-off on battery
- **Keyboard light timer** — idle timeout, brightness slider, keep-on-AC option
- **FN-lock** — software remapping for media keys vs function keys
- **Refresh rate** — Auto / low / high switching for the internal display

### Power modes

| Mode | Profile | Extras |
|------|---------|--------|
| Extreme Saver | power-saver | 60 Hz, Wi-Fi powersave, PCIe ASPM powersave |
| Power Saver | power-saver | Normal refresh and peripherals |
| Balanced | balanced | Normal extras |
| Performance | performance | Normal extras |

### Temperatures

The popup shows CPU and GPU temperature pills under the header, refreshed every few seconds, and the same readings appear when hovering the panel icon. Colors shift from teal (cool) through amber (70 °C+) to red (85 °C+). Readings come straight from sysfs hwmon sensors — `k10temp`/`zenpower`/`coretemp` for the CPU and `amdgpu`/`nouveau` for the GPU, with ACPI thermal-zone and `nvidia-smi` fallbacks. The NVIDIA fallback only queries the GPU while it is awake, so polling never wakes a runtime-suspended dGPU.

### Battery charge limit

The charge limit slider (80–100% in 5% steps) caps how far the battery charges, which helps preserve its long-term health when the laptop lives on AC. The limit is applied through `asusctl battery limit` (no root prompt) and persists in firmware; 100% restores default full charging. The widget stays in sync if the limit is changed elsewhere.

## Requirements

Tested on a **ROG Zephyrus G14 (GA402NV)** running KDE Plasma 6. You will likely need an ASUS ROG laptop with similar sysfs/asusctl support.

**System packages** (names may vary by distro):

- `power-profiles-daemon`
- `asusctl` / `asusd`
- `brightnessctl`
- `swayidle`
- `python-evdev`
- `kscreen` (for refresh-rate switching via `kscreen-doctor`)

**KDE:**

- Plasma 6 (`kpackagetool6`)

## Install

One-liner (downloads the repo, installs everything, enables services, restarts Plasma):

```bash
curl -fsSL https://raw.githubusercontent.com/T3lluz/Power-Deck/main/install.sh | bash
```

The installer checks dependencies, installs the widget, scripts, and systemd user
services, and offers to install the optional root helper for Extreme mode (sudo).

Or from a clone:

```bash
git clone https://github.com/T3lluz/Power-Deck.git
cd Power-Deck
./install.sh
```

Afterwards, add **Power Deck** to your Plasma panel: right-click panel → **Add Widgets** → search for "Power Deck".

## Local development

Clone the repo and install the widget in place:

```bash
git clone https://github.com/T3lluz/Power-Deck.git
cd Power-Deck
./install.sh
```

After editing QML or scripts:

```bash
# Reinstall widget after QML changes
kpackagetool6 -t Plasma/Applet -u plasmoid/org.fredde.powerdeck

# Reinstall scripts after backend changes
./install.sh

# Restart Plasma to pick up widget changes
kquitapp6 plasmashell && plasmashell &
```

### Project layout

```
Power-Deck/
├── plasmoid/org.fredde.powerdeck/   # Plasma 6 panel widget (QML)
├── scripts/                         # CLI helpers called by the widget
├── systemd/                         # User services (FN-lock, kbd idle, restore)
├── system/                          # Root helper + sudoers rule
├── config/                          # Example config files
├── polkit/                          # Optional polkit policy
└── install.sh                       # User-space installer
```

### Refresh-rate handling

Nothing is hardcoded to a specific panel. `refresh-ctl` detects the internal display (`eDP*`) and its modes at runtime, and the widget offers three buttons (like G-Helper): **Auto**, **60 Hz**, and the panel's **highest rate**, shown as the detected number (e.g. "165 Hz"). If the panel has no 60 Hz mode the lowest available rate is used instead. Auto picks 60 Hz on battery or in the Extreme profile and the highest rate otherwise; the explicit 60 Hz / max buttons always win regardless of profile or power source.

## Usage

- **Scroll** on the panel icon to cycle power modes
- **Hover** the icon for current profile, CPU/GPU temperatures, and refresh rate
- **Click** the icon to open the full control popup
- Keyboard idle and FN-lock services start on demand when toggled from the widget

### CLI (optional)

```bash
ghelper-profile extreme|power|balanced|performance|status
anime-ctl on|off|banner|logo|battery-off on|off|status
kbd-idle-ctl on|off|timeout 60|keep-ac on|off|brightness 0-3|status
fnlock-ctl on|off|status
refresh-ctl auto|low|high|sync|status
temp-ctl                  # prints "<cpu> <gpu>" in °C ("-" if unavailable)
charge-ctl status|<20-100>
```

## Uninstall

One-liner (stops services, removes the widget, scripts, and config, and offers to remove the root helper):

```bash
curl -fsSL https://raw.githubusercontent.com/T3lluz/Power-Deck/main/install.sh | bash -s -- --uninstall
```

Or from a clone: `./install.sh --uninstall`

## License

MIT — see [LICENSE](LICENSE).
