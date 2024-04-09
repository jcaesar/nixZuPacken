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
  web-ext,
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
    rustc.llvmPackages.lld
    cargo
    wasm-bindgen
    rustPlatform.cargoSetupHook
    web-ext
  ];

  postPatch = ''
    cp -ar ${./Cargo.lock} ./Cargo.lock
    rm -rf .cargo/config.toml
    runHook cargoSetupHook
  '';
  env.CARGO_TARGET_WASM32_UNKNOWN_UNKNOWN_LINKER = "lld";
  env.CARGO_TARGET_WASM32_UNKNOWN_UNKNOWN_RUSTFLAGS = "-Ctarget-feature=+atomics,+bulk-memory,+mutable-globals -Clink-arg=--max-memory=4294967296";
  
  buildPhase = ''
    cargo build --target wasm32-unknown-unknown --profile release
  	wasm-bindgen --target web --out-dir=pkg target/wasm32-unknown-unknown/release/${name}.wasm
    rm -rf target
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
