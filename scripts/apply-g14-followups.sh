#!/bin/bash
# Apply leftover G14 desktop fixes from the live audit, then install Power Deck.
# Run as your normal user (will prompt for sudo where needed):
#   bash ~/Power-Deck/scripts/apply-g14-followups.sh
set -euo pipefail

REPO="$(cd "$(dirname "$0")/.." && pwd)"

echo "== Fix ownership from earlier root installs =="
sudo chown -R "$USER:$USER" \
  "$HOME/.local/bin" \
  "$HOME/.local/share/plasma/plasmoids/org.fredde.powerdeck" \
  "$HOME/.local/share/power-deck" \
  "$HOME/.config/powerdevilrc" \
  "$HOME/.config/kwinrc" \
  "$HOME/.config/kdeglobals" 2>/dev/null || true

echo "== Powerdevil: stop AC/battery profile stomping Power Deck =="
# Deleting these keys leaves profile control to Power Deck / the applet.
kwriteconfig6 --file powerdevilrc --group AC --group Performance --key PowerProfile --delete || true
kwriteconfig6 --file powerdevilrc --group Battery --group Performance --key PowerProfile --delete || true
systemctl --user try-restart plasma-powerdevil.service 2>/dev/null || true

echo "== KWin: disable blur + low latency =="
kwriteconfig6 --file kwinrc --group Plugins --key blurEnabled false
kwriteconfig6 --file kwinrc --group Compositing --key LatencyPolicy Low
qdbus6 org.kde.KWin /Effects unloadEffect blur 2>/dev/null || true
qdbus6 org.kde.KWin /KWin reconfigure 2>/dev/null || true

echo "== Optional: stop nvidia-persistenced (keeps dGPU awake for nothing) =="
if systemctl is-enabled nvidia-persistenced >/dev/null 2>&1; then
  sudo systemctl disable --now nvidia-persistenced
fi

echo "== Install Power Deck (restarts plasmashell) =="
cd "$REPO"
./install.sh

MODE="$(cat "$HOME/.local/state/ghelper-profile-mode" 2>/dev/null || echo balanced)"
"$HOME/.local/bin/ghelper-profile" "$MODE"

echo
echo "== Verify =="
echo "Powerdevil AC:  $(kreadconfig6 --file powerdevilrc --group AC --group Performance --key PowerProfile 2>/dev/null || echo '(unset)')"
echo "Powerdevil Bat: $(kreadconfig6 --file powerdevilrc --group Battery --group Performance --key PowerProfile 2>/dev/null || echo '(unset)')"
echo "blurEnabled:    $(kreadconfig6 --file kwinrc --group Plugins --key blurEnabled)"
echo "LatencyPolicy:  $(kreadconfig6 --file kwinrc --group Compositing --key LatencyPolicy)"
echo "ProfileBalancedEpp: $(busctl get-property xyz.ljones.Asusd /xyz/ljones xyz.ljones.Platform ProfileBalancedEpp 2>/dev/null || echo n/a)"
echo "sysfs EPP: $(cat /sys/devices/system/cpu/cpu0/cpufreq/energy_performance_preference)"
for d in /sys/bus/pci/devices/*; do
  [ "$(cat "$d/vendor" 2>/dev/null)" = "0x10de" ] || continue
  echo "dGPU $d control=$(cat "$d/power/control" 2>/dev/null) runtime=$(cat "$d/power/runtime_status" 2>/dev/null)"
done
echo
echo "Done. Close Discord/Steam when idle if the desktop still feels soft."
