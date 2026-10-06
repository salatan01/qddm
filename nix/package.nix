{ stdenvNoCC
, lib
, videoDirectory ? null
, videoAbsolutePath ? ""
, mode ? "random"
, playback ? 0
, repeat ? true
, fixedFile ? ""
, showTitle ? true
}:

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
    sed -i "s|^videoPath=.*|videoPath=${videoAbsolutePath}|" "$CONF"

    # videos: populated from the Nix option, never committed to the repo.
    # SDDM greeter is store-immutable, so videos must be baked in here.
    rm -rf $out/share/sddm/themes/qddm/videos
    mkdir -p $out/share/sddm/themes/qddm/videos
  '' + lib.optionalString (videoDirectory != null) ''
    for f in ${videoDirectory}/*.mp4 ${videoDirectory}/*.mkv ${videoDirectory}/*.webm; do
      [ -e "$f" ] || continue
      cp -L "$f" $out/share/sddm/themes/qddm/videos/
    done
    count=$(ls -1 $out/share/sddm/themes/qddm/videos | wc -l)
    if [ "$count" -eq 0 ]; then
      echo "qddm: WARNING: no videos found in ${videoDirectory}" >&2
    else
      echo "qddm: bundled $count video(s)" >&2
    fi
  '' + ''
    runHook postInstall
  '';

  meta = with lib; {
    description = "qddm — R1999-style SDDM video playlist greeter (muted, SDDM-safe)";
    license = licenses.gpl3Only;
    platforms = platforms.linux;
  };
}
