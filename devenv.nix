{pkgs, ...}: {
  cachix.push = "meflove";

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
