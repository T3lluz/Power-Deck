#!/usr/bin/env bash
# Power Deck installer / uninstaller.
#
# Install from a cloned repo:   ./install.sh
# Install from the network:     curl -fsSL https://raw.githubusercontent.com/T3lluz/Power-Deck/main/install.sh | bash
# Uninstall:                    curl -fsSL https://raw.githubusercontent.com/T3lluz/Power-Deck/main/install.sh | bash -s -- --uninstall
set -euo pipefail

REPO_URL="${POWER_DECK_REPO:-https://github.com/T3lluz/Power-Deck.git}"

ACTION="install"
for arg in "$@"; do
    case "$arg" in
        --uninstall|uninstall|--remove|remove) ACTION="uninstall" ;;
        --help|-h)
            echo "Usage: install.sh [--uninstall]"
            exit 0
            ;;
        *)
            echo "Unknown option: $arg (try --help)" >&2
            exit 1
            ;;
    esac
done

# ---------- visuals ----------
if [ -t 1 ]; then
    C_RESET=$'\033[0m'; C_BOLD=$'\033[1m'; C_DIM=$'\033[2m'
    C_GREEN=$'\033[32m'; C_YELLOW=$'\033[33m'; C_RED=$'\033[31m'
    C_CYAN=$'\033[36m'; C_MAGENTA=$'\033[35m'
else
    C_RESET=""; C_BOLD=""; C_DIM=""
    C_GREEN=""; C_YELLOW=""; C_RED=""; C_CYAN=""; C_MAGENTA=""
fi

LOG_FILE="$(mktemp /tmp/power-deck-install.XXXXXX.log)"
WARNINGS=()

banner() {
    printf '\n'
    printf '%s\n' "${C_MAGENTA}${C_BOLD}  ░█▀█░█▀█░█░█░█▀▀░█▀▄░░░█▀▄░█▀▀░█▀▀░█░█${C_RESET}"
    printf '%s\n' "${C_MAGENTA}${C_BOLD}  ░█▀▀░█░█░█▄█░█▀▀░█▀▄░░░█░█░█▀▀░█░░░█▀▄${C_RESET}"
    printf '%s\n' "${C_MAGENTA}${C_BOLD}  ░▀░░░▀▀▀░▀░▀░▀▀▀░▀░▀░░░▀▀░░▀▀▀░▀▀▀░▀░▀${C_RESET}"
    printf '%s\n\n' "${C_DIM}  ROG laptop controls for KDE Plasma 6${C_RESET}"
}

section() { printf '\n%s\n' "${C_CYAN}${C_BOLD}── $1 ──${C_RESET}"; }
step()    { printf '  %s %-46s' "${C_DIM}▸${C_RESET}" "$1"; }
ok()      { printf '%s\n' "${C_GREEN}✓${C_RESET}"; }
skipped() { printf '%s\n' "${C_DIM}skipped${C_RESET}"; }
failed()  { printf '%s\n' "${C_RED}✗${C_RESET}"; }
warn() {
    printf '%s\n' "${C_YELLOW}!${C_RESET}"
    WARNINGS+=("$1")
}

die() {
    printf '\n  %s %s\n' "${C_RED}${C_BOLD}error:${C_RESET}" "$1" >&2
    printf '  %s\n\n' "${C_DIM}full log: ${LOG_FILE}${C_RESET}" >&2
    exit 1
}

# Run a command quietly, logging output. Returns the command's exit code.
run() { "$@" >>"$LOG_FILE" 2>&1; }

banner

