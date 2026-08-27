# Power Deck

KDE Plasma widget for ASUS ROG laptops — switch power modes, fan curves, AniMe, keyboard lighting, FN-lock, charge limit, and temperatures from the panel.

Power Deck brings GHelper-style laptop controls to KDE Plasma. Scroll the panel icon to cycle profiles, hover it for live temperatures, or open the landscape dashboard for full control.

## Features

- **Landscape dashboard** — ~4:3 popup: profile tiles on the left, paired controls on the right
- **Power modes** — Extreme Saver, Power Saver, Balanced, and Performance
- **Fan curves** — per-mode 8-point CPU/GPU editor (same as Armoury / G-Helper). Switching profiles applies that mode's curve; Custom or Firmware per mode. Survives reboot.
- **Scroll to switch** — mouse wheel on the panel icon cycles modes
- **CPU & GPU temperatures & power draw** — live readouts in the popup, the panel, and the panel-icon tooltip, color-coded by heat
- **Battery status** — charge %, time remaining, AC state, and charge/discharge watts in the popup header, tooltip, and (optionally) the panel
- **Battery charge limit** — slider from 80% to 100% (in 5% steps) to extend battery lifespan, plus a one-shot full charge
- **GPU mode switching** — Integrated / Hybrid (queued for next boot), with a live tag showing which GPUs are actually active
- **Notifications** — optional desktop notifications on profile switches, plug/unplug, and GPU mode changes
- **Configurable panel display** — pick any mix of profile, CPU/GPU temps and watts, battery %, charge/discharge watts, time remaining, fan RPM, and refresh rate, then reorder them. Icons + values, values only, or icons only, with optional separators and mini bars (same layout language as CasaOS Homelab)
- **Monochrome theme** — optional neutral grayscale palette (toggle in the widget config) instead of the colored ROG accents
- **AniMe Matrix** — toggle display, pick Banner, Logo, or Static, auto-off on battery
- **Keyboard light timer** — idle timeout, brightness slider, keep-on-AC option
- **FN-lock** — software remapping for media keys vs function keys
- **Refresh rate** — Auto / low / high switching for the internal display

### Power modes

| Mode | Profile | Extras |
|------|---------|--------|
| Extreme Saver | power-saver | CPU boost off, 60 Hz (auto), Wi-Fi powersave, PCIe ASPM powersave, NVIDIA dGPU runtime suspend (D3cold), near-silent fan curve (fans off until ~72 °C) |
| Power Saver | power-saver | CPU boost off, normal refresh and peripherals, fan curve firmware by default |
| Balanced | balanced | On AC: high refresh (auto), Wi-Fi powersave off, ASPM default, EPP nudged to `balance_performance`, stock fan curve. On battery: 60 Hz (auto), Wi-Fi/ASPM powersave on, EPP `balance_power`, dGPU stays free to D3cold |
| Performance | performance | Always-high refresh (even on battery in auto), Wi-Fi powersave off, ASPM default, EPP `performance`, dGPU pinned awake in Hybrid (D0), cool fan curve for sustained boost |

CPU boost is managed by `power-profiles-daemon`: the `power-saver` profile (used by both saver modes) disables per-policy boost on amd_pstate automatically. Power Deck never writes the global boost sysfs knob (that makes PPD profile switches fail with `EINVAL`). On Balanced, PPD alone often picks EPP `balance_power` on amd_pstate; the AC helper nudges it to `balance_performance` for snappier ramp while the ACPI platform profile stays balanced. Unplugging (or leaving Performance) resets EPP to `balance_power` so battery life stays sane.

### Temperatures and power draw

The popup header shows CPU and GPU temperature pills (with live watts where the hardware exposes them — amdgpu PPT, NVIDIA via nvidia-smi, CPU package via RAPL when readable), refreshed every few seconds. The same readings can sit in the panel itself — right-click the widget → Configure Power Deck… → Panel display — alongside battery charge/discharge watts, time remaining, fan RPM, and refresh rate. Hovering the panel icon still shows the full tooltip. Colors shift from teal (cool) through amber (70 °C+) to red (85 °C+). Readings come straight from sysfs hwmon sensors — `k10temp`/`zenpower`/`coretemp` for the CPU and `amdgpu`/`nouveau` for the GPU, with ACPI thermal-zone and `nvidia-smi` fallbacks. The NVIDIA fallback only queries the GPU while it is awake, so polling never wakes a runtime-suspended dGPU.

### Battery charge limit

The charge limit slider (80–100% in 5% steps) caps how far the battery charges, which helps preserve its long-term health when the laptop lives on AC. The limit is applied through `asusctl battery limit` (no root prompt) and persists in firmware; 100% restores default full charging. The widget stays in sync if the limit is changed elsewhere. When a limit is active, a **Charge to 100% once** button performs a one-shot full charge (e.g. before travel) without changing the saved limit.

### GPU mode

When `supergfxd` is available, a Graphics section lets you switch between Integrated and Hybrid modes (the dGPU MUX mode is deliberately not offered — MUX switching through supergfxd is unreliable). A device tag in the header always shows what is live right now — **iGPU only**, **iGPU + dGPU asleep/on**, or **dGPU drives display** — detected straight from the hardware (PCI bus + which card drives the panel), so the widget never shows a mode that isn't actually running. Switching opens a confirmation dialog — cancel and nothing changes; confirm with **Switch + Reboot now** or **Switch, reboot later** (a pulsing "… after reboot" chip stays visible until you do, and clicking the current mode un-queues the switch).

