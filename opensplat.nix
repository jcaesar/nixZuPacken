let
  owner = "pierotofy";
  name = "opensplat";
  version = "1.1.2";
in
  {
    lib,
    stdenv,
    cmake,
    fetchFromGitHub,
    libtorch-bin,
    opencv,
    nlohmann_json,
    nanoflann,
    glm,
    cxxopts,
    config,
    # In theory, this also supports rocm/hip, but I've been unable to get that build to work
    useCuda ? config.cudaSupport,
    cudaPackages,
    cmakeFlags ? [], # There's some interesting flags like OPENSPLAT_BUILD_SIMPLE_TRAINER or OPENSPLAT_MAX_CUDA_COMPATIBILITY
  }:
    stdenv.mkDerivation {
      pname = name;
      version = version;

      src = fetchFromGitHub {
        owner = owner;
        repo = name;
        rev = "refs/tags/v${version}";
        hash = "sha256-3tk62b5fSf6wzuc5TwkdfAKgUMrw3ZxetCJa2RVMS/s=";
      };
      patches = [
        ./install-executables.patch
        ./unvendor-some.patch # the two vendored gsplats are so heavily modified they may be considered a fork
      ];
      prePatch = ''
        # unvendor only what is already packaged in nix. todo: package more
        rm -rf vendor/{glm,json,nanoflann,cxxopts.hpp}
      '';

      nativeBuildInputs =
        [cmake libtorch-bin opencv]
        ++ lib.optionals useCuda [
          cudaPackages.cuda_nvcc
        ];

      buildInputs =
        [
          nanoflann
          nlohmann_json
          glm
          cxxopts
        ]
        ++ lib.optionals useCuda [
          cudaPackages.cuda_cudart
        ];

      cmakeFlags =
        [
          "-DCMAKE_SKIP_RPATH=true"
        ]
        ++ lib.optionals useCuda [
          "-DGPU_RUNTIME=CUDA"
          "-DCUDA_TOOLKIT_ROOT_DIR=${cudaPackages.cudatoolkit}"
        ]
        ++ cmakeFlags;

      meta = {
        description = "Production-grade 3D gaussian splatting";
        homepage = "https://github.com/${owner}/${name}";
        license = lib.licenses.mit;
        platforms = lib.platforms.unix;
      };
    }
