{
  lib,
  fetchFromGitHub,
  pkg-config,
  rustPlatform,
}: let
  cargoToml = lib.importTOML "${src.outPath}/Cargo.toml";
  version = "${cargoToml.workspace.package.version}-${lib.substring 0 7 src.rev}";

  src = fetchFromGitHub {
    owner = "linux-credentials";
    repo = "oo7";
    rev = "ee8fde41cdd0c4ec28c701960454ce07c45542fe";
    hash = "sha256-LGAcZ8zYrtRYzhS9rXCmoVg7WePy3WEjDUT8XfFtmzc=";
  };
in
  rustPlatform.buildRustPackage {
    pname = "oo7";
    inherit version src;

    buildAndTestSubdir = "cli";

    cargoHash = "sha256-hjR3xZSA0957n4l0q2c4+Rs7FjykjYSlWl6wz+UkqvE=";

    nativeBuildInputs = [pkg-config];

    meta = {
      description = "James Bond went on a new mission as a Secret Service provider (CLI)";
      homepage = "https://github.com/linux-credentials/oo7";
      changelog = "https://github.com/linux-credentials/oo7/releases/tag/${cargoToml.workspace.package.version}";
      license = lib.licenses.mit;
      mainProgram = "oo7-cli";
      platforms = lib.platforms.linux;
    };
  }
