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
    python3,
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
        [cmake]
        ++ lib.optionals useCuda [
          cudaPackages.cuda_nvcc
        ];

      buildInputs =
        [
          (python3.pkgs.torch.override { cudaSupport = useCuda; })
          opencv
          nanoflann
          nlohmann_json
          glm
          cxxopts
        ]
        ++ lib.optionals useCuda [
          cudaPackages.cuda_cudart
        ];
      env.VERBOSE = "1";

      cmakeFlags =
        [
          "-DCMAKE_SKIP_RPATH=true"
        ]
        ++ lib.optionals useCuda [
          "-DGPU_RUNTIME=CUDA"
          "-DCUDA_TOOLKIT_ROOT_DIR=${cudaPackages.cudatoolkit}"
          # To avoid: forward.cu(411): error: calling a constexpr __host__ function("min") from a __device__ function("project_cov3d_ewa") is not allowed. The experimental flag '--expt-relaxed-constexpr' can be used to allow this.
          "-DCMAKE_CUDA_FLAGS=--expt-relaxed-constexpr"
          # To avoid: /nix/store/imajhva2ms4zci9gr2znhij3bdbwdm3i-libtorch-2.0.0-dev/include/c10/cuda/CUDAMacros.h:8:10: fatal error: c10/cuda/impl/cuda_cmake_macros.h: No such file or directory
          "-DCMAKE_CXX_FLAGS=-DC10_CUDA_NO_CMAKE_CONFIGURE_FILE"
        ]
        ++ cmakeFlags;

      meta = {
        description = "Production-grade 3D gaussian splatting";
        homepage = "https://github.com/${owner}/${name}";
        license = lib.licenses.mit;
        platforms = lib.platforms.unix;
      };
    }
