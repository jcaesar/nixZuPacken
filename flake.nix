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
        pkgs = import nixpkgs {inherit system;};
      in rec {
        devShells.default = pkgs.mkShell {
          inputsFrom = [packages.default];
        };
        packages.default = pkgs.callPackage ./. {};
      }
    );
}
