{self, ...}: {
  flake.homeModules.${baseNameOf ./.} = {
    config,
    pkgs,
    lib,
    ...
  }: let
    cfg = config.programs.pipewire-soundpad;
  in {
    options.programs.pipewire-soundpad = {
      enable = lib.mkEnableOption "Enable pipewire-soundpad";

      package = lib.mkOption {
        type = lib.types.package;
        default = self.packages.${pkgs.stdenv.hostPlatform.system}.pipewire-soundpad;
      };
    };

    config = lib.mkIf cfg.enable {
      home.packages = [
        cfg.package
      ];

      systemd.user.services.pipewire-soundpad = {
        Unit = {
          Description = "Pipewire Soundpad Daemon";
          After = ["pipewire.service"];
        };

        Service = {
          ExecStart = "${cfg.package}/bin/pwsp-daemon";
          Restart = "no";
          RuntimeDirectory = "pwsp";
        };

        Install = {
          WantedBy = ["default.target"];
        };
      };
    };
  };
}
