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
          preview-present = pkgs.runCommand "qddm-preview-present" { } ''
            test -f ${./.}/preview.qml || (echo "missing preview.qml" && exit 1)
            test -f ${./.}/preview.sh || (echo "missing preview.sh" && exit 1)
            test -f ${./.}/preview-imports/SddmComponents/qmldir || (echo "missing SddmComponents stub" && exit 1)
            test -f ${./.}/preview-imports/SddmComponents/TextConstants.qml || (echo "missing TextConstants stub" && exit 1)
            touch $out
          '';
        });

      devShells = forAll (system:
        let
          pkgs = pkgsFor system;
          qtDeps = with pkgs.qt6; [ qtdeclarative qt5compat qtmultimedia qtsvg ];
          gstDeps = with pkgs.gst_all_1; [ gstreamer gst-plugins-base gst-plugins-good gst-plugins-bad ];
        in
        {
          default = pkgs.mkShell {
            packages = qtDeps ++ gstDeps;

            # Mirrors qlock's shellHook so ./preview.sh finds every QML
            # module and GStreamer codec without extra flags.
            shellHook = ''
              export QML2_IMPORT_PATH="${pkgs.lib.makeSearchPathOutput "out" "lib/qt-6/qml" qtDeps}''${QML2_IMPORT_PATH:+:$QML2_IMPORT_PATH}"
              export QT_PLUGIN_PATH="${pkgs.lib.makeSearchPathOutput "out" "lib/qt-6/plugins" qtDeps}:${pkgs.qt6.qtbase}/${pkgs.qt6.qtbase.qtPluginPrefix}''${QT_PLUGIN_PATH:+:$QT_PLUGIN_PATH}"
              export GST_PLUGIN_SYSTEM_PATH_1_0="${pkgs.lib.makeSearchPathOutput "lib" "lib/gstreamer-1.0" gstDeps}"
              if [ -d "$PWD/preview-imports" ]; then
                export QML2_IMPORT_PATH="$PWD/preview-imports:$QML2_IMPORT_PATH"
              fi
              echo "qddm dev shell: ./preview.sh to preview the theme live."
            '';
          };
        });
    };
}
