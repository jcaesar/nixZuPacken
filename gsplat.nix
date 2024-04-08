# abandonned
{
  stdenv,
  cmake,
  fetchFromGitHub,
  glm,
  config,
  cudaPackages,
}: let
  owner = "nerfstudio-project";
  name = "gsplat";
  version = "0.1.10";
in
  stdenv.mkDerivation {
    pname = name;
    version = version;

    src =
      fetchFromGitHub {
        owner = owner;
        repo = name;
        rev = "refs/tags/v${version}";
        hash = "sha256-3tk62b5fSf6wzuc5TwkdfAKgUMrw3ZxetCJa2RVMS/s=";
      }
      + ./gsplat/cuda/csrc;

    nativeBuildInputs = [cmake];
    buildInputs = [glm cudaPackages.cuda_cudart];
  }
