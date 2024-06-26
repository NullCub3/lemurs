{
  description = "Lemurs: A customizable TUI display/login manager written in Rust";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    utils.url = "github:numtide/flake-utils";
    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, utils, rust-overlay }:
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
          packages = rec {
            default = lemurs;
            lemurs = pkgs.callPackage ./nix/lemurs.nix {
              inherit packageName rustPlatform;
            };
          };

          devShells = {
            default = pkgs.mkShell {
              packages = with pkgs; [
                pam
                nixpkgs-fmt
                rustToolchain
              ];
            };
          };
        }
      ) // {

      overlays = rec {
        default = lemurs;
        lemurs = final: prev: {
          lemurs = self.packages.${final.system}.lemurs;
        };
      };

      nixosModules = rec {
        default = lemurs;
        # lemurs = import ./nix/lemurs-module.nix;
        lemurs.imports = [
          { nixpkgs.overlays = [ self.overlays.lemurs ]; }
          ./nix/lemurs-module.nix
        ];
      };

    };
}
