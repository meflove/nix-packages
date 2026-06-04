{
  lib,
  inputs,
  rustPlatform,
  makeDesktopItem,
  rev ? inputs.pipewire-soundpad.shortRev or inputs.pipewire-soundpad.dirtyShortRev or "dirty",
  # buildDeps
  pkg-config,
  cmake,
  makeWrapper,
  # deps
  pipewire,
  dbus,
  libclang,
  alsa-lib,
  wayland,
  libGL,
  libxkbcommon,
}: let
  inherit (inputs) pipewire-soundpad;
  cargoToml = lib.importTOML "${pipewire-soundpad.outPath}/Cargo.toml";
in
  rustPlatform.buildRustPackage (_finalAttrs: {
    pname = "pipewire-soundpad";
    version = "${cargoToml.workspace.package.version}-${rev}";

    src = lib.cleanSource pipewire-soundpad;

    strictDeps = true;

    nativeBuildInputs = [pkg-config rustPlatform.bindgenHook cmake makeWrapper];
    buildInputs = [pipewire dbus libclang alsa-lib];

    postFixup = ''
      wrapProgram "$out/bin/pwsp-gui" \
        --prefix LD_LIBRARY_PATH : "${
        lib.makeLibraryPath [
          wayland
          libxkbcommon
          libGL
        ]
      }"
    '';

    cargoHash = "sha256-IWAr33Bt+Wq4NhTQl2AADAO2IWeC3oj1lH/3XB7EUnA=";

    doCheck = false;

    desktopItems = [
      (makeDesktopItem {
        name = "PWSP (Soundpad)";
        desktopName = "PWSP (Soundpad)";
        exec = "pwsp-gui %u";
        icon = "pwsp";
        terminal = false;
        type = "Application";
        categories = ["AudioVideo"];
      })
    ];

    meta = {
      description = "Soundpad for linux that works via pipewire ";
      homepage = "https://github.com/erickochen/pipewire-soundpad";
      license = lib.licenses.mit;
      mainProgram = "pipewire-soundpad";
    };
  })
