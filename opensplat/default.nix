let
  owner = "pierotofy";
  name = "opensplat";
  version = "1.1.2";
in
  {
    lib,
    gcc12Stdenv,
    stdenv,
    cmake,
    ninja,
    fetchFromGitHub,
    python3,
    opencv,
    nlohmann_json,
    nanoflann,
    glm,
    cxxopts,
    config,
    # Upstream has rocm/hip support, too. anyone?
    cudaSupport ? config.cudaSupport,
    cudaPackages,
    autoAddDriverRunpath,
    cmakeFlags ? [], # There's some interesting flags like OPENSPLAT_BUILD_SIMPLE_TRAINER or OPENSPLAT_MAX_CUDA_COMPATIBILITY
  }: let
    torch = python3.pkgs.torch.override {inherit cudaSupport;};
    # Using a normal stdenv with cuda torch gives
    # ld: /nix/store/k1l7y96gv0nc685cg7i3g43i4icmddzk-python3.11-torch-2.2.1-lib/lib/libc10.so: undefined reference to `std::ios_base_library_init()@GLIBCXX_3.4.32'
    mkDerivation =
      (
        if cudaSupport
        then gcc12Stdenv
        else stdenv
      )
      .mkDerivation;
  in
    mkDerivation {
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
      ];
      postPatch = ''
        # the two vendored gsplats are so heavily modified they may be considered a fork
        find vendor ! -name 'gsplat*' -maxdepth 1 -mindepth 1 -exec rm -rf {} +
        mkdir vendor/{nanoflann,glm}
        ln -s ${glm}/include/glm vendor/glm/glm
        ln -s ${nanoflann}/include/nanoflann.hpp vendor/nanoflann/nanoflann.hpp
        ln -s ${nlohmann_json}/include/nlohmann vendor/json
        ln -s ${cxxopts}/include/cxxopts.hpp vendor/cxxopts.hpp
      '';

      nativeBuildInputs =
        [cmake ninja]
        ++ lib.optionals cudaSupport [
          cudaPackages.cuda_nvcc
          autoAddDriverRunpath
        ];
      buildInputs =
        [
          nlohmann_json
          torch.cxxdev
          torch
          opencv
        ]
        ++ lib.optionals cudaSupport [cudaPackages.cuda_cudart];
      env.TORCH_CUDA_ARCH_LIST = "${lib.concatStringsSep ";" python3.pkgs.torch.cudaCapabilities}";
      cmakeFlags =
        ["-DCMAKE_SKIP_RPATH=true"]
        ++ lib.optionals cudaSupport [
          "-DGPU_RUNTIME=CUDA"
          "-DCUDA_TOOLKIT_ROOT_DIR=${cudaPackages.cudatoolkit}"
        ]
        ++ cmakeFlags;

      meta = {
        description = "Production-grade 3D gaussian splatting";
        homepage = "https://github.com/${owner}/${name}";
        license = lib.licenses.mit;
        platforms = lib.platforms.linux ++ lib.optionals (!cudaSupport) lib.platforms.darwin;
        maintainers = [lib.maintainers.jcaesar];
      };
    }
