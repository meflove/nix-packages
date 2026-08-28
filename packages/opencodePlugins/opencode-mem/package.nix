{
  lib,
  bun2nix,
  inputs,
}: let
  src = inputs.opencode-mem;
in
  bun2nix.mkDerivation {
    pname = "opencode-mem";
    inherit (lib.importJSON "${src}/package.json") version;

    inherit src;

    nativeBuildInputs = [bun2nix.hook];

    # The default isolated linker keeps transitive dependencies out of the
    # top-level node_modules, which breaks `tsc` resolving "bun-types" (a
    # transitive dependency of @types/bun). Use a classic hoisted layout.
    bunInstallFlags = "--linker=hoisted";

    bunDeps = bun2nix.fetchBunDeps {bunNix = ./bun.nix;};

    # web/ is a standalone bun project (not a workspace member) with its own
    # bun.lock; its dependencies are installed separately before the build.
    webBunDeps = bun2nix.fetchBunDeps {bunNix = ./web-bun.nix;};

    preBuild = ''
      webCache=$(mktemp -d)
      cp -r "$webBunDeps"/share/bun-cache/. "$webCache"
      (cd web && BUN_INSTALL_CACHE_DIR="$webCache" bun install --frozen-lockfile --linker=hoisted --ignore-scripts)
    '';

    # "bun run build" = clean + tsc + web UI (vite) build into dist/web
    buildPhase = ''
      runHook preBuild

      bun run build

      runHook postBuild
    '';

    # Force transformers.js to use only the local model cache
    # (~/.opencode-mem/data/.cache). The opencode host process cannot verify
    # huggingface.co TLS certificates, so any remote revision check kills
    # embedding initialization even when every model file is already cached.
    # The weights must be pre-seeded into the cache (see the module docs).
    postPatch = ''
      substituteInPlace src/services/embedding.ts \
        --replace-fail 'allowRemoteModels = true' 'allowRemoteModels = false'
    '';

    installPhase = ''
      mkdir -p $out

      cp -r package.json dist node_modules $out/
    '';

    meta = {
      description = "OpenCode plugin that gives coding agents persistent memory using local Turso/libSQL vector search (OpenCode V1 plugin API; does not load on OpenCode V2)";
      homepage = "https://github.com/tickernelz/opencode-mem";
      license = lib.licenses.mit;
      platforms = lib.platforms.unix;
    };
  }
