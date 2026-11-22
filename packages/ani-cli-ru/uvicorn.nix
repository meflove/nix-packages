{
  python314Packages,
  fetchFromGitHub,
  lib,
}: let
  python = python314Packages;

  src = fetchFromGitHub {
    owner = "Kludex";
    repo = "uvicorn";
    rev = "1b16995ffef17e7914a261f3ed69f8b9e7c57269";
    hash = "sha256-3dRnIQ/XdFC50TUQSWkNJOkDzYeFPZGdOM093wBB4cg=";
  };

  # uvicorn's version is dynamic in pyproject (tool.hatch.version.path)
  initPy = builtins.readFile "${src.outPath}/uvicorn/__init__.py";
  versionMatch = builtins.match ".*__version__[[:space:]]*=[[:space:]]*\"([^\"]+)\".*" initPy;
  version = "${builtins.elemAt versionMatch 0}-${lib.substring 0 7 src.rev}";
in
  python.buildPythonApplication (_old: {
    pname = "uvicorn";
    inherit src version;

    pyproject = true;

    build-system = with python; [
      hatchling
    ];

    dependencies = with python; [
      click
      h11
      typing-extensions
    ];

    meta = {
      description = "ASGI web server implementation for Python";
      homepage = "https://github.com/Kludex/uvicorn";
      license = lib.licenses.bsd3ClauseTso;
      mainProgram = "uvicorn";
    };
  })
