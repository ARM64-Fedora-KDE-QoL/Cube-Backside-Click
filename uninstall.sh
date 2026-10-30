#!/usr/bin/env bash
# uninstall.sh - Cube-Backside-Click
#
# Removes everything install.sh added: the patched Desktop Cube (only if this tool created it),
# the sync script, the patch, and the update watcher. KDE's own cube is used after your next login.
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
CUBE_OVERRIDE="$DATA/kwin/effects/cube"

say "Removing the update watcher"
systemctl --user disable --now cube-backside-click.path 2>/dev/null || true
systemctl --user disable cube-backside-click-login.service 2>/dev/null || true
rm -f "$UNIT_DIR/cube-backside-click.path" "$UNIT_DIR/cube-backside-click-update.service" \
  "$UNIT_DIR/cube-backside-click-login.service"
systemctl --user daemon-reload 2>/dev/null || true

if [[ -f "$CUBE_OVERRIDE/.cube-backside-click" ]]; then
  say "Removing the patched Desktop Cube"
  rm -rf "$CUBE_OVERRIDE"
fi

say "Removing the sync script and patch"
rm -f "$HOME/.local/bin/cube-backside-click-sync"
rm -rf "$DATA/cube-backside-click" "${XDG_STATE_HOME:-$HOME/.local/state}/cube-backside-click"
if [[ "${1:-}" == "--purge" ]]; then
  rm -rf "${XDG_CONFIG_HOME:-$HOME/.config}/cube-backside-click"
fi

say "Done"
echo "Log out and back in to switch back to KDE's own cube."
