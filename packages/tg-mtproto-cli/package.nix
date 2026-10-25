{
  lib,
  buildNpmPackage,
  fetchFromGitHub,
  nodejs_22,
}: let
  packageJson = lib.fromJSON (builtins.readFile "${src}/package.json");
  version = "${packageJson.version}-${lib.substring 0 7 src.rev}";

  src = fetchFromGitHub {
    owner = "cyberash-dev";
    repo = "tg-mtproto-cli";
    rev = "a3b181abf1b586c58e33b61f3d481d5bc3c7d0c3";
    hash = "sha256-eQVaibu8XpnKnq9jyy+wq+0+KDk4YLsSUkyk6tg3GdU=";
  };
in
  buildNpmPackage (_finalAttrs: {
    pname = "tg-mtproto-cli";
    inherit src version;

    npmDepsHash = "sha256-0YfBLrWlUER/aNVfKkj25IBlANrS7NsJYpamjZo0tas=";
    npmBuildScript = "build";

    nodejs = nodejs_22;

    postFixup = ''
      mv $out/bin/tg $out/bin/tg-mtproto
    '';

    meta = {
      description = "Read-only Telegram CLI over MTProto";
      homepage = "https://github.com/cyberash-dev/tg-mtproto-cli";
      license = lib.licenses.mit;
      mainProgram = "tg-mtproto";
    };
  })
