{
  python314Packages,
  fetchFromGitHub,
  lib,
}: let
  python = python314Packages;

  src = fetchFromGitHub {
    owner = "vypivshiy";
    repo = "anicli-api";
    rev = "ab79153c504dd1e6877749d64c978c362a2936a2";
    hash = "sha256-F6y/PzE2ZA8mLbiYk9sMyYocq1uzj6z2o8tad+ErUuo=";
  };

  pyproject = lib.importTOML "${src.outPath}/pyproject.toml";
  version = "${pyproject.project.version}-${lib.substring 0 7 src.rev}";
in
  python.buildPythonApplication (_old: {
    pname = "anicli_api";
    inherit src version;

    pyproject = true;

    build-system = with python; [
      hatchling
    ];

    # httpx[brotli,http2,socks] + attrs, cssselect, lxml from pyproject
    dependencies = with python; [
      attrs
      brotli
      cssselect
      h2
      httpx
      lxml
      socksio
    ];

    meta = {
      description = "Parse anime from RU websites";
      homepage = "https://github.com/vypivshiy/anicli-api";
      license = lib.licenses.mit;
    };
  })
