{
  description = "bc-250 governor";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-stable";
    flake-utils.url = "github:numtide/flake-utils";
    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, flake-utils, rust-overlay }:
    let
      perSystem = flake-utils.lib.eachDefaultSystem (system:
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
              description = "utils for bc-250 to run on NixOS";
              license = pkgs.lib.licenses.mit;
              platforms = [ "x86_64-linux" ];
            };
          };

          devShells.default = pkgs.mkShell {
            packages = [ rustToolchain pkgs.libdrm ];
          };
        }
      );

      nixosModule = { config, lib, pkgs, ... }:
        let cfg = config.bc250.display;
        in {
          options.bc250.display = {
            connector = lib.mkOption {
              type = lib.types.str;
              default = "DP-2";
            };
            width = lib.mkOption {
              type = lib.types.int;
              default = 3840;
            };
            height = lib.mkOption {
              type = lib.types.int;
              default = 2160;
            };
            refresh = lib.mkOption {
              type = lib.types.int;
              default = 144;
              description = "Display refresh rate in Hz";
            };
          };

          config = {
            hardware.firmware = [
              (pkgs.runCommand "bc250-edid" {} ''
                mkdir -p $out/lib/firmware/edid
                cp ${./edid/${toString cfg.width}x${toString cfg.height}.bin} \
                  $out/lib/firmware/edid/bc250.bin
              '')
            ];
            boot.kernelParams = [
              "drm.edid_firmware=${cfg.connector}:edid/bc250.bin"
              "video=${cfg.connector}:${toString cfg.width}x${toString cfg.height}@${toString cfg.refresh}"
            ];
          };
        };

    in
    perSystem // {
      nixosModules.default = nixosModule;
    };
}

