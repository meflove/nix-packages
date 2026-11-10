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

    # OpenCode V2 only: the server plugin (`dist/server`) and its TUI
    # companion (`dist/tui2.js`). The V1 plugin, V1 TUI, CLI and marketplace
    # contract are separate entrypoints V2 never resolves, so they are not
    # built or shipped.
    buildPhase = ''
      runHook preBuild

      bun run gen:build-info
      bun run clean:dist
      bun run build:v2
      bun run build:tui

      runHook postBuild
    '';

    installPhase = ''
      runHook preInstall

      # The build needs dev dependencies (typescript/biome/stryker tooling);
      # the runtime does not.
      bun prune --production

      mkdir -p $out/src/companion
      cp package.json oh-my-opencode-slim.schema.json $out/
      cp -r dist $out/dist
      cp -r src/skills $out/src/skills
      cp src/companion/companion-manifest.json $out/src/companion/
      cp -r node_modules $out/node_modules

      runHook postInstall
    '';

    meta = {
      description = "Multi-agent orchestration plugin for OpenCode (V2 plugin API)";
      homepage = "https://github.com/alvinunreal/oh-my-opencode-slim";
      license = lib.licenses.mit;
      platforms = lib.platforms.unix;
    };
  }
