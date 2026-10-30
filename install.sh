#!/usr/bin/env bash
# install.sh - Cube-Backside-Click
#
# Click the back of a desktop inside KDE Plasma's Desktop Cube to switch to that desktop.
#
# KDE's cube only reacts to clicks on the front of a desktop face (Qt Quick 3D's picking ignores
# back sides), so clicking the visible back of a desktop on the far side of the ring sends you to
# the desktop in front instead. This installs a small patch to KDE's cube that checks both sides.
# kde-cube-patches-sync (shared with 3-Finger-Cube-Gesture, which also patches the cube) keeps a
# patched per-user copy of KDE's cube, rebuilt from KDE's cube whenever Fedora updates it.
# Everything goes in your home folder; no sudo needed. See README.md for details.
#
# Upgrading from v1.0: just run this; it takes over v1.0's patched cube and removes its watcher.
#
# Usage (as your normal user):
#   ./install.sh
# To remove everything: ./uninstall.sh
#
# Copyright (C) 2026 Cynders
# SPDX-License-Identifier: GPL-3.0-or-later
# This program is free software: you can redistribute it and/or modify it under the terms of
# the GNU General Public License as published by the Free Software Foundation, either version 3
# of the License, or (at your option) any later version. It is distributed WITHOUT ANY WARRANTY;
# see the LICENSE file for details.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DATA="${XDG_DATA_HOME:-$HOME/.local/share}"
PATCH_DIR="$DATA/kde-cube-patches"
ENGINE="$HOME/.local/bin/kde-cube-patches-sync"
KDE_CUBE=/usr/share/kwin/effects/cube

say() { printf '\n\033[1;34m==> %s\033[0m\n' "$*"; }
warn() { printf '\033[1;33m!!  %s\033[0m\n' "$*"; }

# --- 0. Checks ----------------------------------------------------------------
if [[ $EUID -eq 0 ]]; then
  echo "Run this as your normal user, not root. It only changes files in your home folder."
  exit 1
fi
if [[ ! -f "$KDE_CUBE/contents/ui/ScreenView.qml" ]]; then
  echo "KDE's Desktop Cube isn't installed. Install it with:  sudo dnf install kdeplasma-addons"
  exit 1
fi
if ! command -v git >/dev/null 2>&1; then
  echo "git is needed to apply the patch. Install it with:  sudo dnf install git"
  exit 1
fi
for f in cube-backside.patch kde-cube-patches-sync; do
  if [[ ! -f "$SCRIPT_DIR/$f" ]]; then
    echo "$f is missing; run install.sh from the Cube-Backside-Click folder."
    exit 1
  fi
done
if [[ "$(kreadconfig6 --file kwinrc --group Plugins --key cubeEnabled --default false 2>/dev/null)" != "true" ]]; then
  warn "The Desktop Cube effect is turned off. Back-side clicking will work once you turn it on:"
  warn "  System Settings -> Window Management -> Desktop Effects -> Cube"
fi

# --- 1. Patch and the shared cube patcher ---------------------------------------
say "Installing the patch and the cube patcher"
engine_version() { sed -n 's/^ENGINE_VERSION=//p' "$1" 2>/dev/null || true; }
mkdir -p "$HOME/.local/bin" "$PATCH_DIR"
# Keep a newer copy if another project installed one.
installed_engine="$(engine_version "$ENGINE")"
if [[ -z "$installed_engine" || "$installed_engine" -le "$(engine_version "$SCRIPT_DIR/kde-cube-patches-sync")" ]]; then
  install -m 755 "$SCRIPT_DIR/kde-cube-patches-sync" "$ENGINE"
fi
install -m 644 "$SCRIPT_DIR/cube-backside.patch" "$PATCH_DIR/cube-backside-click.patch"

# --- 2. Update watcher, login check, and the patched cube ------------------------
# A user-level systemd path unit notices when Fedora replaces KDE's cube files (an update) and
# rebuilds the patched copy; a login service is the backstop. Nothing here runs as root.
say "Installing the update watcher and building the patched cube"
"$ENGINE" --setup

say "Done"
if grep -qs '^applied=.*cube-backside-click' "$DATA/kwin/effects/cube/.kde-cube-patches"; then
  echo "Back-side clicking is installed. If this is your first install, log out and back in to activate it"
  echo "(KWin loads the cube at login)."
  echo "Then open the cube, tilt it by dragging, and click the back of a desktop on the far side."
else
  echo "Back-side clicking isn't active; see the message above."
fi
echo "To turn it off later: see README.md, or run ./uninstall.sh"
