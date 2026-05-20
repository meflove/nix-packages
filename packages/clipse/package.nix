{
  lib,
  inputs,
  buildGoModule,
  stdenv,
  rev ? inputs.clipse.shortRev or inputs.clipse.dirtyShortRev or "dirty",
  enableWayland ? true,
  enableX11 ? false,
}: let
  inherit (inputs) clipse;

  rootGo = builtins.readFile "${clipse.outPath}/cmd/root.go";
  versionMatch = builtins.match ".*version[[:space:]]+=[[:space:]]+\"v([^\"]+)\".*" rootGo;
  version =
    if versionMatch == null
    then "unknown"
    else "${builtins.elemAt versionMatch 0}-${rev}";

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
      inherit version;

      src = lib.cleanSource clipse;

      vendorHash = "sha256-aMIea38qFsBeacjJ16woSt3FBLyZ3Dw4MlwuwT8J9TM=";

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
