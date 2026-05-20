{
  inputs,
  lib,
  stdenv,
}:
stdenv.mkDerivation (_finalAttrs: {
  pname = "all-packages";
  version = "0.0.0";

  buildInputs = lib.attrValues (
    lib.filterAttrs (_name: lib.isDerivation) (
      lib.removeAttrs inputs.self.legacyPackages.x86_64-linux ["all-packages"]
    )
  );

  meta = {
    description = "just meta package to build all packages at once";
  };
})
