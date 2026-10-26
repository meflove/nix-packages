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
    rev = "dabea8a31b370abc1dea6b46ca2f2355e9ccde38";
    hash = "sha256-Q+MTI31EFGTnA4D2HDgTXMvVovrXQmz+PDU/2N83hyA=";
  };

  packageJson = builtins.fromJSON (builtins.readFile "${src.outPath}/desktop/package.json");
  version = "${packageJson.version}-${lib.substring 0 7 src.rev}";
in
  rustPlatform.buildRustPackage (finalAttrs: {
    inherit pname version src;

    cargoRoot = "desktop/src-tauri";
    cargoHash = "sha256-pIgqgAP+Z8x+gc2jMpda1XEt9YdK8mHG37w46Y87Uf4=";

    buildAndTestSubdir = finalAttrs.cargoRoot;

    doCheck = false;

    pnpmDeps = fetchPnpmDeps {
      inherit pname version src;
      pnpm = pnpm_10;
      fetcherVersion = 3;
      sourceRoot = "${src.name}/desktop";
      hash = "sha256-+kMpuXlt3bHSkgrBX1pzIgtMY8O5PKkUW4zO3P53/jA=";
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
