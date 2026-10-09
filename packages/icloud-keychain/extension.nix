{
  lib,
  fetchFromGitHub,
  imagemagick,
  jq,
  stdenv,
  zip,
}: let
  src = fetchFromGitHub {
    owner = "Sank6";
    repo = "iCloud-Keychain-for-Linux";
    rev = "d098a7af024345f59ede47f2298e3113fd2b821b";
    hash = "sha256-wtlnAzy/eUOgb1AZXgTfvemdllNFlo9cqQS+2fyOVmY=";
  };

  manifest = lib.importJSON "${src.outPath}/extension/manifest.json";
  version = "${manifest.version}-${lib.substring 0 7 src.rev}";

  # Firefox toolkit app GUID + the extension's fixed gecko id, matching the
  # layout that Home Manager's profiles.<name>.extensions expects (same shape
  # as packages built by buildFirefoxXpiAddon).
  firefoxAppId = "ec8030f7-c20a-464f-9b0e-13a3a9e97384";
  addonId = "icp-linux@local";

  # Upstream ships no icon (the manifest has no `icons`), so browsers show a
  # placeholder. Resized at build time from the PNG master; Firefox-family
  # extension icons must be PNG or SVG.
  icons = {
    "48" = "icons/48.png";
    "96" = "icons/96.png";
    "128" = "icons/128.png";
  };
in
  stdenv.mkDerivation {
    pname = "icp-extension";
    inherit src version;

    sourceRoot = "source/extension";
    nativeBuildInputs = [imagemagick jq zip];

    buildPhase = ''
      runHook preBuild
      mkdir icons
      for size in 48 96 128; do
        magick ${./icloud_keychain.png} -resize "''${size}x''${size}" "icons/$size.png"
      done
      jq '.icons = $icons | .action.default_icon = $icons' \
        --argjson icons '${builtins.toJSON icons}' \
        manifest.json > manifest.json.new
      mv manifest.json.new manifest.json
      # manifest.json must sit at the root of the archive; build it outside
      # the tree so the unpacked copy below does not contain the xpi itself.
      zip -r -X -q "$NIX_BUILD_TOP/icp.xpi" .
      runHook postBuild
    '';

    installPhase = ''
      runHook preInstall
      install -Dm644 "$NIX_BUILD_TOP/icp.xpi" "$out/share/mozilla/extensions/{${firefoxAppId}}/${addonId}.xpi"
      # The unpacked tree (icon included) for the CLI package's share/ and
      # for Chromium-family "Load unpacked".
      mkdir -p "$out/share/icloud-keychain/extension"
      cp -r . "$out/share/icloud-keychain/extension/"
      runHook postInstall
    '';

    passthru = {inherit addonId;};

    meta = {
      description = "Apple Passwords browser extension (iCloud Keychain autofill for Linux) — unsigned, MV3";
      homepage = "https://github.com/Sank6/iCloud-Keychain-for-Linux";
      license = lib.licenses.mit;
    };
  }
