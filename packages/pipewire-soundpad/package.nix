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
    rev = "07321afb60c711c72b511182768b99d2a70d6bbb";
    hash = "sha256-cejBolY4UkUdcZp8Ik8uQgYGmgwp5Nr+ahB9WyRnzvs=";
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

    cargoHash = "sha256-vWKNQYgwzKjH7JEdDsD9vxGan9ndyCUtztEbTSmidKY=";

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
