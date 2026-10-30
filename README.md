# Cube-Backside-Click

**Built on ARM64 Linux Fedora 44 Asahi KDE Plasma**

Click the **back of a desktop** inside KDE Plasma's **Desktop Cube** to switch to that desktop.

The cube's desktops face outward. When you tilt the open cube (click and drag), you can look into the ring and see the back of the desktops on the far side, such as desktop 4 when you started from desktop 1. In KDE's own cube, clicking that back side is ignored and you land on the desktop in front instead. **With Cube-Backside-Click, clicking it takes you to that desktop.**

- **No sudo, no build tools.** Everything goes in your home folder.
- **Works with a mouse or a touchpad.**
- **Stays up to date by itself** when Fedora updates KDE's cube, and falls back to KDE's own cube if a future KDE version changes too much.

Part of [**ARM64-Fedora-KDE-QoL**](https://github.com/ARM64-Fedora-KDE-QoL/ARM64-Fedora-KDE-QoL), quality-of-life improvements for Fedora KDE on ARM64 laptops. Pairs well with [**3-Finger-Cube-Gesture**](https://github.com/ARM64-Fedora-KDE-QoL/3-Finger-Cube-Gesture) (3-finger swipe up/down opens and closes the cube, and left/right turns it smoothly); both can be installed together.

## Versions

| | [v1.0](https://github.com/ARM64-Fedora-KDE-QoL/Cube-Backside-Click/releases/tag/v1.0) | **[v2.0](https://github.com/ARM64-Fedora-KDE-QoL/Cube-Backside-Click/releases/tag/v2.0) (current, recommended)** |
|---|---|---|
| Back-side clicking | ✅ | ✅ (same patch) |
| Rebuilt automatically after KDE updates | ✅ | ✅ |
| Works together with 3-Finger-Cube-Gesture v4.0's smooth swiping | ❌ (only one tool can patch the cube) | ✅ (both share one patched cube) |

**Upgrading from v1.0:** in your copy of this project, run `git pull` and then `./install.sh`. It takes over v1.0's patched cube and removes v1.0's watcher; back-side clicking keeps working without a logout.

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
- **A per-user copy.** `kde-cube-patches-sync` copies KDE's cube into `~/.local/share/kwin/effects/cube/` and applies the patch. KDE automatically prefers this copy over the system one. The system files are never changed.
- **Shared with other cube patches.** KDE only uses one per-user copy of the cube, so `kde-cube-patches-sync` is shared with [3-Finger-Cube-Gesture](https://github.com/ARM64-Fedora-KDE-QoL/3-Finger-Cube-Gesture) (smooth swiping): each project adds its patch to `~/.local/share/kde-cube-patches/`, and the patched cube gets all of them. Either project can be installed or removed on its own.
- **Automatic updates.** A user-level watcher notices when Fedora replaces KDE's cube files (an update to `kdeplasma-addons`) and rebuilds the patched copy from KDE's new cube, so you keep KDE's own fixes. You get a notification; log out and back in to use the rebuilt cube. A check at login is the backstop.
- **Safe fallback.** If a future KDE version changes the cube so the patch no longer fits, back-side clicking is turned off and **KDE's own cube is used** (with any other project's patch that still fits), so nothing breaks; you just lose back-side clicking until this project is updated. You get one notification saying so.
- **Your own changes are respected.** If `~/.local/share/kwin/effects/cube/` already holds a cube these tools didn't create, it's left alone.

### What it installs (all in your home folder)

| What | Where |
|---|---|
| Patched cube | `~/.local/share/kwin/effects/cube/` (marked by a `.kde-cube-patches` file) |
| Patch | `~/.local/share/kde-cube-patches/cube-backside-click.patch` |
| Cube patcher (shared) | `~/.local/bin/kde-cube-patches-sync` |
| Update watcher and login check (shared) | `~/.config/systemd/user/kde-cube-patches.path`, `kde-cube-patches-update.service`, `kde-cube-patches-login.service` |

### Disk space and memory

- **Disk space: about 100 KB** (the patched cube copy, the patch, the patcher and the systemd units).
- **Memory: nothing extra to speak of.** The patched cube uses the same memory as KDE's own cube while it's open, and nothing while it's closed. The update watcher is a file-change notification handled by systemd, and the update and login services exit within seconds.

### Keep `git` installed

The patcher uses `git` to apply the patch. If you remove `git`, the next KDE update can't rebuild the patched cube: back-side clicking is turned off and KDE's own cube is used, with a notification saying the patch couldn't be applied. Reinstall it with `sudo dnf install git`, re-run `./install.sh`, and log out and back in.

## Turning it off

To switch back to KDE's own cube but keep the tool installed:

```bash
mkdir -p ~/.config/cube-backside-click && touch ~/.config/cube-backside-click/disabled && ~/.local/bin/kde-cube-patches-sync
```

then log out and back in. To turn it on again: `rm ~/.config/cube-backside-click/disabled && ~/.local/bin/kde-cube-patches-sync`, then log out and back in.

## Uninstall

```bash
./uninstall.sh            # removes back-side clicking; takes effect after your next login
./uninstall.sh --purge    # also removes the "turned off" setting, if you made one
```

If 3-Finger-Cube-Gesture's smooth swiping is installed, the patched cube is rebuilt without back-side clicking; otherwise it's removed and KDE's own cube is used.

## Troubleshooting

- **Clicking the back of a desktop still takes me to the one in front.** Log out and back in first. Then check that the patched cube has back-side clicking: `grep applied ~/.local/share/kwin/effects/cube/.kde-cube-patches` should list `cube-backside-click`. If it doesn't, run `~/.local/bin/kde-cube-patches-sync` and read its message: it says if the patch doesn't fit your KDE version, or if another cube override is in the way.
- **The cube doesn't open at all.** Make sure the Cube effect is turned on (System Settings → Window Management → Desktop Effects → Cube). If it broke after a KDE update, run `./uninstall.sh` (or delete `~/.local/share/kwin/effects/cube/`), log out and back in, and please report it.

## License

Copyright (C) 2026 Cynders. Licensed under the [GNU General Public License v3.0 or later](LICENSE): you can use, modify and share this project, and any modified versions you distribute must stay open source under the same license. It comes with no warranty.

## Credits

- KDE Plasma's Desktop Cube effect by Vlad Zahorodnii (GPL-2.0-only OR GPL-3.0-only). `cube-backside.patch` modifies two of its files; the patched copy is generated on your machine from your installed KDE cube.