# ---------- uninstall ----------
if [ "$ACTION" = "uninstall" ]; then
    BIN_DIR="${HOME}/.local/bin"
    SYSTEMD_USER_DIR="${HOME}/.config/systemd/user"

    section "Stopping services"
    for svc in anime-power-sync fnlock-daemon kbd-backlight-idle ghelper-restore; do
        step "${svc}.service"
        run systemctl --user disable --now "${svc}.service" || true
        ok
    done

    section "Removing files"

    step "Plasma widget (org.fredde.powerdeck)"
    if ! kpackagetool6 -t Plasma/Applet -l 2>/dev/null | grep -qx 'org.fredde.powerdeck'; then
        skipped
    elif run kpackagetool6 -t Plasma/Applet -r org.fredde.powerdeck; then
        ok
    else
        warn "widget removal failed — remove it from the panel first, then re-run"
    fi

    step "Helper scripts"
    rm -f "${BIN_DIR}"/{ghelper-profile,anime-ctl,anime-power-watch,kbd-idle-ctl,kbd-idle-helper,fnlock-ctl,fnlock-daemon.py,ghelper-restore}
    ok

    step "Systemd user services"
    rm -f "${SYSTEMD_USER_DIR}"/{anime-power-sync,fnlock-daemon,kbd-backlight-idle,ghelper-restore}.service
    run systemctl --user daemon-reload
    ok

    step "Polkit policy"
    rm -f "${HOME}/.local/share/polkit-1/actions/org.fredde.powerdeck.policy"
    ok

    step "Saved state"
    rm -f "${HOME}/.local/state"/{anime-power,anime-shape,ghelper-profile-mode,fnlock}
    ok

    section "Root helper"
    if [ -f /usr/local/bin/power-mode ] || [ -f /etc/sudoers.d/power-mode ]; then
        if { true < /dev/tty; } 2>/dev/null; then
            printf '  %s' "${C_BOLD}Remove the power-mode root helper (needs sudo)? [Y/n] ${C_RESET}"
            read -r reply < /dev/tty || reply="n"
            step "power-mode root helper"
            if [[ "$reply" =~ ^[Nn] ]]; then
                skipped
            elif sudo rm -f /usr/local/bin/power-mode /etc/sudoers.d/power-mode < /dev/tty; then
                ok
            else
                warn "sudo removal failed — remove manually:
      sudo rm -f /usr/local/bin/power-mode /etc/sudoers.d/power-mode"
            fi
        else
            step "power-mode root helper"
            warn "no terminal for sudo — remove manually:
      sudo rm -f /usr/local/bin/power-mode /etc/sudoers.d/power-mode"
        fi
    else
        step "power-mode root helper"
        skipped
    fi

    section "Finishing up"
    step "Restarting Plasma shell"
    if run systemctl --user try-restart plasma-plasmashell.service; then
        ok
    elif command -v kquitapp6 >/dev/null 2>&1; then
        run kquitapp6 plasmashell || true
        (setsid plasmashell >>"$LOG_FILE" 2>&1 &)
        ok
    else
        warn "could not restart plasmashell — log out and back in"
    fi

    printf '\n%s\n' "${C_GREEN}${C_BOLD}  Power Deck removed.${C_RESET}"
    if [ "${#WARNINGS[@]}" -gt 0 ]; then
        printf '\n%s\n' "${C_YELLOW}${C_BOLD}  Warnings:${C_RESET}"
        for w in "${WARNINGS[@]}"; do
            printf '  %s %s\n' "${C_YELLOW}•${C_RESET}" "$w"
        done
    fi
    printf '\n  %s\n\n' "${C_DIM}Log: ${LOG_FILE}${C_RESET}"
    exit 0
fi

# ---------- locate or fetch the repo ----------
CLEANUP_DIR=""
cleanup() { if [ -n "$CLEANUP_DIR" ]; then rm -rf "$CLEANUP_DIR"; fi; }
trap cleanup EXIT

SCRIPT_SOURCE="${BASH_SOURCE[0]:-}"
if [ -n "$SCRIPT_SOURCE" ] && [ -f "$SCRIPT_SOURCE" ] \
   && [ -f "$(cd "$(dirname "$SCRIPT_SOURCE")" && pwd)/plasmoid/org.fredde.powerdeck/metadata.json" ]; then
    REPO_ROOT="$(cd "$(dirname "$SCRIPT_SOURCE")" && pwd)"
else
    section "Fetching Power Deck"
    command -v git >/dev/null 2>&1 || die "git is required to download Power Deck"
    CLEANUP_DIR="$(mktemp -d /tmp/power-deck.XXXXXX)"
    step "Cloning ${REPO_URL}"
    run git clone --depth 1 "$REPO_URL" "$CLEANUP_DIR/repo" || die "git clone failed"
    ok
    REPO_ROOT="$CLEANUP_DIR/repo"
fi

# ---------- dependency check ----------
section "Checking dependencies"

require() {
    step "$1"
    if command -v "$1" >/dev/null 2>&1; then ok; else
        failed
        die "'$1' not found — install it first (see README requirements)"
    fi
}

recommend() {
    step "$1"
    if command -v "$1" >/dev/null 2>&1; then ok; else
        warn "'$1' not found — $2"
    fi
}

require kpackagetool6
require systemctl
recommend powerprofilesctl "power profile switching will not work"
recommend asusctl          "AniMe Matrix controls will not work"
recommend brightnessctl    "keyboard backlight controls will not work"
recommend swayidle         "keyboard idle timer will not work"
recommend udevadm          "AniMe AC sync falls back to polling"

step "python3 + evdev (FN-lock daemon)"
if command -v python3 >/dev/null 2>&1 && run python3 -c "import evdev"; then ok; else
    warn "python evdev not found — FN-lock will not work (install python-evdev)"
fi

# ---------- file installation ----------
section "Installing files"

BIN_DIR="${HOME}/.local/bin"
CONFIG_DIR="${HOME}/.config"
SYSTEMD_USER_DIR="${CONFIG_DIR}/systemd/user"

mkdir -p "$BIN_DIR" "$SYSTEMD_USER_DIR" "${HOME}/.local/state" \
    "${HOME}/.local/share/polkit-1/actions"

