#!/usr/bin/env bash
# Power Deck test suite — exercises the GPU mode staging/commit logic in
# system/power-mode against a sandboxed fake filesystem (no root needed,
# nothing on the real system is touched).
#
# Usage: tests/run-tests.sh
set -u

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
POWER_MODE="$REPO_ROOT/system/power-mode"

PASS=0
FAIL=0

sandbox="$(mktemp -d /tmp/power-deck-tests.XXXXXX)"
trap 'rm -rf "$sandbox"' EXIT

# Fresh sandbox state before every test.
reset_sandbox() {
    rm -rf "$sandbox"/*
    mkdir -p "$sandbox/state" "$sandbox/modprobe.d" "$sandbox/modules-load.d" \
        "$sandbox/usr-modules-load.d"
    cat > "$sandbox/supergfxd.conf" <<'EOF'
{
  "mode": "Hybrid",
  "vfio_enable": false,
  "always_reboot": true
}
EOF
    # mimics the real /usr/lib/modules-load.d/nvidia-utils.conf
    echo "nvidia-uvm" > "$sandbox/usr-modules-load.d/nvidia-utils.conf"
    echo "uinput" > "$sandbox/usr-modules-load.d/uinput.conf"
}

pm() {
    POWER_DECK_TEST=1 \
    POWER_DECK_GFX_CONF="$sandbox/supergfxd.conf" \
    POWER_DECK_GFX_STATE_DIR="$sandbox/state" \
    POWER_DECK_MODPROBE_DIR="$sandbox/modprobe.d" \
    POWER_DECK_MODLOAD_DIR="$sandbox/modules-load.d" \
    POWER_DECK_MODLOAD_SRC_DIR="$sandbox/usr-modules-load.d" \
    bash "$POWER_MODE" "$@"
}

conf_mode() {
    sed -n 's/.*"mode"[[:space:]]*:[[:space:]]*"\([A-Za-z]*\)".*/\1/p' \
        "$sandbox/supergfxd.conf" | head -n1
}

check() {
    local desc="$1"; shift
    if "$@"; then
        printf 'ok   - %s\n' "$desc"
        PASS=$((PASS + 1))
    else
        printf 'FAIL - %s\n' "$desc"
        FAIL=$((FAIL + 1))
    fi
}

# ---------- staging ----------

reset_sandbox
pm gfx-mode Integrated >/dev/null 2>&1
check "gfx-mode stages the requested mode" \
    test "$(cat "$sandbox/state/gfx-pending" 2>/dev/null)" = "Integrated"
check "gfx-mode does not touch the config" \
    test "$(conf_mode)" = "Hybrid"

reset_sandbox
pm gfx-mode Bogus >/dev/null 2>&1
check "gfx-mode rejects invalid modes" test "$?" -ne 0
check "invalid mode leaves no pending file" \
    test ! -e "$sandbox/state/gfx-pending"

reset_sandbox
pm gfx-mode Integrated >/dev/null 2>&1
pm gfx-mode Hybrid >/dev/null 2>&1
check "re-selecting the configured mode cancels the queued switch" \
    test ! -e "$sandbox/state/gfx-pending"

# ---------- commit ----------

reset_sandbox
pm gfx-mode Integrated >/dev/null 2>&1
pm gfx-commit >/dev/null 2>&1
check "gfx-commit writes the staged mode into the config" \
    test "$(conf_mode)" = "Integrated"
check "gfx-commit removes the pending file" \
    test ! -e "$sandbox/state/gfx-pending"

reset_sandbox
sed -i 's/"mode": "Hybrid"/"mode":"Hybrid"/' "$sandbox/supergfxd.conf"
pm gfx-mode Integrated >/dev/null 2>&1
pm gfx-commit >/dev/null 2>&1
check "gfx-commit handles compact config formatting" \
    test "$(conf_mode)" = "Integrated"

reset_sandbox
echo "Garbage" > "$sandbox/state/gfx-pending"
pm gfx-commit >/dev/null 2>&1
check "gfx-commit discards a garbage pending file" \
    test ! -e "$sandbox/state/gfx-pending"
check "garbage pending leaves the config untouched" \
    test "$(conf_mode)" = "Hybrid"

# ---------- NVIDIA boot guard ----------

reset_sandbox
pm gfx-mode Integrated >/dev/null 2>&1
pm gfx-commit >/dev/null 2>&1
check "Integrated commit writes the modprobe blacklist" \
    grep -q "blacklist nvidia_drm" "$sandbox/modprobe.d/power-deck-integrated.conf"
check "Integrated commit masks nvidia modules-load entries" \
    test -f "$sandbox/modules-load.d/nvidia-utils.conf"
check "Integrated mask contains no module names" \
    bash -c "! grep -q '^nvidia' '$sandbox/modules-load.d/nvidia-utils.conf'"
check "non-nvidia modules-load entries stay untouched" \
    test ! -e "$sandbox/modules-load.d/uinput.conf"

# switching back to Hybrid removes every guard
pm gfx-mode Hybrid >/dev/null 2>&1
pm gfx-commit >/dev/null 2>&1
check "Hybrid commit removes the modprobe blacklist" \
    test ! -e "$sandbox/modprobe.d/power-deck-integrated.conf"
check "Hybrid commit removes the modules-load masks" \
    test ! -e "$sandbox/modules-load.d/nvidia-utils.conf"

# guard reconciles even with nothing queued (external config edits heal)
reset_sandbox
sed -i 's/"mode": "Hybrid"/"mode": "Integrated"/' "$sandbox/supergfxd.conf"
pm gfx-commit >/dev/null 2>&1
check "gfx-commit reconciles the guard without a pending file" \
    test -f "$sandbox/modprobe.d/power-deck-integrated.conf"

# a user-created modules-load override must never be clobbered or removed
reset_sandbox
sed -i 's/"mode": "Hybrid"/"mode": "Integrated"/' "$sandbox/supergfxd.conf"
echo "nvidia-uvm # I want this" > "$sandbox/modules-load.d/nvidia-utils.conf"
pm gfx-commit >/dev/null 2>&1
check "user-created modules-load file is not clobbered" \
    grep -q "I want this" "$sandbox/modules-load.d/nvidia-utils.conf"
sed -i 's/"mode": "Integrated"/"mode": "Hybrid"/' "$sandbox/supergfxd.conf"
pm gfx-commit >/dev/null 2>&1
check "user-created modules-load file is not removed" \
    test -f "$sandbox/modules-load.d/nvidia-utils.conf"

# ---------- script syntax ----------

for f in "$REPO_ROOT"/scripts/* "$REPO_ROOT"/system/power-mode "$REPO_ROOT"/install.sh; do
    [ -f "$f" ] || continue
    case "$f" in
        *.py) python3 -B -m py_compile "$f" 2>/dev/null \
                && check "python syntax: $(basename "$f")" true \
                || check "python syntax: $(basename "$f")" false ;;
        *)    bash -n "$f" 2>/dev/null \
                && check "bash syntax: $(basename "$f")" true \
                || check "bash syntax: $(basename "$f")" false ;;
    esac
done

printf '\n%d passed, %d failed\n' "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ]
