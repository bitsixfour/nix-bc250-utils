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
              default = "HDMI-A-1";
            };
            width = lib.mkOption {
              type = lib.types.int;
              default = 1920;
            };
            height = lib.mkOption {
              type = lib.types.int;
              default = 1080;
            };
          };
        # add firmware blobs to this?
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
