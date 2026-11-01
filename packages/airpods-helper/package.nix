{
  lib,
  dbus,
  fdk_aac,
  fetchFromGitHub,
  patchelf,
  pkg-config,
  rustPlatform,
}: let
  src = fetchFromGitHub {
    owner = "superninjv";
    repo = "airpods-helper";
    rev = "ace961aefc577c3512db5cff786e4ba25fbc4a6a";
    hash = "sha256-PbJpAJasb4kLO98yhLn/VeNKF4vt0Q4qE89gVQlif40=";
  };

  cargoToml = lib.importTOML "${src.outPath}/Cargo.toml";
  version = "${cargoToml.workspace.package.version}-${lib.substring 0 7 src.rev}";
in
  rustPlatform.buildRustPackage {
    pname = "airpods-helper";

    inherit
      src
      version
      ;

    strictDeps = true;

    nativeBuildInputs = [
      pkg-config
      patchelf
    ];
    buildInputs = [
      dbus
    ];

    cargoHash = "sha256-FikPVXAXRQUUu+JQxKr8k+C0tUXdOhD2iEglKxTYla8=";

    postInstall = ''
      install -Dm644 config.example.toml $out/share/airpods-helper/config.example.toml
    '';

    # The microphone source decodes AAC-ELD with libfdk-aac, which the daemon
    # dlopen()s by soname instead of linking (Debian/Fedora don't ship it).
    # Add its directory to RUNPATH so dlopen("libfdk-aac.so.2") resolves on NixOS.
    postFixup = ''
      patchelf --add-rpath ${fdk_aac}/lib $out/bin/airpods-daemon
    '';

    meta = {
      description = "Native AirPods support for Linux: ANC, battery, EQ, ear detection, mic without losing stereo";
      homepage = "https://github.com/superninjv/airpods-helper";
      license = lib.licenses.mit;
      mainProgram = "airpods-cli";
      platforms = lib.platforms.linux;
    };
  }
