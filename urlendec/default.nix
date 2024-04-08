let
  owner = "arcaartem";
  repo = "urlendec";
  version = "0.1.1";
in
  {
    rustPlatform,
    fetchFromGitHub,
    lib,
  }:
    rustPlatform.buildRustPackage rec {
      inherit version;
      pname = repo;

      src = fetchFromGitHub {
        inherit owner repo;
        rev = "v${version}";
        hash = "sha256-aONZ3fsTYglPsdHuPaPCR8NzMOWbxZi7F9RPSB7P8QI=";
      };
      cargoLock.lockFile = "${src}/Cargo.lock";

      meta = with lib; {
        description = "A simple command-line application to URL encode/decode strings or files";
        license = licenses.mit;
        platforms = platforms.linux;
        homepage = "https://github.com/${repo}/${owner}";
      };
    }
