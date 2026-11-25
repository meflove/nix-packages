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
    rev = "ba31a7da6a5973fc252d4fcf9acf368d64aeae8f";
    hash = "sha256-0p1d6QJ71rmwzkzpf6argoPpNDFh7y1QAwbG9wvm0v8=";
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
    cargoHash = "sha256-3HgzU+dEEN/bWF2qfQe8DuXSHX/dSPmlvMRxFDoumRg=";

    doCheck = false;

    meta = {
      description = "Desktop notifications for ActivityWatch time-tracking data";
      homepage = "https://github.com/ActivityWatch/aw-notify-rs";
      license = lib.licenses.mpl20;
      mainProgram = "aw-notify";
      platforms = lib.platforms.linux;
    };
  })
