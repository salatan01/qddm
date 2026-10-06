{ config, lib, pkgs, ... }:

let
  cfg = config.services.qddm;
  qddmPkg = pkgs.callPackage ./package.nix {
    inherit (cfg) videoDirectory mode playback repeat fixedFile showTitle;
    videoAbsolutePath = cfg.videoAbsolutePath;
  };
in
{
  options.services.qddm = {
    enable = lib.mkEnableOption "qddm SDDM video playlist theme";

    videoDirectory = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      example = "/home/user/qSets/qDDM";
      description = ''
        Folder of *.mp4/*.mkv/*.webm baked into the theme's videos/.
        SDDM runs as the sddm user from the Nix store, so videos must be
        copied in at build time — the greeter cannot read ~/ at runtime.
        Null builds a video-less theme (black background, HUD still works).
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
      description = "Bare file name inside videos/ for mode=fixed. Empty = first video found.";
    };

    showTitle = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Bottom-center now-playing pill with humanized file name.";
    };

    videoAbsolutePath = lib.mkOption {
      type = lib.types.str;
      default = "";
      example = "/home/user/qSets/qDDM";
      description = ''
        Absolute host folder read at greeter runtime INSTEAD of bundled videos/.
        Use this for git-annex libraries (e.g. ~/qSets/qDDM): annex symlinks
        cannot be copied into the Nix store, but the running greeter resolves
        them fine on the host. The sddm user needs read+execute permission on
        every parent directory. Empty = use store-baked videos/ from
        videoDirectory.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    services.displayManager.sddm.theme = "qddm";
    services.displayManager.sddm.extraPackages = [
      qddmPkg
      pkgs.qt6.qt5compat
      pkgs.qt6.qtmultimedia
      pkgs.qt6.qtsvg
    ];
    environment.systemPackages = [ qddmPkg ];
  };
}
