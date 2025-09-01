#!/usr/bin/env bash
set -euo pipefail

GAME_DIR=/game
INSTALL_ZIP=/tmp/smapi-install.dat

if [[ ! -d "$GAME_DIR" ]]; then
  echo "Game dir not found: $GAME_DIR" >&2
  exit 1
fi

# Ensure Mods folder exists
mkdir -p "$GAME_DIR/Mods"

# Unpack SMAPI installer payload (install.dat is actually a zip)
TMP_DIR=$(mktemp -d)
unzip -q "$INSTALL_ZIP" -d "$TMP_DIR"

# Copy files into game dir
cp -a "$TMP_DIR"/* "$GAME_DIR"/

# Per README: rename StardewValley -> StardewValley-original, and StardewModdingAPI -> StardewValley
if [[ -f "$GAME_DIR/StardewValley" && ! -f "$GAME_DIR/StardewValley-original" ]]; then
  mv "$GAME_DIR/StardewValley" "$GAME_DIR/StardewValley-original"
fi

if [[ -f "$GAME_DIR/StardewModdingAPI" ]]; then
  mv -f "$GAME_DIR/StardewModdingAPI" "$GAME_DIR/StardewValley"
fi

# Optional: copy deps.json if present (mainly affects Windows, but safe to apply)
if [[ -f "$GAME_DIR/Stardew Valley.deps.json" && ! -f "$GAME_DIR/StardewModdingAPI.deps.json" ]]; then
  cp "$GAME_DIR/Stardew Valley.deps.json" "$GAME_DIR/StardewModdingAPI.deps.json" || true
fi
if [[ -f "$GAME_DIR/StardewValley.deps.json" && ! -f "$GAME_DIR/StardewModdingAPI.deps.json" ]]; then
  cp "$GAME_DIR/StardewValley.deps.json" "$GAME_DIR/StardewModdingAPI.deps.json" || true
fi

# Cleanup
rm -rf "$TMP_DIR"

# Ensure executable bit (in case zip permissions are lost)
chmod +x "$GAME_DIR/StardewValley" || true
