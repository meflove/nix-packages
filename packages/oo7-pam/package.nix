{
  cargo,
  meson,
  ninja,
  oo7,
  pam,
  pkg-config,
  rustPlatform,
  rustc,
  stdenv,
  systemdLibs,
}:
stdenv.mkDerivation (finalAttrs: {
  pname = "oo7-pam";
  inherit (oo7) version src cargoDeps;

  sourceRoot = "${finalAttrs.src.name}/pam";
  cargoRoot = "../";

  strictDeps = true;
  __structuredAttrs = true;
  separateDebugInfo = true;

  nativeBuildInputs = [
    pkg-config
    meson
    ninja
    rustPlatform.cargoSetupHook
    rustc
    cargo
  ];

  buildInputs = [
    pam
    systemdLibs
  ];

  meta = {
    inherit (oo7.meta) homepage changelog license platforms;
    description = "PAM module for the oo7 Secret Service";
  };
})
