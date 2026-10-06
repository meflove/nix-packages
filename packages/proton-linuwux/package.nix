{
  lib,
  fetchzip,
  stdenvNoCC,
  # Can be overridden to alter the display name in steam
  # This could be useful if multiple versions should be installed together
  steamDisplayName ? "proton-LinUwUx",
}:
stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "proton";
  version = "GE-Proton11-7-LinUwUx-Rework";

  src = fetchzip {
    url = "https://codeberg.org/xshaduwulfx/proton-linuwux/releases/download/${finalAttrs.version}/${finalAttrs.version}.tar.gz";
    stripRoot = false;
    hash = "sha256-AxxK5gpPwrNEEz/EzksHlanF9OpCPxF4DKqU2QDMCAY=";
  };

  dontUnpack = true;
  dontConfigure = true;
  dontBuild = true;

  outputs = [
    "out"
    "steamcompattool"
  ];

  installPhase = ''
    runHook preInstall

    mkdir -p $out
    ln -s $src/* $out
    rm $out/compatibilitytool.vdf
    cp $src/compatibilitytool.vdf $out

    mkdir $steamcompattool
    ln -s $src/* $steamcompattool
    rm $steamcompattool/compatibilitytool.vdf
    cp $src/compatibilitytool.vdf $steamcompattool

    runHook postInstall
  '';

  preFixup = ''
    substituteInPlace "$out/compatibilitytool.vdf" \
      --replace-fail "${finalAttrs.version}" "${steamDisplayName}"
    substituteInPlace "$steamcompattool/compatibilitytool.vdf" \
      --replace-fail "${finalAttrs.version}" "${steamDisplayName}"
  '';

  meta = {
    description = ''
      Compatibility tool for Steam Play based on Wine and additional components.

      (This is intended for use in the `programs.steam.extraCompatPackages` option only.)
    '';
    homepage = "https://codeberg.org/xshaduwulfx/proton-linuwux";
    license = lib.licenses.mit;
    platforms = ["x86_64-linux"];
    sourceProvenance = [lib.sourceTypes.binaryNativeCode];
  };
})
