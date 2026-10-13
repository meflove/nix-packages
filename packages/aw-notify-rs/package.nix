{
  lib,
  fetchFromGitHub,
  rustPlatform,
  # buildDeps
  pkg-config,
  # deps
  openssl,
}: let
  src = fetchFromGitHub {
    owner = "ActivityWatch";
    repo = "aw-notify-rs";
    rev = "8c5c1b11751da21be2433c77f195fa425bebc00a";
    hash = "sha256-dhnTuvusPzXOKbsxPnTEeyvXQeOQ6m0qAbMV0C+JcWk=";
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
    cargoHash = "sha256-yAio+ZuoaNvfbZf+VjOrlV/MfLHGlOlCtaUNlSFciOU=";

    meta = {
      description = "Desktop notifications for ActivityWatch time-tracking data";
      homepage = "https://github.com/ActivityWatch/aw-notify-rs";
      license = lib.licenses.mpl20;
      mainProgram = "aw-notify";
      platforms = lib.platforms.linux;
    };
  })
