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
    rev = "b096a4a2ddce8b4c2723a4d7fd65bccfad6cc718";
    hash = "sha256-1KnahDsGCXU4xkMSx/Rg0mrYwF/5L0fOaqDM3l0aVwg=";
  };

  packageJson = builtins.fromJSON (builtins.readFile "${src.outPath}/desktop/package.json");
  version = "${packageJson.version}-${lib.substring 0 7 src.rev}";
in
  rustPlatform.buildRustPackage (finalAttrs: {
    inherit pname version src;

    cargoRoot = "desktop/src-tauri";
    cargoHash = "sha256-vJZS7YI4VyopyhuHnypIQz5DIk/zphE+uzuxI3ub8XA=";

    buildAndTestSubdir = finalAttrs.cargoRoot;

    doCheck = false;

    pnpmDeps = fetchPnpmDeps {
      inherit pname version src;
      pnpm = pnpm_10;
      fetcherVersion = 3;
      sourceRoot = "${src.name}/desktop";
      hash = "sha256-3wzUrB014w5CG2rZr/vmKbnBbkvFlClaZksfP0dIz0Q=";
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
