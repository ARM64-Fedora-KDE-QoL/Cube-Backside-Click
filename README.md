# Cube-Backside-Click

**Built on ARM64 Linux Fedora 44 Asahi KDE Plasma**

Click the **back of a desktop** inside KDE Plasma's **Desktop Cube** to switch to that desktop.

The cube's desktops face outward. When you tilt the open cube (click and drag), you can look into the ring and see the back of the desktops on the far side, such as desktop 4 when you started from desktop 1. In KDE's own cube, clicking that back side is ignored and you land on the desktop in front instead. **With Cube-Backside-Click, clicking it takes you to that desktop.**

- **No sudo, no build tools.** Everything goes in your home folder.
- **Works with a mouse or a touchpad.**
- **Stays up to date by itself** when Fedora updates KDE's cube, and falls back to KDE's own cube if a future KDE version changes too much.

Part of [**ARM64-Fedora-KDE-QoL**](https://github.com/ARM64-Fedora-KDE-QoL/ARM64-Fedora-KDE-QoL), quality-of-life improvements for Fedora KDE on ARM64 laptops. Pairs well with [**3-Finger-Cube-Gesture**](https://github.com/ARM64-Fedora-KDE-QoL/3-Finger-Cube-Gesture) (3-finger swipe up/down opens and closes the cube).

## Requirements

- Fedora with KDE Plasma 6 on Wayland
- KDE's Desktop Cube (package `kdeplasma-addons`; most Fedora KDE installs have it), turned on in **System Settings → Window Management → Desktop Effects → Cube**
- `git` (used to apply the patch): `sudo dnf install git` if `git --version` says *command not found*

Built and tested on **ARM64 Linux Fedora 44 Asahi KDE Plasma**: Fedora Linux Asahi Remix 44 (KDE Plasma Desktop Edition) on an Apple Silicon MacBook (aarch64), with KDE Plasma 6.7.5 and `kdeplasma-addons` 6.7.5. Nothing in it is ARM-specific, so it should also work on other Fedora KDE systems.

## Install

```bash
git clone https://github.com/ARM64-Fedora-KDE-QoL/Cube-Backside-Click.git
cd Cube-Backside-Click
./install.sh
```

**Without git for the download:** click **Code → Download ZIP**, extract it, open a terminal in the folder, and run `bash install.sh`. (git is still needed to apply the patch.)

Run it as your normal user, **not** with `sudo`. Then **log out and back in once**: KWin loads the cube at login and keeps it in memory, so the patched cube is used from your next login.

**Try it:** open the cube (Meta+C, or a 3-finger swipe up with 3-Finger-Cube-Gesture), click and drag downward to tilt it so you look into the ring, and click the back of a desktop on the far side.

## Using the cube

All of KDE's cube controls work as before; only the back-side click is new.

| Action | Result |
|---|---|
| Click a desktop's **front** | Switches to that desktop |
| Click a desktop's **back** (new) | Switches to that desktop |
| Click empty space | Switches to the desktop facing you |
| Click and drag | Rotates and tilts the cube |
| Scroll | Zooms in and out |
| ← / → arrow keys, Enter / Space, Esc | Rotate, switch to the desktop facing you, close |

A click always goes to the **nearest** desktop under the pointer, front or back. If another desktop is in front of the one you want, rotate or tilt until the one you want is clear.

## How it works

- **Why KDE's cube ignores back-side clicks.** The cube is drawn with Qt Quick 3D, which displays both sides of each desktop but only *detects clicks* on the front side. A click on a back side looked like a click on empty space, which switches to the desktop in front.
- **The fix.** A small patch (about 40 lines in two of the cube's files) works out which desktop the pointer's ray passes through, checking both sides of every desktop, and picks the nearest one. See [`cube-backside.patch`](cube-backside.patch).
- **A per-user copy.** The installer copies KDE's cube into `~/.local/share/kwin/effects/cube/` and applies the patch. KDE automatically prefers this copy over the system one. The system files are never changed.
- **Automatic updates.** A user-level watcher notices when Fedora replaces KDE's cube files (an update to `kdeplasma-addons`) and rebuilds the patched copy from KDE's new cube, so you keep KDE's own fixes. You get a notification; log out and back in to use the rebuilt cube. A check at login is the backstop.
- **Safe fallback.** If a future KDE version changes the cube so the patch no longer fits, the patched copy is removed and **KDE's own cube is used**, so nothing breaks; you just lose back-side clicking until this project is updated. You get one notification saying so.
- **Your own changes are respected.** If `~/.local/share/kwin/effects/cube/` already holds a cube this tool didn't create, it's left alone.

### What it installs (all in your home folder)

| What | Where |
|---|---|
| Patched cube | `~/.local/share/kwin/effects/cube/` (marked by a `.cube-backside-click` file) |
| Patch | `~/.local/share/cube-backside-click/cube-backside.patch` |
| Sync script | `~/.local/bin/cube-backside-click-sync` |
| Update watcher and login check | `~/.config/systemd/user/cube-backside-click.path`, `cube-backside-click-update.service`, `cube-backside-click-login.service` |

## Turning it off

To switch back to KDE's own cube but keep the tool installed:

```bash
mkdir -p ~/.config/cube-backside-click && touch ~/.config/cube-backside-click/disabled && ~/.local/bin/cube-backside-click-sync
```

then log out and back in. To turn it on again: `rm ~/.config/cube-backside-click/disabled && ~/.local/bin/cube-backside-click-sync`, then log out and back in.

## Uninstall

```bash
./uninstall.sh            # removes everything; KDE's own cube is used after your next login
./uninstall.sh --purge    # also removes the "turned off" setting, if you made one
```

## Troubleshooting

- **Clicking the back of a desktop still takes me to the one in front.** Log out and back in first. Then check that the patched cube is installed: `ls -a ~/.local/share/kwin/effects/cube/` should list `.cube-backside-click`. If it doesn't, run `~/.local/bin/cube-backside-click-sync` and read its message: it says if the patch doesn't fit your KDE version, or if another cube override is in the way.
- **The cube doesn't open at all.** Make sure the Cube effect is turned on (System Settings → Window Management → Desktop Effects → Cube). If it broke after a KDE update, run `./uninstall.sh` (or delete `~/.local/share/kwin/effects/cube/`), log out and back in, and please report it.

## License

Copyright (C) 2026 Cynders. Licensed under the [GNU General Public License v3.0 or later](LICENSE): you can use, modify and share this project, and any modified versions you distribute must stay open source under the same license. It comes with no warranty.

## Credits

- KDE Plasma's Desktop Cube effect by Vlad Zahorodnii (GPL-2.0-only OR GPL-3.0-only). `cube-backside.patch` modifies two of its files; the patched copy is generated on your machine from your installed KDE cube.
