{
  lib,
  buildNpmPackage,
  inputs,
}: let
  src = inputs.opencode-dynamic-context-pruning;
in
  buildNpmPackage {
    pname = "opencode-dynamic-context-pruning";
    inherit (lib.importJSON "${src}/package.json") version;

    inherit src;

    npmDepsHash = "sha256-ucNE3Le/nr85P33X9FDx8WlWbwGgB9H3/VMPuBuuk9Q=";

    # @effect/platform-node declares `redis` as a peer without pinning it in the
    # lockfile, so npm tries to resolve it from the registry even offline and
    # fails with ENOTCACHED. Peer resolution is unnecessary here: the locked
    # tree is complete for this package.
    npmFlags = ["--legacy-peer-deps"];

    npmBuild = "npm run build";

    installPhase = ''
      runHook preInstall

      # @opencode-ai/plugin and zod are dev/peer deps upstream, so
      # `npm prune --omit=dev` would remove them even though dist/index.js
      # imports "@opencode-ai/plugin" at runtime and its dist/tool.js imports
      # "zod". Save both aside before the prune and restore them afterwards.
      # @opencode-ai/sdk is a prod dep and is kept by the prune (including
      # cross-spawn).
      mkdir -p .kept-node_modules/@opencode-ai
      cp -r node_modules/@opencode-ai/plugin .kept-node_modules/@opencode-ai/plugin
      cp -r node_modules/zod .kept-node_modules/zod

      npm prune --omit=dev --legacy-peer-deps

      mkdir -p node_modules/@opencode-ai
      cp -r .kept-node_modules/@opencode-ai/plugin node_modules/@opencode-ai/plugin
      cp -r .kept-node_modules/zod node_modules/zod
      rm -rf .kept-node_modules

      # Upstream declares a private `tests/logger` workspace which npm symlinks
      # into node_modules. It is test-only tooling and tests/ is not shipped, so
      # the link would dangle in the output.
      rm -f node_modules/opencode-request-logger

      mkdir -p $out
      cp -r package.json dcp.schema.json dist lib tui.tsx server.js README.md LICENSE node_modules $out/

      runHook postInstall
    '';

    meta = {
      description = "OpenCode plugin that optimizes token usage by pruning obsolete tool outputs from conversation context (V2 plugin API)";
      homepage = "https://github.com/Opencode-DCP/opencode-dynamic-context-pruning";
      license = lib.licenses.agpl3Only;
      platforms = lib.platforms.unix;
    };
  }
