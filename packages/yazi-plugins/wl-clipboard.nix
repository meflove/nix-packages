{
  yaziPlugins,
  fetchFromGitHub,
  lib,
}: let
  src = fetchFromGitHub {
    owner = "alterkeyy";
    repo = "wl-clipboard.yazi";
    rev = "a22bb04181c4e391a9f474dbba4a866888c73974";
    hash = "sha256-v7SDA85NAQ6jhB6CELrlXyzi4X+zMgBSdu+Zb7s4DCI=";
  };

  version = "unstable-${lib.substring 0 7 src.rev}";
in
  yaziPlugins.mkYaziPlugin {
    pname = "wl-clipboard.yazi";
    inherit src version;

    meta = {
      description = "Simple system clipboard for yazi";
      homepage = "https://github.com/alterkeyy/wl-clipboard.yazi";
      license = lib.licenses.mit;
    };
  }
