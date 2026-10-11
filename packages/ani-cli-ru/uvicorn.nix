{
  python314Packages,
  fetchFromGitHub,
  lib,
}: let
  python = python314Packages;

  src = fetchFromGitHub {
    owner = "Kludex";
    repo = "uvicorn";
    rev = "31e3e00f7cd78e4381268ed6b06e8506d2a641fb";
    hash = "sha256-xXSMZ1Xyxxrw2SWJG3XeeSzBzPUBVKrYM6JwRzK0ypM=";
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
