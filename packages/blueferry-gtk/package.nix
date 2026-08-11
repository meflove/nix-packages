{
  lib,
  stdenv,
  symlinkJoin,
  makeBinaryWrapper,
  gobject-introspection,
  wrapGAppsHook4,
  copyDesktopItems,
  makeDesktopItem,
  python3Packages,
  writeText,
  # deps
  gtk4,
  libadwaita,
  # our
  blueferry,
}: let
  inherit (blueferry) version;

  # Reuse the backend's exact runtime deps and add nothing GTK-specific at the
  # Python level (PyGObject is already in runtimeDeps). gtk4/libadwaita come in
  # via buildInputs + wrapGAppsHook4 below.
  runtimePython = python3Packages.python.withPackages blueferry.passthru.runtimeDeps;

  pythonSite = python3Packages.python.sitePackages;

  # Entry script lives in its own file: makeBinaryWrapper --add-flags word-splits
  # its argument, so a `-c "..."` one-liner does not survive wrapping.
  launcher = writeText "blueferry-gtk.py" ''
    from blueferry.ui.app import main
    raise SystemExit(main())
  '';

  # Thin GTK launcher: only provides `bin/blueferry-gtk`. The fat output below
  # merges in the backend so one package yields `blueferry`, `blueferry-tui` and
  # `blueferry-gtk` on PATH.
  client = stdenv.mkDerivation {
    pname = "blueferry-gtk";
    inherit version;

    dontUnpack = true;

    nativeBuildInputs = [
      makeBinaryWrapper
      gobject-introspection
      wrapGAppsHook4
      copyDesktopItems
    ];

    buildInputs = [
      gtk4
      libadwaita
    ];

    # Self-contained launcher: a Python interpreter that carries blueferry's
    # runtime deps, with blueferry itself on PYTHONPATH (from the backend's
    # installed site-packages), running the GTK entry script. wrapGAppsHook4
    # then wraps this ELF in preFixup, layering the gtk4 / libadwaita typelibs
    # (GI_TYPELIB_PATH), GSettings schemas and XDG_DATA_DIRS on top.
    installPhase = ''
      runHook preInstall

      mkdir -p "$out/bin"
      makeBinaryWrapper "${lib.getExe runtimePython}" "$out/bin/blueferry-gtk" \
        --prefix PYTHONPATH : "${blueferry}/${pythonSite}" \
        --add-flags "${launcher}"

      runHook postInstall
    '';

    desktopItems = [
      (makeDesktopItem {
        name = "io.weirdware.BlueFerry.Gtk";
        desktopName = "BlueFerry (GTK)";
        exec = "blueferry-gtk";
        icon = "io.weirdware.BlueFerry.Gtk";
        terminal = false;
        type = "Application";
        categories = ["Network" "InstantMessaging"];
        keywords = ["iphone" "imessage" "bluetooth" "sms"];
      })
    ];

    meta = {
      description = "BlueFerry GTK client — iPhone messages, notifications and contacts on Linux";
      homepage = "https://github.com/erikwb/blueferry";
      license = lib.licenses.gpl2Only;
      platforms = lib.platforms.linux;
      mainProgram = "blueferry-gtk";
    };
  };
in
  # Fat package = backend (CLI/TUI/daemon + D-Bus service) + GTK launcher, so
  # `programs.blueferry.package = pkgs."angeldust-pkgs".blueferry-gtk` is a
  # single self-contained install. No path conflicts: the backend ships only
  # `bin/blueferry`/`bin/blueferry-tui`, the client only `bin/blueferry-gtk`.
  symlinkJoin {
    name = "blueferry-gtk-${version}";
    paths = [blueferry client];
    inherit (client) meta;
  }