step "Helper scripts -> ~/.local/bin"
for script in ghelper-profile anime-ctl anime-power-watch kbd-idle-ctl \
    kbd-idle-helper fnlock-ctl fnlock-daemon.py ghelper-restore; do
    install -m 755 "${REPO_ROOT}/scripts/${script}" "${BIN_DIR}/${script}"
done
ok

step "Default config (kbd-idle.conf)"
if [ -f "${CONFIG_DIR}/kbd-idle.conf" ]; then
    skipped
else
    install -m 644 "${REPO_ROOT}/config/kbd-idle.conf.example" \
        "${CONFIG_DIR}/kbd-idle.conf"
    ok
fi

step "Systemd user services"
for svc in "${REPO_ROOT}/systemd/"*.service; do
    install -m 644 "$svc" "${SYSTEMD_USER_DIR}/$(basename "$svc")"
done
run systemctl --user daemon-reload
ok

step "Polkit policy"
install -m 644 "${REPO_ROOT}/polkit/org.fredde.powerdeck.policy" \
    "${HOME}/.local/share/polkit-1/actions/org.fredde.powerdeck.policy"
ok

step "Plasma widget (org.fredde.powerdeck)"
if kpackagetool6 -t Plasma/Applet -l 2>/dev/null | grep -qx 'org.fredde.powerdeck'; then
    run kpackagetool6 -t Plasma/Applet -u "${REPO_ROOT}/plasmoid/org.fredde.powerdeck" \
        || die "widget upgrade failed"
else
    run kpackagetool6 -t Plasma/Applet -i "${REPO_ROOT}/plasmoid/org.fredde.powerdeck" \
        || die "widget install failed"
fi
ok

# ---------- services ----------
section "Enabling services"

enable_service() {
    step "$1"
    if run systemctl --user enable --now "$1"; then ok; else
        warn "could not enable $1 (check: systemctl --user status $1)"
    fi
}

enable_service ghelper-restore.service
enable_service anime-power-sync.service
enable_service fnlock-daemon.service

# ---------- optional root helper (Extreme mode) ----------
section "Root helper (Extreme mode extras)"

install_root_helper() {
    run sudo install -m 755 "${REPO_ROOT}/system/power-mode" /usr/local/bin/power-mode \
        && run sudo install -m 440 "${REPO_ROOT}/system/power-mode.sudoers" /etc/sudoers.d/power-mode
}

if [ -f /usr/local/bin/power-mode ] && [ -f /etc/sudoers.d/power-mode ]; then
    step "power-mode already installed"
    ok
elif { true < /dev/tty; } 2>/dev/null; then
    printf '  %s\n' "${C_DIM}Extreme mode needs a small root helper (panel dimming, Wi-Fi/PCIe powersave).${C_RESET}"
    printf '  %s' "${C_BOLD}Install it now with sudo? [Y/n] ${C_RESET}"
    read -r reply < /dev/tty || reply="n"
    if [[ "$reply" =~ ^[Nn] ]]; then
        step "power-mode root helper"
        skipped
        WARNINGS+=("Extreme mode disabled — install later with:
      sudo install -m 755 <repo>/system/power-mode /usr/local/bin/power-mode
      sudo install -m 440 <repo>/system/power-mode.sudoers /etc/sudoers.d/power-mode")
    else
        # sudo prompts on the tty itself, so don't swallow its output
        if sudo -v < /dev/tty 2>/dev/null && install_root_helper; then
            step "power-mode root helper"
            ok
        else
            step "power-mode root helper"
            warn "sudo install failed — Extreme mode extras disabled"
        fi
    fi
else
    step "power-mode root helper"
    warn "no terminal available for sudo — install manually for Extreme mode (see README)"
fi

# ---------- restart plasma ----------
section "Finishing up"

step "Restarting Plasma shell"
if run systemctl --user try-restart plasma-plasmashell.service; then
    ok
elif command -v kquitapp6 >/dev/null 2>&1; then
    run kquitapp6 plasmashell || true
    (setsid plasmashell >>"$LOG_FILE" 2>&1 &)
    ok
else
    warn "could not restart plasmashell — log out and back in to load the widget"
fi

# ---------- summary ----------
printf '\n%s\n' "${C_GREEN}${C_BOLD}  Power Deck installed successfully.${C_RESET}"

if [ "${#WARNINGS[@]}" -gt 0 ]; then
    printf '\n%s\n' "${C_YELLOW}${C_BOLD}  Warnings:${C_RESET}"
    for w in "${WARNINGS[@]}"; do
        printf '  %s %s\n' "${C_YELLOW}•${C_RESET}" "$w"
    done
fi

cat <<EOF

  ${C_BOLD}Next step:${C_RESET} add the widget to your panel
    right-click panel → Add Widgets → search "${C_BOLD}Power Deck${C_RESET}"

  ${C_DIM}Install log: ${LOG_FILE}${C_RESET}

EOF
