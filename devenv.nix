{
  lib,
  pkgs,
  ...
}: {
  cachix.push = "meflove";

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
      trim-trailing-whitespace.enable = true;
      detect-private-keys.enable = true;

      # Nix specific hooks
      alejandra.enable = true;
      deadnix.enable = true;
      statix.enable = true;
    };
  };
}
