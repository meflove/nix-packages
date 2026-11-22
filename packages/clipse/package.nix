{
  lib,
  fetchFromGitHub,
  buildGoModule,
  stdenv,
  enableWayland ? true,
  enableX11 ? false,
}: let
  src = fetchFromGitHub {
    owner = "savedra1";
    repo = "clipse";
    rev = "284d50f47ce708a0eb80247de9d84ec88d4c7a61";
    hash = "sha256-zPJfeFxh1jIp86qg4L1IrIsYXpuFtU4w+vK8xMAgZP4=";
  };

  rootGo = builtins.readFile "${src.outPath}/cmd/root.go";
  versionMatch = builtins.match ".*version[[:space:]]+=[[:space:]]+\"v([^\"]+)\".*" rootGo;
  version =
    if versionMatch == null
    then "unknown"
    else "${builtins.elemAt versionMatch 0}-${
      lib.substring 0 7 src.rev
    }";

  pname = "clipse";

  tags =
    if stdenv.hostPlatform.isDarwin
    then ["darwin"]
    else if enableWayland
    then ["wayland"]
    else if enableX11
    then ["linux"]
    else [];

  cgoEnabled = enableX11 || stdenv.hostPlatform.isDarwin;

  packageName =
    if enableX11
    then "${pname}-x11"
    else pname;
in
  assert lib.assertMsg (
    stdenv.hostPlatform.isLinux -> (lib.xor enableX11 enableWayland)
  ) "Exactly one of enableWayland, enableX11 must be true";
    buildGoModule {
      pname = packageName;
      inherit version src;

      goSum = "${src.outPath}/go.sum";
      vendorHash = "sha256-uJOgOfJcVHZ58xPjO92t9FD0QzDdd4loqNeqChnYywU=";

      inherit tags;

      env = {
        CGO_ENABLED =
          if cgoEnabled
          then "1"
          else "0";
      };

      meta = {
        description = "Useful clipboard manager TUI for Unix";
        homepage = "https://github.com/savedra1/clipse";
        license = lib.licenses.mit;
        mainProgram = "clipse";
        maintainers = [lib.maintainers.savedra1];
      };
    }
