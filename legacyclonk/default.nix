{
  stdenv,
  fetchurl,
  lib,
  writeScriptBin,
  callPackage,
  unzip,
  engine ? callPackage ./engine.nix {},
  extraAssets ? [],
}: let
  getAsset = name: data: let
    src = fetchurl {inherit (data) url hash;};
  in
    stdenv.mkDerivation {
      inherit src;
      name = "legacyclonk-asset-${name}";
      dontUnpack = true;
      nativeBuildInputs = [unzip];
      installPhase = ''
        mkdir $out
        ${data.script src}
      '';
      meta = {
        license = [lib.licenses.unfreeRedistributable];
        maintainers = [lib.maintainers.jcaesar];
        inherit (data) homepage;
      };
    };

  assets = lib.mapAttrs getAsset (import ./assets.nix);

  assetPaths =
    lib.concatStringsSep " "
    (map (path: "${path}/*")
      (lib.attrValues assets ++ extraAssets));

  # legacyclonk expects
  #  - game assets at the path where the executable is
  #  - to be able to write to the path where the executable is
  # patching around this gets pretty complicated,
  # so instead crate a directory that can be written to
  script = writeScriptBin "clonk" ''
    rm -rf ~/.legacyclonk/.nix
    mkdir -p ~/.legacyclonk/.nix

    cd ~/.legacyclonk/.nix
    mkdir Extra.c4g
    for f in ${assetPaths}; do
      if test "$(basename "$f")" == Extra.c4g; then
        for ff in "$f"/*; do
          ln -s "$ff" Extra.c4g/.
        done
      else
        ln -s "$f" .
      fi
    done
    for f in ${engine}/*; do
        ln -sf "$f" .
    done
    exec ./clonk "$@"
  '';
in
  script
  // {
    name = "legacyclonk";

    passthru = {
      inherit engine assets;
    };

    meta = {
      license = [lib.licenses.cc-by-nc-40 lib.licenses.isc lib.licenses.unfreeRedistributable];
      maintainers = [lib.maintainers.jcaesar];
      homepage = "https://clonkspot.org/lc-en";
      mainProgram = "clonk";
    };
  }
