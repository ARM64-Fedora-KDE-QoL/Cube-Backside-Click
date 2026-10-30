#!/usr/bin/env bash
# uninstall.sh - Cube-Backside-Click
#
# Removes the back-side clicking patch. The patched Desktop Cube is rebuilt without it if
# another project's cube patch is installed (3-Finger-Cube-Gesture's smooth swiping); otherwise
# the patched cube, the update watcher and the shared cube patcher are removed too, and KDE's own
# cube is used after your next login.
#
# Usage (as your normal user):
#   ./uninstall.sh [--purge]     --purge also removes the "turned off" setting, if you made one
#
# Copyright (C) 2026 Cynders
# SPDX-License-Identifier: GPL-3.0-or-later
# This program is free software: you can redistribute it and/or modify it under the terms of
# the GNU General Public License as published by the Free Software Foundation, either version 3
# of the License, or (at your option) any later version. It is distributed WITHOUT ANY WARRANTY;
# see the LICENSE file for details.

set -euo pipefail

say() { printf '\n\033[1;34m==> %s\033[0m\n' "$*"; }

DATA="${XDG_DATA_HOME:-$HOME/.local/share}"
UNIT_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/systemd/user"
ENGINE="$HOME/.local/bin/kde-cube-patches-sync"

say "Removing the back-side clicking patch"
rm -f "$DATA/kde-cube-patches/cube-backside-click.patch"
rm -f "${XDG_STATE_HOME:-$HOME/.local/state}/kde-cube-patches/failed-cube-backside-click"
if [[ -x "$ENGINE" ]]; then
  # Rebuilds the patched cube with the other projects' patches, or removes it (and the shared
  # patcher) if none are left.
  "$ENGINE" --remove-if-unused || true
fi

# Leftovers from v1.0, in case it was never upgraded.
systemctl --user disable --now cube-backside-click.path 2>/dev/null || true
systemctl --user disable cube-backside-click-login.service 2>/dev/null || true
rm -f "$UNIT_DIR/cube-backside-click.path" "$UNIT_DIR/cube-backside-click-update.service" \
  "$UNIT_DIR/cube-backside-click-login.service" "$HOME/.local/bin/cube-backside-click-sync"
systemctl --user daemon-reload 2>/dev/null || true
if [[ -f "$DATA/kwin/effects/cube/.cube-backside-click" ]]; then
  rm -rf "$DATA/kwin/effects/cube"
fi
rm -rf "$DATA/cube-backside-click" "${XDG_STATE_HOME:-$HOME/.local/state}/cube-backside-click"

if [[ "${1:-}" == "--purge" ]]; then
  rm -rf "${XDG_CONFIG_HOME:-$HOME/.config}/cube-backside-click"
fi

say "Done"
echo "Log out and back in to use the cube without back-side clicking."
