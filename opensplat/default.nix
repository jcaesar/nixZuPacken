let
  owner = "pierotofy";
  name = "opensplat";
  version = "1.1.2";
in
  {
    lib,
    gcc12Stdenv,
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
    autoAddDriverRunpath,
    cmakeFlags ? [], # There's some interesting flags like OPENSPLAT_BUILD_SIMPLE_TRAINER or OPENSPLAT_MAX_CUDA_COMPATIBILITY
  }: let
    torch = python3.pkgs.torch.override {cudaSupport = useCuda;};
  in
    # Using a normal stdenv gives
    # ld: /nix/store/k1l7y96gv0nc685cg7i3g43i4icmddzk-python3.11-torch-2.2.1-lib/lib/libc10.so: undefined reference to `std::ios_base_library_init()@GLIBCXX_3.4.32'
    # Apparently, nvcc/cudatoolkit bring their own gcc. Look for CMAKE_CUDA_HOST_COMPILER in the --keep-failed folder if you see a similar linking failure
    gcc12Stdenv.mkDerivation {
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
          autoAddDriverRunpath
        ];

      buildInputs =
        [
          torch.cxxdev
          torch
          opencv
          nanoflann
          nlohmann_json
          glm
          cxxopts
        ]
        ++ lib.optionals useCuda [
          cudaPackages.cuda_cudart
        ];
      env.TORCH_CUDA_ARCH_LIST = "${lib.concatStringsSep ";" python3.pkgs.torch.cudaCapabilities}";

      cmakeFlags =
        [
          "-DCMAKE_SKIP_RPATH=true"
        ]
        ++ lib.optionals useCuda [
          "-DGPU_RUNTIME=CUDA"
          "-DCUDA_TOOLKIT_ROOT_DIR=${cudaPackages.cudatoolkit}"
          # To avoid: forward.cu(411): error: calling a constexpr __host__ function("min") from a __device__ function("project_cov3d_ewa") is not allowed. The experimental flag '--expt-relaxed-constexpr' can be used to allow this.
          "-DCMAKE_CUDA_FLAGS=--expt-relaxed-constexpr"
        ]
        ++ cmakeFlags;

      meta = {
        description = "Production-grade 3D gaussian splatting";
        homepage = "https://github.com/${owner}/${name}";
        license = lib.licenses.mit;
        platforms = lib.platforms.unix;
      };
    }
