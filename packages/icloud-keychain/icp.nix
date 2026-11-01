{
  lib,
  fetchFromGitHub,
  icloud-keychain,
  python314Packages,
}: let
  python = python314Packages;

  src = fetchFromGitHub {
    owner = "Sank6";
    repo = "iCloud-Keychain-for-Linux";
    rev = "74964eeef01d71db8daa0fc961306ec194bc98df";
    hash = "sha256-m8g++GJh5f2MNnhptIEui0d3chpRo/aTTOwevqhIQYg=";
  };

  pyproject = lib.importTOML "${src.outPath}/pyproject.toml";
  version = "${pyproject.project.version}-${lib.substring 0 7 src.rev}";
in
  python.buildPythonApplication (_old: {
    pname = "icp-linux";
    inherit src version;

    # Since ~2026-10-12 Apple only accepts anisette made by Windows ADI, presented with that
    # client's own identity (a Mac claim answers -80045). Upstream adopted that in a1342ca
    # (Sank6#24), so only the robustness part is left here: the GSA edge intermittently answers
    # an HTML 503 to the second SRP login `icp join` runs seconds after `icp login`, so a
    # non-plist answer becomes a GSAEdgeError with one retry, the GSA keep-alive connection is
    # never reused, the iCloud setup POSTs retry transient network failures, and the SMS 403
    # (texted codes refused for anisette-server sign-ins) is explained. See Sank6#15.
    patches = [./grandslam-windows-client-info.patch];

    pyproject = true;

    build-system = with python; [
      setuptools
    ];

    dependencies = with python; [
      cryptography
      pynacl
      requests
      secretstorage
      srp
    ];

    postInstall = ''
      cat > $out/bin/icp-host <<'PYEOF'
      #!/usr/bin/env python3
      import sys

      from icp.vault.host import main

      sys.exit(main())
      PYEOF
      chmod +x $out/bin/icp-host

      mkdir -p $out/lib/mozilla/native-messaging-hosts
      cat > $out/lib/mozilla/native-messaging-hosts/org.icp.native.json <<EOF
      {
        "name": "org.icp.native",
        "description": "Apple Passwords native messaging host",
        "path": "$out/bin/icp-host",
        "type": "stdio",
        "allowed_extensions": ["icp-linux@local"]
      }
      EOF

      # Unpacked extension (icon-patched manifest included, same tree as the
      # xpi) for Chromium-family "Load unpacked".
      mkdir -p $out/share/icloud-keychain/extension
      cp -r ${icloud-keychain.extension}/share/icloud-keychain/extension/. $out/share/icloud-keychain/extension/
    '';

    meta = {
      description = "Unofficial iCloud Keychain client for Linux — Apple passwords, TOTP and Hide My Email";
      homepage = "https://github.com/Sank6/iCloud-Keychain-for-Linux";
      license = lib.licenses.mit;
      mainProgram = "icp";
    };
  })
