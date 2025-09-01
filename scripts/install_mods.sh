#!/usr/bin/env bash
set -euo pipefail

GAME_DIR=/game
MODS_DIR="$GAME_DIR/Mods"
DEDICATED_ZIP=/tmp/dedicated.zip
UNATTENDED_SRC=/tmp/StardewUnattendedServer

mkdir -p "$MODS_DIR"

# Install Dedicated Server Mod
if [[ -f "$DEDICATED_ZIP" ]]; then
  unzip -o -q "$DEDICATED_ZIP" -d "$MODS_DIR"
fi

# Ensure expected structure (folder name may already be DedicatedServer)
if [[ -d "$MODS_DIR/DedicatedServer" ]]; then
  echo "DedicatedServer mod installed."
else
  # Attempt to find the extracted directory and rename
  set +e
  FOUND=$(find "$MODS_DIR" -maxdepth 1 -type d -iname "*Dedicated*Server*")
  set -e
  if [[ -n "${FOUND:-}" ]]; then
    FIRST=$(echo "$FOUND" | head -n1)
    mv "$FIRST" "$MODS_DIR/DedicatedServer"
  fi
fi

# Install Stardew Unattended Server Mod
if [[ -d "$UNATTENDED_SRC" ]]; then
  rm -rf "$MODS_DIR/StardewUnattendedServer"
  mkdir -p "$MODS_DIR/StardewUnattendedServer"
  cp -a "$UNATTENDED_SRC"/* "$MODS_DIR/StardewUnattendedServer"/
fi

# Drop default config for Dedicated Server if provided
if [[ -f "/configs/dedicated/config.json" ]]; then
  mkdir -p "$MODS_DIR/DedicatedServer"
  cp -n "/configs/dedicated/config.json" "$MODS_DIR/DedicatedServer/config.json" || true
fi
