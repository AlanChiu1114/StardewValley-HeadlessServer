#!/usr/bin/env bash
set -euo pipefail

# Health criteria:
# 1) UDP 24642 is listening inside the container
# 2) SMAPI log exists (ensures game has at least started)

LOG_FILE="/data/StardewValley/ErrorLogs/SMAPI-latest.txt"

# ensure log exists
if [ ! -f "$LOG_FILE" ]; then
  echo "waiting: smapi log not found yet"
  exit 1
fi

# check UDP port listening
if ss -u -lntu 2>/dev/null | awk '{print $5}' | grep -qE '(^|:)24642($|\s)'; then
  echo "ok: udp 24642 listening"
  exit 0
fi

echo "waiting: udp 24642 not listening yet"
exit 1
