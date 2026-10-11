{
  lib,
  addDriverRunpath,
  buildNpmPackage,
  copyDesktopItems,
  electron_44,
  fetchFromGitHub,
  libglvnd,
  makeDesktopItem,
  makeWrapper,
  nodejs_22,
  xdg-utils,
  # Flags appended to the launcher, e.g. "--enable-logging=stderr".
  # Mirrors the `commandLineArgs` argument of `google-chrome`/`brave` in nixpkgs,
  # which is what `programs.blanc.commandLineArgs` overrides.
  commandLineArgs ? "",
}: let
  electron = electron_44;

  # Upstream pins Electron exactly (src/main/ublock-platforms.json, 44.5.1) and
  # scripts/preflight-electron-runtime.js refuses to package unless the locked,
  # installed and running versions all match. electron_44 is that version.
  electronVersion = electron.version;

  # Tracks main rather than a release tag, like the other branch-tracking
  # packages here: the bulk updater only has to move `rev` (and the hashes), and
  # `version` follows from the checkout.
  src = fetchFromGitHub {
    owner = "bnfy";
    repo = "blanc";
    rev = "5b15b4622849e70a3c53a2d2536044f74a4bacfc";
    hash = "sha256-bnlDNMInSAtEfmEA+/LaXy7LjInz7xyXo9DbZ8IBTVw=";
  };

  packageJson = builtins.fromJSON (builtins.readFile "${src.outPath}/package.json");
  version = "${packageJson.version}-${lib.substring 0 7 src.rev}";

  extraFlags = lib.optionalString (
    commandLineArgs != ""
  ) " --add-flags ${lib.escapeShellArg commandLineArgs}";
