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
    rev = "04cfdad5640f9ce6f70afb5f8f46a29aa8c095b8";
    hash = "sha256-UMg93vI7v33DfOF7HX+i57j+z5Umoj27CElJoZDiCUs=";
  };
in
  rustPlatform.buildRustPackage {
    pname = "oo7";
    inherit version src;

    buildAndTestSubdir = "cli";

    cargoHash = "sha256-6runkOoVV2t2l9fV9Qmi9cOmQIemjSKBgvSttQX3ITk=";

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
