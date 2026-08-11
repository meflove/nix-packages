{
  flake = _: {
    homeModules.${baseNameOf ./.} = {
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
          default = pkgs.angeldust-pkgs.pipewire-soundpad;
          defaultText = lib.literalExpression ''pkgs.angeldust-pkgs.blueferry'';
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
  };
}
