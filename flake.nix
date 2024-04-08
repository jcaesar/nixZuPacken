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
      in rec {
        packages = {
          opensplat = pkgs.callPackage ./opensplat.nix {};
          opensplatWithCuda = packages.opensplat.override {useCuda = true;};
          default = packages.opensplat;
        };
        devShells.cuda = pkgs.mkShell {
          inputsFrom = [packages.opensplatWithCuda];
        };
        devShells.default = pkgs.mkShell {
          inputsFrom = [packages.opensplat];
        };
      }
    );
}
