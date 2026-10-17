{
  lib,
  fetchFromGitHub,
  # deps
  openssl,
  # buildDeps
  pkg-config,
  rustPlatform,
}: let
  src = fetchFromGitHub {
    owner = "ActivityWatch";
    repo = "aw-notify-rs";
    rev = "87e83cca65276b2278e4361db74087764c3ecf2c";
    hash = "sha256-NAWAvRNRV4zFQ15nuguwP4GdSFCglMybca7DTVLONlI=";
  };

  cargoToml = lib.importTOML "${src.outPath}/Cargo.toml";
  version = "${cargoToml.package.version}-${lib.substring 0 7 src.rev}";
in
  rustPlatform.buildRustPackage (_finalAttrs: {
    pname = "aw-notify-rs";

    inherit src version;

    strictDeps = true;

    nativeBuildInputs = [pkg-config];
    # aw-client-rust pulls reqwest with the default native-tls backend.
    buildInputs = [openssl];

    # The client and model crates are consumed from a git branch, so the
    # registry-only `cargoLock` path cannot be used; the vendored-deps hash
    # covers them (fetchCargoVendor vendors git sources from Cargo.lock).
    cargoHash = "sha256-Mep7ppAQ/nCwHKSsokjY7HKFwDtakmqK8oFoM6HtTT0=";

    doCheck = false;

    meta = {
      description = "Desktop notifications for ActivityWatch time-tracking data";
      homepage = "https://github.com/ActivityWatch/aw-notify-rs";
      license = lib.licenses.mpl20;
      mainProgram = "aw-notify";
      platforms = lib.platforms.linux;
    };
  })
