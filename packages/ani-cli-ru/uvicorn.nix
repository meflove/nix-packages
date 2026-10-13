{
  python314Packages,
  fetchFromGitHub,
  lib,
}: let
  python = python314Packages;

  src = fetchFromGitHub {
    owner = "Kludex";
    repo = "uvicorn";
    rev = "07bd5d4c94c093960de94d1c96000fb0fa029f13";
    hash = "sha256-d/MSAeeL9vesOxgfQ51M54K7I9rK3YjmqaRlk12umO8=";
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
