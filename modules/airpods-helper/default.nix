{self, ...}: {
  flake.nixosModules.airpods-helper = {
    config,
    lib,
    pkgs,
    ...
  }: let
    cfg = config.services.airpods-helper;

    daemonPath = "${config.security.wrapperDir}/airpods-daemon";

    toml = pkgs.formats.toml {};
    settingsFile = toml.generate "airpods-helper-config.toml" cfg.settings;

    dbusService = pkgs.writeTextDir "share/dbus-1/services/org.costa.AirPods.service" ''
      [D-BUS Service]
      Name=org.costa.AirPods
      Exec=${daemonPath}
      SystemdService=airpods-daemon.service
    '';
  in {
    options.services.airpods-helper = {
      enable = lib.mkEnableOption ''
        AirPods Helper: noise control, battery, ear detection, EQ and the
        "AirPods Microphone" source that keeps A2DP stereo audio playing
      '';

      package = lib.mkOption {
        type = lib.types.package;
        default = self.packages.${pkgs.stdenv.hostPlatform.system}.airpods-helper;
        defaultText = lib.literalExpression "self.packages.\${pkgs.stdenv.hostPlatform.system}.airpods-helper";
        description = ''
          Package providing `airpods-daemon` and `airpods-cli`.
        '';
      };

      user = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        example = "angeldust";
        description = ''
          Run the user service only for this user (systemd `ConditionUser`).
          When null, it starts for every user that logs in, which only makes
          sense on a single-user machine.
        '';
      };

      settings = lib.mkOption {
        inherit (toml) type;
        default = {};
        example = lib.literalExpression ''
          {
            eq = {
              active_preset = "bass-boost";
              backend = "pipewire";
            };
            mic.enabled = true;
          }
        '';
        description = ''
          Initial contents of `~/.config/airpods-helper/config.toml`.

          The file is installed on service start only when it does not exist
          yet. The daemon rewrites this file when a setting changes
          (`airpods-cli set`, the desktop app), and those changes must survive
          a restart, so this option cannot keep it declarative.
        '';
      };
    };

    config = lib.mkIf cfg.enable {
      environment.systemPackages = [
        cfg.package
        pkgs.libcap
        dbusService
      ];

      security.wrappers.airpods-daemon = {
        source = "${cfg.package}/bin/airpods-daemon";
        owner = "root";
        group = "root";
        capabilities = "cap_net_raw,cap_net_admin+ep";
      };

      systemd.user.services.airpods-daemon = {
        description = "AirPods Helper Daemon";
        wantedBy = ["default.target"];
        after = [
          "pipewire.service"
          "wireplumber.service"
        ];

        unitConfig = lib.optionalAttrs (cfg.user != null) {
          ConditionUser = cfg.user;
        };

        path = [
          pkgs.pulseaudio
          pkgs.pipewire
          pkgs.wireplumber
        ];

        preStart = lib.mkIf (cfg.settings != {}) ''
          config="$HOME/.config/airpods-helper/config.toml"
          if [ ! -e "$config" ]; then
            ${pkgs.coreutils}/bin/mkdir -p "$(dirname "$config")"
            ${pkgs.coreutils}/bin/install -m 600 ${settingsFile} "$config"
          fi
        '';

        serviceConfig = {
          ExecStart = daemonPath;
          Restart = "on-failure";
          RestartSec = 5;
        };
      };
    };
  };
}
