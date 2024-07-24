{
  description = "Lemurs: A customizable TUI display/login manager written in Rust";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, rust-overlay }:
    let
      pname = "lemurs";
      version = "3.2.0-nightly";

      # System types to support.
      supportedSystems = [
        "x86_64-linux"
        "aarch64-linux"
        # "x86_64-darwin"
        # "aarch64-darwin"
      ];

      forAllSystems = function: nixpkgs.lib.genAttrs supportedSystems
        (system: function (import nixpkgs {
          inherit system;
          overlays = [ self.overlay rust-overlay.overlays.default ];
        }));
    in
    {
      overlay = final: prev: {
        lemurs = self.packages.${final.system}.lemurs;
      };

      packages = forAllSystems (pkgs:
        let
          rustToolchain = pkgs.rust-bin.stable.latest.default;
          rustPlatform = pkgs.makeRustPlatform {
            cargo = rustToolchain;
            rustc = rustToolchain;
          };
        in
        rec {
          default = lemurs;
          lemurs = pkgs.callPackage ./nix/lemurs.nix {
            inherit pname version rustPlatform;
          };
        });

      devShells = forAllSystems (pkgs: {
        default = pkgs.mkShell {
          packages = with pkgs; [
            pam
            nixpkgs-fmt
            rust-bin.stable.latest.default
          ];
        };
      });

      nixosModules = rec {
        default = lemurs;
        lemurs.imports = [
          { nixpkgs.overlays = [ self.overlay ]; }
          ./nix/lemurs-module.nix
        ];
      };
    };
}
