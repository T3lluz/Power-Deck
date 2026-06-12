#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BIN_DIR="${HOME}/.local/bin"
CONFIG_DIR="${HOME}/.config"
SYSTEMD_USER_DIR="${CONFIG_DIR}/systemd/user"

mkdir -p "$BIN_DIR" "$SYSTEMD_USER_DIR" "${HOME}/.local/state" \
    "${HOME}/.local/share/polkit-1/actions"

echo "Installing scripts to ${BIN_DIR}..."
for script in ghelper-profile anime-ctl kbd-idle-ctl kbd-idle-helper \
    fnlock-ctl fnlock-daemon.py ghelper-restore; do
    install -m 755 "${REPO_ROOT}/scripts/${script}" "${BIN_DIR}/${script}"
done

if [ ! -f "${CONFIG_DIR}/kbd-idle.conf" ]; then
    echo "Creating ${CONFIG_DIR}/kbd-idle.conf..."
    install -m 644 "${REPO_ROOT}/config/kbd-idle.conf.example" \
        "${CONFIG_DIR}/kbd-idle.conf"
fi

echo "Installing systemd user services..."
for svc in "${REPO_ROOT}/systemd/"*.service; do
    install -m 644 "$svc" "${SYSTEMD_USER_DIR}/$(basename "$svc")"
done

echo "Installing Plasma widget..."
kpackagetool6 -t Plasma/Applet -i "${REPO_ROOT}/plasmoid/org.fredde.powerdeck"

install -m 644 "${REPO_ROOT}/polkit/org.fredde.powerdeck.policy" \
    "${HOME}/.local/share/polkit-1/actions/org.fredde.powerdeck.policy"

cat <<EOF

Power Deck user install finished.

Optional root setup (required for Extreme mode extras):
  sudo install -m 755 ${REPO_ROOT}/system/power-mode /usr/local/bin/power-mode
  sudo install -m 440 ${REPO_ROOT}/system/power-mode.sudoers /etc/sudoers.d/power-mode

If your user is not in the wheel group, edit the sudoers file before installing it.

Recommended user services:
  systemctl --user enable --now ghelper-restore.service

Add the "Power Deck" widget to your Plasma panel, then restart Plasma:
  kquitapp6 plasmashell && plasmashell &

EOF
