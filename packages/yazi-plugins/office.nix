{
  yaziPlugins,
  fetchFromGitHub,
  lib,
}: let
  src = fetchFromGitHub {
    owner = "cwelsys";
    repo = "office.yazi";
    rev = "a5db2324cfd09e4ad48a4ac9ee5ea263557f84d6";
    hash = "sha256-x8DXFLS+G6BLQRDJW6pfUCVb81b1IX6LNNii2B8V4bM=";
  };

  version = "unstable-${lib.substring 0 7 src.rev}";
in
  yaziPlugins.mkYaziPlugin {
    pname = "office.yazi";
    inherit src version;

    meta = {
      description = "Documents previewer plugin, using libreoffice";
      homepage = "https://github.com/cwelsys/office.yazi";
      license = lib.licenses.mit;
    };
  }
