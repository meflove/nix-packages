{
  python314Packages,
  fetchFromGitHub,
  lib,
}: let
  python = python314Packages;

  src = fetchFromGitHub {
    owner = "Kludex";
    repo = "uvicorn";
    rev = "21f39ef7988366f77fb3172569bd235ac5de34cc";
    hash = "sha256-lKbeA+f3VYcl1RxOocW5C0RM1nYXtpPBg7XWwZtd+uU=";
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
