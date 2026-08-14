{
  yaziPlugins,
  fetchFromGitHub,
  lib,
}: let
  src = fetchFromGitHub {
    owner = "kirasok";
    repo = "torrent-preview.yazi";
    rev = "d745df633a4a52f9621eeab46e74a54e8c056a56";
    hash = "sha256-nC8mIGB4wQftDMRXKprvF4SThNdvueCLQ8REiPs8HUY=";
  };

  version = "unstable-${lib.substring 0 7 src.rev}";
in
  yaziPlugins.mkYaziPlugin {
    pname = "torrent-preview";
    inherit src version;

    meta = {
      description = "Yazi plugin to preview bittorrent files";
      homepage = "https://github.com/kirasok/torrent-preview.yazi";
      license = lib.licenses.agpl3Only;
    };
  }
