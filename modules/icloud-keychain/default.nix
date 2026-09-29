{self, ...}: {
  flake.nixosModules.icloud-keychain = {
    config,
    lib,
    pkgs,
    options,
    ...
  }: let
    cfg = config.services.icloud-keychain;

    anisetteVolume =
      if cfg.anisette.dataDir != null
      then "${cfg.anisette.dataDir}:/home/Alcoholic/.config/anisette-v3/lib/"
      else "anisette-v3_data:/home/Alcoholic/.config/anisette-v3/lib/";
  in {
    options.services.icloud-keychain = {
      enable = lib.mkEnableOption ''
        iCloud Keychain for Linux: the `icp` CLI, the anisette-v3-server
        container Apple sign-in needs, and native-messaging wiring for
        enabled Firefox-family browsers
      '';

      package = lib.mkOption {
        type = lib.types.package;
        default = self.legacyPackages.${pkgs.stdenv.hostPlatform.system}.icloud-keychain.icp;
        description = ''
          The `icp` package. Ships the CLI (`icp`), the native-messaging
          launcher (`icp-host`) with its manifest under
          `lib/mozilla/native-messaging-hosts`, and the unpacked browser
          extension under `share/icloud-keychain/extension`.
        '';
      };

      anisette = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = ''
            Run the anisette-v3-server container locally. Disable when you
            already run an anisette server elsewhere and point `icp` at it via
            `ICP_ANISETTE_URL`.
          '';
        };

        image = lib.mkOption {
          type = lib.types.str;
          default = "docker.io/dadoum/anisette-v3-server:latest";
          description = "OCI image for the anisette server.";
        };

        listenAddress = lib.mkOption {
          type = lib.types.str;
          default = "127.0.0.1";
          description = "Host address to bind the anisette port to.";
        };

        port = lib.mkOption {
          type = lib.types.port;
          default = 6969;
          description = "Host port for the anisette server (container port is fixed at 6969).";
        };

        dataDir = lib.mkOption {
          type = lib.types.nullOr lib.types.path;
          default = null;
          description = ''
            Host directory to persist the anisette device data. `null` (the
            default) uses the named docker volume `anisette-v3_data`, as
            recommended upstream.
          '';
        };

        pull = lib.mkOption {
          type = lib.types.enum ["always" "missing" "never" "newer"];
          default = "missing";
          description = ''
            Image pull policy. With a moving tag such as `:latest` and the
            default `missing`, the image stays as first pulled — use `newer` or
            `always` to refresh it, or pull manually.
          '';
        };

        extraOptions = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [];
          description = "Extra options passed to the container.";
        };
      };
    };

    config = lib.mkIf cfg.enable (lib.mkMerge [
      {
        environment.systemPackages = [cfg.package];

        programs.firefox.nativeMessagingHosts.packages =
          lib.mkIf config.programs.firefox.enable [cfg.package];
      }

      (lib.mkIf (options ? home-manager) {
        home-manager.sharedModules = [
          (
            {
              config,
              lib,
              ...
            }: let
              # The (unsigned) Apple Passwords extension, installed into every
              # profile of enabled Firefox-family browsers via globalExtensions.
              # Firefox release builds also need
              # `xpinstall.signatures.required = false` per profile.
              extension = self.legacyPackages.${pkgs.stdenv.hostPlatform.system}.icloud-keychain.extension;
            in {
              # attrByPath on the browser's `enable` is the working guard: it
              # short-circuits where the browser's module is not imported and
              # reads a declared option's value (never a plain existence check
              # on `options.programs`, whose intermediate keys are not
              # materialized).
              config = lib.mkMerge [
                (lib.mkIf (lib.attrByPath ["programs" "zen-browser" "enable"] false config) {
                  programs.zen-browser = {
                    nativeMessagingHosts = [cfg.package];
                    globalExtensions = [extension];
                  };
                })
                (lib.mkIf (lib.attrByPath ["programs" "firefox" "enable"] false config) {
                  programs.firefox = {
                    nativeMessagingHosts = [cfg.package];
                    globalExtensions = [extension];
                  };
                })
              ];
            }
          )
        ];
      })

      (lib.mkIf cfg.anisette.enable {
        environment.sessionVariables.ICP_ANISETTE_URL = "http://${cfg.anisette.listenAddress}:${toString cfg.anisette.port}";

        virtualisation.oci-containers.containers.anisette-v3 = {
          autoStart = true;
          image = cfg.anisette.image;
          ports = ["${cfg.anisette.listenAddress}:${toString cfg.anisette.port}:6969"];
          volumes = [anisetteVolume];
          pull = cfg.anisette.pull;
          extraOptions = cfg.anisette.extraOptions;
        };
      })
    ]);
  };
}
