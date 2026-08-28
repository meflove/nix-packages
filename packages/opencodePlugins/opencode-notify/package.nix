{
  lib,
  buildNpmPackage,
  fetchurl,
}:
buildNpmPackage {
  pname = "opencode-notify";
  version = "0.3.1";

  # The upstream git repository only ships TypeScript sources that do not
  # compile (src/notify.ts imports modules missing upstream), so build from
  # the prebuilt dist published on the npm registry instead. The tarball
  # unpacks into the standard "package/" root.
  src = fetchurl {
    url = "https://registry.npmjs.org/opencode-notify/-/opencode-notify-0.3.1.tgz";
    hash = "sha512-ciKLEswpmR8itz3dMPbXmzvxZLfzOLc2KTbhdVMJWg/Fki/VnRgVErYU7zj1ZHT2qj4Qdz8ch85w4MZA93grDQ==";
  };

  # The published manifest declares optional native-notification backends
  # (powertoast, node-dbus-notifier, node-notifier) and @opencode-ai/* peer
  # deps that this build must not pull in: the dist bundles its own platform
  # backends (notify-send on Linux) and imports only node builtins at load
  # time. Synthesize a minimal manifest whose single runtime dependency is
  # detect-terminal, pinned to the resolution from the previous lockfile.
  postPatch = ''
    cp ${./package.json} package.json
    cp ${./package-lock.json} package-lock.json
    chmod 644 package.json package-lock.json
  '';

  npmDepsHash = "sha256-0zexSwR7HLCuDzLnAqxDhGK0y49836Q7yF/2RvGvxDk=";

  dontNpmBuild = true;

  installPhase = ''
    runHook preInstall

    npm prune --omit=dev

    mkdir -p $out
    cp package.json $out/
    cp -r dist node_modules $out/
    # The macOS OpenCodeNotifier.app bundle is not usable on this platform.
    rm -rf $out/dist/OpenCodeNotifier.app
    # The published tarball has no LICENSE file; keep whichever docs exist.
    for f in README.md LICENSE; do
      if [ -f "$f" ]; then
        cp "$f" $out/
      fi
    done

    runHook postInstall
  '';

  meta = {
    description = "Native OS notifications for OpenCode - know when tasks complete (OpenCode V1 plugin API; does not load on OpenCode V2)";
    homepage = "https://github.com/kdcokenny/opencode-notify";
    license = lib.licenses.mit;
    platforms = lib.platforms.unix;
  };
}