in
  buildNpmPackage (finalAttrs: {
    pname = "blanc";
    inherit src version;

    # Upstream builds with Node 22 (.github/workflows/release-windows-linux.yml).
    nodejs = nodejs_22;

    npmDepsHash = "sha256-DTdDwIa6sfLUkJW5mc0Y6Bp7es4qkFap3FUG2s/vxnk=";

    # `npm rebuild` would otherwise run the install scripts of dependencies; the
    # only ones in the lock file are the root `postinstall` (reproduced below from
    # committed inputs) and electron-winstaller (Windows-only).
    npmRebuildFlags = ["--ignore-scripts"];

    env = {
      # electron@44 ships no install script: index.js downloads the binary as soon
      # as it is required. Point it at the Nix Electron 44.5.1 instead — the same
      # directory electron-builder packs below.
      ELECTRON_OVERRIDE_DIST_PATH = "${electron.dist}";
      ELECTRON_SKIP_BINARY_DOWNLOAD = "1";
      PLAYWRIGHT_SKIP_BROWSER_DOWNLOAD = "1";
    };

    postPatch = ''
        # Blanc self-updates with electron-updater against GitHub Releases, replacing
        # the AppImage it was launched from — impossible from a read-only store, and
        # pointless next to nix-update. Short-circuit the policy so neither the
        # scheduled check nor "Check for Updates…" tries; the reason is logged and
        # shown in the menu dialog. `--replace-fail` keeps this honest across bumps.
        substituteInPlace src/main/updater-policy.js --replace-fail \
          "  if (!isPackaged) return disabled('development builds do not self-update');" \
          "  if (!isPackaged) return disabled('development builds do not self-update');
      return disabled('updates are managed by the Nix package (nix-update), not electron-updater');"
    '';

    nativeBuildInputs = [
      copyDesktopItems
      makeWrapper
    ];

    dontNpmBuild = true;
    dontNpmInstall = true;

    buildPhase = ''
      runHook preBuild

      export HOME="$TMPDIR"
      export ELECTRON_BUILDER_CACHE="$TMPDIR/electron-builder-cache"

      # The `postinstall` script normally writes this gitignored seed, and scripts
      # are skipped here. It is derived from the committed, hash-pinned
      # EasyList/EasyPrivacy copies, so generate it explicitly.
      node adblock/seed.mjs --prepare

      # electron-builder renames the Electron binary and rewrites its fuse wire, so
      # it needs a writable copy: the store distribution is read-only.
      cp -r ${electron.dist} "$TMPDIR/electron-dist"
      chmod -R u+w "$TMPDIR/electron-dist"

      # Everything else the packer needs (tokens, settings schema, copy,
      # dark-reader preload, uBlock adaptation, compliance notices) is committed
      # and asserted by the beforePack/afterPack hooks, which `--dir` still runs.
      npm exec electron-builder -- \
        --dir \
        -c.electronDist="$TMPDIR/electron-dist" \
        -c.electronVersion=${electronVersion} \
        -c.npmRebuild=false

      runHook postBuild
    '';

    installPhase = ''
      runHook preInstall

      # A real packaged layout, not "electron <path>/app.asar": with
      # app.isPackaged false blanc falls back to dev behaviour (a `Blanc-Dev`
      # profile, the Polar sandbox API, no Bowser→Blanc profile migration), and
      # electron-builder also fuses the binary to load the app only from app.asar.
      # So install what the packer produced.
      mkdir -p $out/libexec/blanc
      cp -r dist/linux-unpacked/. $out/libexec/blanc/

      # Blanc refuses to start when Chromium sandboxing is off (it aborts before
      # any window exists), and a Nix store path can never carry the setuid bit
      # that `chrome-sandbox` wants. Naming it through CHROME_DEVEL_SANDBOX makes
      # Chromium take the unprivileged user-namespace sandbox instead of aborting
      # — the same thing the nixpkgs wrappers for electron and chromium do. A
      # setuid helper, if NixOS installs one (see the README), wins.
      makeWrapper $out/libexec/blanc/blanc $out/bin/blanc \
        --add-flags "\''${NIXOS_OZONE_WL:+\''${WAYLAND_DISPLAY:+--ozone-platform-hint=auto --enable-features=WaylandWindowDecorations --enable-wayland-ime=true}}" \
        --suffix PATH : ${lib.makeBinPath [xdg-utils]}${extraFlags} \
        --prefix LD_LIBRARY_PATH : ${lib.makeLibraryPath [libglvnd]}:${addDriverRunpath.driverLink}/lib \
        --prefix XDG_DATA_DIRS : ${addDriverRunpath.driverLink}/share \
        --set CHROME_DEVEL_SANDBOX $out/libexec/blanc/chrome-sandbox \
        --run 'if [ -x /run/wrappers/bin/blanc-sandbox ]; then export CHROME_DEVEL_SANDBOX=/run/wrappers/bin/blanc-sandbox; fi'

      install -Dm644 build/icon.png $out/share/icons/hicolor/1024x1024/apps/blanc.png

      runHook postInstall
    '';

    desktopItems = [
      (makeDesktopItem {
        name = "blanc";
        desktopName = "Blanc";
        comment = "Minimal Chromium-based browser with built-in ad/tracker blocking";
        exec = "blanc %U";
        icon = "blanc";
        categories = [
          "Network"
          "WebBrowser"
        ];
        mimeTypes = [
          "text/html"
          "application/xhtml+xml"
          "x-scheme-handler/http"
          "x-scheme-handler/https"
          "x-scheme-handler/blanc-import"
        ];
        # Matches the entry Blanc ships in its own AppImage.
        startupWMClass = "Blanc";
        terminal = false;
      })
    ];

    passthru = {
      inherit electron;
    };

    meta = {
      description = "Minimal Chromium-based (Electron) browser with built-in ad and tracker blocking";
      longDescription = ''
        Blanc is a browser built on Electron 44 (Chromium) with its own chrome UI,
        network-level ad/tracker blocking, a bundled uBlock Origin and Dark Reader,
        and no extension store.

        Built here from source rather than repackaged from the upstream AppImage,
        with the self-updater disabled since Nix owns updates. Tracks the main
        branch, so the version carries the commit it was built from.

        The application name, logo and icon artwork are not covered by the MIT code
        licence — see TRADEMARKS.md and ASSET-LICENSE.md upstream.
      '';
      homepage = "https://blancbrowser.com";
      downloadPage = "https://github.com/bnfy/blanc";
      changelog = "https://github.com/bnfy/blanc/commit/${finalAttrs.src.rev}";
      license = lib.licenses.mit;
      mainProgram = "blanc";
      platforms = ["x86_64-linux"];
    };
  })
