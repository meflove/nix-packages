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
    rev = "52269292ce07a010eb612fbacc6d025115d23e0e";
    hash = "sha256-d+IfdXMybwJqVXbtZTPC78PR+f7KDA/V4FW3Thq4deg=";
  };
in
  rustPlatform.buildRustPackage {
    pname = "oo7";
    inherit version src;

    buildAndTestSubdir = "cli";

    cargoHash = "sha256-swQayXvRzhdO8KjyqGJvuoeT/rSg7hTukL/l93VLCVQ=";

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
