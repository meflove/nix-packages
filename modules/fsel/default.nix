{
  flake = _: {
    homeModules.${baseNameOf ./.} = {
      config,
      lib,
      pkgs,
      ...
    }: let
      cfg = config.programs.fsel;
      toml-format = pkgs.formats.toml {};
      toml = toml-format.type;
    in {
      options.programs.fsel = {
        enable = lib.mkEnableOption "fsel";
        package = lib.mkPackageOption pkgs "fsel" {};

        settings = lib.mkOption {
          type = toml;
          default = {};
          defaultText = lib.literalExpression "{ }";
          description = ''
            Configuration written to {file}`$XDG_CONFIG_DIR/fsel/config.toml`.

            See the [keybinds section](https://github.com/Mjoyufull/fsel/blob/main/config.toml)
          '';
        };

        keybinds = lib.mkOption {
          type = toml;
          default = {};
          defaultText = lib.literalExpression "{ }";
          description = ''
            Keybindings configuration.

            See the [keybinds section](https://github.com/Mjoyufull/fsel/blob/main/keybinds.toml)
          '';
        };
      };

      config = lib.mkIf cfg.enable {
        home.packages = [
          cfg.package
        ];

        xdg.configFile."fsel/config.toml" = lib.mkIf (cfg.settings != {}) {
          source = toml-format.generate "fsel-config" cfg.settings;
        };

        xdg.configFile."fsel/keybinds.toml" = lib.mkIf (cfg.keybinds != {}) {
          source = toml-format.generate "fsel-keybinds-config" cfg.keybinds;
        };
      };
    };
  };
}
