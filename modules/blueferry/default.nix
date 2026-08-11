{
  flake = _: {
    homeModules.${baseNameOf ./.} = {
      config,
      lib,
      pkgs,
      ...
    }: let
      cfg = config.programs.blueferry;
    in {
      options.programs.blueferry = {
        enable = lib.mkEnableOption "BlueFerry — iPhone messages, notifications and contacts over Bluetooth";

        package = lib.mkOption {
          type = lib.types.package;
          default = pkgs.angeldust-pkgs.blueferry;
          defaultText = lib.literalExpression ''pkgs.angeldust-pkgs.blueferry'';
          description = ''
            BlueFerry package providing the backend — the `blueferry` CLI, the
            `blueferry-tui` TUI and the D-Bus daemon.

            Defaults to the headless backend. To also get a GUI, set this to
            `pkgs.angeldust-pkgs.blueferry-gtk`, `.blueferry-qt` or
            `.blueferry-quickshell` — those bundle the backend, so a single
            `package` is all you need.

            Requires the `angeldust-pkgs` package set on `pkgs` (your overlay).
          '';
        };
      };

      config = lib.mkIf cfg.enable {
        home.packages = [cfg.package];

        systemd.user.services.blueferry = {
          Unit = {
            Description = "BlueFerry — iPhone↔Linux Bluetooth bridge";
            Documentation = ["https://github.com/erikwb/blueferry"];
            ConditionPathExists = "%h/.config/blueferry/local.env";
          };

          Service = {
            Type = "dbus";
            BusName = "io.weirdware.BlueFerry";
            ExecStart = "${cfg.package}/bin/blueferry run";
            Restart = "on-failure";
            RestartForceExitStatus = 75;
            RestartSec = 5;
            TimeoutStopSec = 180;
            UMask = "0077";
            NoNewPrivileges = true;
            CapabilityBoundingSet = "";
            PrivateDevices = true;
            ProtectClock = true;
            ProtectControlGroups = true;
            ProtectHostname = true;
            ProtectKernelLogs = true;
            ProtectKernelModules = true;
            ProtectKernelTunables = true;
            ProtectSystem = "strict";
            RestrictNamespaces = true;
            SystemCallArchitectures = "native";
            RestrictAddressFamilies = "AF_UNIX";
            RestrictRealtime = true;
            RestrictSUIDSGID = true;
            LockPersonality = true;
            StandardOutput = "journal";
            StandardError = "journal";
          };

          Install = {
            WantedBy = ["default.target"];
          };
        };
      };
    };
  };
}
