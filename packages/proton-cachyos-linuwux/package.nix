{
  lib,
  stdenvNoCC,
  fetchzip,
  # Can be overridden to alter the display name in steam
  # This could be useful if multiple versions should be installed together
  steamDisplayName ? "proton-cachyos-LinUwUx",
}:
stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "proton-cachyos-LinUwUx";
  version = "11.0-20260703-slr-LinUwUx-Rework";

  src = fetchzip {
    url = "https://github.com/xshaduwulfx/proton-linuwux/releases/download/proton-cachyos-${finalAttrs.version}/proton-cachyos-${finalAttrs.version}.tar.gz";
    hash = "sha256-gRXm+Lxq8tHlh/pThDiRBWc9CV4lSDeJBHUs+mnlEnQ=";
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

    # Make it impossible to add to an environment. You should use the appropriate NixOS option.
    # Also leave some breadcrumbs in the file.
    echo "${finalAttrs.pname} should not be installed into environments. Please use programs.steam.extraCompatPackages instead." > $out

    mkdir $steamcompattool
    ln -s $src/* $steamcompattool
    rm $steamcompattool/compatibilitytool.vdf
    cp $src/compatibilitytool.vdf $steamcompattool

    runHook postInstall
  '';

  preFixup = ''
    substituteInPlace "$steamcompattool/compatibilitytool.vdf" \
      --replace-fail "proton-cachyos-${finalAttrs.version}" "${steamDisplayName}"
  '';

  meta = {
    description = ''
      Compatibility tool for Steam Play based on Wine and additional components.

      (This is intended for use in the `programs.steam.extraCompatPackages` option only.)
    '';
    homepage = "https://github.com/xshaduwulfx/proton-linuwux";
    license = lib.licenses.mit;
    platforms = ["x86_64-linux"];
    sourceProvenance = [lib.sourceTypes.binaryNativeCode];
  };
})
