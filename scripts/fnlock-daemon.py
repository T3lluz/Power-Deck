#!/usr/bin/env python3
# Software Fn-lock remapper — port of g-helper-linux FnLockRemapper/FnLockKeymap.
# Widget state file (written by fnlock-ctl):
#   on  = FN-lock on  → remap F-keys to media targets
#   off = FN-lock off → F1–F12 passthrough (default)

import os
import select
import signal
import sys
import time

from evdev import InputDevice, UInput, ecodes, list_devices

STATE_FILE = os.path.expanduser("~/.local/state/fnlock")
VIRTUAL_NAME = "ghelper-fnlock-virtual-keyboard"

# GenericDefaults() from g-helper-linux FnLockKeymap for modern ROG/TUF.
MEDIA_MAP = {
    ecodes.KEY_F1: ecodes.KEY_MUTE,
    ecodes.KEY_F2: ecodes.KEY_KBDILLUMDOWN,
    ecodes.KEY_F3: ecodes.KEY_KBDILLUMUP,
    ecodes.KEY_F6: ecodes.KEY_SYSRQ,
    ecodes.KEY_F7: ecodes.KEY_BRIGHTNESSDOWN,
    ecodes.KEY_F8: ecodes.KEY_BRIGHTNESSUP,
    ecodes.KEY_F9: ecodes.KEY_SWITCHVIDEOMODE,
    ecodes.KEY_F10: ecodes.KEY_TOUCHPAD_TOGGLE,
    ecodes.KEY_F11: ecodes.KEY_SLEEP,
}


def read_state() -> str:
    try:
        with open(STATE_FILE) as f:
            state = f.read().strip()
            if state in ("on", "off"):
                return state
    except OSError:
        pass
    return "off"


def media_remap_active() -> bool:
    return read_state() == "on"


def find_keyboard() -> InputDevice:
    preferred = []
    fallback = []
    for path in list_devices():
        try:
            dev = InputDevice(path)
        except (OSError, PermissionError):
            continue
        name = dev.name or ""
        info = dev.info
        if "vicinae" in name.lower() or VIRTUAL_NAME in name:
            dev.close()
            continue
        if info.vendor == 0x0B05 or "asus keyboard" in name.lower() or "n-key" in name.lower():
            preferred.append(dev)
        elif info.bustype in (ecodes.BUS_USB, ecodes.BUS_I8042, ecodes.BUS_I2C, ecodes.BUS_HOST):
            if any(dev.capabilities().get(ecodes.EV_KEY, [])):
                fallback.append(dev)
        else:
            dev.close()
    if preferred:
        for dev in fallback:
            dev.close()
        return preferred[0]
    if fallback:
        for dev in fallback[1:]:
            dev.close()
        return fallback[0]
    raise RuntimeError("No suitable keyboard device found")


def emit(ui: UInput, event):
    ui.write(event.type, event.code, event.value)
    if event.type == ecodes.EV_KEY:
        ui.syn()


def main():
    os.makedirs(os.path.dirname(STATE_FILE), exist_ok=True)
    if not os.path.exists(STATE_FILE):
        with open(STATE_FILE, "w") as f:
            f.write("off\n")

    src = find_keyboard()
    ui = UInput.from_device(src, name=VIRTUAL_NAME)
    src.grab()

    reload = False

    def on_hup(_signum, _frame):
        nonlocal reload
        reload = True

    signal.signal(signal.SIGHUP, on_hup)
    signal.signal(signal.SIGTERM, lambda *_: sys.exit(0))

    print(f"fnlock-daemon: grabbed {src.path} ({src.name}), state={read_state()}", flush=True)

    while True:
        if reload:
            reload = False
            print(f"fnlock-daemon: state={read_state()} remap={media_remap_active()}", flush=True)

        r, _, _ = select.select([src.fd], [], [], 0.5)
        if not r:
            continue

        for event in src.read():
            if event.type != ecodes.EV_KEY:
                emit(ui, event)
                continue

            if media_remap_active() and event.code in MEDIA_MAP:
                mapped = MEDIA_MAP[event.code]
                ui.write(ecodes.EV_KEY, mapped, event.value)
                ui.syn()
            else:
                emit(ui, event)


if __name__ == "__main__":
    try:
        main()
    except Exception as exc:
        print(f"fnlock-daemon: {exc}", file=sys.stderr, flush=True)
        sys.exit(1)
