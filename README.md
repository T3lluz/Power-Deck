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

```bash
git clone https://github.com/T3lluz/Power-Deck.git
cd Power-Deck
./install.sh
```

Then install the optional root helper (needed for Extreme mode):

```bash
sudo install -m 755 system/power-mode /usr/local/bin/power-mode
sudo install -m 440 system/power-mode.sudoers /etc/sudoers.d/power-mode
```

Enable login restore (re-applies saved profile and FN-lock):

```bash
systemctl --user enable --now ghelper-restore.service
```

Add **Power Deck** to your Plasma panel: right-click panel → **Add Widgets** → search for "Power Deck".

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

```bash
kpackagetool6 -t Plasma/Applet -r org.fredde.powerdeck
rm -f ~/.local/bin/{ghelper-profile,anime-ctl,kbd-idle-ctl,kbd-idle-helper,fnlock-ctl,fnlock-daemon.py,ghelper-restore}
rm -f ~/.config/systemd/user/{kbd-backlight-idle,fnlock-daemon,ghelper-restore}.service
rm -f ~/.local/share/polkit-1/actions/org.fredde.powerdeck.policy
sudo rm -f /usr/local/bin/power-mode /etc/sudoers.d/power-mode
systemctl --user daemon-reload
```

## License

MIT — see [LICENSE](LICENSE).
