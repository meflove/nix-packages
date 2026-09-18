{
  lib,
  fetchFromGitHub,
  rustPlatform,
  makeDesktopItem,
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
  openssl,
}: let
  src = fetchFromGitHub {
    owner = "arabianq";
    repo = "pipewire-soundpad";
    rev = "4555a002ef63c43b619d2de65ffa458f03e3c452";
    hash = "sha256-Q9HO1d5ZICW8xGgt68CsQ+FwP5O/4PPM5dg9ZZQ8H3g=";
  };

  cargoToml = lib.importTOML "${src.outPath}/Cargo.toml";
  version = "${cargoToml.workspace.package.version}-${lib.substring 0 7 src.rev}";
in
  rustPlatform.buildRustPackage (_finalAttrs: {
    pname = "pipewire-soundpad";

    inherit
      src
      version
      ;

    strictDeps = true;

    nativeBuildInputs = [
      pkg-config
      rustPlatform.bindgenHook
      cmake
      makeWrapper
    ];
    buildInputs = [
      pipewire
      dbus
      libclang
      alsa-lib
      openssl
    ];

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

    cargoHash = "sha256-SRojuqaZ2l5Ks3UFHuu5C1Oz8H6yi0tpByTApfDtQI0=";

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
