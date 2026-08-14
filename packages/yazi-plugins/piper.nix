{
  yaziPlugins,
  fetchFromGitHub,
  lib,
}: let
  src = fetchFromGitHub {
    owner = "alberti42";
    repo = "faster-piper.yazi";
    rev = "bb90261ce3952762b0de2d5720ea176615c1bbd9";
    hash = "sha256-a7/KTIoIU9idxhYmYFsp6/ezmiBK/mEYfEz9zqZZiEU=";
  };

  version = "unstable-${lib.substring 0 7 src.rev}";
in
  yaziPlugins.mkYaziPlugin {
    pname = "piper";
    inherit src version;

    meta = {
      description = "Pipe any shell command as a cached previewer";
      homepage = "https://github.com/alberti42/faster-piper.yazi";
      license = lib.licenses.mit;
    };
  }
