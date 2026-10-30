#!/usr/bin/env bash
# install.sh - Cube-Backside-Click
#
# Click the back of a desktop inside KDE Plasma's Desktop Cube to switch to that desktop.
#
# KDE's cube only reacts to clicks on the front of a desktop face (Qt Quick 3D's picking ignores
# back sides), so clicking the visible back of a desktop on the far side of the ring sends you to
# the desktop in front instead. This installs a per-user copy of KDE's cube with a small patch
# that checks both sides, and keeps it rebuilt from KDE's cube whenever Fedora updates it.
# Everything goes in your home folder; no sudo needed. See README.md for details.
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
TOOL_DIR="$DATA/cube-backside-click"
SYNC="$HOME/.local/bin/cube-backside-click-sync"
UNIT_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/systemd/user"
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
if [[ ! -f "$SCRIPT_DIR/cube-backside.patch" ]]; then
  echo "cube-backside.patch is missing; run install.sh from the Cube-Backside-Click folder."
  exit 1
fi
if [[ "$(kreadconfig6 --file kwinrc --group Plugins --key cubeEnabled --default false 2>/dev/null)" != "true" ]]; then
  warn "The Desktop Cube effect is turned off. Back-side clicking will work once you turn it on:"
  warn "  System Settings -> Window Management -> Desktop Effects -> Cube"
fi

# --- 1. Patch and sync script -------------------------------------------------
say "Installing the patch and the sync script"
mkdir -p "$TOOL_DIR" "$HOME/.local/bin" "$UNIT_DIR"
cp "$SCRIPT_DIR/cube-backside.patch" "$TOOL_DIR/cube-backside.patch"

cat > "$SYNC" <<'EOF'
#!/usr/bin/env bash
# cube-backside-click-sync: keep a patched copy of KDE's Desktop Cube (clicking the back of a
# desktop face switches to that desktop) as a per-user override in
# ~/.local/share/kwin/effects/cube, rebuilt from KDE's cube whenever KDE's cube files change.
# Installed by Cube-Backside-Click's install.sh.
#   --settle   wait a few seconds first (used when triggered by a file change mid-update)
set -u
SRC=/usr/share/kwin/effects/cube
DATA="${XDG_DATA_HOME:-$HOME/.local/share}"
DST="$DATA/kwin/effects/cube"
PATCH="$DATA/cube-backside-click/cube-backside.patch"
MARKER="$DST/.cube-backside-click"   # marks an override this tool manages; holds KDE's cube fingerprint
STATE="${XDG_STATE_HOME:-$HOME/.local/state}/cube-backside-click"
OPT_OUT="${XDG_CONFIG_HOME:-$HOME/.config}/cube-backside-click/disabled"

# Triggered by KDE's cube files changing: let the package update finish before reading them.
[[ "${1:-}" == "--settle" ]] && sleep 10

notify() { # <urgency> <title> <body>
  local bus="/run/user/$(id -u)/bus"
  [[ -S "$bus" ]] || return 0
  DBUS_SESSION_BUS_ADDRESS="unix:path=$bus" notify-send -a "Cube-Backside-Click" -u "$1" \
    -i preferences-desktop-effects "$2" "$3" 2>/dev/null || true
}
ours() { [[ -f "$MARKER" ]]; }
# A short checksum of all of KDE's cube files, so any change to them (an update) is noticed
# even before the package database lists the new version. LC_ALL=C keeps the file order, and so
# the checksum, the same whatever language the session uses.
fingerprint() { (cd "$SRC" && find . -type f -print0 | LC_ALL=C sort -z | xargs -0 sha256sum) | sha256sum | cut -c1-16; }

mkdir -p "$STATE"
[[ -d "$SRC" && -f "$PATCH" ]] || exit 0
kde_version="$(rpm -q --qf '%{VERSION}-%{RELEASE}' kdeplasma-addons 2>/dev/null || echo unknown)"

if [[ -e "$OPT_OUT" ]]; then
  ours && rm -rf "$DST" && echo "Back-side clicking is turned off; removed the patched cube."
  exit 0
fi
fp="$(fingerprint)"
if ours && [[ "$(cat "$MARKER")" == "$fp" ]]; then
  exit 0
fi

