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
          opensplat = pkgs.callPackage ./opensplat {};
          opensplatWithCuda = packages.opensplat.override {useCuda = true;};
          licensed = pkgs.callPackage ./licensed {};
          urlendec = pkgs.callPackage ./urlendec {};
        };
      }
    );
}
