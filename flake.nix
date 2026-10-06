{
  description = "qddm — R1999-style SDDM video playlist greeter (muted, SDDM-safe)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs }:
    let
      systems = [ "x86_64-linux" "aarch64-linux" ];
      forAll = nixpkgs.lib.genAttrs systems;
      pkgsFor = system: import nixpkgs { inherit system; };
    in
    {
      packages = forAll (system:
        let pkgs = pkgsFor system; in {
          qddm = pkgs.callPackage ./nix/package.nix { };
          default = self.packages.${system}.qddm;
        });

      nixosModules = {
        qddm = import ./nix/module.nix;
        default = self.nixosModules.qddm;
      };

      checks = forAll (system:
        let pkgs = pkgsFor system; in {
          theme-present = pkgs.runCommand "qddm-theme-present" { } ''
            for f in Main.qml metadata.desktop theme.conf font/Cinzel-Bold.ttf; do
              test -f ${./.}/themes/qddm/$f || (echo "missing themes/qddm/$f" && exit 1)
            done
            grep -q "audioOutput" ${./.}/themes/qddm/Main.qml || (echo "muted audioOutput guard missing" && exit 1)
            grep -q "videoMode" ${./.}/themes/qddm/theme.conf || (echo "videoMode key missing" && exit 1)
            grep -q "videoPath" ${./.}/themes/qddm/theme.conf || (echo "videoPath key missing" && exit 1)
            touch $out
          '';
        });

      devShells = forAll (system:
        let pkgs = pkgsFor system; in {
          default = pkgs.mkShell {
            packages = with pkgs; [
              qt6.qtdeclarative
              qt6.qt5compat
              qt6.qtmultimedia
              qt6.qtsvg
              gst_all_1.gstreamer
              gst_all_1.gst-plugins-base
              gst_all_1.gst-plugins-good
              gst_all_1.gst-plugins-bad
            ];
          };
        });
    };
}
