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
    rev = "347dee713ca0ff94075e79db35de3c00c0d59c7e";
    hash = "sha256-sPDBIWIJursCEnuM9GzAkQ+7PjLHSdvix8o3vJKDSfc=";
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

    cargoHash = "sha256-GTsBw3xmccyx7v9LmsaN5he++f5Fk5P0wgQwIFSx2Lg=";

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
