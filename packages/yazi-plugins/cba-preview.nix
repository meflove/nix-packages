{
  yaziPlugins,
  fetchFromGitHub,
  lib,
}: let
  src = fetchFromGitHub {
    owner = "navysky12";
    repo = "comicthumb.yazi";
    rev = "fa398e831cab751223084a8dbaac21901b7c165f";
    hash = "sha256-FFPWdQxpyMyvIBJ8nR4v8EP56LDlatzxySCUwVwvGx8=";
  };

  version = "unstable-${lib.substring 0 7 src.rev}";
in
  yaziPlugins.mkYaziPlugin {
    pname = "cba-preview";
    inherit src version;

    meta = {
      description = "Yazi plugin to preview Comic Book Archive";
      homepage = "https://github.com/navysky12/comicthumb.yazi";
      license = lib.licenses.mit;
    };
  }
