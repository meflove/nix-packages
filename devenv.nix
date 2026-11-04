{
  pkgs,
  lib,
  ...
}: {
  cachix.push = "meflove";

  # jj-hp runs `git worktree add`, which triggers prek's post-checkout hook
  # inside the new ephemeral worktree. The generated .pre-commit-config.yaml
  # is gitignored, so it does not exist there yet and prek would abort the
  # worktree creation. jj-hp links the config in afterwards via
  # [[jj-hooks.setup]] (see .jj/repo/config.toml).
  env.PREK_ALLOW_NO_CONFIG = "1";

  packages = lib.attrValues {
    inherit
      (pkgs)
      jq
      ;
  };

  git-hooks = {
    package = pkgs.prek;

    hooks = {
      # Basic hooks
      shellcheck.enable = true;
      end-of-file-fixer.enable = true;
      trim-trailing-whitespace.enable = true;
      detect-private-keys.enable = true;

      # Nix specific hooks
      alejandra.enable = true;
      deadnix.enable = true;
      statix.enable = true;
    };
  };
}
