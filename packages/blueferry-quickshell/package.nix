{
  lib,
  stdenv,
  symlinkJoin,
  qt6,
  quickshell,
  copyDesktopItems,
  makeDesktopItem,
  systemd,
  dbus,
  # our
  blueferry,
}: let
  inherit (blueferry) version;

  # Thin Quickshell launcher: ships only the QML config + `bin/blueferry-quickshell`.
  # The fat output below merges in the backend so one package yields `blueferry`,
  # `blueferry-tui` and `blueferry-quickshell` on PATH.
  client = stdenv.mkDerivation {
    pname = "blueferry-quickshell";
    inherit version;

    dontUnpack = true;
    dontConfigure = true;
    dontBuild = true;

    nativeBuildInputs = [
      qt6.wrapQtAppsHook
      copyDesktopItems
    ];

    buildInputs = [
      qt6.qtbase
      qt6.qtdeclarative
      systemd
      dbus
    ];

    # Install the QML config and create a launcher via qs symlink.
    # Patch all hardcoded /usr/bin paths in the QML files to Nix store paths.
    installPhase = ''
      runHook preInstall

      mkdir -p "$out/share/blueferry/quickshell" "$out/bin"
      # Copy QML files from backend source and patch hardcoded /usr/bin paths
      for f in shell.qml Theme.qml; do
        cp "${blueferry.passthru.src}/data/quickshell/$f" "$out/share/blueferry/quickshell/$f"
        substituteInPlace "$out/share/blueferry/quickshell/$f" \
          --replace "/usr/bin/blueferry" "${blueferry}/bin/blueferry" \
          --replace "/usr/bin/dbus-monitor" "${dbus}/bin/dbus-monitor" \
          --replace "/usr/bin/hyprctl" "hyprctl"
      done

      # quickshell is a QML shell toolkit — the launcher just runs qs with the config path
      ln -s "${lib.getExe' quickshell "qs"}" "$out/bin/blueferry-quickshell"

      runHook postInstall
    '';

    # wrapQtAppsHook wraps the qs symlink; inject the config path so quickshell
    # loads our shell.qml. Same pattern nixpkgs' noctalia-shell uses.
    preFixup = ''
      qtWrapperArgs+=(
        --add-flags "-p"
        --add-flags "$out/share/blueferry/quickshell"
      )
    '';

    desktopItems = [
      (makeDesktopItem {
        name = "io.weirdware.BlueFerry.Quickshell";
        desktopName = "BlueFerry (Quickshell)";
        exec = "blueferry-quickshell";
        icon = "io.weirdware.BlueFerry.Quickshell";
        terminal = false;
        type = "Application";
        categories = ["Network" "InstantMessaging"];
        keywords = ["iphone" "imessage" "bluetooth" "sms"];
      })
    ];

    meta = {
      description = "BlueFerry Quickshell client — iPhone messages on a Wayland shell";
      homepage = "https://github.com/erikwb/blueferry";
      license = lib.licenses.gpl2Only;
      platforms = lib.platforms.linux;
      mainProgram = "blueferry-quickshell";
    };
  };
in
  # Fat package = backend (CLI/TUI/daemon + D-Bus service) + Quickshell launcher,
  # so `programs.blueferry.package = pkgs."angeldust-pkgs".blueferry-quickshell`
  # is a single self-contained install. No path conflicts: the backend ships only
  # `bin/blueferry`/`bin/blueferry-tui` + `share/blueferry/package-release`, the
  # client only `bin/blueferry-quickshell` + `share/blueferry/quickshell/`.
  symlinkJoin {
    name = "blueferry-quickshell-${version}";
    paths = [blueferry client];
    inherit (client) meta;
  }
