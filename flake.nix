{
  description = "Lemurs: A customizable TUI display/login manager written in Rust";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    utils.url = "github:numtide/flake-utils";
    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    { nixpkgs, utils, rust-overlay, ... }:
    utils.lib.eachDefaultSystem
      (system:
      let
        packageName = "lemurs";

        pkgs = import nixpkgs {
          inherit system;
          overlays = [ rust-overlay.overlays.default ];
        };

        rustToolchain = pkgs.rust-bin.stable.latest.default;

        rustPlatform = pkgs.makeRustPlatform {
          cargo = rustToolchain;
          rustc = rustToolchain;
        };
      in
      rec {
        devShells.default = pkgs.mkShell {
          packages = with pkgs; [
            linux-pam
            nixpkgs-fmt
            rustToolchain
          ];
        };

        packages = {
          default = packages.lemurs;
          lemurs = pkgs.callPackage ./nix/lemurs.nix {
            inherit packageName rustPlatform;
          };
        };
      }

      ) // {
      nixosModules = rec {
        default = lemurs;
        lemurs = import ./nix/lemurs-module.nix;
      };
    };
}
