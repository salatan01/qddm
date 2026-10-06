{ config, lib, pkgs, ... }:

let
  cfg = config.services.qddm;
  # Single-copy rule: the library lives in exactly one host folder.
  # videoLibrary (e.g. ~/qSets/qDDM) is bind-mounted read-only to
  # videoMountPoint and the theme reads from there — nothing is ever
  # copied to the store, /etc, or anywhere else.
  useBind = cfg.videoLibrary != "";
  effectivePath = if useBind then cfg.videoMountPoint else cfg.videoAbsolutePath;
  qddmPkg = pkgs.callPackage ./package.nix {
    inherit (cfg) mode playback repeat fixedFile showTitle;
    videoPath = effectivePath;
  };
in
{
  options.services.qddm = {
    enable = lib.mkEnableOption "qddm SDDM video playlist theme";

    videoLibrary = lib.mkOption {
      type = lib.types.str;
      default = "";
      example = "/home/user/qSets/qDDM";
      description = ''
        The ONE folder holding your videos (git-annex libraries welcome).
        Bind-mounted read-only to videoMountPoint at boot; the greeter reads
        from there. Your home keeps mode 0700 — sddm never enters it.
        Empty disables the bind mount (use videoAbsolutePath instead).
      '';
    };

    videoMountPoint = lib.mkOption {
      type = lib.types.str;
      default = "/var/lib/qddm";
      description = "Where videoLibrary is bind-mounted (read-only) for the greeter.";
    };

    videoAbsolutePath = lib.mkOption {
      type = lib.types.str;
      default = "";
      example = "/srv/wallpapers";
      description = ''
        Direct runtime folder, used only when videoLibrary is empty.
        The sddm user needs read+execute on every parent directory.
      '';
    };

    mode = lib.mkOption {
      type = lib.types.enum [ "random" "fixed" "sequence" ];
      default = "random";
      description = ''
        random: shuffled bag, every video once per cycle, then reshuffle.
        fixed: single video looped forever (see fixedFile).
        sequence: alphabetical order, wrap around.
      '';
    };

    playback = lib.mkOption {
      type = lib.types.ints.between 0 100;
      default = 0;
      description = ''
        Repeats per video before advancing (mode != fixed, repeat = true).
        0 = loop current video forever. 1 = once then advance.
        2 = twice then random next ("2playback"). Up to 100.
      '';
    };

    repeat = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = ''
        Master loop switch. true = seamless in-player looping.
        false = play once then advance (playback is ignored).
      '';
    };

    fixedFile = lib.mkOption {
      type = lib.types.str;
      default = "";
      description = "Bare file name inside the library for mode=fixed. Empty = first video found.";
    };

    showTitle = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Bottom-center now-playing pill with humanized file name.";
    };
  };

  config = lib.mkIf cfg.enable (lib.mkMerge [
    (lib.mkIf useBind {
      fileSystems.${cfg.videoMountPoint} = {
        device = cfg.videoLibrary;
        fsType = "none";
        options = [ "bind" "ro" ];
      };
    })
    {
      services.displayManager.sddm.theme = "qddm";
      services.displayManager.sddm.extraPackages = [
        qddmPkg
        pkgs.qt6.qt5compat
        pkgs.qt6.qtmultimedia
        pkgs.qt6.qtsvg
      ];
      environment.systemPackages = [ qddmPkg ];
    }
  ]);
}
