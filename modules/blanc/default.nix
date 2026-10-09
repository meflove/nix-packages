{self, ...}: {
  flake.homeModules.${baseNameOf ./.} = {
    config,
    lib,
    pkgs,
    ...
  }: let
    cfg = config.programs.blanc;

    # `commandLineArgs` is an argument of the package itself, the way
    # google-chrome/brave take one in nixpkgs, so customize the package instead
    # of wrapping the launcher a second time — same approach as Home Manager's
    # `programs.chromium` family.
    finalPackage =
      if cfg.commandLineArgs == []
      then cfg.package
      else
        cfg.package.override {
          commandLineArgs = lib.concatStringsSep " " cfg.commandLineArgs;
        };

    # Blanc registers http/https plus its own `blanc-import` tab-handoff scheme.
    desktopFile = "blanc.desktop";

    browserMimeTypes = [
      "text/html"
      "application/xhtml+xml"
      "x-scheme-handler/http"
      "x-scheme-handler/https"
      "x-scheme-handler/blanc-import"
    ];
  in {
    options.programs.blanc = {
      enable = lib.mkEnableOption "Blanc — minimal Chromium-based (Electron) browser";

      package = lib.mkOption {
        type = lib.types.package;
        default = self.packages.${pkgs.stdenv.hostPlatform.system}.blanc;
        description = ''
          The Blanc package to use.

          Requires the `angeldust-pkgs` package set on `pkgs` (your overlay).
        '';
      };

      commandLineArgs = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [];
        example = ["--enable-logging=stderr"];
        description = ''
          Switches appended to the launcher, in the spirit of
          `programs.chromium.commandLineArgs`.

          Applied by overriding the package's `commandLineArgs` argument, so the
          result is what `pkgs.angeldust-pkgs.blanc` is customized with — not a
          wrapper script around it.
        '';
      };

      setAsDefaultBrowser = lib.mkOption {
        type = lib.types.bool;
        default = false;
        example = true;
        description = ''
          Register Blanc as the handler for `http`, `https`, `text/html` and its
          own `blanc-import` scheme through `xdg.mimeApps.defaultApplications`.

          Off by default: nothing is changed unless you ask for it.
        '';
      };
    };

    config = lib.mkIf cfg.enable {
      home.packages = [finalPackage];

      xdg.mimeApps = lib.mkIf cfg.setAsDefaultBrowser {
        enable = lib.mkDefault true;
        defaultApplications = lib.genAttrs browserMimeTypes (_: desktopFile);
      };
    };
  };
}
