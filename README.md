# qddm — R1999-style SDDM video playlist greeter

Fork of `qylock`'s Reverse:1999-I style, stripped to **one owned theme** with a
**muted, SDDM-safe video playlist**. No audio in the greeter, ever.

## Playback modes (`theme.conf`, all Nix-configurable)

| `mode` | `repeat` | `playback` | Behaviour |
|---|---|---|---|
| `random` | `true` | `0` | Loop current video forever |
| `random` | `true` | `1` | Play once, then random next |
| `random` | `true` | `2` | Twice, then random next ("2playback") |
| `random` | `false` | — | Once, then advance (`playback` ignored) |
| `fixed` | — | — | One file looped forever (`fixedFile`, else first found) |
| `sequence` | `true` | `N` | Alphabetical order, `N` repeats each |

`showTitle=true` shows a bottom-center now-playing pill (humanized file name).

Unlike `qlock` (a lockscreen), there is **no history.json, no volume, no
pinSink**: SDDM runs as the `sddm` user from an immutable store with a
short-lived process, so the shuffle bag is in-memory only (no repeat within a
cycle, reshuffle after). Audio is hard-muted via
`audioOutput: AudioOutput { muted: true; volume: 0 }`.

## NixOS usage

```nix
{
  inputs.qddm.url = "github:you/qddm";

  outputs = { nixpkgs, qddm, ... }: {
    nixosConfigurations.host = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        qddm.nixosModules.default
        ({ ... }: {
          services.displayManager.sddm.enable = true;
          services.displayManager.sddm.wayland.enable = true;
          services.qddm = {
            enable = true;
            # Single copy, zero duplication: your annex library stays where
            # it is, bind-mounted read-only for the greeter. Home keeps 0700.
            videoLibrary = "/home/user/qSets/qDDM";
            mode = "random";
            playback = 2;      # twice, then random next
            repeat = true;
            showTitle = true;
          };
        })
      ];
    };
  };
}
```

GStreamer codecs for the greeter come from QtMultimedia; if a video stays
black, add `gst_all_1.gst-plugins-*` to the system packages (same as qylock).

## Video sources: one folder, no copies

`videoLibrary` (e.g. `/home/user/qSets/qDDM`) is bind-mounted **read-only**
to `/var/lib/qddm` (`videoMountPoint`) at boot, and the theme reads from
there. One folder on disk, nothing in the store, nothing in `/etc`, home
stays `0700` so `sddm` never enters it — and `ro` means the greeter
physically cannot write back. `videoAbsolutePath` skips the bind mount and
reads a folder directly (you then own the permissions yourself).

## Preview without logging out

```sh
./preview.sh          # fullscreen window, Esc quits
```

Mocks the SDDM context so `themes/qddm/Main.qml` runs unmodified. Test
password is `qddm` (anything else fails like a real greeter). Live keys:

| Key | Action |
|---|---|
| `F1` | Cycle `random → sequence → fixed` |
| `F2` | Cycle `playback 0 → 1 → 2` (forever / once / twice) |
| `F3` | Toggle title pill |
| `F4` | Toggle `repeat` |
| `Esc` | Quit |

Knobs live at the top of `preview.qml` (`videoPath` defaults to
`~/qSets/qDDM`). Needs `qml` (Qt6) on `PATH`, else falls back to a
`nix shell` with Qt6 + GStreamer. `nix develop` sets the same env up
via its `shellHook`.

## Local test (non-Nix)

```sh
ln -s ~/qSets/qDDM/aemeanth_so_cold.mp4 themes/qddm/videos/test.mp4
# point sddm-greeter at themes/qddm, or use sddm --test-mode
```

## Layout

`themes/qddm/Main.qml` (R1999-I port) · `theme.conf` · `metadata.desktop` ·
`font/Cinzel-Bold.ttf` · `videos/` (populated at build, never committed) ·
`nix/package.nix` · `nix/module.nix` (`services.qddm.*`).
