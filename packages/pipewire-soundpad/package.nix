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
}: let
  src = fetchFromGitHub {
    owner = "arabianq";
    repo = "pipewire-soundpad";
    rev = "ec4e87307117beb8f1687fff028417b99c9fa218";
    hash = "sha256-icIwEKutHqQg10I37tIOGq9ss7mK8rBk866KIrkCaHI=";
  };

  cargoToml = lib.importTOML "${src.outPath}/Cargo.toml";
  version = "${cargoToml.workspace.package.version}-${lib.substring 0 7 src.rev}";
in
  rustPlatform.buildRustPackage (_finalAttrs: {
    pname = "pipewire-soundpad";

    inherit src version;

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

    cargoHash = "sha256-LeHW+GXwvEOPquIhTx0k6yTG1AmxgdHcNSmIBjRQPnA=";

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