# Build the new override next to the old one, then swap it in.
mkdir -p "$(dirname "$DST")"
tmp="$(mktemp -d "$(dirname "$DST")/.cube-new.XXXXXX")" || exit 1
cp -r "$SRC/." "$tmp/"
if ! (cd "$tmp" && GIT_CEILING_DIRECTORIES="$(dirname "$tmp")" git apply -p1 "$PATCH") 2>/dev/null; then
  rm -rf "$tmp"
  if ours; then rm -rf "$DST"; fi
  echo "The back-side clicking patch doesn't fit KDE's cube ($kde_version); using KDE's own cube."
  if [[ "$(cat "$STATE/patch-failed-for" 2>/dev/null)" != "$fp" ]]; then
    printf '%s\n' "$fp" > "$STATE/patch-failed-for"
    notify normal "Cube back-side clicking turned off" \
      "KDE's Desktop Cube changed (kdeplasma-addons $kde_version) and the back-side clicking patch no longer fits, so KDE's own cube is used. Check Cube-Backside-Click for an update."
  fi
  exit 0
fi
rm -f "$STATE/patch-failed-for"

if [[ -e "$DST" ]] && ! ours; then
  # A cube override this tool didn't create. Adopt it only if it's exactly what we'd install
  # (ignoring marker files, e.g. from 3-Finger-Cube-Gesture's unreleased v4.0 test).
  if diff -rq --exclude='.cube-backside-click' --exclude='.cube-gesture-override' "$DST" "$tmp" >/dev/null 2>&1; then
    rm -f "$DST/.cube-gesture-override"
    printf '%s\n' "$fp" > "$MARKER"
    rm -rf "$tmp"
    echo "Adopted the existing cube override (identical to the patched cube)."
  else
    rm -rf "$tmp"
    echo "Left $DST alone: it's a cube override this tool didn't create."
  fi
  exit 0
fi

previous="$(cat "$MARKER" 2>/dev/null)"
printf '%s\n' "$fp" > "$tmp/.cube-backside-click"
if [[ -e "$DST" ]]; then
  mv "$DST" "$DST.old.$$" && mv "$tmp" "$DST" && rm -rf "$DST.old.$$"
else
  mv "$tmp" "$DST"
fi
echo "Installed the patched cube (kdeplasma-addons $kde_version)."
if [[ -n "$previous" ]]; then
  notify normal "Cube back-side clicking updated" \
    "KDE's Desktop Cube was updated (kdeplasma-addons $kde_version) and the patched copy was rebuilt. Log out and back in to use it."
fi
EOF
chmod 755 "$SYNC"

# --- 2. Watchers ----------------------------------------------------------------
# A user-level systemd path unit notices when Fedora replaces KDE's cube files (an update) and
# rebuilds the patched copy; a login service is the backstop. Nothing here runs as root.
say "Installing the update watcher"
cat > "$UNIT_DIR/cube-backside-click.path" <<'EOF'
# Installed by Cube-Backside-Click's install.sh
[Unit]
Description=Watch KDE's Desktop Cube for updates (Cube-Backside-Click)

[Path]
PathChanged=/usr/share/kwin/effects/cube/contents/ui/ScreenView.qml
PathChanged=/usr/share/kwin/effects/cube/contents/ui/Cube.qml
Unit=cube-backside-click-update.service

[Install]
WantedBy=default.target
EOF
cat > "$UNIT_DIR/cube-backside-click-update.service" <<'EOF'
# Installed by Cube-Backside-Click's install.sh
[Unit]
Description=Rebuild the patched Desktop Cube after a KDE update (Cube-Backside-Click)

[Service]
Type=oneshot
ExecStart=%h/.local/bin/cube-backside-click-sync --settle
EOF
cat > "$UNIT_DIR/cube-backside-click-login.service" <<'EOF'
# Installed by Cube-Backside-Click's install.sh
[Unit]
Description=Check the patched Desktop Cube at login (Cube-Backside-Click)

[Service]
Type=oneshot
ExecStart=%h/.local/bin/cube-backside-click-sync

[Install]
WantedBy=default.target
EOF
systemctl --user daemon-reload
systemctl --user enable --now cube-backside-click.path
systemctl --user enable cube-backside-click-login.service

# --- 3. Build the patched cube ---------------------------------------------------
say "Building the patched cube"
"$SYNC"

say "Done"
if [[ -f "$DATA/kwin/effects/cube/.cube-backside-click" ]]; then
  echo "Back-side clicking is installed. If this is your first install, log out and back in to activate it"
  echo "(KWin loads the cube at login)."
  echo "Then open the cube, tilt it by dragging, and click the back of a desktop on the far side."
else
  echo "Back-side clicking isn't active; see the message above."
fi
echo "To turn it off later: see README.md, or run ./uninstall.sh"
