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
  version = "GE-Proton11-8-LinUwUx-Rework";

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

  # Upstream ships compatibilitytool.vdf with the internal name of an older
  # release (11-8 still names 11-7), so its contents are not substituted.
  # Generate the manifest instead: it is derived from steamDisplayName and
  # stays stable across version bumps.
  compatibilityToolVdf = builtins.toFile "compatibilitytool.vdf" ''
    "compatibilitytools"
    {
      "compat_tools"
      {
        "${steamDisplayName}" // Internal name of this tool
        {
          "install_path" "."
          "display_name" "${steamDisplayName}"
          "from_oslist" "windows"
          "to_oslist" "linux"
        }
      }
    }
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out $steamcompattool
    ln -s $src/* $out
    ln -s $src/* $steamcompattool
    rm $out/compatibilitytool.vdf $steamcompattool/compatibilitytool.vdf
    install -m 0644 ${finalAttrs.compatibilityToolVdf} $out/compatibilitytool.vdf
    install -m 0644 ${finalAttrs.compatibilityToolVdf} $steamcompattool/compatibilitytool.vdf

    runHook postInstall
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
