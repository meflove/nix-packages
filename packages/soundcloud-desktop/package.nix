{
  lib,
  stdenv,
  rustPlatform,
  fetchFromGitHub,
  fetchPnpmDeps,
  makeDesktopItem,
  # nativeBuildInputs
  cargo-tauri,
  nodejs,
  pnpm_10,
  pnpmConfigHook,
  pkg-config,
  makeWrapper,
  autoconf,
  automake,
  libtool,
  wrapGAppsHook4,
  # buildInputs
  glib-networking,
  openssl,
  webkitgtk_4_1,
  alsa-lib,
  libopus,
  libayatana-appindicator,
  libappindicator-gtk3,
  libappindicator,
  pulseaudioFull,
}: let
  pname = "soundcloud-desktop";
  src = fetchFromGitHub {
    owner = "zxcloli666";
    repo = "SoundCloud-Desktop";
    rev = "5b4a7c2d4c5a71688e219f148b64907cb2a6e972";
    hash = "sha256-2ZQsTRXOU09nhWfLXxfaGF/fGUQIvgXGmmDFA8I1dmA=";
  };

  packageJson = builtins.fromJSON (builtins.readFile "${src.outPath}/desktop/package.json");
  version = "${packageJson.version}-${lib.substring 0 7 src.rev}";
in
  rustPlatform.buildRustPackage (finalAttrs: {
    inherit pname version src;

    cargoRoot = "desktop/src-tauri";
    cargoHash = "sha256-U2K+LOi6fhNujtOSjxxluCGRCCKsErtvt/NPROvPg30=";

    buildAndTestSubdir = finalAttrs.cargoRoot;

    doCheck = false;

    pnpmDeps = fetchPnpmDeps {
      inherit pname version src;
      pnpm = pnpm_10;
      fetcherVersion = 3;
      sourceRoot = "${src.name}/desktop";
      hash = "sha256-07AXmYnBMqHTCKfo6vMFl13LK1KTYl9XV2fEyKLZCE4=";
    };

    pnpmRoot = "desktop";

    nativeBuildInputs =
      [
        cargo-tauri.hook

        nodejs
        pnpmConfigHook
        pnpm_10

        pkg-config
        makeWrapper

        autoconf
        automake
        libtool
      ]
      ++ lib.optionals stdenv.hostPlatform.isLinux [wrapGAppsHook4];

    buildInputs = lib.optionals stdenv.hostPlatform.isLinux [
      glib-networking
      openssl
      webkitgtk_4_1
      alsa-lib
      libopus
      libayatana-appindicator
      libappindicator-gtk3
      libappindicator
    ];

    propagatedBuildInputs = lib.optionals stdenv.hostPlatform.isLinux [
      pulseaudioFull
    ];

    postPatch = ''
      if [ $cargoDepsCopy ]; then
        substituteInPlace $cargoDepsCopy/*/libappindicator-sys-*/src/lib.rs \
          --replace-fail "libayatana-appindicator3.so.1" "${lib.getLib libayatana-appindicator}/lib/libayatana-appindicator3.so.1"
      fi
    '';

    postInstall = ''
      wrapProgram $out/bin/soundcloud-desktop \
        --argv0 soundcloud-desktop \
        --prefix PATH : ${lib.makeBinPath [pulseaudioFull]} \
    '';

    desktopItems = [
      (makeDesktopItem {
        name = "SoundCloud Desktop";
        desktopName = "SoundCloud Desktop";
        exec = pname;
        icon = "io.github.zxcloli666.SoundcloudDesktop";
        terminal = false;
        type = "Application";
        categories = ["AudioVideo" "Music"];
        keywords = ["soundcloud" "music" "player"];
      })
    ];
    meta.mainProgram = pname;
  })
