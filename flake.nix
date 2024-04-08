{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };
  outputs = {
    self,
    nixpkgs,
    flake-utils,
  }:
    flake-utils.lib.eachDefaultSystem
    (
      system: let
        pkgs = import nixpkgs {
          inherit system;
          config.allowUnfree = true;
        };
        callPackage = pkgs.lib.callPackageWith packages;
        packages =
          pkgs
          // {
            gsplat = callPackage ./gsplat.nix {};
            opensplat = callPackage ./opensplat.nix {};
            opensplatWithCuda = packages.opensplat.override {gpuBackend = "CUDA";};
            opensplatWithRocm = packages.opensplat.override {gpuBackend = "HIP";};
            default = packages.opensplat;
          };
      in rec {
        inherit packages;
        devShells.cuda = pkgs.mkShell {
          inputsFrom = [packages.opensplatWithCuda];
        };
        devShells.hip = pkgs.mkShell {
          inputsFrom = [packages.opensplatWithRocm];
        };
        devShells.default = pkgs.mkShell {
          inputsFrom = [packages.opensplat];
        };
      }
    );
}
