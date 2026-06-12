# Power Deck

KDE Plasma widget for ASUS ROG laptops — switch power modes, AniMe, keyboard lighting, and FN-lock from the panel.

Power Deck brings GHelper-style laptop controls to KDE Plasma. Scroll the panel icon to cycle profiles, or open the popup for full control.

## Features

- **Power modes** — Extreme Saver, Power Saver, Balanced, and Performance
- **Scroll to switch** — mouse wheel on the panel icon cycles modes
- **AniMe Matrix** — toggle display, pick Banner or Logo, auto-off on battery
- **Keyboard light timer** — idle timeout, brightness slider, keep-on-AC option
- **FN-lock** — software remapping for media keys vs function keys

### Power modes

| Mode | Profile | Extras |
|------|---------|--------|
| Extreme Saver | power-saver | 60 Hz, Wi-Fi powersave, PCIe ASPM powersave |
| Power Saver | power-saver | Normal refresh and peripherals |
| Balanced | balanced | Normal extras |
| Performance | performance | Normal extras |

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

### Machine-specific settings

`scripts/ghelper-profile` contains panel refresh-rate modes for a 2560×1600@165 Hz internal display. Edit these lines if your panel differs:

```bash
PANEL_MODE_HZ_HIGH="2560x1600@165"
PANEL_MODE_HZ_LOW="2560x1600@60"
```

List available modes with:

```bash
kscreen-doctor -o
```

## Usage

- **Scroll** on the panel icon to cycle power modes
- **Click** the icon to open the full control popup
- Keyboard idle and FN-lock services start on demand when toggled from the widget

### CLI (optional)

```bash
ghelper-profile extreme|power|balanced|performance|status
anime-ctl on|off|banner|logo|battery-off on|off|status
kbd-idle-ctl on|off|timeout 60|keep-ac on|off|brightness 0-3|status
fnlock-ctl on|off|status
```

## Uninstall

One-liner (stops services, removes the widget, scripts, and config, and offers to remove the root helper):

```bash
curl -fsSL https://raw.githubusercontent.com/T3lluz/Power-Deck/main/install.sh | bash -s -- --uninstall
```

Or from a clone: `./install.sh --uninstall`

## License

MIT — see [LICENSE](LICENSE).
