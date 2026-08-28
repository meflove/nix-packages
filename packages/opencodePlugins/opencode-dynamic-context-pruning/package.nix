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

    npmDepsHash = "sha256-GMilj6GzaulQ9Akw11+TpRrC0t9oezcDj6wZSOVugS8=";

    npmBuild = "npm run build";

    installPhase = ''
      runHook preInstall

      # @opencode-ai/plugin (and its nested zod) are dev/peer deps upstream, so
      # `npm prune --omit=dev` would remove them even though dist/index.js
      # imports "@opencode-ai/plugin" at runtime. Save the subtree aside before
      # the prune and restore it afterwards. Its runtime deps are covered:
      # @opencode-ai/sdk is a prod dep (kept by the prune, including
      # cross-spawn), and zod lives nested inside this subtree.
      mkdir -p .kept-node_modules/@opencode-ai
      cp -r node_modules/@opencode-ai/plugin .kept-node_modules/@opencode-ai/plugin

      npm prune --omit=dev

      mkdir -p node_modules/@opencode-ai
      cp -r .kept-node_modules/@opencode-ai/plugin node_modules/@opencode-ai/plugin
      rm -rf .kept-node_modules

      mkdir -p $out
      cp -r package.json dcp.schema.json dist lib tui.tsx README.md LICENSE node_modules $out/

      runHook postInstall
    '';

    meta = {
      description = "OpenCode plugin that optimizes token usage by pruning obsolete tool outputs from conversation context (OpenCode V1 plugin API; does not load on OpenCode V2)";
      homepage = "https://github.com/Opencode-DCP/opencode-dynamic-context-pruning";
      license = lib.licenses.agpl3Only;
      mainProgram = "opencode-dynamic-context-pruning";
      platforms = lib.platforms.unix;
    };
  }
