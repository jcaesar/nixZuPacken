let
  name = "licensed";
in
  {
    lib,
    bundlerApp,
    bundlerUpdateScript,
  }:
    bundlerApp {
      pname = name;
      gemdir = ./.;
      exes = [name];

      passthru.updateScript = bundlerUpdateScript name;

      meta = {
        description = "A Ruby gem to cache and verify the licenses of dependencies ";
        homepage = "https://github.com/github/${name}";
        license = lib.licenses.mit;
        platforms = lib.platforms.unix;
      };
    }
