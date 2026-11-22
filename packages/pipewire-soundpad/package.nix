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
    rev = "2a4f4ecffd444710139cb05f92592810b04ca573";
    hash = "sha256-StqlNjDbhIMK2ietFJg/867rkRHQQTQbjyD7T5sozxs=";
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

    cargoHash = "sha256-Aj5CU06WraApAH9vbPxC7y+OBtJsi4H7ZIp8qjmidHU=";

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
