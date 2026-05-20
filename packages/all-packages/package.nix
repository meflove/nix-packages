{
  inputs,
  lib,
  symlinkJoin,
}:
symlinkJoin {
  name = "all-packages";
  paths = lib.attrValues (
    lib.filterAttrs (_name: lib.isDerivation) (
      lib.removeAttrs inputs.self.legacyPackages.x86_64-linux ["all-packages"]
    )
  );

  meta = {
    description = "just meta package to build all packages at once";
  };
}
