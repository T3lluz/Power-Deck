# Power Deck — agent notes

## g-helper-linux (fan reference)

Upstream we studied for fan curves and fan control:

**https://github.com/utajum/g-helper-linux**

Unofficial Linux port of Windows G-Helper (GPL-3.0). Fan UI lives in
`src/UI/Views/FansWindow.axaml(.cs)` and `src/UI/Controls/FanCurveChart.cs`.
The writer is `src/Platform/Linux/Asus/LinuxAsusWmi.cs`.

What we take from it (behavior, not their C#):

- The EC/BIOS still owns real-time fan speed. Userspace only sets an
  **8-point temperature → duty curve** (same as Armoury / G-Helper).
- Kernel hwmon `asus_custom_fan_curve`: `pwmN_auto_point{1-8}_{temp,pwm}`
  plus `pwmN_enable` (`1` custom, `2` firmware auto, `3` BIOS defaults).
- Temps in that sysfs are **raw °C**, not millidegrees. Duty is 0–255.
- Live RPM is a different chip: hwmon name `asus`, labels `cpu_fan` /
  `gpu_fan` (`fan1_input` / `fan2_input`). This G14 has no mid fan.
- There is **no** live “set fan to 50%” PWM on GA402-class machines —
  the regular `asus` hwmon has enable flags only, no duty file.
- **Apply order** (from `LinuxAsusWmi.SetFanCurve`): write all 8
  temp/pwm points first (each point write clears `data->enabled` in
  the kernel), then `pwm_enable=1` which calls `fan_curve_write()` and
  pushes the curve to the EC. Enable-only or store-only is not enough.

What we do **not** copy:

- Do **not** write those sysfs files from the widget. They are root-only
  and `asusd` already owns them. Power Deck goes through D-Bus
  `xyz.ljones.FanCurves` on `/xyz/ljones` (asusd 6.3; there is no
  `/xyz/ljones/FanCurves` object). Same as charge limit and AniMe.
- Do not run g-helper-linux’s fan writer at the same time as Power Deck
  — the two will overwrite each other.

asusd 6.3 apply notes (GA402):

- Platform profile ids: `0` Balanced, `1` Performance, `2` Quiet,
  `3` LowPower. This machine’s live profile is **LowPower**, not Quiet.
- Quiet and LowPower share `/etc/asusd/fan_curves.ron` `quiet:`.
  `SetFanCurve` / `SetFanCurvesEnabled` on id **3** writes hwmon.
  The same calls on id **2**, or `asusctl --mod-profile Quiet`, only
  update the store.
- `asusctl fan-curve --data` rejects a duty dip (PWM must be
  non-decreasing). D-Bus `SetFanCurve` does not — same as g-helper.

## Power Deck fan implementation

- Script: `scripts/fan-ctl` → `~/.local/bin/fan-ctl`
- UI: header **Fans** chip opens a full-popup overlay (dashboard stays
  packed). `FanCurveStrip.qml` is the 8-bar editor; temps under the
  bars are editable. Live RPM and a Saved / Applied tag.
- Curves are per **Power Deck mode**: `extreme`, `power`, `balanced`,
  `performance`. Store: `~/.local/state/power-deck-fans/<mode>`.
- Firmware slots: extreme + power → LowPower (id 3), balanced → 0,
  performance → 1. Switching a mode calls `fan-ctl apply <mode>`,
  which writes that store onto the slot (or disables custom).
- Extreme defaults to the quiet preset (custom). Power Saver defaults
  to firmware / stock so it does not inherit Extreme’s silent curve.
- asusd’s `ChangePlatformProfileOnAc/Battery` must stay **false** —
  otherwise AC plug-in yanks the platform profile to Performance and
  the wrong curve is live. `ghelper-profile` and `ghelper-restore`
  pin those properties. Login restore re-applies the curve a few
  times so a late asusd write cannot win.
- Status line (widget): `avail mode viewed cpuRpm gpuRpm live` then
  `cpu t:p,...` and `gpu t:p,...` (`avail` is `yes|no`, `mode` is
  `custom|firmware`, `viewed`/`live` are Power Deck modes).
- Calibration (g-helper-linux `FanSensorControl`): run a flat 100%
  curve, poll RPM until the peak stops rising, store max. Cosmetic
  only — the Y-axis / % readout. Does **not** rewrite the per-mode
  store. GA402 defaults 5500 / 5600.
  `fan-ctl calibrate` writes `~/.local/state/power-deck-fan-cal`.
