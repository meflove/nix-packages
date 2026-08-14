{
  python314Packages,
  fetchFromGitHub,
  ani-cli-ru,
  lib,
}: let
  python = python314Packages;

  src = fetchFromGitHub {
    owner = "vypivshiy";
    repo = "ani-cli-ru";
    rev = "22714065418aed5a4c387d96aa6000dc977aa10e";
    hash = "sha256-6/Wkf64QP44NFYKzX0FX/Oz+0RcSSOBadwhfLI8S/Fc=";
  };

  pyproject = lib.importTOML "${src.outPath}/pyproject.toml";
  version = "${pyproject.project.version}-${lib.substring 0 7 src.rev}";
in
  python.buildPythonApplication (_old: {
    pname = "anicli_ru";
    inherit src version;

    pyproject = true;

    build-system = with python; [
      hatchling
    ];

    # base deps + [web] extra (fastapi, jinja2, uvicorn, python-multipart, segno)
    dependencies = with python; [
      ani-cli-ru.api
      ani-cli-ru.uvicorn
      fastapi
      jinja2
      prompt-toolkit
      python-multipart
      rich
      segno
      typer
    ];

    meta = {
      description = "Watch anime with ru sources via mpv";
      homepage = "https://github.com/vypivshiy/ani-cli-ru";
      license = lib.licenses.gpl3;
      mainProgram = "anicli-ru";
    };
  })
