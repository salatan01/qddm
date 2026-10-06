{ stdenvNoCC
, lib
, videoPath ? ""
, mode ? "random"
, playback ? 0
, repeat ? true
, fixedFile ? ""
, showTitle ? true
}:

# NOTE: videos are NEVER baked into the store. The single library folder
# lives on the host (e.g. ~/qSets/qDDM, bind-mounted read-only to
# /var/lib/qddm by the module) and the theme reads it at greeter runtime
# via theme.conf videoPath. No duplication, no store bloat.
stdenvNoCC.mkDerivation {
  pname = "qddm";
  version = "0.1.0";

  src = ../themes/qddm;

  dontBuild = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/share/sddm/themes/qddm
    cp -r $src/. $out/share/sddm/themes/qddm/
    chmod -R u+w $out/share/sddm/themes/qddm

    # theme.conf tweaks (build-time, mirrors qylock mkConfEdits ideology)
    CONF=$out/share/sddm/themes/qddm/theme.conf
    sed -i "s/^videoMode=.*/videoMode=${mode}/" "$CONF"
    sed -i "s/^playback=.*/playback=${toString playback}/" "$CONF"
    sed -i "s/^repeat=.*/repeat=${if repeat then "true" else "false"}/" "$CONF"
    sed -i "s|^fixedFile=.*|fixedFile=${fixedFile}|" "$CONF"
    sed -i "s|^showTitle=.*|showTitle=${if showTitle then "true" else "false"}|" "$CONF"
    sed -i "s|^videoPath=.*|videoPath=${videoPath}|" "$CONF"

    # videos/ ships empty: runtime path above is the only source.
    rm -rf $out/share/sddm/themes/qddm/videos
    mkdir -p $out/share/sddm/themes/qddm/videos

    runHook postInstall
  '';

  meta = with lib; {
    description = "qddm — R1999-style SDDM video playlist greeter (muted, SDDM-safe)";
    license = licenses.gpl3Only;
    platforms = platforms.linux;
  };
}
