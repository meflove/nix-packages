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
    rev = "a1342ca61ba28234e274e549487c181aae50588a";
    hash = "sha256-5DcMjXXGcMObwZBbeqOtXziGpjs1oimXiFdyHaSip5c=";
  };

  pyproject = lib.importTOML "${src.outPath}/pyproject.toml";
  version = "${pyproject.project.version}-${lib.substring 0 7 src.rev}";
in
  python.buildPythonApplication (_old: {
    pname = "icp-linux";
    inherit src version;

    # Since ~2026-10-12 Apple only accepts anisette made by Windows/iTunes ADI, presented
    # with that client's own identity: a Mac claim answers -80045, the plain akd /
    # iCloud-for-Windows one -27952, and the Mac identity is refused on both setup
    # endpoints (loginDelegates `status 1`, get_account_settings 401). The patch also handles
    # the hsc 409 "code already pushed" 2FA shape and retries the flaky edge/setup calls.
    # See Sank6#15 and SideloaderKit/Anisette.swift in SideStep.
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
