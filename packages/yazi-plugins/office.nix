{
  yaziPlugins,
  fetchFromGitHub,
  lib,
}: let
  src = fetchFromGitHub {
    owner = "cwelsys";
    repo = "office.yazi";
    rev = "6c26ad951761aaf0012c3d62c7abf5f006ba17db";
    hash = "sha256-QJpaI7v0XMDXCIe6SmG72EfaGFT/GqQlezBweK9OURY=";
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
