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
  cmake,
  git,
  autoconf,
  automake,
  libtool,
  wrapGAppsHook4,
  # buildInputs
  glib-networking,
  openssl,
  sqlite,
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
    rev = "8eaed08b4777c6cae4f151b8900f59376bb10ac2";
    hash = "sha256-Bl27uzsj4ZLy6ST9TFr/cHJw2vuDNh+JrGls+L/AG3g=";
  };

  packageJson = builtins.fromJSON (builtins.readFile "${src.outPath}/desktop/package.json");
  version = "${packageJson.version}-${lib.substring 0 7 src.rev}";
in
  rustPlatform.buildRustPackage (finalAttrs: {
    inherit pname version src;

    cargoRoot = "desktop/src-tauri";
    cargoHash = "sha256-KLko42Gl5YeClsipO92ZqmxsdFPcayNaMLzxzaDv+HY=";

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
        rustPlatform.bindgenHook

        nodejs
        pnpmConfigHook
        pnpm_10

        pkg-config
        makeWrapper

        cmake
        git

        autoconf
        automake
        libtool
      ]
      ++ lib.optionals stdenv.hostPlatform.isLinux [wrapGAppsHook4];

    buildInputs = lib.optionals stdenv.hostPlatform.isLinux [
      glib-networking
      openssl
      sqlite
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
