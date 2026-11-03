{
  lib,
  fetchFromGitHub,
  librepods,
  qt6Packages,
  ...
}: let
  src = fetchFromGitHub {
    owner = "harveywuk";
    repo = "librepods";
    rev = "4ed49df0b301ac3e6fba9c81dfbbb6726cc52201";
    hash = "sha256-Ygoqz5lnGMwZkys+Q4c4pyAUI0llvpGZ/ij5E91CkAg=";
  };
  version = "${librepods.version}-${lib.substring 0 7 src.rev}";
in
  librepods.overrideAttrs (old: {
    inherit src version;
    buildInputs = old.buildInputs ++ [qt6Packages.qtstyleplugin-kvantum];
    sourceRoot = "source";
  })
