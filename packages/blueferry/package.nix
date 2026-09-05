{
  lib,
  fetchFromGitHub,
  gobject-introspection,
  wrapGAppsHook3,
  python3Packages,
  # deps
  libsecret,
  glib,
  # runtime tools blueferry shells out to via absolute paths (patched below)
  systemd,
  bluez,
}: let
  src = fetchFromGitHub {
    owner = "erikwb";
    repo = "blueferry";
    rev = "ac8630f44c7966da91b17d9eaab69eb5bb1d7880";
    hash = "sha256-tVNDDOL3gI5yywU15ogmMQlXvMYNnHczk57da1bruK0=";
  };

  pyproject = lib.importTOML "${src.outPath}/pyproject.toml";
  version = "${pyproject.project.version}-${lib.substring 0 7 src.rev}";

  # Runtime Python deps
  runtimeDeps = ps:
    with ps; [
      cryptography
      textual
      typer
      dbus-python
      pygobject3
    ];
in
  python3Packages.buildPythonApplication (_finalAttrs: {
    pname = "blueferry";
    inherit src version;

    pyproject = true;

    build-system = with python3Packages; [
      setuptools
      wheel
    ];

    dependencies = runtimeDeps python3Packages;

    nativeBuildInputs = [
      gobject-introspection
      wrapGAppsHook3
    ];

    buildInputs = [
      libsecret
      glib
      # Blueferry hardcodes /usr/bin & /usr/libexec paths for these tools; the
      # postPatch below rewrites them to these store paths, which makes the
      # tools part of the runtime closure.
      systemd
      bluez
    ];

    # Upstream assumes a FHS layout with /usr/bin/{systemctl,btmgmt,pkexec} and
    # /usr/libexec/bluetooth/obexd. Rewrite every one to its Nix store path so
    # the CLI, TUI and daemon find them on NixOS. Also point the
    # package-release marker at our own share dir (written in postInstall).
    # Also patch QML files that hardcode /usr/bin/blueferry for the Quickshell client.
    postPatch = ''
      substituteInPlace \
        src/blueferry/backend_lifecycle.py \
        src/blueferry/bluetooth_capabilities.py \
        src/blueferry/pair_setup.py \
        src/blueferry/bluez_setup.py \
        src/blueferry/cli.py \
        src/blueferry/ui/app.py \
        src/blueferry/qt/app.py \
        --replace "/usr/bin/systemctl" "${systemd}/bin/systemctl" \
        --replace "/usr/bin/btmgmt" "${bluez}/bin/btmgmt" \
        --replace "/usr/bin/pkexec" "/run/wrappers/bin/pkexec" \
        --replace "/usr/libexec/bluetooth/obexd" "${bluez}/libexec/bluetooth/obexd" \
        --replace "/usr/lib/bluetooth/obexd" "${bluez}/libexec/bluetooth/obexd" \
        --replace "/usr/share/blueferry/package-release" "${placeholder "out"}/share/blueferry/package-release" \
        --replace "/usr/lib/systemd/system/bluetooth.service.d/blueferry.conf" "${placeholder "out"}/lib/systemd/system/bluetooth.service.d/blueferry.conf"
    '';

    postInstall = ''
      mkdir -p "$out/share/blueferry"
      echo "${version}" > "$out/share/blueferry/package-release"

      # Bluetooth experimental-mode drop-in: enables BlueZ's bearer API
      # (-E flag) that blueferry needs for MAP/PBAP/ANCS.
      # On NixOS add this package to `systemd.packages` so systemd picks it up,
      # OR enable experimental directly:
      #   systemd.services.bluetooth.serviceConfig.ExecStart = lib.mkForce
      #     [ "${bluez}/libexec/bluetooth/bluetoothd -E" ];
      mkdir -p "$out/lib/systemd/system/bluetooth.service.d"
      printf '%s\n' '[Service]' 'ExecStart=' 'ExecStart=${bluez}/libexec/bluetooth/bluetoothd -E' \
        > "$out/lib/systemd/system/bluetooth.service.d/blueferry.conf"

      # The GTK/Qt clients ship as separate packages (blueferry-gtk,
      # blueferry-qt) with their own toolkit runtimes, so drop the entry-point
      # stubs the backend would otherwise install. Otherwise `blueferry-gtk` /
      # `blueferry-qt` would exist here without gtk4 / PySide6 and crash.
      rm -f "$out/bin/blueferry-gtk" "$out/bin/.blueferry-gtk-wrapped"
      rm -f "$out/bin/blueferry-qt" "$out/bin/.blueferry-qt-wrapped"
    '';

    # The upstream test suite needs a live Bluetooth/DBus session.
    doCheck = false;

    passthru = {
      inherit runtimeDeps src;
    };

    meta = {
      description = "BlueFerry brings iPhone messages, notifications, and contacts to Linux";
      homepage = "https://github.com/erikwb/blueferry";
      license = lib.licenses.gpl2Only;
      platforms = lib.platforms.linux;
      mainProgram = "blueferry";
    };
  })
