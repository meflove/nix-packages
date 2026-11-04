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
    rev = "0bcd627958cf0ce45edb42ec9a668a2ccb7a6ec9";
    hash = "sha256-2Dez2l2SDtk0ApcjnZ2ATj/jjoFX28fnrSCNr9t/LHM=";
  };
in
  rustPlatform.buildRustPackage {
    pname = "oo7";
    inherit version src;

    buildAndTestSubdir = "cli";

    cargoHash = "sha256-6jj21lbSv0SM3shReI8meih135I38UqjWGfn04kMSf4=";

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
