#!/usr/bin/env bash
set -euo pipefail
set -x

export XDG_CONFIG_HOME=${XDG_CONFIG_HOME:-/data}
DATA_DIR=/data
GAME_DIR=/game

mkdir -p "$DATA_DIR" /tmp/xdg
chmod 777 "$DATA_DIR" /tmp/xdg || true

cd "$GAME_DIR"
echo "[entrypoint] XDG_CONFIG_HOME=$XDG_CONFIG_HOME"
echo "[entrypoint] Starting Xvfb..."

# Start Xvfb directly and disable access control to avoid Xauthority issues in containers
XVFB_DISPLAY_NUM=${XVFB_DISPLAY_NUM:-0}
XVFB_DISPLAY=":${XVFB_DISPLAY_NUM}"
XVFB_RES=${XVFB_RES:-1024x768x24}
(
  Xvfb "$XVFB_DISPLAY" -screen 0 "$XVFB_RES" -nolisten tcp -noreset -ac &
) || true

# Wait until X socket is ready
for i in {1..60}; do
  if [[ -S "/tmp/.X11-unix/X${XVFB_DISPLAY_NUM}" ]]; then
    break
  fi
  sleep 0.5
done

export DISPLAY="$XVFB_DISPLAY"
echo "[entrypoint] DISPLAY=$DISPLAY"

# Launch Stardew Valley
exec ./StardewValley
