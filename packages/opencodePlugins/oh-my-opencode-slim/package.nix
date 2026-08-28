{
  lib,
  bun2nix,
  inputs,
}: let
  src = inputs.oh-my-opencode-slim;
in
  bun2nix.mkDerivation {
    pname = "oh-my-opencode-slim";
    inherit ((lib.importJSON "${src}/package.json")) version;

    inherit src;

    nativeBuildInputs = [bun2nix.hook];

    bunDeps = bun2nix.fetchBunDeps {bunNix = ./bun.nix;};

    buildPhase = ''
      bun run build
    '';

    installPhase = ''
      mkdir -p $out

      cp -r package.json oh-my-opencode-slim.schema.json dist src node_modules $out/
    '';
  }
