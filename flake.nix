{
  description = "bc-250 governor";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-stable";
    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, rust-overlay }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        overlays = [ (import rust-overlay) ];
        pkgs = import nixpkgs { inherit system overlays; };
        rustToolchain = pkgs.rust-bin.stable.latest.default;
      in {
        packages.default = pkgs.rustPlatform.buildRustPackage {
          pname = "cyan-skillfish-governor";
          version = "0.3.0";
          src = ./.;
          cargoLock.lockFile = ./Cargo.lock;

          buildInputs = [ pkgs.libdrm ];
          nativeBuildInputs = [ rustToolchain ];

          meta = {
            description = "GPU governor for the AMD Cyan Skillfish APU";
            license = pkgs.lib.licenses.mit;
            platforms = [ "x86_64-linux" ];
          };
        };

        devShells.default = pkgs.mkShell {
          packages = [ rustToolchain pkgs.libdrm ];
        };
      }
    );
}
