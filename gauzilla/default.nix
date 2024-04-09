let
  owner = "BladeTransformerLLC";
  name = "gauzilla";
in
  {
    lib,
    wasm-bindgen-cli,
    rustc,
    rustPlatform,
    stdenv,
    cargo,
    wasm-pack,
    fetchFromGitHub,
  }:
    stdenv.mkDerivation {
      pname = name;
      version = "2024-04-09";

      src = fetchFromGitHub {
        owner = owner;
        repo = name;
        rev = "1164218b8f2133f2d892d390ab4e7508d81a0c8c";
        hash = "sha256-K6zoq0EAT+9SjfrSznLjDara76ND4+COSD8mYigLZRk=";
      };
      cargoDeps = rustPlatform.importCargoLock {
        lockFile = ./Cargo.lock;
      };

      nativeBuildInputs = let
        wasm-bindgen = wasm-bindgen-cli.override {
          version = "0.2.91";
          hash = "sha256-f/RK6s12ItqKJWJlA2WtOXtwX4Y0qa8bq/JHlLTAS3c=";
          cargoHash = "sha256-3vxVI0BhNz/9m59b+P2YEIrwGwlp7K3pyPKt4VqQuHE=";
        };
      in [
        rustc # so wasm-pack can figure out the rust version
        rustc.llvmPackages.lld
        cargo
        wasm-bindgen
        wasm-pack
        rustPlatform.cargoSetupHook
      ];

      postPatch = ''
        cp -ar ${./Cargo.lock} ./Cargo.lock
        rm -rf .cargo/config.toml
        runHook cargoSetupHook
      '';
      env.CARGO_TARGET_WASM32_UNKNOWN_UNKNOWN_LINKER = "lld";
      env.CARGO_TARGET_WASM32_UNKNOWN_UNKNOWN_RUSTFLAGS = ''
        -Ctarget-feature=+atomics,+bulk-memory,+mutable-globals
        -Clink-arg=--max-memory=4294967296
      '';
      env.WASM_PACK_CACHE = "/build/.wasm-pack-cache";

      buildPhase = ''
        sh ./build.sh
      '';
      checkPhase = '''';
      installPhase = ''
        mkdir -p $out
        cp -art $out pkg *.html *.js
      '';

      meta = with lib; {
        description = "a 3D Gaussian Splatting renderer written in Rust for WebAssembly with lock-free multithreading";
        license = licenses.mit;
        platforms = platforms.linux;
        homepage = "https://github.com/${owner}/${name}";
      };
    }