Mode changes are staged in `/var/lib/power-deck/gfx-pending` (via the `power-mode` root helper) and committed into `/etc/supergfxd.conf` by `power-deck-gfx-apply.service` at shutdown — after supergfxd has stopped — so the daemon applies the new mode cleanly when it starts at the next boot. The widget deliberately never calls `supergfxctl -m`: even with `always_reboot` enabled, supergfxd reacts to it by attempting a live driver unload (`rmmod nvidia_drm`) that always fails while a desktop session is running, after which the daemon wedges on a PCI unbind in uninterruptible kernel state and the next reboot hangs on a black screen. Editing the config under a running daemon is equally unsafe (any daemon restart live-applies it), which is why the commit is deferred to shutdown.

Unlike GHelper on Windows, Integrated ↔ Hybrid cannot switch live on Linux: supergfxd requires the session to end for these changes (verified even with PCI `hotplug_type` enabled), because the compositor holds the display stack. In practice you rarely need to switch, though — in Hybrid mode the NVIDIA dGPU runtime-suspends to D3cold (~0 W) whenever it is unused, so battery life matches Integrated until an app actually wakes the dGPU.

The exception is the **Performance** profile: in Hybrid mode it pins the dGPU awake (`power/control = on`, kept in D0) so it never runtime-suspends. That keeps the card instantly available to apps and games — no wake-up latency, and offload-aware launchers always see a ready dGPU — at the cost of the idle dGPU draw. Switching to any other profile sets it back to `auto`, so it resumes suspending to D3cold when idle. In Integrated mode there is no dGPU on the bus, so Performance behaves like the other profiles. Note this keeps the dGPU *available*; per-app render offload still follows the usual PRIME mechanism (`prime-run` / `__NV_PRIME_RENDER_OFFLOAD`, or per-game launch options) for software that doesn't pick the dGPU on its own.

### Fan curves

The **Fans** chip in the popup header opens an 8-point CPU/GPU curve editor. Each power mode has its own stored curve (`~/.local/state/power-deck-fans/`). Extreme Saver and Power Saver both use the firmware LowPower slot, so Power Deck keeps two copies and writes the active one when you switch. Balanced and Performance have their own firmware slots.

**Custom** writes the 8 points through asusd D-Bus and enables them; **Firmware** hands the fans back to the BIOS curve for that mode (your points stay stored). Switching profiles — from the tiles, the panel scroll, or at login via `ghelper-restore` — applies the mode you landed on. A login-time re-apply covers the race where asusd finishes later than the session.

Calibration (`fan-ctl calibrate`) runs a flat 100% curve, records peak RPM, then restores your points. That max is cosmetic (the % readout); it does not change how the EC interpolates.

## Requirements

Tested on a **ROG Zephyrus G14 (GA402NV)** running KDE Plasma 6. You will likely need an ASUS ROG laptop with similar sysfs/asusctl support.

**System packages** (names may vary by distro):

- `power-profiles-daemon`
- `asusctl` / `asusd`
- `brightnessctl`
- `swayidle`
- `python-evdev`
- `kscreen` (for refresh-rate switching via `kscreen-doctor`)
- `supergfxctl` / `supergfxd` (optional, for GPU mode switching)
- `libnotify` (optional, for desktop notifications)

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

AC detection for Auto is deliberately robust so it doesn't get stuck at 60 Hz while charging: it treats the laptop as plugged in when a wall adapter (`Mains`) **or** a USB-C/PD source reports `online`, and also when the battery status is `Charging`/`Full`/`Not charging`. The battery-status signal is the backstop for cold boots, where the adapter's `online` flag can momentarily read 0 even though the charger is attached. On top of that, `ghelper-restore` re-syncs the rate a few times over the first several seconds of the session, because KDE's kscreen daemon restores its own remembered display config shortly after login and would otherwise clobber the rate back to 60 Hz.

## Usage

- **Scroll** on the panel icon to cycle power modes
- **Hover** the icon for current profile, CPU/GPU temperatures, and refresh rate
- **Click** the icon to open the full control popup
- Keyboard idle and FN-lock services start on demand when toggled from the widget

### CLI (optional)

```bash
ghelper-profile extreme|power|balanced|performance|status
anime-ctl on|off|banner|logo|static|battery-off on|off|status
kbd-idle-ctl on|off|timeout 60|keep-ac on|off|brightness 0-3|status
fnlock-ctl on|off|status
refresh-ctl auto|low|high|sync|status
temp-ctl                  # prints "<cpuT> <gpuT> <cpuW> <gpuW>" ("-" if unavailable)
charge-ctl status|oneshot|<20-100>
battery-ctl               # prints "<state> <percent> <minutes> <ac> <watts>"
gfx-ctl status|set <Mode> # live GPU mode + queue a switch for next boot
fan-ctl status|set|enable|apply|preset|calibrate
```

## Uninstall

One-liner (stops services, removes the widget, scripts, and config, and offers to remove the root helper):

```bash
curl -fsSL https://raw.githubusercontent.com/T3lluz/Power-Deck/main/install.sh | bash -s -- --uninstall
```

Or from a clone: `./install.sh --uninstall`

## License

MIT — see [LICENSE](LICENSE).
