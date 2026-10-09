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
    rev = "d098a7af024345f59ede47f2298e3113fd2b821b";
    hash = "sha256-wtlnAzy/eUOgb1AZXgTfvemdllNFlo9cqQS+2fyOVmY=";
  };

  pyproject = lib.importTOML "${src.outPath}/pyproject.toml";
  version = "${pyproject.project.version}-${lib.substring 0 7 src.rev}";
in
  python.buildPythonApplication (_old: {
    pname = "icp-linux";
    inherit src version;

    # Apple's GrandSlam edge returns 503 when X-MMe-Client-Info does not
    # match the provisioned machine identity; take it from the anisette
    # server (which provisions with the same value) instead of the const.
    patches = [./anisette-client-info.patch];

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
