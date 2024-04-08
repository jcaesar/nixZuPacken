let
  owner = "pierotofy";
  repo = "OpenSplat";
  version = "1.1.2";
in
  {
    lib,
    stdenv,
    cmake,
    fetchFromGitHub,
    libtorch-bin,
    opencv,
    config,
    cudaSupport ? config.cudaSupport,
    cudaPackages,
    cmakeFlags ? [], # There's some interesting flags like OPENSPLAT_BUILD_SIMPLE_TRAINER or OPENSPLAT_MAX_CUDA_COMPATIBILITY
  }:
    stdenv.mkDerivation {
      inherit version;
      pname = "opensplat";

      src = fetchFromGitHub {
        inherit owner repo;
        rev = "refs/tags/v${version}";
        hash = "sha256-3tk62b5fSf6wzuc5TwkdfAKgUMrw3ZxetCJa2RVMS/s=";
      };
      patches = [ ./install-executables.patch ];

      nativeBuildInputs =
        [cmake libtorch-bin opencv]
        ++ lib.optionals cudaSupport [
          cudaPackages.autoAddDriverRunpathHook
          cudaPackages.cuda_nvcc
        ];

      buildInputs = lib.optionals cudaSupport [
        cudaPackages.cuda_cudart
      ];

      cmakeFlags = cmakeFlags ++ [ "-DCMAKE_SKIP_RPATH=true" ];

      meta = {
        description = "Production-grade 3D gaussian splatting";
        homepage = "https://github.com/${owner}/${repo}";
        license = lib.licenses.mit;
        platforms = lib.platforms.unix;
      };
    }
