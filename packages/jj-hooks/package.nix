{
  lib,
  fetchFromGitHub,
  rustPlatform,
}: let
  cargoToml = lib.importTOML "${src.outPath}/Cargo.toml";
  version = "${cargoToml.package.version}-${lib.substring 0 7 source.rev}";

  source = fetchFromGitHub {
    owner = "mattwilkinsonn";
    repo = "jj-hooks";
    rev = "ad3c6f545f17bd52e22cc0d26788a19915e20834";
    hash = "sha256-D3gUyaf9dg6ZDa24Nb98+Kha/6ai8y/yhk08iH/LbIQ=";
  };
  src = lib.sources.cleanSource source;
in
  rustPlatform.buildRustPackage (finalAttrs: {
    pname = "jj-hooks";
    inherit version src;

    cargoHash = "sha256-FzL6Z51zu9W0VV9RRn/DKS/EC1EO5qLkfKz+Jhx544Q=";

    doCheck = false;

    meta = {
      description = "Use your pre-commit/pre-push hook runner with jj.";
      homepage = "https://github.com/mattwilkinsonn/jj-hooks";
      license = with lib.licenses; [mit asl20];
      mainProgram = "jj-hp";
      platforms = lib.platforms.linux;
    };
  })
