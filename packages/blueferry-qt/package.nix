{
  lib,
  stdenv,
  symlinkJoin,
  makeBinaryWrapper,
  qt6,
  copyDesktopItems,
  makeDesktopItem,
  python3Packages,
  writeText,
  kdePackages,
  # our
  blueferry,
}: let
  inherit (blueferry) version;

  # Reuse the backend's runtime deps and add PySide6 (same python3Packages set,
  # so the ABI matches the interpreter). Qt/Kirigami come via buildInputs.
  runtimePython =
    python3Packages.python.withPackages (ps:
      (blueferry.passthru.runtimeDeps ps) ++ [ps.pyside6]);

  pythonSite = python3Packages.python.sitePackages;

  # Entry script lives in its own file: makeBinaryWrapper --add-flags word-splits
  # its argument, so a `-c "..."` one-liner does not survive wrapping.
  launcher = writeText "blueferry-qt.py" ''
    from blueferry.qt.app import main
    raise SystemExit(main())
  '';

  # Thin Qt launcher: only provides `bin/blueferry-qt`. The fat output below
  # merges in the backend so one package yields `blueferry`, `blueferry-tui` and
  # `blueferry-qt` on PATH.
  client = stdenv.mkDerivation {
    pname = "blueferry-qt";
    inherit version;

    dontUnpack = true;

    nativeBuildInputs = [
      makeBinaryWrapper
      qt6.wrapQtAppsHook
      copyDesktopItems
    ];

    buildInputs = [
      python3Packages.pyside6
      qt6.qtbase
      qt6.qtdeclarative
      kdePackages.kirigami
      kdePackages.qqc2-desktop-style
    ];

    # Self-contained launcher: a Python interpreter carrying blueferry's deps
    # plus PySide6, with blueferry itself on PYTHONPATH (from the backend's
    # installed site-packages), running the Qt entry script. qt6.wrapQtAppsHook
    # wraps this ELF in preFixup, wiring up QT_PLUGIN_PATH / QML2_IMPORT_PATH
    # from the Qt/Kirigami inputs.
    installPhase = ''
      runHook preInstall

      mkdir -p "$out/bin"
      makeBinaryWrapper "${lib.getExe runtimePython}" "$out/bin/blueferry-qt" \
        --prefix PYTHONPATH : "${blueferry}/${pythonSite}" \
        --add-flags "${launcher}"

      runHook postInstall
    '';

    desktopItems = [
      (makeDesktopItem {
        name = "io.weirdware.BlueFerry.Qt";
        desktopName = "BlueFerry (Qt)";
        exec = "blueferry-qt";
        icon = "io.weirdware.BlueFerry.Qt";
        terminal = false;
        type = "Application";
        categories = ["Network" "InstantMessaging"];
        keywords = ["iphone" "imessage" "bluetooth" "sms"];
      })
    ];

    meta = {
      description = "BlueFerry Qt client — iPhone messages, notifications and contacts on Linux";
      homepage = "https://github.com/erikwb/blueferry";
      license = lib.licenses.gpl2Only;
      platforms = lib.platforms.linux;
      mainProgram = "blueferry-qt";
    };
  };
in
  # Fat package = backend (CLI/TUI/daemon + D-Bus service) + Qt launcher, so
  # `programs.blueferry.package = pkgs."angeldust-pkgs".blueferry-qt` is a
  # single self-contained install. No path conflicts: the backend ships only
  # `bin/blueferry`/`bin/blueferry-tui`, the client only `bin/blueferry-qt`.
  symlinkJoin {
    name = "blueferry-qt-${version}";
    paths = [blueferry client];
    inherit (client) meta;
  }
