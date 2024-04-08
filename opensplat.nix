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
  gpuBackend ? (
    if config.cudaSupport
    then "CUDA"
    else if config.rocmSupport
    then "HIP"
    else null
  ),
  cudaPackages,
  rocmPackages,
  cmakeFlags ? [], # There's some interesting flags like OPENSPLAT_BUILD_SIMPLE_TRAINER or OPENSPLAT_MAX_CUDA_COMPATIBILITY
}: let
  owner = "pierotofy";
  name = "opensplat";
  version = "1.1.2";

  validAccel = lib.assertOneOf "opensplat.gpuBackend" gpuBackend [null "CUDA" "HIP"];
  useCuda = validAccel && gpuBackend == "CUDA";
  useHip = validAccel && gpuBackend == "HIP";
in
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
      ./unvendor-some.patch
    ];
    prePatch = ''
      # unvendor only what is already packaged in nix. todo: package more
      rm -rf vendor/{glm,json,nanoflann,cxxopts.hpp}
    '';

    nativeBuildInputs =
      [cmake libtorch-bin opencv]
      ++ lib.optionals useCuda [
        cudaPackages.cuda_nvcc
      ]
      ++ lib.optionals useHip [
        rocmPackages.hipcc
        rocmPackages.hip-common
        rocmPackages.rocminfo
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
      ]
      ++ lib.optionals useHip [
        rocmPackages.rocm-core
      ];

    cmakeFlags =
      [
        "-DCMAKE_SKIP_RPATH=true"
      ]
      ++ lib.optionals useCuda [
        "-DGPU_RUNTIME=CUDA"
        "-DCUDA_TOOLKIT_ROOT_DIR=${cudaPackages.cudatoolkit}"
      ]
      ++ lib.optionals useHip [
        "-DGPU_RUNTIME=HIP"
        "-DHIP_PATH=${rocmPackages.clr}"
        "-DCMAKE_MODULE_PATH=${rocmPackages.clr}/lib/cmake/hip"
        "-DCMAKE_HIP_PLATFORM=amd"
        "-DCMAKE_HIP_COMPILER_ROCM_ROOT=${rocmPackages.clr}"
        "-DCMAKE_HIP_COMPILER=${rocmPackages.clr}/bin/hipcc"
        "-DCMAKE_HIP_ARCHITECTURES=gfx000" # TODO: this should be autodetected from rocminfo / rocm_agent_enumerator
      ]
      ++ cmakeFlags;

    meta = {
      description = "Production-grade 3D gaussian splatting";
      homepage = "https://github.com/${owner}/${name}";
      license = lib.licenses.mit;
      platforms = lib.platforms.unix;
    };
  }
